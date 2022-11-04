#!/usr/bin/env python3

# The MIT License (MIT)
# Copyright © 2022 Mike Szczys

# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: 

# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import argparse
import string
import codecs
import sys

__version__ = "1.0"

class SyntaxConstants:
    comment_delimiter = ";"     #Must be a single character or tokenizer will break
    accepted_chars = string.ascii_letters+string.digits+"._"
    special_delimiters = [',',':','[',']','+','-']  #Characters that me up the ASM language
    modifying_keywords = ["LOW","MID","HIGH"]
    modifying_operators = ["+","-"]
    header = [0x00, 0xFF, 0x00, 0xFF, 0xA5, 0xC3]

    def get_all_delimiters(self):
        return self.special_delimiters + [self.comment_delimiter]

#Output options
class DisplayOptions:
    def __init__(self):
        self.show_output = True
        self.show_verbose = True     #Prints all optional things (spaces, comments, empty lines)
        self.show_wordspace = False
        self.show_linenums = False
        self.show_comments = False
        self.show_assembly = False

        #used only by fbb_dis.py
        self.show_words = False
        self.force = False

    def show_verbose_output(self):
        return self.show_output & self.show_verbose

    def show_linenums_or_verbose(self):
        return self.show_linenums | self.show_verbose

    def show_assembly_or_verbose(self):
        return self.show_assembly | self.show_verbose

    def show_wordspace_or_verbose(self):
        return self.show_wordspace | self.show_verbose

########### Globals #################
options = DisplayOptions()  #options for what output will be shown
symbols = dict()            #lookup table for symbols (labes, EQU, etc.)
syntax = SyntaxConstants()  #stores values for partsing ASM language
#####################################

class Registers:
    named_registers = (
        #Important: Don't change the index positions of the ops as they're
        #being used in generating machine code
        "R0",
        "R1",
        "R2",
        "R3",
        "R4",
        "R5",
        "R6",
        "R7",
        "R8",
        "R9",
        "OUT",
        "IN",
        "JSR",
        "PCL",
        "PCM",
        "PCH",
        )

    special_registers = (
        #Important: Don't change the index positons of C,NC,Z,NZ as they're
        #being used in generating machine code
        "C",
        "NC",
        "Z",
        "NZ",
        "PC",
    )

    all_registers = named_registers+special_registers

def parse_asm(lines_of_asm,hexfile_out=None):
    global symbols

    #First pass: Tokenize the input
    try:
        code_list, symbols = get_tokenized_code(lines_of_asm)
    except ParserError:
        #Error message will have already printed so bail
        return

    #Second pass: Generate output
    machine_lines = 0
    assembled_code = []
    for i, c in enumerate(code_list):
        c = code_list[i]
        tokens = c.tokens
        
        #Print Blank Lines and Tokens in Verbose Mode
        if tokens == None:
            if options.show_verbose_output():
                print_output(c.source, None, None, non_opcode=True)
            continue
        elif tokens[0] in symbols:
            if options.show_verbose_output():
                print_output(c.source, None, None, non_opcode=True)
            continue

        #Do a substitution pass for variables in this set of tokens
        working_tokens = list()
        for t in tokens:
            if type(t) == SmartToken:
                if len(working_tokens) > 0 and working_tokens[0] == "JR":
                    working_tokens.append(t.resolve(symbols, relative_to_this_line_number=machine_lines))
                else:
                    working_tokens.append(t.resolve(symbols))
            elif t in syntax.special_delimiters:
                continue
            else:
                working_tokens.append(t.upper())
        #Get the machine code for this set of tokens
        try:
            opcode = working_tokens[0]
            if opcode.upper() == Opcodes().ORG:
                machinecode_tuple = Opcodes().get_binary(working_tokens, machine_lines)
                #Print source line if needed
                if options.show_verbose_output():
                    print_output(c.source, None, None, non_opcode=True)
                if len(machinecode_tuple) == 0:
                    #This only happens when ORG # calls the next valid line number so do nothing
                    continue
            elif opcode.upper() == Opcodes().ASCII:
                if options.show_verbose_output():
                    print_output(c.source+"\n", None, None, non_opcode=True)
                #Don't use working_tokens for ASCII op as it made everything uppercase
                machinecode_tuple = Opcodes().get_binary(tokens)
            else:
                machinecode_tuple = Opcodes().get_binary(working_tokens)
        except ParserError as e:
            print_error(e, i, c.source)
            return

        #Bomb out if we didn't get any code back
        if machinecode_tuple == None:
            print_error(ParserError("E::Uncaught syntax error"), i, c.source)
            return
        
        #vars to track repeated line output
        last_output_array = [None,None,None]
        repeat_count = 0
        for i,mcode in enumerate(machinecode_tuple):
            #Special directives GOSUB, GOTO, and ORG will return multiple lines
            ln = machine_lines if options.show_linenums_or_verbose() else None
            
            cm = None

            #Setup comment and source code display for non-special cases
            #"BYTE" gets grouped in here to write these to just the first of the two generated lines
            if tokens[0] not in Opcodes().pseudo_opcodes or (tokens[0] in (Opcodes().BYTE,Opcodes().GOTO,Opcodes().GOSUB) and i==0):
                if options.show_assembly_or_verbose():
                    cm = c.source
                elif options.show_comments:
                    cm = c.comment
            elif tokens[0]==Opcodes().ASCII and i==0 and options.show_comments:
                cm = c.comment

            if options.show_output:
                #logic to truncate repeated lines
                cur_output = [convert_machine_code_to_binary(mcode), ln, cm]
                if last_output_array[0] != cur_output[0]:
                    if repeat_count >= 3:
                        print_output("\n...repeated lines truncated...\n",None,None, assembler_message=True)
                    repeat_count = 0
                    last_output_array = cur_output
                    print_output(*cur_output)
                else:
                    if repeat_count < 3:
                        print_output(*cur_output)
                    elif i==len(machinecode_tuple)-1:
                        print_output("\n...repeated lines truncated...\n",None,None, assembler_message=True)
                    repeat_count += 1

            assembled_code.append(mcode)
            machine_lines += 1
    
        if machine_lines > 0xFFF+1:
            print_error("\nE::Program memory limit (4096) overflow\n", i, c.source)
            return

    if hexfile_out != None:
        with open(hexfile_out, "wb") as f:
            f.write(bytes(generate_hex(assembled_code)))
        return True

