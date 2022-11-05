# Compiler for Hackaday Supercon 6 Badge

import os.path
import argparse

import parser
import intermediate


def compile(parsed_source: list, output_name: str):
    """Convert parsed source code into assembly"""
    output_asm: str = ""
    # Output assembly

    for expression in parsed_source:
        output_asm += f"{expression.to_asm()}\n"
    
    with open(output_name, "w") as outfile:
        outfile.write(output_asm)


def main():
    arg_parser = argparse.ArgumentParser("Badge Compiler")
    arg_parser.add_argument("sources", nargs=1)
    args = arg_parser.parse_args()

    parsed_intermediate = []
    for source_filename in args.sources:
        source_name = os.path.splitext(source_filename)[0]
        output_name = f"{source_name}.asm"
        parsed_intermediate.extend(parser.parse(source_filename))
        compile(parsed_intermediate, output_name)

    # Debug, print intermediate rep
    for inter in parsed_intermediate:
        print(inter)

if __name__ == "__main__":
    main()