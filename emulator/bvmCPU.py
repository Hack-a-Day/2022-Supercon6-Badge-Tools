# bvmCPU.py
# Adam Zeloof
# 3.12.2022
# requires Python 3.10 or higher


def get_bit(n, i):  
    """returns the i'th bit of the number n (in binary)"""
    if n & (1<<i):
        return 1
    else:
        return 0

def get_bits(number, bit_list):
    """Returns the specified bits.  
    bit_list can be any list of bits, need not be sequential, but range(0,4) or
    range(4,8) are obvious candidates."""
    bitmask = 0
    for i in bit_list:
        bitmask = bitmask | (1 << i)
    number = number & bitmask
    lsb = min(bit_list) # in case list is out of order
    number = number >> lsb
    return number

def signed(n, b):
    # https://stackoverflow.com/questions/1604464/twos-complement-in-python
    if (n & (1 << (b - 1))) != 0: # if sign bit is set e.g., 8bit: 128-255
        n = n - (1 << b)        # compute negative value
    return n     


class CPU:
    def __init__(self):
        self.ram = [0] * 256
        self.sp = 0
        self.pc = 0

        # Flags
        self.V = 0
        self.Z = 0
        self.C = 0


    def getPC(self):
        #pcl = self.ram[13]
        #pcm = self.ram[14] << 4
        #pch = self.ram[15] << 8
        #return pch | pcm | pcl
        return self.pc


    def setPC(self, pc):
        #pc = bin(pc % 4096).split('b')[1]
        #pc = pad(pc, 12)
        #self.ram[13] = int(pc[8:12],2)
        #self.ram[14] = int(pc[4:8],2)
        #self.ram[15] = int(pc[0:4],2)
        self.pc = pc % 4096


    def step(self):
        # print(f"PC: {hex(self.pc)}")
        pc = self.getPC() + 1
        self.setPC(pc)
        


    def handleJumps(self, dest):
        if dest == 0x0c:
            # print(f"JSR called: {[hex(x) for x in self.ram[:15]]}")
            # dest is JSR, execute a subroutine call
            pc = self.pc % 4096
            self.sp = self.sp + 1
            if self.sp > 5:
                raise RuntimeError("Crash!  Stack overflow.  You can only nest five subroutines deep on this machine.  Or something has gotten loose.  Anyway, we're not going to let you just write all over page RAM so easily.")
            print(f"stack pointer depth: {self.sp}")
            # Load the current PC into the stack
            self.ram[0x10+self.sp*3-3] = get_bits(pc, range(0,4))#self.ram[0x0d]
            self.ram[0x10+self.sp*3-2] = get_bits(pc, range(4,8))#self.ram[0x0e]
            self.ram[0x10+self.sp*3-1] = get_bits(pc, range(8,12))#self.ram[0x0f]
            # Set the PC
            jsr = self.ram[0x0c]
            pcm = self.ram[0x0e] << 4
            pch = self.ram[0x0f] << 8
            self.pc = pch + pcm + jsr 
            print(f"GOSUB jump to {hex(self.pc)}")
            print (f"RAM before GOSUB:\n {[hex(x) for x in self.ram[:8]]}\n {[hex(x) for x in self.ram[8:16]]}")
        elif dest == 0x0d:
            # dest is PCL, execute a program jump
            pcl = self.ram[0x0d]
            pcm = self.ram[0x0e] << 4
            pch = self.ram[0x0f] << 8
            self.pc = pch | pcm | pcl 
            print(f"GOTO jump to {hex(self.pc)}")
            #print (f"RAM before GOTO:\n {[hex(x) for x in self.ram[:8]]}\n {[hex(x) for x in self.ram[8:16]]}")

    def ADD(self, args):
        if args['mode'] == 0:
            # RX,RY
            x = args['x']
            y = args['y']
            a = self.ram[x]
            b = self.ram[y]
            res = a + b
            self.ram[x] = res % 16
            if res > 15:
                self.C = 1
            else:
                self.C = 0
            if res == 0:
                self.Z = 1
            else:
                self.Z = 0
            if (signed(a, 4) + signed(b, 4) > 7) or (signed(a, 4) + signed(b, 4) < -8):
                self.V = 1
            else:
                self.V = 0

        elif args['mode'] == 1: # R0,N
            a = self.ram[0]
            b = args['n']
            res = a + b
            self.ram[0] = res % 16
            if res > 15:
                self.C = 1
            else:
                self.C = 0
            if res == 0:
                self.Z = 1
            else:
                self.Z = 0
            if (signed(a, 4) + signed(b, 4) > 7) or (signed(a, 4) + signed(b, 4) < -8):
                self.V = 1
            else:
                self.V = 0
    

    def ADC(self, args):
        x = args['x']
        y = args['y']
        a = self.ram[x]
        b = self.ram[y]
        res = a + b + self.C
        self.ram[x] = res % 16
        # I think the docs are wrong here, using same behaivor as ADD regarding overflow
        if res > 15:
            self.C = 1
        else:
            self.C = 0
        if res == 0:
            self.Z = 1
        else:
            self.Z = 0
        if (signed(a, 4) + signed(b, 4) + self.C > 7) or (signed(a, 4) + signed(b, 4) + self.C < -8):
            self.V = 1
        else:
            self.V = 0
    

    def SUB(self, args):
        x = args['x']
        y = args['y']
        a = self.ram[x]
        b = self.ram[y]
        res = a - b
        self.ram[x] = res % 16
        if res < 0:
            self.C = 1
        else:
            self.C = 0
        if res == 0:
            self.Z = 1
        else:
            self.Z = 0
        if (signed(a, 4) - signed(b, 4) > 7) or (signed(a, 4) - signed(b, 4) < -8):
            self.V = 1
        else:
            self.V = 0
    

    def SBB(self, args):
        x = args['x']
        y = args['y']
        a = self.ram[x]
        b = self.ram[y]
        res = a - b - int(self.C==0)
        self.ram[x] = res % 16
        if res < 0:
            self.C = 1
        else:
            self.C = 0
        if res == 0:
            self.Z = 1
        else:
            self.Z = 0
        if (signed(a, 4) - signed(b, 4)  - int(self.C==0) > 7) or (signed(a, 4) - signed(b, 4) - int(self.C==0) < -8):
            self.V = 1
        else:
            self.V = 0
    

    def OR(self, args):
        if args['mode'] == 0:
            x = args['x']
            y = args['y']
            self.ram[x] = self.ram[x] | self.ram[y]
            if self.ram[x] == 0:
                self.Z = 1
            else:
                self.Z = 0
        elif args['mode'] == 1:
            n = args['n']
            self.ram[0] = self.ram[0] | n
            if self.ram[0] == 0:
                self.Z = 1
            else:
                self.Z = 0
    

    def AND(self, args):
        if args['mode'] == 0:
            x = args['x']
            y = args['y']
            self.ram[x] = self.ram[x] & self.ram[y]
            if self.ram[x] == 0:
                self.Z = 1
            else:
                self.Z = 0
        elif args['mode'] == 1:
            n = args['n']
            self.ram[0] = self.ram[0] & n
            if self.ram[0] == 0:
                self.Z = 1
            else:
                self.Z = 0
    

    def XOR(self, args):
        if args['mode'] == 0:
            x = args['x']
            y = args['y']
            self.ram[x] = self.ram[x] ^ self.ram[y]
            if self.ram[x] == 0:
                self.Z = 1
            else:
                self.Z = 0
        elif args['mode'] == 1:
            n = args['n']
            self.ram[0] = self.ram[0] ^ n
            if self.ram[0] == 0:
                self.Z = 1
            else:
                self.Z = 0
    

    def MOV(self, args):
        if args['mode'] ==  0: # RX,RY
            x = args['x']
            y = args['y']
            self.ram[x] = self.ram[y]
            self.handleJumps(x)
        elif args['mode'] ==  1: # RX,N
            x = args['x']
            n = args['n']
            self.ram[x] = n
            self.handleJumps(x)
        elif args['mode'] ==  2: # XY,R0
            rx = self.ram[args['x']]
            ry = self.ram[args['y']]
            addr = rx << 4 | ry
            self.ram[addr] = self.ram[0]
        elif args['mode'] ==  3: # R0,XY
            rx = self.ram[args['x']]
            ry = self.ram[args['y']]
            addr = rx << 4 | ry
            self.ram[0] = self.ram[addr]
        elif args['mode'] ==  4: # NN,R0
            self.ram[args['nn']] = self.ram[0]
        elif args['mode'] ==  5: # R0,NN
            self.ram[0] = self.ram[args['nn']]
        elif args['mode'] ==  6: # PC,NN
            # print(f"before mov PC, {hex(args['nn'])}" )
            self.ram[15] = (args['nn'] & 0xF0) >> 4
            self.ram[14] = args['nn'] & 0x0F
            # print(f"mov PC, {self.ram[15]}  , {self.ram[14]}" )
            # print (f"RAM after MOV: {[hex(x) for x in self.ram[:16]]}")
    

    def JR(self, args):
        pc = self.getPC()
        pc += signed(args['nn'], 8)
        self.setPC(pc)
    

    def CP(self, args):
        r0 = self.ram[0]
        n = args['n']
        # print(f"comparing {r0} with {n}")
        if (r0 >= n):
            self.C = 1
        else:
            self.C = 0
        if r0 == n:
            self.Z = 1
        else:
            self.Z = 0
        # print(f"C: {self.C}, Z: {self.Z}")

    def INC(self, args):
        y = args['y']
        self.ram[y] = (self.ram[y] + 1) % 16
        self.handleJumps(y)
        if self.ram[y] == 0:
            self.Z = 1
        else:
            self.Z = 0


    def DEC(self, args):
        y = args['y']
        self.ram[y] = (self.ram[y] - 1) % 16
        self.handleJumps(y)
        if self.ram[y] == 0:
            self.Z = 1
        else:
            self.Z = 0

    

    def DSZ(self, args):
        y = args['y']
        self.ram[y] = (self.ram[y] - 1) % 16
        if self.ram[y] == 0:
            self.step()
    

    def EXR(self, args):
        n = args['n']
        for i in range(0, (n-1)%16+1):
            p14_addr = 0xE << 4 | i
            r = self.ram[i]
            p = self.ram[p14_addr]
            self.ram[i] = p
            self.ram[p14_addr] = r
    
    def BIT(self, args):
        r = self.ram[args['g']] # doesn't handle RIN, but emu anyway
        b = args['m']
        if get_bit(r, b): # test if bit is 0
            self.Z = 0
        else:
            self.Z = 1

    def BSET(self, args):
        r = self.ram[args['g']]
        self.ram[args['g']] = r | ( 1<<args['m'] )

    def BCLR(self, args):
        r = self.ram[args['g']]
        self.ram[args['g']] = r & ~(1 << args['m'])

    def BTG(self, args):
        r = self.ram[args['g']]
        self.ram[args['g']] = r ^ (1 << args['m'])

    def RRC(self, args):
        y = self.ram[args['y']]
        y = y + (self.C << 4) # add in carry
        if y & 1:  # last bit is set
            self.C = 1
        else:
            self.C = 0
        self.ram[args["y"]] = y >> 1 


    def RET(self, args): 
        self.ram[0] = args['n']
        #self.ram[13] = self.ram[0x10+self.sp*3-3]
        #self.ram[14] = self.ram[0x10+self.sp*3-2]
        #self.ram[15] = self.ram[0x10+self.sp*3-1]
        pcl = self.ram[0x10+self.sp*3-3]
        pcm = self.ram[0x10+self.sp*3-2] << 4
        pch = self.ram[0x10+self.sp*3-1] << 8
        # print (f"{self.ram[0x10]}, {self.ram[0x11]},{self.ram[0x12]}")
        # print(f"jump to {hex(self.pc)}")
        self.pc = pch | pcm | pcl
        self.sp = self.sp - 1
        if self.sp < 0:
            raise RuntimeError("Crash!  Stack underrun.  You've called one more RET than JSRs.  Check your control flow.")
        print(f"returning: stack pointer {self.sp}")
        print (f"RAM on RET:\n {[hex(x) for x in self.ram[:8]]}\n {[hex(x) for x in self.ram[8:16]]}")
    

    def SKIP(self, args):
        f = args['f'] ## condition
        m = args['m'] ## number of instructions
        #print(f"condition {f}, instructions {m}")
        skip = False
        if f ==  0b00: # C
            if self.C:
                skip = True
        elif f ==  0b01: # NC
            if not self.C:
                skip = True
        elif f ==  0b10: # Z
            if self.Z:
                skip = True
        elif f ==  0b11: # NZ
            if not self.Z:
                skip = True
        if skip:
            pc = self.getPC()
            # print(f"pre-skip: {hex(pc)}")
            pc += (m-1)%4+1  
            # print(f"post-skip: {hex(pc)}")
            self.setPC(pc)
    