def get_tokenized_code(lines_of_asm):
    code_array = []
    symbols = dict()

    reg_addr = 0
    
    raw_code = lines_of_asm.split('\n')
    for i in range(len(raw_code)):
        try:
            code_obj = parse_line(raw_code[i])
        except ParserError as e:
            print_error(e, i, raw_code[i])
            raise ParserError()

        code_array.append(code_obj)

        #Validate the opcodes/labels during first pass
        if code_obj.tokens != None:
            token = code_obj.tokens[0].upper()
            if token not in Opcodes().instructions:
                #This must be a symbol or a variable definition
                if token in symbols:
                    print_error("E::Cannot define a token that was previously defined", i, code_obj.source)
                    raise ParserError()
                else:
                    #Prewind the register number for use if this turns out to be a label
                    s_value = reg_addr
                    if len(code_obj.tokens) > 1:
                        if str(code_obj.tokens[1]).upper() == Opcodes().EQU:
                            #This is a variable definition, set this value in the symbol table
                            s_value = code_obj.tokens[2].resolve(symbols)
                            symbols[token] = s_value
                        elif str(code_obj.tokens[1]) == ":":
                            #This is a label, write line number to symbol table
                            symbols[token] = s_value
                        else:
                            print_error(format("E::Invalid keyword: %s" % str(code_obj.tokens[0])), i, code_obj.source)
                            raise ParserError()
            else:
                if token == Opcodes().GOSUB or token == Opcodes().GOTO:
                    #These directives will add two lines of code instead of one so adjust here
                    reg_addr += 2
                elif token == Opcodes().ORG:
                    new_linenum = get_dec_or_token(code_obj.tokens[1].resolve(symbols))
                    if type(new_linenum) != int or not 0 <= new_linenum < 4096:
                        print_error("E::This opcode requires a number [0..4095] as argument but got %s" % new_linenum, i, code_obj.source)
                        raise ParserError()
                    elif new_linenum < reg_addr:
                        print_error("E::The ORG opcode requires the argument (%s) be greater or equal to the next program memory register number (%s)" % (str(new_linenum), str(reg_addr)), i, code_obj.source)
                        raise ParserError()
                    else:
                        reg_addr = new_linenum
                elif token.upper() == Opcodes().ASCII:
                    #Each character will generate two RET instructions
                    reg_addr += 2*len(code_obj.tokens[1])
                else:
                    #All other instructions increment the address by one
                    reg_addr += 1
    return code_array,symbols

def tokenize(instring, delimiters=syntax.get_all_delimiters()):
    '''
    Tokenize a string of ASM code, splitting based on special characters
    but at the same time including delimiters (but not whitespace) in the set
    '''
    #Speedup: Only test delimiters that we know are present
    found_delimiters = [x for x in delimiters if x in instring]
    tokens = instring.split()
    for d in found_delimiters:
        newtokens = list()
        for t in tokens:
            raw = t.split(d)
            for r_idx, r_token in enumerate(raw):
                if r_token != '':
                    '''
                    element will be empty when delimiter begins or
                    ends the string that was split
                    so don't add empty elements
                    '''
                    newtokens.append(r_token)
                if r_idx != len(raw)-1:
                    newtokens.append(d)
        tokens = newtokens
    return tokens

