"""Tokens representing an intermediate state of actions in the language"""

import os
from typing import Optional

import errors
import variables

class Token:
    """Token parsed from source"""

    def __init__(self, file_source, line_source, value) -> None:
        self.file_source: str = file_source
        self.line_source: int = line_source
        self.source_value: str = value
        self.instructions: list = []

    def __repr__(self) -> str:
        return f"{self.file_source}:{self.line_source}: \"{self.source_value}\""

    def process(self, scope: variables.Scope) -> None:
        """Compute what a tokenshould do in the current scope (which it can modify)
        Return a list of tokens"""

    def to_asm(self) -> str:
        return "\n".join(self.instructions)


class Comment(Token):
    """Comment"""

    def to_asm(self):
        return f"; {self.source_value}\n"


class Empty(Token):
    """Empty line"""

    def __init__(self, file_source, line_source) -> None:
        self.file_source = file_source
        self.line_source = line_source

    def __repr__(self) -> str:
        return ""

    def to_asm(self):
        return ""


class Noop(Token):
    """Advance PC but do nothing useful"""

    def __init__(self, file_source, line_source) -> None:
        super().__init__(file_source, line_source, "<noop>")

    def to_asm(self) -> str:
        return "mov r0, r0\n"


class VariableAssign(Token):
    """Assign a value to a variable"""

    def process(self, scope: variables.Scope) -> None:
        # Split line into <dest_variable> <=> <expression> 
        line_tokens = self.source_value.split(" ", 2)
        var_name = line_tokens[0].strip()
        if var_name in scope:
            variable = scope[var_name]
        else:
            variable = variables.Variable(var_name)
            scope[var_name] = variable
        dest = variable.get_register()
        src_raw = line_tokens[2].strip()
        # Check if source is another variable
        if src_raw in scope:
            src = scope[src_raw].get_register()
            self.instructions.append(f"mov {dest}, {src} ; {var_name} = {src_raw}\n")
        else:
            # Try to make a literal
            try:
                src = variables.Nibble(src_raw).value
                self.instructions.append(f"mov {dest}, {src} ; {var_name} = {src_raw}\n")
            except ValueError:
                # Not a literal, process the more complicated expression
                temp_var, instrs = process_expression(src_raw.split(" "), scope)
                self.instructions.extend(instrs)
                self.instructions.append(f"mov {dest}, {temp_var.get_register()} ; {variable.name} = {temp_var.name}\n")
                temp_var.drop()
                if temp_var.name in scope:
                    del scope[temp_var.name]


def process_expression(src_tokens: list, scope: variables.Scope) -> tuple[variables.Variable, list]:
    """Process an expression of multiple math operations"""
    instructions = []

    # Get operators
    left_val = src_tokens[0]
    operator = src_tokens[1]
    right_val = src_tokens[2]
    
    with scope:
        left_var, extra_instrs = temp_variable_from_value(left_val, scope)
        instructions.extend(extra_instrs)
        right_var, extra_instrs = temp_variable_from_value(right_val, scope)
        instructions.extend(extra_instrs)

        if operator == "+":
            instructions.append(f"add {left_var.get_register()}, {right_var.get_register()} ; {left_var.name} += {right_var.name}")
        elif operator == "-":
            instructions.append(f"sub {left_var.get_register()}, {right_var.get_register()} ; {left_var.name} -= {right_var.name}")
        elif operator == "|":
            instructions.append(f"or {left_var.get_register()}, {right_var.get_register()} ; {left_var.name} |= {right_var.name}")
        elif operator == "&":
            instructions.append(f"and {left_var.get_register()}, {right_var.get_register()} ; {left_var.name} &= {right_var.name}")
        elif operator == "^":
            instructions.append(f"xor {left_var.get_register()}, {right_var.get_register()} ; {left_var.name} ^= {right_var.name}")
        right_var.drop()  # Done with this temporary variable

        if len(src_tokens) > 3:
            new_tokens = [left_var.name] + src_tokens[3:]
            scope[left_var.name] = left_var
            old_left_var = left_var
            left_var, new_instrs = process_expression(new_tokens, scope)
            instructions.extend(new_instrs)
            # del scope[old_left_var.name]
            # old_left_var.drop()


    return left_var, instructions


