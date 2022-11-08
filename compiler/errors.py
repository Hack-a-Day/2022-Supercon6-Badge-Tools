"""Possible errors reported by the compiler"""

class BadgeSyntaxError(ValueError):
    """Invalid Syntax"""


class BadgeUnknownKeyword(ValueError):
    """Unknown keyword"""


class BadgeNumberTooBig(ValueError):
    """Literal value is too large to fit in a 4-bit number"""


class CompilerDoubleRegisterAssignment(ValueError):
    """The compiler tried to use a register for two different variables"""


class CompilerDoubleFree(ValueError):
    """The compiled freed a register twice"""


class CompilerOutOfRegisters(ValueError):
    """1202 Program Alarm"""


class CompilerBadNumber(ValueError):
    """Tried to turn a string into an integer and failed"""


class CompilerUnknownVariable(KeyError):
    """Tried to lookup a variable that doesn't seem previously defined"""