def parse_line(instring):
    '''
    Performs the work of tokenizing a single line of code,
    ensuring that the syntax is valid (although this does
    not mean the combo of instructions and operands is valid.)

    Returns CodePack() object
    '''
    raw_tokens = tokenize(instring)
    parsed_tokens = list()
    code = CodePack(source=instring)
    s = TokenizerStates()

    #Preserve full comment
    if syntax.comment_delimiter in instring:
        d_idx = instring.index(syntax.comment_delimiter)
        code.comment = instring[d_idx:]

    #Custom type to contain Token streams. Will be used for symbol substition and math in second pass
    token_stream = SmartToken()

    if len(raw_tokens) > 0 and raw_tokens[0].upper() == Opcodes().ASCII:
        #ASCII is a special pseudo-op not compatible with the flow chart
        target_string = validate_string(instring.split(syntax.comment_delimiter)[0]) #Be sure to filter out any comment
        code.tokens = [raw_tokens[0].upper(),target_string]
        return code


    #Walk through the flowchart
    for e in raw_tokens:
        e = e.upper()
        if s.cur_state==s.OPCODE:
            if all(c in syntax.accepted_chars for c in e):
                parsed_tokens.append(e)
                s.cur_state = s.WATCH_TOKEN_SET
                continue
            elif e == syntax.comment_delimiter:
                #Comment already preserved, nothing left to parse
                break
            else:
                raise ParserError("E::Syntax error: Invalid characters found in: %s" % e)

        elif s.cur_state==s.WATCH_COMMENT:
            #The only trigger character valid from here on out is comment_delimiter
            if e != syntax.comment_delimiter:
                raise ParserError("E::Expected comment (%s) or end of line but got %s" % (syntax.comment_delimiter, e))
            else:
                #Comment already preserved, nothing left to do
                break

        elif s.cur_state==s.WATCH_COMMA_COMMENT:
            if e==",":
                #Should be another token or set coming
                s.cur_state = s.WATCH_TOKEN_SET
                continue
            elif e==syntax.comment_delimiter:
                #Comment already preserved, nothing left to do
                break
            else:
                raise ParserError("E::Expected comma (,) or comment (%s) but got %s" % (syntax.comment_delimiter, e))

        elif s.cur_state in [s.WATCH_TOKEN_SET,
                s.TOKEN_COLON_BRACKET,
                s.TOKEN_BRACKET,
                s.TOKEN_COMMA_COMMENT,
                s.TOKEN_COMMENT,
                s.TOKEN_VAR_DEF]:

            '''
            Need to know what came before. This is tricky because sometimes we will already
            be filling a token stream and other times we'll just be starting one
            '''
            if len(token_stream) != 0:
                previous = token_stream[-1]
            else:
                previous = parsed_tokens[-1]
            
            if type(previous) == int:
                prev_isvalid = True
            else:
                #Raised error tells us this is not a valid token but has special characters in it
                try:
                    validate_token(previous)
                    prev_isvalid = True
                except:
                    prev_isvalid = False

            if e==Opcodes().EQU:
                if s.cur_state == s.WATCH_TOKEN_SET and len(parsed_tokens)==1 and len(token_stream)==0:
                    #Found EQU in the right place
                    parsed_tokens.append(e)
                    s.cur_state = s.TOKEN_VAR_DEF
                    continue
                raise ParserError("E::Unexpected EQU after %s" % str(previous))
            elif e=='[':
                if s.cur_state == s.WATCH_TOKEN_SET:
                    #Found [ in right place
                    token_stream.append(e)
                    s.cur_state = s.TOKEN_COLON_BRACKET
                    continue
                raise ParserError("E::Unexpected opening bracket ([) after %s" % str(previous))
            elif e==':':
                if s.cur_state == s.TOKEN_COLON_BRACKET and prev_isvalid:
                    #Found : in right place
                    token_stream.append(e)
                    s.cur_state = s.TOKEN_BRACKET
                    continue
                elif len(parsed_tokens)==1 and prev_isvalid:
                    #This is a label assignment; Nothing should come after this but a comment
                    #This colon is not inside of brackets so it isn't part of a token_stream; it's part of parsed_tokens
                    parsed_tokens.append(e)
                    s.cur_state = s.WATCH_COMMENT
                    continue
                raise ParserError("E::Unexpected colon (:) after %s" % str(previous))
            elif e=="]":
                if s.cur_state in [s.TOKEN_BRACKET, s.TOKEN_COLON_BRACKET] and prev_isvalid:
                    #Found ] in right place
                    token_stream.append(e)
                    parsed_tokens.append(token_stream)
                    token_stream = SmartToken()
                    s.cur_state = s.WATCH_COMMA_COMMENT
                    continue
                raise ParserError("E::Unexpected closing bracket (]) after " % str(previous))
            elif e==",":
                if s.cur_state == s.TOKEN_COMMA_COMMENT and prev_isvalid:
                    #Found , in right place
                    if len(token_stream) != 0:
                        parsed_tokens.append(token_stream)
                        token_stream = SmartToken()
                    parsed_tokens.append(e)
                    s.cur_state = s.WATCH_TOKEN_SET
                    continue
                raise ParserError("E::Unexpected comma (,) after %s" % str(previous))
            elif e==";":
                if s.cur_state in [s.TOKEN_COMMA_COMMENT, s.TOKEN_COMMENT, s.TOKEN_VAR_DEF] and prev_isvalid:
                    if len(token_stream) != 0:
                        parsed_tokens.append(token_stream)
                        token_stream = SmartToken() #Probably don't need to reset this but just in case
                    if s.cur_state==s.TOKEN_VAR_DEF:
                        if len(parsed_tokens) != 3:
                            raise ParserError("E::Wrong number of items in EQU statement")
                    #Found ; in right place, no need to parse more
                    break
                raise ParserError("E::Unexpected opening semicolon (;) after " % str(previous))

            elif e in syntax.modifying_keywords:
                if previous in Opcodes().token_preceders:
                    #Valid HIGH/LOW modifier
                    token_stream.append(e)
                    continue
                raise ParserError("E::Unexpected modifier %s after %s" % (e,str(previous)))
            elif e in syntax.modifying_operators:
                if previous in Opcodes().token_preceders:
                    #Hack: add 0 before leading operator (like -/+)
                    token_stream.append(0)
                    token_stream.append(e)
                    continue
                elif prev_isvalid:
                    #Operators can follow valid tokens
                    token_stream.append(e)
                    continue
                raise ParserError("E::Unexpected operator %s after %s" % (e,str(previous)))
            else:

                #Should have taken care of all modifiers and dividers
                #This will raise an error if it is not a valid token being added
                token_stream.append(validate_token(e))
                if s.cur_state == s.WATCH_TOKEN_SET:
                    #We got the token we were watching for so now look for more of this token, or a comma or comment
                    s.cur_state = s.TOKEN_COMMA_COMMENT
                continue
        else:
            raise ParserError("E::Unknown parser state machine cur_state value: %s" % s.cur_state)

    #Catch any token_streams that weren't written
    if len(token_stream) != 0:
        parsed_tokens.append(token_stream)
    if len(parsed_tokens) != 0:
        code.tokens = parsed_tokens
    return code