def temp_variable_from_value(src: str, scope: variables.Scope) -> tuple[variables.Variable, list]:
    """Get a variable with a value (variable or literal) stored in it
    and the instruction to get the value into that register if necessary"""
    if src in scope:
        # Existing variable
        src_var = scope[src]
        temp_var = variables.Variable(f"{src}_copy")
        inst = [f"mov {temp_var.get_register()}, {src_var.get_register()} ; {temp_var.name} = {src_var.name}"]
        return temp_var, inst
    try:
        # int literal value
        value = variables.Nibble(src).value
        dest_var = variables.Variable(f"temp_{value}")
        dest_reg = dest_var.get_register()
        inst = [f"mov {dest_reg}, {value} ; temp_{value} = {value}"]
        return dest_var, inst
    except:
        raise

class If(Token):
    """Start of an if block"""

    branch_type = "if"

    def process(self, scope: variables.Scope) -> None:
        word_tokens = self.source_value.split(" ")
        left = word_tokens[0].strip()
        comparator = word_tokens[1].strip()
        right = word_tokens[2].strip()

        # Compare the left and right values
        if variables.Nibble.can_be_nibble(left) and variables.Nibble.can_be_nibble(right):
            # Comparing two int literals, move one to a variable before comparing
            self.instructions.append(f"mov r0, {left} ; R0 = {left} for compare")
            self.instructions.append(f"cp r0, {right} ; Compare {left} and {right}")
        elif variables.Nibble.can_be_nibble(left) and not variables.Nibble.can_be_nibble(right):
            # Comparing int literal and variable, move var to r0 then compare
            right_var = scope[right]
            self.instructions.append(f"mov r0, {right_var.get_register()} ; R0 = {right} for compare")
            self.instructions.append(f"cp r0, {left} ; Compare {left} and {right}")
        elif (not variables.Nibble.can_be_nibble(left)) and variables.Nibble.can_be_nibble(right):
            # Comparing variable and int literal, move variable to r0 then compare
            left_var = scope[left]
            self.instructions.append(f"mov r0, {left_var.get_register()} ; R0 = {left} for compare")
            self.instructions.append(f"cp r0, {right} ; Compare {left} and {right}")
        elif left in scope and right in scope:
            # Comparing two variables, subtract then put result in r0, compare to 0
            left_var = scope[left]
            right_var = scope[right]
            self.instructions.append(f"mov r0, {left_var.get_register()} ; Move {left} to R0")
            self.instructions.append(f"sub r0, {right_var.get_register()} ; Subtract {left} and {right}, compare")
            # self.instructions.append(f"cp r0, 0 ; compare difference with 0 to see if {left} and {right} are the same")
        else:
            raise KeyError(f"Unable to recognize `{left}` and `{right}` as variables from {self.file_source}:{self.line_source}")

        # Make comparison ==, !=
        if comparator == "==":
            self.instructions.append(f"skip z, 2 ; skip next goto if values are ==")
        elif comparator == "!=":
            self.instructions.append(f"skip nz, 2 ; skip next goto if values are !=")
        # >= and > are currently broken, they always evaluate true
        # elif comparator == ">=":
        #     self.instructions.append(f"skip c, 2 ; skip next goto if {left} >= {right}")
        # elif comparator == "<":
        #     self.instructions.append(f"skip nc, 2 ; skip next goto if {left} < {right}")
        else:
            raise ValueError(f"Unknown comparator `{comparator}`")

        # Jump to bottom of if/while-block
        filename = os.path.splitext(os.path.basename(self.file_source))[0]
        block_name = f"{self.branch_type}_{filename}_{self.line_source}"
        self.instructions.append(f"goto end{block_name}\n")

        if self.branch_type == "if":
            scope.push(if_block=block_name)
        elif self.branch_type == "while":
            scope.push(while_block=block_name)
        else:
            raise ValueError


class EndIf(Token):
    """End of an if block definition"""

    def __init__(self, file_source, line_source) -> None:
        super().__init__(file_source, line_source, "")

    def process(self, scope: variables.Scope) -> None:
        if_name = scope.pop(pop_if=True)
        self.instructions.append(f"end{if_name}:\n\n")


class While(If):
    """Start a while loop"""

    branch_type = "while"

    def process(self, scope: variables.Scope) -> None:
        # Make a label for the top of the while loop
        filename = os.path.splitext(os.path.basename(self.file_source))[0]
        while_name = f"{self.branch_type}_{filename}_{self.line_source}"
        self.instructions.append(f"{while_name}:\n")
        super().process(scope)


