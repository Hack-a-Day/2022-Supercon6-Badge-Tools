#!/usr/bin/env python3

# The MIT License (MIT)
# Copyright © 2022 Mike Szczys

# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: 

# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import argparse
from assemble import checksum, DisplayOptions, Registers

__version__ = "1.0"
header = [0x00, 0xFF, 0x00, 0xFF, 0xA5, 0xC3]

#Output options
options = DisplayOptions()

def is_valid(hexarray, h=header):
    #Return True if hex string has header and correct checksum
    #    Param: Hexarray is a list of hex values. There must be an even number of
    #    elements, each pair arrange with low byte first, high second.
    #    It must begin with the header values and end with a valid
    #    16-bit checksum as low-byte, high-byte pair for hex values
    header_len = len(h)
    hexarray_len = len(hexarray)

    if hexarray_len%2 != 0:
        raise Exception("Binary message must be an even number of bytes but %d were found." % hexarray_len)
    if hexarray[:6] != h:
        raise Exception("Binary message must begin with header: %s but found: %s" % (str(h),str(hexarray)))


    message = hexarray[header_len:-2]
    csum = checksum(message)
    if csum == hexarray[-2:]:
        return True
    else:
        m = format("Data has an invalid checksum, calculated %s but got %s" % (str(csum),str(hexarray[-2:])))
        if options.force:
            print(m)
            print("Force flag used, continuing despite failed checksum\n\n")
        else:
            raise Exception(m)

def read_hex_file(filename):
    with open(filename, mode='rb') as file:
        stream = file.read()
    return [h for h in stream]

def write_asm_file(filename, contents):
    with open(filename, 'w') as file:
        file.writelines("%s\n" % i for i in contents)
    return True

def disassemble(hexarray, h=header, print_output=True, outfile=None):
    output_buffer = []

    is_valid(hexarray)

    line_number = 0
    message = hexarray[len(h)+2:-2]
    for low,high in zip(*[iter(message)]*2):
        byte_l = format(low,"08b")
        byte_h = format(high,"08b")
        word_l = byte_l[4:]
        word_m = byte_l[:4]
        word_h = byte_h[4:]

        if word_h == "0000":
            source = excodes[word_m](word_h,word_m,word_l)
        else:
            source = opcodes[word_h](word_h,word_m,word_l)

        this_line = format_output_line(line_number, word_h, word_m, word_l, source)
        line_number += 1
        if print_output:
            print(this_line)
        if outfile != None:
            output_buffer.append(this_line)

    if outfile != None:
        return write_asm_file(outfile,output_buffer)


def format_output_line(ln, word_h, word_m, word_l, source):
    outstring = ""
    if options.show_linenums or options.show_verbose:
        outstring += "{:<3}    ".format(format(ln, "03X"))
    if options.show_words or options.show_verbose:
        if options.show_wordspace or options.show_verbose:
            outstring += "{:<4} {:<4} {:<4}    ".format(word_h, word_m, word_l)
        else:
            outstring += "{:<4}{:<4}{:<4}    ".format(word_h, word_m, word_l)

    if options.show_assembly or options.show_verbose:
        outstring += source

    return outstring.rstrip()

def args_rxry(instruction, oper_x, oper_y):
    return format("%s %s,%s" % (instruction, Registers().named_registers[int(oper_x,2)], Registers().named_registers[int(oper_y,2)]))

def args_ry(instruction, oper_y):
    return format("%s %s" % (instruction, Registers().named_registers[int(oper_y,2)]))

def args_r0n(instruction, oper_y):
    return format("%s R0,0b%s" % (instruction, oper_y))

def args_rgm(instruction, oper_y):
    reg = Registers().named_registers[int(oper_y[:2],2)]
    return format("%s %s,0b%s" % (instruction, reg, oper_y[2:]))
                  
def op_add_rxry(word_h,word_m,word_l):
    return args_rxry("ADD",word_m,word_l)
def op_adc(word_h,word_m,word_l):
    return args_rxry("ADC",word_m,word_l)
def op_sub(word_h,word_m,word_l):
    return args_rxry("SUB",word_m,word_l)
def op_sbb(word_h,word_m,word_l):
    return args_rxry("SBB",word_m,word_l)
def op_or_rxry(word_h,word_m,word_l):
    return args_rxry("OR",word_m,word_l)
def op_and_rxry(word_h,word_m,word_l):
    return args_rxry("AND",word_m,word_l)
def op_xor_rxry(word_h,word_m,word_l):
    return args_rxry("XOR",word_m,word_l)
def op_mov_rxry(word_h,word_m,word_l):
    return args_rxry("MOV",word_m,word_l)
def op_mov_rxn(word_h,word_m,word_l):
    return format("MOV %s,0b%s" % (Registers().named_registers[int(word_m,2)], word_l))
def op_mov_xyr0(word_h,word_m,word_l):
    return format("MOV [%s:%s],R0" % (Registers().named_registers[int(word_m,2)], Registers().named_registers[int(word_l,2)]))