def validate_token(e):
    '''
    Validates the token part of the token stream (letter, numbers, underscore, period)
    but raises error if special characters like +,-,[,] are found.
    '''
    if all(c in syntax.accepted_chars for c in e):
        return e
    else:
        raise ParserError("E::Illegal characters in token: %s" % e)

def validate_string(instring):
    '''
    Validates string passed by ASCII pseudo-op
    This will separate the code, and ensure the string escapes correctly without unprintable chars
    '''
    p_op = instring.lstrip().split()[0]
    if p_op.upper() != Opcodes().ASCII:
        raise ParserError("E::Expected ASCII psuedo-op but got %s" % p_op)
    target_string = instring.lstrip()[len(Opcodes().ASCII):].strip()
    if target_string[0] != '"' or target_string[-1] != '"':
        raise ParserError("E::Expected string to start/end with a quote (\") but got %s and %s" % (target_string[0], target_string[-1]))
    for c in target_string:
        if c not in Opcodes().VALID_MESSAGE_CHARS:
            raise ParserError("E::Invalid character in string passed by ASCII: %s\nOnly these characters are valid: %s" % (c,Opcodes.VALID_MESSAGE_CHARS))
    return target_string[1:-1]

def format_unexpected_char_error(element,previous):
    return format("E::Syntax error: Unexpected %s after %s" % (element,str(previous)))

class TokenizerStates:
    OPCODE = 0
    TOKEN_COMMA_COMMENT = 1
    TOKEN_COMMENT = 2
    TOKEN_COLON_BRACKET = 3
    TOKEN_BRACKET = 4
    BRACKETS = 5
    WATCH_TOKEN_SET = 6
    WATCH_COMMA_COMMENT = 7
    WATCH_COMMENT = 8
    TOKEN_VAR_DEF = 9

    def __init__(self):
        self.cur_state = self.OPCODE
        self.reset_buffers()
    
    def reset_buffers(self):
        self.bracket_token_buffer = []

class SmartToken(list):
    def __init__(self, data=None):
        if (data != None):
            self._stream = list(data)
        else:
            self._stream = list()
    def resolve(self, symbols, relative_to_this_line_number=None):
        is_set = False
        found_named_reg = False
        prefix = None
        working_token = None
        resolved_set = None
        for i, e in enumerate(self):
            try:
                e = e.upper()
            except:
                pass
            if e in Registers().all_registers:
                    found_named_reg = True

            if e=='[':
                if i==0:
                    is_set = True
                    resolved_set = list()
                    continue
                else:
                    raise Exception("Unexpected opening bracket when parsing smart token. This should never happen")
            elif e==":":
                resolved_set.append(working_token)
                found_named_reg = False
                prefix = None
                working_token = None
                continue
            elif e=="]":
                if i==len(self)-1:
                    resolved_set.append(working_token)
                    found_named_reg = False
                    prefix = None
                    working_token = None
                    continue
                else:
                    raise Exception("Unexpected opening bracket when parsing smart token. This should never happen")
            elif e in syntax.modifying_keywords+syntax.modifying_operators:
                prefix = e
                continue
                    
            #Everything that's not a symbol or a token has been filtered out by now
            if e in symbols:
                if working_token == None and relative_to_this_line_number != None:
                    #This is used for calculating symbol values relative to actual line number for JR opcode
                    target_line = symbols[e]
                    filtered_t = target_line-relative_to_this_line_number
                    #Subtract 1 to counteract PC increment
                    filtered_t -= 1
                else:
                    filtered_t = symbols[e]
            else:
                filtered_t = get_dec_or_token(e)

            if prefix != None:
                if found_named_reg == True:
                    #If a named register is already in the working_token this will already be set to True
                    raise ParserError("E::Syntax error: Modifications like (%s) may only be performed on numbers but a named register was found." % prefix)
                if type(filtered_t) != int:
                    raise ParserError("E::Syntax error: Modifications like (%s) may only be performed on numbers but %s was found." % prefix)
                if prefix=="LOW":
                    working_token = filtered_t&0xF
                elif prefix=="MID":
                    working_token = (filtered_t>>4)&0xF
                elif prefix=="HIGH":
                    working_token = (filtered_t>>8)&0xF
                elif prefix=="+":
                    working_token += filtered_t
                elif prefix=="-":
                    if not working_token:
                        working_token = 0-filtered_t
                    else:
                        working_token -= filtered_t
            elif working_token == None:
                working_token = filtered_t
            else:
                raise Exception("Error, multiple tokens without modifiers. This should never happen")

        if is_set:
            if resolved_set != None:
                return resolved_set
        else:
            if working_token != None:
                return working_token
        
        raise Exception("Error, SmartToken.resolve() was unable to finish and didn't raise ParserError(). This should never happen.")

