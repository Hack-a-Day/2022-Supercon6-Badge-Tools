# Intermediate representation

from typing import Optional

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
        return "jr 0\n"


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