def op_mov_r0xy(word_h,word_m,word_l):
    return format("MOV R0,[%s:%s]" % (Registers().named_registers[int(word_m,2)], Registers().named_registers[int(word_l,2)]))
def op_mov_nnr0(word_h,word_m,word_l):
    return format("MOV [0b%s:0b%s],R0" % (word_m, word_l))
def op_mov_r0nn(word_h,word_m,word_l):
    return format("MOV R0,[0b%s:0b%s]" % (word_m, word_l))
def op_mov_pcnn(word_h,word_m,word_l):
    return format("MOV PC,[0b%s:0b%s]" % (word_m, word_l))
def op_jr(word_h,word_m,word_l):
    return format("JR [0b%s:0b%s]" % (word_m, word_l))
def op_cp(word_h,word_m,word_l):
    return args_r0n("CP", word_l)
def op_add_r0n(word_h,word_m,word_l):
    return args_r0n("ADD", word_l)
def op_inc(word_h,word_m,word_l):
    return args_ry("INC", word_l)
def op_dec(word_h,word_m,word_l):
    return args_ry("DEC", word_l)
def op_dsz(word_h,word_m,word_l):
    return args_ry("DSZ", word_l)
def op_or_r0n(word_h,word_m,word_l):
    return args_r0n("OR", word_l)
def op_and_r0n(word_h,word_m,word_l):
    return args_r0n("AND", word_l)
def op_xor_r0n(word_h,word_m,word_l):
    return args_r0n("XOR", word_l)
def op_exr(word_h,word_m,word_l):
    return format("EXR %s" % word_l)
def op_bit(word_h,word_m,word_l):
    return args_rgm("BIT", word_l)
def op_bset(word_h,word_m,word_l):
    return args_rgm("BSET", word_l)
def op_bclr(word_h,word_m,word_l):
    return args_rgm("BCLR", word_l)
def op_btg(word_h,word_m,word_l):
    return args_rgm("BTG", word_l)
def op_rrc(word_h,word_m,word_l):
    return args_ry("RRC", word_l)
def op_ret(word_h,word_m,word_l):
    return args_r0n("RET", word_l)
def op_skip(word_h,word_m,word_l):
    flag = Registers().special_registers[int(word_l[:2],2)]
    return format("SKIP %s,0b%s" % (flag, word_l[2:]))

opcodes = {
    "0001": op_add_rxry,
    "0010": op_adc,
    "0011": op_sub,
    "0100": op_sbb,
    "0101": op_or_rxry,
    "0110": op_and_rxry,
    "0111": op_xor_rxry,
    "1000": op_mov_rxry,
    "1001": op_mov_rxn,
    "1010": op_mov_xyr0,
    "1011": op_mov_r0xy,
    "1100": op_mov_nnr0,
    "1101": op_mov_r0nn,
    "1110": op_mov_pcnn,
    "1111": op_jr,
    }

excodes = {
    "0000": op_cp,
    "0001": op_add_r0n,
    "0010": op_inc,
    "0011": op_dec,
    "0100": op_dsz,
    "0101": op_or_r0n,
    "0110": op_and_r0n,
    "0111": op_xor_r0n,
    "1000": op_exr,
    "1001": op_bit,
    "1010": op_bset,
    "1011": op_bclr,
    "1100": op_btg,
    "1101": op_rrc,
    "1110": op_ret,
    "1111": op_skip,
    }

def main():
    print("Supercon.6 Badge Disassembler version %s\n" % __version__)

    parser = argparse.ArgumentParser()
    parser.add_argument("hexfile", help=".hex file for disassembly")
    parser.add_argument("-q", help="Write to file without showing any human-readable output", action="store_true")
    parser.add_argument("-c", help="enable sourcecode readout", action="store_true")
    parser.add_argument("-n", help="enable line numbers", action="store_true")
    group = parser.add_mutually_exclusive_group()
    group.add_argument("-s", help="Show 12-bit instructions with spaces between words", action="store_true")
    group.add_argument("-w", help="Show 12-bit instructions without spaces between words", action="store_true")
    parser.add_argument("-f", help="Force disassembly if checksum fails", action="store_true")
    args = parser.parse_args()

    global options

    if args.q:
        options.show_output = False
    if args.c:
        options.show_verbose = False
        options.show_assembly = True
    if args.n:
        options.show_verbose = False
        options.show_linenums = True
    if args.s:
        options.show_verbose = False
        options.show_words = True
    if args.w:
        options.show_verbose = False
        options.show_words = True
        options.show_wordspace = False
    if args.f:
        options.force = True

    ext_idx = args.hexfile.rfind('.')
    if ext_idx > 0:
        outfile = args.hexfile[:ext_idx] + ".s"
    else:
        outfile = args.hexfile + ".s"
        
    status = disassemble(read_hex_file(args.hexfile), print_output=options.show_output, outfile=outfile)
    if status == True:
        print("\nSuccessfully wrote asm file: %s\n" % outfile)

if __name__ == "__main__":
    main()
