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
            self.instructions.append(f"mov {dest}, {src}\n")
        else:
            # Try to make a literal
            try:
                src = variables.Nibble(src_raw).value
                self.instructions.append(f"mov {dest}, {src}\n")
            except ValueError:
                # Not a literal, process the more complicated expression
                self.instructions.extend(process_expression(src_raw, scope))


def process_expression(src_raw: str, scope: dict) -> list:

    return []