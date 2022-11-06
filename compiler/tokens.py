# Intermediate representation

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

    def process(self, scope: dict) -> None:
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

    def process(self, scope: dict) -> None:
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
                self.instructions.append(f"mov {dest}, {temp_var.get_register()} ; from {src_raw}\n")


def process_expression(src_tokens: list, scope: dict) -> tuple[variables.Variable, list]:
    """Process an expression of multiple math operations"""
    instructions = []

    # Get operators
    left_val = src_tokens[0]
    operator = src_tokens[1]
    right_val = src_tokens[2]
    
    left_var, extra_instrs = variable_from_value(left_val, scope)
    instructions.extend(extra_instrs)
    right_var, extra_instrs = variable_from_value(right_val, scope)
    instructions.extend(extra_instrs)

    if operator == "+":
        instructions.append(f"add {left_var.get_register()}, {right_var.get_register()} ; {left_var.name} += {right_var.name}")

    return left_var, instructions


def variable_from_value(src: str, scope: dict) -> tuple[variables.Variable, list]:
    """Get a variable with a value (variable or literal) stored in it
    and the instruction to get the value into that register if necessary"""
    if src in scope:
        # Existing variable
        return scope[src], []
    try:
        # int literal value
        value = variables.Nibble(src).value
        dest_var = variables.Variable(f"temp_{value}")
        scope[dest_var.name] = dest_var
        dest_reg = dest_var.get_register()
        inst = [f"mov {dest_reg}, {value} ; temp_{value} = {value}\n"]
        return dest_var, inst
    except:
        raise 
