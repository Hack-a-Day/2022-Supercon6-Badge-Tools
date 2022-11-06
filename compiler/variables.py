# Variables

import enum

import errors

class Variable:
    def __init__(self, name: str) -> None:
        self.name: str = name
        self.register: Register = RegisterPool.assign()
        # print(f"{name}: {self.register}")

    def drop(self) -> None:
        RegisterPool.free(self.register)

    def get_register(self):
        return self.register.name.lower()

    def __repr__(self) -> str:
        return f"Var:{self.name}"


class Literal:
    """A literal value"""
    MAXINT = 0

    def __init__(self, value: str) -> None:
        self.value = None
        try:
            intval = int(value)
        except ValueError:
            raise errors.CompilerBadNumber()
        if (-1 * self.MAXINT - 1) <= intval <= self.MAXINT:
            self.value = intval
        else:
            raise errors.BadgeNumberTooBig()

    def __repr__(self) -> str:
        return f"Lit:{self.value}"


class Nibble(Literal):
    """A Signed 4-bit integer"""
    MAXINT = 7


class Byte(Literal):
    """A Signed 8-bit integer"""
    MAXINT = 127
            

class Register(enum.Enum):
    """Enum of possible registers to use"""
    R0 = 0
    R1 = 1
    R2 = 2
    R3 = 3
    R4 = 4
    R5 = 5
    R6 = 6
    R7 = 7
    R8 = 8
    R9 = 9

    def __repr__(self) -> str:
        return f"Reg:{self.name}"

class RegisterPool:
    """Set of available registers"""
    # Skip R0 because it's special and needed for some opcodes
    pool = [
        Register.R1,
        Register.R2,
        Register.R3,
        Register.R4,
        Register.R5,
        Register.R6,
        Register.R7,
        Register.R8,
        Register.R9,
    ]

    @staticmethod
    def assign() -> Register:
        try:
            return RegisterPool.pool.pop()
        except IndexError:
            raise errors.CompilerOutOfRegisters

    @staticmethod
    def free(reg: Register) -> None:
        if reg in RegisterPool.pool:
            raise 
        RegisterPool.pool.append(reg)


class Scope:
    """Implements a program scope for variables"""

    def __init__(self) -> None:
        self.scope_stack: list[dict[str, Variable]] = [{}]

    def push(self) -> None:
        self.scope_stack.append({})

    def pop(self) -> None:
        for var in self.scope_stack[-1].values():
            var.drop()
        self.scope_stack.pop()

    def __setitem__(self, key: str, value: Variable) -> None:
        for frame in self.scope_stack:
            if key in frame:
                frame[key] = value
                return
        self.scope_stack[-1][key] = value

    def __getitem__(self, key: str) -> Variable:
        for frame in self.scope_stack:
            if key in frame:
                return frame[key]
        raise KeyError

    def __contains__(self, key):
        try:
            self[key]
            return True
        except KeyError:
            False

    def __delitem__(self, key):
        del self.scope_stack[-1][key]

    def __enter__(self):
        self.push()
        return self

    def __exit__(self, type, value, traceback):
        self.pop()

    def __repr__(self) -> str:
        rep = ""
        for fidx, frame in enumerate(self.scope_stack):
            rep += f"{fidx}: {[var for var in frame.values()]};"
        return rep