def get_dec_or_token(token):
    #Takes a string
    #  returns a decimal number if that string was a number (decimal, hex, or binary)
    #  otherwise returns the string

    if type(token) == int:
        return token
    base = 10
    if len(token) > 2:
        if token[:2].lower() == "0x":
            base = 16
        elif token[:2].lower() == "0b":
            base = 2

    try:
        #Try to return it as a number
        return int(token, base)
    except:
        #Otherwise it must be a token
        return token

def checksum(hexarray):
    #Returns 16-bit checksum
    #    Param: Hexarray is an array of hex values. There must be an even number,
    #    each pair arrange with low byte first, high second
    #
    #    Return: 16-bit checksum as two hex values, low byte first, high second

    checksum = 0
    for low,high in zip(*[iter(hexarray)]*2):
        checksum += low + (high<<8)
        checksum = checksum & 0xFFFF
    byte_h = int(checksum>>8)
    byte_l =  int(checksum&0xFF)
    return [byte_l, byte_h]

def generate_hex(machinecode, h=syntax.header):
    len_message = pack_hex_bytes(len(machinecode))
    message = len_message
    for i in machinecode:
        message += pack_hex_bytes(i)
    message += checksum(message)
    message = h + message
    return message

def pack_hex_bytes(int_value):
    #Returns two decimal bytes, low byte first
    return [int_value & 0xFF, int_value>>8]


def is_int(val):
    return(type(val) == int)

def validate_two_bit_int(value):
    #Raise error if 2-bit int out of range
    if not 0 <= value < 4:
        raise ParserError("E::Literal value (%d) out of range. Expected [0..3]" % value)
    else:
        return value

def validate_four_bit_int(value):
    #Raise error if 4-bit int out of range
    if not 0 <= value < 16:
        raise ParserError("E::Literal value (%d) out of range. Expected [0..15]" % value)
    else:
        return value

def validate_eight_bit_int(value):
    #Raise error if 8-bit int out of range
    if not 0 <= value < 256:
        raise ParserError("E::Literal value (%d) out of range. Expected [0..255]" % value)
    else:
        return value

def resolve_brackets(brackets, signed=False):
    #Convert array containing numbers to an int
    #Raise if out of range
    if type(brackets) != list:
        brackets = [brackets]
    if len(brackets) == 1:
        if not 0 <= brackets[0] < 256 and signed==False:
            raise ParserError("E::Literal value (%d) out of range. Expected [0..255]" % brackets[0])
        elif not -128 <= brackets[0] < 127 and signed==True:
            raise ParserError("E::Literal value (%d) out of range. Expected [-128..127]" % brackets[0])
        else:
            value = brackets[0]
            if value < 0:
                value+=256
            return value>>4, value&0xF
    else:
        if any(not 0 <= i < 16 for i in brackets):
            raise ParserError("E::Literal value out of range. Expected [0..15]")
        else:
            return brackets[0], brackets[1]
        

def get_reg_number(reg_name):
    #Returns int value of a named register
    return Registers().named_registers.index(reg_name)

def arg_count_test(actual, expected):
    #Token count includes opcode so arg count will be one less
    if actual != expected:
        raise ParserError("E::Expected %d arguments for this opcode but got %d" % (expected-1, actual-1))

def convert_machine_code_to_binary(mc):
    #Converts a 12-bit int to a 12-bit binary string, including spaces based on global setting
    if not 0<=mc<4096:
        raise Exception("Machine code must be [0..4095] but got %d" % mc)
    
    outstring = format(mc, "012b")
    if options.show_wordspace_or_verbose():
        return " ".join([outstring[:4],outstring[4:8],outstring[8:]])
    else:
        return outstring

def make_machinecode(opcode, oper_x, oper_y):
    return (opcode<<8) + (oper_x<<4) + oper_y

def byte_to_nibbles(byte):
    return (byte>>4, byte&0xF)

def pc_addr_to_nibbles(pc_num):
    return (pc_num>>8, (pc_num>>4)&0xF, pc_num&0xF)

def print_output(binary,ln,cm, non_opcode=False, assembler_message=False):
    if assembler_message:
        print(binary)
        return
    if non_opcode:
        print(' '*20,binary)
        return

    format_string = ""
    out_values = []
    if ln != None:
        out_values += [format(ln, "03X"), binary]
        format_string = "{:<5}{:<19}"
    else:
        #Add formatting entry for the binary file
        out_values.append(binary)
        format_string = "{:<16}"

    if cm != None:
        out_values.append(format(cm))
        format_string = str(format_string +"{}").lstrip()
    print(format_string.format(*out_values))
    
