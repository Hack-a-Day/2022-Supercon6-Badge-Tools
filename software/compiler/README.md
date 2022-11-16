# High Level language and compiler for Supercon 6 badge

## Installation

Requires Python3.6+

## Running

```
python compiler/compiler.py [--assemble] <path to source file>
```

This will generate a `.asm` file with the same path and base name, but replace the source file's
extension.

## High level Language

## Note on syntax

Each statement is one line. Each symbol or term in a statement must be space separated.
For example, `foo=1` is not legal, but `foo = 1` is.

### Types

The language is dynamically typed and will intelligently pick the right type for any variable,
from the list of available types: uint4.

You can have any type you want, as long as it's unsigned 4-bit integers.

## Comments

Comments are preceeded by a `#` character. Comments will get copied into the compiled assembly file.
Comments can be on the same line as code, but must be at the end. They will get copied to the following
line of the `.asm` file.

## Variable assignment and math

Examples:
```
foo = 3
bar = 2 + foo
baz = bar - 1 + foo
foo = baz | bar
bar = baz & foo
```

Math operations can be chained on the same line. Order of operations is always left to right (not PEMDAS).
There are no `()` for enforcing order of operations at this time.

Currently only 9 variables can exist at once (one per register).

## Conditionals

Available comparisons: `==`, `!=`

`==` is equality comparison

`!=` is inequality comparison

Comparisons can not be chained. For example, you cannot evaluate `foo == bar == baz` in one line.
Conditionals can only be used in branch evaluations.


## Branches
Available branches and loops: `if`, `while`

Each block must end with the matching closing statement: `endif`, `endwhile`

Indentation does not matter inside an `if` or `while` block, but can be used for readability.
Variables only defined inside an `if`/`while` block will not exist after exiting that block 
(they have fallen out of scope).

Example:
```
foo = 1
bar = 1
baz = 0
if foo == bar
    baz = 1
endif

idx = 0
max = 10
while idx != max
    idx = idx + 1
endwhile
```

## Memory access

Memory addresses can be read or written to with the `<=` operator.
The syntax is `<page> <slot> <= <variable>` or `<variable> <= <page> <slot>`
There is currently no restriction on which memory addresses can be accessed.
Memory access cannot be combined with math on the same line.

TODO: Using literals for `<page>` and `<slot>` is not implemneted. These must be variables.
