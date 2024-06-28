# badge.py
# Adam Zeloof
# 9.14.2022
# requires Python 3.10 or higher

from bvmCPU import CPU
from bvmParser import parse
from timeit import default_timer as timer
from random import randint
class Badge():
    def __init__(self):
        self.cpu = CPU()
        self.initMemory()
        self.clock = 0b0
        self.oldTime = timer()
        self.oldSync = timer()
        self.newTime = timer()
        self.speed = 250e3 # Hz
        self.usync = 1e3   # Hz
        self.progMem = []
        #self.pc = 0
        self.acc = [
            0b0000, # lower
            0b0000, # middle
            0b0000  # upper
        ]
        self.cFlag = [
            0b0, # lower
            0b0, # middle
            0b0  # upper
        ]
        self.zFlag = [
            0b0, # lower
            0b0, # middle
            0b0  # upper
        ]
        self.vFlag = [
            0b0, # lower
            0b0, # middle
            0b0  # upper
        ]
        self.userCarry = 0b0
        self.adders = [
            0b0000, # dest bits
            0b0000, # source bits
            0b0000, # carry bits
            0b0000  # sum bits
        ]
        self.page = 0b0000
        self.opcode0 = 0
        self.opcode1 = 0
        self.opcode2 = 0
    

    def initMemory(self):
        self.cpu.ram[0xff] = randint(0, 16) # Set random value at SFRFF
        self.cpu.ram[0xf4] = 0              # zero RdFlags

    def load(self, program):
        self.progmem=[]
        prog = open(program, 'rb').read()
        header = prog[0:6] 
        #print(header)
        lenBytes = prog[6:8]
        ll = (lenBytes[1]<<8) + lenBytes[0]
        # print(ll)
        checksum = prog[-2:]
        prog = prog[8:-2]
        for i in range(0, len(prog), 2):
            ins = prog[i:i+2]
            self.progMem.append(ins)
        # for (i,p) in enumerate(self.progMem):
        #     print(f"{i}:{p}")
        return

    def step(self):
        raw_instr = None
        try:
            raw_instr = self.progMem[self.cpu.getPC()]
        except IndexError:
            print('End of program!')
            raise EOFError
        instruction = parse(raw_instr)
        # print(instruction)
        print (f'{instruction["op"]}: {instruction["args"]}')
        self.cpu.step()
        if instruction is not None:
            self.opcode0 = instruction["opcode0"]
            self.opcode1 = instruction["opcode1"]  
            self.opcode2 = instruction["opcode2"] 
            getattr(self.cpu, instruction['op'])(instruction['args'])


    def update(self):
        self.newTime = timer()
        if self.newTime > self.oldSync + 0.5/self.usync:
            self.oldSync = timer()
            self.cpu.ram[0xf4] |= 0b0001 # set bit 0 in SFRF4
        if self.newTime > self.oldTime + 0.5/self.speed:
            if self.clock == 0:
                # Set random value at SFRFF
                # This does not really happen every clock cycle but its good enough
                self.cpu.ram[0xff] = randint(0, 16)
                # Set the page status
                self.page = self.cpu.ram[0xf0]
                # Step through the instructions
                self.step()
                self.clock = 1
            else:
                self.clock = 0
            self.oldTime = timer()

        # Check SFRF1 and set clock speed accordingly
        speeds = [250e3, 100e3, 30e3, 10e3, 3e3, 1e3, 500, 200, 100, 50, 20, 10, 5, 2, 1, .5]
        self.speed = speeds[self.cpu.ram[0xf1]]
        # Check SFRF2 and set UserSync accordingly
        usyncs = [1000, 600, 400, 250, 150, 100, 60, 40, 25, 15, 10, 6, 4, 2.5, 1.5, 1]
        self.usync = usyncs[self.cpu.ram[0xf2]]