def print_error(e, line_num, line):
    print("%s\n\tLine %d:\t%s" % (e,line_num,line))

def read_asm_file(filename):
    with codecs.open(filename, 'r', encoding='utf-8', errors='replace') as file:
        stream = file.read()
    return stream

class CodePack:
    def __init__(self, tokens=None, comment=None, source=None):
        self.tokens = tokens
        self.comment = comment
        self.source = source

class ParserError(Exception):
    pass

class Opcodes:
    #Takes tokens as input, returns a tuple of machine codes
    #Opcode names defined at end of class

    def get_binary(self, *args):
        try:
            return self.instructions.get(args[0][0])(self,*args)
        except Exception as e:
            raise type(e)(str(e) +
                      '\n\tThis happened when passing opcode %s (which assembler thinks doesn\'t exist?)' % str(args[0][0])).with_traceback(sys.exc_info()[2])


    def args_rxry(self, tokens,opcode):
        #ADD ADC SUB SBB OR AND XOR MOV
        arg_count_test(len(tokens),3)
        if tokens[1] in Registers().named_registers and tokens[2] in Registers().named_registers:
            return (make_machinecode(opcode, get_reg_number(tokens[1]), get_reg_number(tokens[2])),)
        else:
            raise ParserError("E::This opcode requires register names as arguments")

    def args_r0n(self, tokens,opcode):
        #CP ADD OR AND XOR RET
        arg_count_test(len(tokens),3)
        if tokens[1] != "R0":
            raise ParserError("E::This opcode requires R0 as the first argument")
        elif not is_int(tokens[2]):
            raise ParserError("E::This opcode requires a number as the second argument")
        else:
            return (make_machinecode(0, opcode, tokens[2]),)

    def args_ry(self, tokens,opcode):
        #INC DEC DSZ RRC
        arg_count_test(len(tokens),2)
        if tokens[1] not in Registers().named_registers:
            raise ParserError("E::This opcode requires a register name as the argument")
        else:
            return (make_machinecode(0, opcode, get_reg_number(tokens[1])),)

    def args_rgm(self, tokens,opcode):
        #BIT BSET BCLR BTG
        arg_count_test(len(tokens),3)
        if tokens[1] not in ["R0","R1","R2","R3"]:
            raise ParserError("E::This opcode requires R0, R1, R2, or R3 as the first argument")
        elif not is_int(tokens[2]) or not 0 <= tokens[2] < 4: 
            raise ParserError("E::This opcode requires a number [0..3] as the second argument")
        else:
            return (make_machinecode(0, opcode, (get_reg_number(tokens[1])<<2) + validate_two_bit_int(tokens[2])),)

    def args_go(self, tokens,trigger_reg):
        arg_count_test(len(tokens),2)
        reg_value = tokens[1]
        if 0 <= reg_value < 4096:
            nibble_h, nibble_m, nibble_l = pc_addr_to_nibbles(reg_value)
            two_lines = (make_machinecode(Opcodes.MOVPCNN, nibble_h, nibble_m), make_machinecode(Opcodes.MOVRXN, trigger_reg, nibble_l))
            return two_lines
        else:
            raise ParserError("E::Register value is out of range (0 <= reg_value < 4096): %d" % reg_value)

    def opcode_add(self, tokens):
        #ADD R0,N
        if is_int(tokens[2]):
            return self.args_r0n(tokens,self.ADDR0N)
        #ADD RX,RY
        else:
            return self.args_rxry(tokens,self.ADDRXRY)
        
    def opcode_adc(self, tokens):
        return self.args_rxry(tokens,self.ADCRXRY)
        
    def opcode_sub(self, tokens):
        return self.args_rxry(tokens,Opcodes.SUBRXRY)
        
    def opcode_sbb(self, tokens):
        return self.args_rxry(tokens,self.SBBRXRY)

    def opcode_or(self, tokens):
        #OR R0,N
        if is_int(tokens[2]):
            return self.args_r0n(tokens,self.ORR0N)
        #OR RX,RY
        else:
            return self.args_rxry(tokens,self.ORRXRY)

    def opcode_and(self, tokens):
        #AND R0,N
        if is_int(tokens[2]):
            return self.args_r0n(tokens,self.ANDR0N)
        #AND RX,RY
        else:
            return self.args_rxry(tokens,self.ANDRXRY)

    def opcode_xor(self, tokens):
        #XOR R0,N
        if is_int(tokens[2]):
            return self.args_r0n(tokens,self.XORR0N)
        #XOR RX,RY
        else:
            return self.args_rxry(tokens,self.XORRXRY)
        
    def opcode_mov(self, tokens):
        arg_count_test(len(tokens),3)
        if any(isinstance(i,list) for i in tokens):
            #Must be instruction containing a set of brackets
            if tokens[1] == "PC":
                #MOV PC,NN
                if all(is_int(i) for i in tokens[2]):
                    nibble_high, nibble_low = resolve_brackets(tokens[2])
                    return (make_machinecode(self.MOVPCNN, nibble_high, nibble_low),)
                else:
                    raise ParserError("E::Expected literal number for MOV PC, NN")
            elif "R0" in tokens:
                if tokens[1] == "R0":
                    if all(is_int(i) for i in tokens[2]):
                        #MOV R0,[NN]
                        nibble_high, nibble_low = resolve_brackets(tokens[2])
                        return (make_machinecode(self.MOVR0NN, nibble_high, nibble_low),)
                    elif len(tokens[2]) == 2 and all(i in Registers().named_registers for i in tokens[2]):
                        #MOV R0,[XY]
                        return (make_machinecode(self.MOVR0XY, get_reg_number(tokens[2][0]), get_reg_number(tokens[2][1])),)
                    else:
                        raise ParserError("E::Type mismatch for values inside brackets")
                elif tokens[2] == "R0":
                    if all(is_int(i) for i in tokens[1]):
                        #MOV [NN],R0
                        nibble_high, nibble_low = resolve_brackets(tokens[1])
                        return (make_machinecode(self.MOVNNR0, nibble_high, nibble_low),)
                    elif len(tokens[1]) == 2 and all(i in Registers().named_registers for i in tokens[1]):
                        #MOV [XY],R0
                        return (make_machinecode(self.MOVXYR0, get_reg_number(tokens[1][0]),get_reg_number(tokens[1][1])),)
                    else:
                        raise ParserError("E::Type mismatch for values inside brackets")
                else:
                    raise Exception()
        #Catch edge case syntax error
        elif tokens[1] == "PC":
            raise ParserError("E::Syntax error, numeric literal must be in brackets for PC,[NN]")
        #MOV RX,RY
        elif tokens[1] in Registers().named_registers and tokens[2] in Registers().named_registers:
            return self.args_rxry(tokens,self.MOVRXRY)
        #MOV RX,N
        elif is_int(tokens[2]):
            if tokens[1] in Registers().named_registers:
                return (make_machinecode(self.MOVRXN, get_reg_number(tokens[1]), validate_four_bit_int(tokens[2])),)
            else:
                raise ParserError("E::Expected register name for first argument of MOV RX,N")
        else:
            raise Exception()
        
    def opcode_jr(self, tokens):
        arg_count_test(len(tokens),2)
        if type(tokens[1]) == int or all(is_int(i) for i in tokens[1]):
            nibble_high, nibble_low = resolve_brackets(tokens[1], signed=True)
            return (make_machinecode(self.JRNN, nibble_high, nibble_low),)
        else:
            raise ParserError("E::This opcode requires two numbers as arguments")
        
    def opcode_cp(self, tokens):
        return self.args_r0n(tokens,self.CPR0N)
        
    def opcode_inc(self, tokens):
        return self.args_ry(tokens,self.INCRY)
        
    def opcode_dec(self, tokens):
        return self.args_ry(tokens,self.DECRY)
        
    def opcode_dsz(self, tokens):
        return self.args_ry(tokens,self.DSZRY)
        
    def opcode_exr(self, tokens):
        arg_count_test(len(tokens),2)
        if is_int(tokens[1]):
            return (make_machinecode(self.EXTENDEDOP, self.EXRN, validate_four_bit_int(tokens[1])),)
        else:
            raise ParserError("E::This opcode requires a number as the argument")
        
    def opcode_bit(self, tokens):
        return self.args_rgm(tokens,self.BITRGM)

    def opcode_bset(self, tokens):
        return self.args_rgm(tokens,self.BSETRGM)

    def opcode_bclr(self, tokens):
        return self.args_rgm(tokens,self.BCLRRGM)

    def opcode_btg(self, tokens):
        return self.args_rgm(tokens,self.BTGRGM)

    def opcode_rrc(self, tokens):
        return self.args_ry(tokens,self.RRCRY)
        
    def opcode_ret(self, tokens):
        return self.args_r0n(tokens,self.RETR0N)

    def opcode_skip(self, tokens):
        #SKIP F,M
        arg_count_test(len(tokens),3)
        if tokens[1] not in Registers().special_registers[:4]:
            raise ParserError("E::This opcode requires %s, %s, %s, or %s as the first argument" % Registers().special_registers[:4])
        elif not is_int(tokens[2]) or not 0 <= tokens[2] < 4: 
            raise ParserError("E::This opcode requires a number [0..3] as the second argument")
        else:
            F = Registers().special_registers.index(tokens[1])<<2
            return (make_machinecode(self.EXTENDEDOP, self.SKIPFM, F + validate_two_bit_int(tokens[2])),)

    def opcode_goto(self, tokens):
        return self.args_go(tokens,get_reg_number("PCL"))
                    
    def opcode_gosub(self, tokens):
        return self.args_go(tokens,get_reg_number("JSR"))

    def opcode_org(self, tokens,linenum):
        arg_count_test(len(tokens),2)
        #This should have been validated as a number within range and greater than
        #current program memory register when the symbols table was calculated
        #in get_tokenized_code()
        lines_to_fill = tokens[1] - linenum 
        return tuple([make_machinecode(0b0000, 0b0000, 0b0000)]*lines_to_fill)

    def opcode_ascii(self, tokens):
        arg_count_test(len(tokens),2)
        #Split each caracter into low/high nibble and RET in that order
        return_tuple = tuple()
        for i in tokens[1]:
            return_tuple += self.args_r0n([tokens[0],"R0",ord(i)&0xF],self.RETR0N)  #Low nibble
            return_tuple += self.args_r0n([tokens[0],"R0",ord(i)>>4],self.RETR0N)   #High nibble
        return return_tuple
    
    def opcode_byte(self, tokens):
        arg_count_test(len(tokens),2)
        validate_eight_bit_int(tokens[1])
        #Split byte into low/high nibble and RET in that order
        return self.args_r0n([tokens[0],"R0",tokens[1]&0xF],self.RETR0N) + self.args_r0n([tokens[0],"R0",tokens[1]>>4],self.RETR0N)

    #Constants for opcode lookup
    EXTENDEDOP,ADDRXRY,ADCRXRY,SUBRXRY = 0b0000,0b0001,0b0010,0b0011
    SBBRXRY,ORRXRY,ANDRXRY,XORRXRY = 0b0100,0b0101,0b0110,0b0111
    MOVRXRY,MOVRXN,MOVXYR0,MOVR0XY = 0b1000,0b1001,0b1010,0b1011
    MOVNNR0,MOVR0NN,MOVPCNN,JRNN = 0b1100,0b1101,0b1110,0b1111
    CPR0N,ADDR0N,INCRY,DECRY = 0b0000,0b0001,0b0010,0b0011
    DSZRY,ORR0N,ANDR0N,XORR0N = 0b0100,0b0101,0b0110,0b0111
    EXRN,BITRGM,BSETRGM,BCLRRGM = 0b1000,0b1001,0b1010,0b1011
    BTGRGM,RRCRY,RETR0N,SKIPFM = 0b1100,0b1101,0b1110,0b1111

    #Constants for pseudo-opcode names
    GOTO="GOTO"
    GOSUB="GOSUB"
    ORG="ORG"
    ASCII="ASCII"
    BYTE="BYTE"
    EQU="EQU"

    instructions = {
        "ADD": opcode_add, # 17
        "ADC": opcode_adc,
        "SUB": opcode_sub,
        "SBB": opcode_sbb,
        "OR":  opcode_or,  #21
        "AND": opcode_and, #22
        "XOR": opcode_xor, #23
        "MOV": opcode_mov, #9,10,11,12,13,14
        "JR":  opcode_jr,
        "CP":  opcode_cp,
        "INC": opcode_inc,
        "DEC": opcode_dec,
        "DSZ": opcode_dsz,
        "EXR": opcode_exr,
        "BIT": opcode_bit,
        "BSET": opcode_bset,
        "BCLR": opcode_bclr,
        "BTG": opcode_btg,
        "RRC": opcode_rrc,
        "RET": opcode_ret,
        "SKIP": opcode_skip,
        GOTO: opcode_goto,
        GOSUB: opcode_gosub,
        ORG: opcode_org,
        ASCII: opcode_ascii,
        BYTE: opcode_byte,
        }
    pseudo_opcodes = [GOTO, GOSUB, ORG, ASCII, BYTE]
    token_preceders = [instructions]+[EQU,"[",":",","]
    VALID_MESSAGE_CHARS = ' !"#$%&\'()*+,-./0123456789:<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~'

