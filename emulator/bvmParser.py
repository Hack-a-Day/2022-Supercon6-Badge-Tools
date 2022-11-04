# bvmParser.py
# Adam Zeloof
# 3.12.2022


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

def parse(instruction: list) -> dict:
    opcode2 = get_bits(instruction[0], range(0,4))  
    opcode1 = get_bits(instruction[0], range(4,8)) 
    opcode0  = get_bits(instruction[1], range(0,4))
    padding = get_bits(instruction[1], range(4,8))
    # print(f"{bin(opcode0)},{bin(opcode1)}, {bin(opcode2)}") 
    assert(padding==0)
    g = get_bits(opcode2, [2,3])
    f = get_bits(opcode2, [2,3])
    m = get_bits(opcode2, [0,1])
    n = opcode2
    x = opcode1
    y = opcode2
    nn = opcode1 * 16 + opcode2   
    instr = {"opcode0":opcode0, "opcode1":opcode1, "opcode2":opcode2}
    

    if opcode0 != 0: # Four-bit opcode
        if opcode0 == 0x1:
            instr['op']= 'ADD'
            instr['args']={'mode':0, 'x':x, 'y':y}              
        elif opcode0 == 0x2:
            instr['op']= 'ADC'
            instr['args']= {'x':x, 'y':y}
        elif opcode0 == 0x3:
            instr['op']= 'SUB'
            instr['args']= {'x':x, 'y':y}
        elif opcode0 == 0x4:
            instr['op']= 'SBB'
            instr['args']= {'x':x, 'y':y}
        elif opcode0 == 0x5:
            instr['op']= 'OR'
            instr['args']= {'mode':0, 'x':x, 'y':y}
        elif opcode0 == 0x6:
            instr['op']= 'AND'
            instr['args']= {'mode':0, 'x':x, 'y':y}
        elif opcode0 == 0x7:
            instr['op']= 'XOR'
            instr['args']= {'mode':0, 'x':x, 'y':y}
        elif opcode0 == 0x8:
            instr['op']= 'MOV'
            instr['args']= {'mode':0, 'x':x, 'y':y}
        elif opcode0 == 0x9:
            instr['op']= 'MOV'
            instr['args']= {'mode':1, 'x':x, 'n':n}
        elif opcode0 == 0xA:
            instr['op']= 'MOV'
            instr['args']= {'mode':2, 'x':x, 'y':y}
        elif opcode0 == 0xB:
            instr['op']= 'MOV'
            instr['args']= {'mode':3, 'x':x, 'y':y}
        elif opcode0 == 0xC: # MOV [NN],R0
            instr['op']= 'MOV'
            instr['args']= {'mode':4, 'nn':nn}
        elif opcode0 == 0xD: # MOV R0,[NN]
            instr['op']= 'MOV'
            instr['args']= {'mode':5, 'nn':nn}
        elif opcode0 == 0xE: # MOV MOV PC, NN
            instr['op']= 'MOV'
            instr['args']= {'mode':6, 'nn':nn}
        elif opcode0 == 0xF:
            instr['op']= 'JR'
            instr['args']= {'nn':nn} # where does this get 2s-comped?
    else: #Eight-bit opcode
        if opcode1 == 0x0:
            instr['op']= 'CP'
            instr['args']= {'n':n}
        elif opcode1 == 0x1:
            instr['op']= 'ADD'
            instr['args']= {'mode':1, 'n':n}
        elif opcode1 == 0x2:
            instr['op']= 'INC'
            instr['args']= {'y':n}
        elif opcode1 == 0x3:
            instr['op']= 'DEC'
            instr['args']= {'y':n}
        elif opcode1 == 0x4:
            instr['op']= 'DSZ'
            instr['args']= {'y':y}
        elif opcode1 == 0x5:
            instr['op']= 'OR'
            instr['args']= {'mode':1, 'n':n}
        elif opcode1 == 0x6:
            instr['op']= 'AND'
            instr['args']= {'mode':1, 'n':n}
        elif opcode1 == 0x7:
            instr['op']= 'XOR'
            instr['args']= {'mode':1, 'n':n}
        elif opcode1 == 0x8:
            instr['op']= 'EXR'
            instr['args']= {'n':n}
        elif opcode1 == 0x9:
            instr['op']= 'BIT'
            instr['args']= {'g':g, 'm':m}
        elif opcode1 == 0xA:
            instr['op']= 'BSET'
            instr['args']= {'g':g, 'm':m}
        elif opcode1 == 0xB:
            instr['op']= 'BCLR'
            instr['args']= {'g':g, 'm':m}
        elif opcode1 == 0xC:
            instr['op']= 'BTG'
            instr['args']= {'g':g, 'm':m}
        elif opcode1 == 0xD:
            instr['op']= 'RRC'
            instr['args']= {'y':y}
        elif opcode1 == 0xE:
            instr['op']= 'RET'
            instr['args']= {'n':n}
        elif opcode1 == 0xF:
            instr['op']= 'SKIP'
            instr['args']= {'f':f, 'm':m}
        else:
            return None

    return instr
