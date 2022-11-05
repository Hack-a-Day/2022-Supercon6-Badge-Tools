# Intermediate representation

class Expression:
    """Expression parsed from source"""
    file_source: str = None
    line_source: str = None
    source_value: str = None
    instructions: list = []

    def __init__(self, file_source, line_source, value) -> None:
        self.file_source = file_source
        self.line_source = line_source
        self.source_value = value

    def __repr__(self) -> str:
        return f"{self.file_source}:{self.line_source}: \"{self.source_value}\""

    def to_asm(self) -> str:
        return ""


class Comment(Expression):
    """Comment"""

    def to_asm(self):
        return f"; {self.source_value}\n"


class Empty(Expression):
    """Empty line"""

    def __init__(self, file_source, line_source) -> None:
        self.file_source = file_source
        self.line_source = line_source

    def __repr__(self) -> str:
        return ""

    def to_asm(self):
        return ""


class Noop(Expression):
    """Advance PC but do nothing useful"""

    def __init__(self, file_source, line_source) -> None:
        super().__init__(file_source, line_source, "<noop>")

    def to_asm(self):
        return "jr 0 ; no-op\n"