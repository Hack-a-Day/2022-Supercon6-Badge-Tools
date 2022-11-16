"""Parse language into tokens"""

import errors
import tokens

def parse(filename):
    """Parse source file text"""

    parsed_tokens = []

    with open(filename, "r") as source_file:
        for line_num_0, line_text in enumerate(source_file.readlines()):
            # People are used to file line numbers being one-indexed
            line_num = line_num_0 + 1
            # Remove leading/trailing whitespace
            line_stripped = line_text.strip()
            line_parsed = False

            # Skip empty lines
            if not line_stripped:
                # parsed_tokens.append(tokens.Empty(filename, line_num))
                continue

            # Split comments off line
            fragments = line_stripped.split("#", 1)
            # Read first part of line
            line_stripped = fragments[0].strip()
            # No-op. Advance PC, but do nothing else
            if line_stripped == "noop":
                parsed_tokens.append(tokens.Noop(filename, line_num))
                line_parsed = True
            # Create a variable
            if " <= " in line_stripped:
                parsed_tokens.append(tokens.MemAccess(filename, line_num, line_stripped))
                line_parsed = True
            elif " = " in line_stripped:
                expression = line_stripped.lstrip("var ").strip()
                parsed_tokens.append(tokens.VariableAssign(filename, line_num, expression))
                line_parsed = True
            elif line_stripped.startswith("if"):
                expression = line_stripped.lstrip("if").strip()
                parsed_tokens.append(tokens.If(filename, line_num, expression))
                line_parsed = True
            elif line_stripped == "endif":
                parsed_tokens.append(tokens.EndIf(filename, line_num))
                line_parsed = True
            elif line_stripped.startswith("while"):
                expression = line_stripped.lstrip("while").strip()
                parsed_tokens.append(tokens.While(filename, line_num, expression))
                line_parsed = True
            elif line_stripped == "endwhile":
                parsed_tokens.append(tokens.EndWhile(filename, line_num))
                line_parsed = True

            # Comments
            if len(fragments) > 1:
                comment = fragments[1].strip()
                parsed_tokens.append(tokens.Comment(filename, line_num, comment))
                line_parsed = True

            if not line_parsed:
                raise errors.BadgeSyntaxError(f"Unknown syntax: {filename}:{line_num}: `{line_stripped}`")

    return parsed_tokens