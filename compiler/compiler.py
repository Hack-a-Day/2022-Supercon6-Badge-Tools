# Compiler for Hackaday Supercon 6 Badge

import argparse
import os.path
import subprocess
import sys

import parser


def compile(parsed_source: list) -> str:
    """Convert parsed source code into assembly"""
    output_asm: str = ""
    """Output assembly"""

    for expression in parsed_source:
        output_asm += f"{expression.to_asm()}"
    
    return output_asm

def write_hex(output_asm: str, output_name: str) -> str:
    """Write the compiled hex to a file"""
    with open(output_name, "w") as outfile:
        outfile.write(output_asm)


def main():
    arg_parser = argparse.ArgumentParser("Badge Compiler")
    arg_parser.add_argument("sources", nargs=1, help="List of source text files to compile")
    arg_parser.add_argument("--assemble", help="Also assemble to hex files", action="store_true", default=False)
    arg_parser.add_argument("--simulate", help="Also run emulator with compiled code. Implies --assemble.", action="store_true", default=False)
    args = arg_parser.parse_args()

    tokens = []
    for source_filename in args.sources:
        source_name = os.path.splitext(source_filename)[0]
        output_name = f"{source_name}.asm"
        tokens.extend(parser.parse(source_filename))
        output_asm = compile(tokens)
        write_hex(output_asm, output_name)
        
        # Assemble to .hex file if desired
        # If asked to simulate, also assemble
        if args.assemble or args.simulate:
            subprocess.run(
                [sys.executable,
                 os.path.join(os.path.dirname(__file__), "..", "assembler", "assemble.py"),
                 output_name])
        if args.simulate:
            emulator_dir = os.path.join(os.path.dirname(__file__), "..", "emulator")
            bin_relpath = os.path.relpath(output_name, start=emulator_dir)
            subprocess.run(
                [sys.executable,
                 os.path.join(emulator_dir, "bvm.py"),
                 bin_relpath],
                cwd=emulator_dir)

if __name__ == "__main__":
    main()