class EndWhile(Token):
    """End of a while loop definition"""
    
    def __init__(self, file_source, line_source) -> None:
        super().__init__(file_source, line_source, "")

    def process(self, scope: variables.Scope) -> None:
        while_name = scope.pop(pop_while=True)
        self.instructions.append(f"goto {while_name}\n")
        self.instructions.append(f"end{while_name}:\n\n")


class MemAccess(Token):
    """Read/Write to an address in memory"""

    def process(self, scope: variables.Scope) -> None:
        # dest <= page slot
        # page slot <= src
        word_tokens = self.source_value.split(" ")
        page = ""
        slot = ""
        src = ""
        dest_var = None
        # Get src/dest vars
        if "<=" == word_tokens[1].strip():
            # Reads
            dest_var = scope[word_tokens[0].strip()]
            page_raw = word_tokens[2].strip()
            slot_raw = word_tokens[3].strip()
            read = True
        elif "<=" == word_tokens[2].strip():
            # Writes
            page_raw = word_tokens[0].strip()
            slot_raw = word_tokens[1].strip()
            src_name = word_tokens[3].strip()
            if src_name in scope:
                src = scope[src_name].get_register()
            elif variables.Nibble.can_be_nibble(src_name):
                src = "r0"
                self.instructions.append(f"mov r0, {src_name} ; Copy int literal to r0 for copy to memory\n")
            read = False
        with scope:
            # Convert page/slot to valid strings
            print("page raw", page_raw)
            if variables.Nibble.can_be_nibble(page_raw) and not page_raw in scope:
                page = f"0x{hex(int(page_raw))[2:]}"
                print("page", page)
            elif page_raw in scope:
                print("else")
                page = scope[page_raw].get_register()
            if variables.Nibble.can_be_nibble(slot_raw) and not slot_raw in scope:
                slot = f"{hex(int(slot_raw))[2:]}"
            elif slot_raw in scope:
                slot = scope[slot_raw].get_register()
            if variables.Nibble.can_be_nibble(page_raw) and slot_raw in scope:
                print("page is a literal")
                temp_var = variables.Variable("temp_page")
                self.instructions.append(f"mov {temp_var.get_register()}, {page_raw} ; Copy literal to temp variable\n")
                scope[temp_var.name] = temp_var
                page = temp_var.get_register()

        # Perform read/write
        print(f"Memory: read: {read} page: {page} slot: {slot}")
        if read:
            self.instructions.append(f"mov r0, [{page}:{slot}] ; read value from memory [{page_raw}, {slot_raw}]\n")
            self.instructions.append(f"mov {dest_var.get_register()}, r0 ; copy value from r0 to {dest_var.name}\n")
        else:  # write
            self.instructions.append(f"mov [{page}:{slot}], r0; write {src} to memory [{page_raw}, {slot_raw}]\n")


class FunctionDefine(Token):
    """Create a function definition"""

    def __init__(self, file_source, line_source, value) -> None:
        super().__init__(file_source, line_source, value)
        
        fun_tokens = value.split(" ")

        self.name: str = fun_tokens[1]
        self.arg_names: list[str] = fun_tokens[1:]
        self.ret_var: Optional[variables.Variable] = None

    def process(self, scope: variables.Scope) -> None:
        scope.push()
        for arg_name in self.arg_names:
            scope[arg_name] = variables.Variable(arg_name)

    def to_asm(self) -> str:
        return f"{self.name}:\n"


class FunctionDefineEnd(Token):
    """End a function definition"""

    def __init__(self, file_source, line_source, value) -> None:
        super().__init__(file_source, line_source, value)

    def process(self, scope: variables.Scope) -> None:
        self.instructions = [f"ret R0, 0 ; return from function"]
        scope.pop()


class FunctionCall(Token):
    """Call a previously defined function"""

    def __init__(self, file_source, line_source, value) -> None:
        super().__init__(file_source, line_source, value)

        fun_tokens = value.split(" ")
        
        self.name:str = fun_tokens[0]
        self.arg_names: list[str] = fun_tokens[1:]

    def process(self, scope: variables.Scope) -> None:
        instructions = []
        for arg_name in self.arg_names:
            pass