#For testing:
# import inspect
# def lineno():
#     """Returns the current line number in our program."""
#     return inspect.currentframe().f_back.f_lineno
# parse_asm(read_asm_file('/home/mike/compile/fbb_assembler/examples/hamlet/hamlet.asm'),hexfile_out='outfile.hex')

def main():
    print("Supercon.6 Badge Assembler version %s\n" % __version__)
    
    parser = argparse.ArgumentParser()
    parser.add_argument("asmfile", help="assembly language file to be processed")
    parser.add_argument("-q", help="Write to file without showing any human-readable output", action="store_true")
    assembly_comments = parser.add_mutually_exclusive_group()
    assembly_comments.add_argument("-c", help="enable comments (without assembly code) in readout", action="store_true")
    assembly_comments.add_argument("-m", help="enable assembly code (with comments) in readout", action="store_true")
    parser.add_argument("-n", help="enable line numbers in readout", action="store_true")
    binary_format = parser.add_mutually_exclusive_group()
    binary_format.add_argument("-s", help="Show 12-bit instructions with spaces between words", action="store_true")
    binary_format.add_argument("-w", help="Show 12-bit instructions without spaces between words", action="store_true")
    args = parser.parse_args()

    global options

    if args.q:
        options.show_output = False
    if args.c:
        options.show_verbose = False
        options.show_comments = True
    if args.m:
        options.show_verbose = False
        options.show_assembly = True
    if args.n:
        options.show_verbose = False
        options.show_linenums = True
    if args.s:
        options.show_verbose = False
        options.show_wordspace = True
    if args.w:
        options.show_verbose = False
        options.show_wordspace = False


    ext_idx = args.asmfile.rfind('.')
    if ext_idx > 0:
        outfile = args.asmfile[:ext_idx] + ".hex"
    else:
        outfile = args.asmfile + ".hex"
        
    if parse_asm(read_asm_file(args.asmfile),hexfile_out=outfile) == True:
        print("\nSuccessfully wrote hex file: %s\n" % outfile)

if __name__ == "__main__":
    main()
