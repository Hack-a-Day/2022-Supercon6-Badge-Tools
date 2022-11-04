# assemble.py
# Adam Zeloof
# 9.17.2022
# requires Python 3.10 or higher

def format(n):
    if len(n) < 2:
        return int(n)
    else:
        if n[0:2] == '0x':
            return int(n[2:],16)
        elif n[0:2] == '0b':
            return int(n[2:],2)
        else:
            return int(n)

def pad(n, b):
    if len(n) < b:
        n = '0'*(b-len(n)) + n
    elif len(n) > b:
        pass
    return n

def bits(n, b):
    # takes an int n and int b
    # returns a string of n represented in binary with b bits
    return pad(bin(n).split('b')[1],b)

def parse(instruction):
    ins = instruction.split(" ")
    if len(ins) > 1:
        # we have an instruction in the form [ins, args]
        op = ins[0]
        args = ins[1].split(",")
        nArgs = len(args)
        match op:
            case 'add':
                assert(nArgs==2)
                if args[1][0]=="r":
                    # RX,RY
                    x = int(args[0][1:])
                    y = int(args[1][1:])
                    return (0x1, x, y)
                else:
                    # R0,N
                    n = format(args[1])
                    return (0x0, 0x1, n)
            case 'adc':
                # RX,RY
                assert(nArgs==2)
                x = int(args[0][1:])
                y = int(args[1][1:])
                return (0x2, x, y)
            case 'sub':
                # RX,RY
                assert(nArgs==2)
                x = int(args[0][1:])
                y = int(args[1][1:])
                return (0x3, x, y)
            case 'sbb':
                # RX,RY
                assert(nArgs==2)
                x = int(args[0][1:])
                y = int(args[1][1:])
                return (0x4, x, y)
            case 'or':
                assert(nArgs==2)
                if args[1][0]=="r":
                    # RX,RY
                    x = int(args[0][1:])
                    y = int(args[1][1:])
                    return (0x5, x, y)
                else:
                    # R0,N
                    n = format(args[1])
                    return (0x0, 0x5, n)
            case 'and':
                assert(nArgs==2)
                if args[1][0]=="r":
                    # RX,RY
                    x = int(args[0][1:])
                    y = int(args[1][1:])
                    return (0x6, x, y)
                else:
                    # R0,N
                    n = format(args[1])
                    return (0x0, 0x6, n)
            case 'xor':
                assert(nArgs==2)
                if args[1][0]=="r":
                    # RX,RY
                    x = int(args[0][1:])
                    y = int(args[1][1:])
                    return (0x7, x, y)
                else:
                    # R0,N
                    n = format(args[1])
                    return (0x0, 0x7, n)
            case 'mov':
                if args[0][0] == 'r' and args[1][0] == 'r':
                    # RX,RY
                    x = int(args[0][1:])
                    y = int(args[1][1:])
                    return (0x8, x, y)
                elif args[0][0] == '[' and ':' in args[0]:
                     # [X:Y],R0
                    xy = args[0].strip('[]').split(":")
                    x = int(xy[0])
                    y = int(xy[1])
                    return (0xa, x, y)
                elif args[1][0] == '[' and ':' in args[1]:
                    # R0,[X:Y]
                    xy = args[1].strip('[]').split(":")
                    x = int(xy[0])
                    y = int(xy[1])
                    return (0xb, x, y)
                elif args[0][0] == '[':
                    # [NN],R0
                    nn = bits(format(args[0].strip('[]')),8)
                    n0 = int(nn[0:4],2)
                    n1 = int(nn[4:8],2)
                    return (0xc, n0 , n1)
                elif args[1][0] == '[':
                    # R0,[NN]
                    nn = bits(format(args[1].strip('[]')),8)
                    n0 = int(nn[0:4],2)
                    n1 = int(nn[4:8],2)
                    return (0xd, n0, n1)
                elif args[0][0] == 'r':
                    # RX,N
                    x = int(args[0][1:])
                    n = format(args[1])
                    return (0x9, x, n)
                elif args[0] == 'pc':
                    # PC,NN
                    nn = bits(format(args[1].strip('[]')),8)
                    n0 = int(nn[0:4],2)
                    n1 = int(nn[4:8],2)
                    return (0xe, n0, n1)
            case 'jr':
                # NN
                assert(nArgs==1)
                nn = bits(format(args[0].strip('[]')),8)
                n0 = int(nn[0:4],2)
                n1 = int(nn[4:8],2)
                return (0xf, n0, n1)
            case 'cp':
                # R0,N
                assert(nArgs==2)
                n = format(args[1])
                return (0x0, 0x0, n)
            case 'inc':
                # R0,N
                assert(nArgs==1)
                y = int(args[0][1:])
                return (0x0, 0x2, y)
            case 'dec':
                # R0,N
                assert(nArgs==1)
                y = int(args[0][1:])
                return (0x0, 0x3, y)
            case 'dsz':
                # RY
                assert(nArgs==1)
                y = int(args[0][1:])
                return (0x0, 0x4, y)
            case 'exr':
                # N
                assert(nArgs==1)
                n = format(args[0])
                return (0x0, 0x8, n)
            case 'bit':
                # RG,M
                assert(nArgs==2)
                g = bits(int(args[0][1:]),2)
                m = bits(format(args[1]),2)
                gm = int(g+m, 2)
                return (0x0, 0x9, gm)
            case 'bset':
                # RG,M
                assert(nArgs==2)
                g = bits(int(args[0][1:]),2)
                m = bits(format(args[1]),2)
                gm = int(g+m, 2)
                return (0x0, 0xa, gm)
            case 'bclr':
                # RG,M
                assert(nArgs==2)
                g = bits(int(args[0][1:]),2)
                m = bits(format(args[1]),2)
                gm = int(g+m, 2)
                return (0x0, 0xb, gm)
            case 'btg':
                # RG,M
                assert(nArgs==2)
                g = bits(int(args[0][1:]),2)
                m = bits(format(args[1]),2)
                gm = int(g+m, 2)
                return (0x0, 0xc, gm)
            case 'rrc':
                # RY
                assert(nArgs==1)
                y = int(args[0][1:])
                return (0x0, 0xd, y)
            case 'ret':
                # R0,N
                assert(nArgs==2)
                n = format(args[1])
                return (0x0, 0xe, n)
            case 'skip':
                #F,M
                f = bits(format(args[0]))
                m = bits(format(args[1]))
                fm = int(f+m, 2)
                return (0x0, 0xf, fm)
    return None


def load(program):
    out = []
    with open(program) as f:
        lines = f.readlines()
        for line in lines:
            #line = line.replace(" ","")
            line = line.replace("\n","")
            line = line.split('//')[0]
            if line != '':
                out.append(parse(line))
    return out


def assemble(inFile, outFile):
    instructions = load(inFile)
    with open(outFile, 'wb') as f:
        header = (0x00, 0xff, 0x00, 0xff, 0xa5, 0xc3)
        length = len(instructions)
        for b in header:
            f.write(b.to_bytes(1, byteorder='little', signed=False))
        f.write(length.to_bytes(2, byteorder='little', signed=False))
        for ins in instructions:
            assert(len(ins) == 3)
            A = (ins[1] << 4) + ins[2]
            B = ins[0]
            f.write(A.to_bytes(1, byteorder='little', signed=False))
            f.write(B.to_bytes(1, byteorder='little', signed=False))
        # TODO write checksum


if __name__ == "__main__":
    assemble("animation.bvm", "animation.bin")
