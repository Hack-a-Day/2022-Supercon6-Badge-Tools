# Parser

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

            # Comments
            fragments = line_stripped.split("#", 1)
            line_stripped = fragments[0].strip()
            # No-op. Advance PC, but do nothing else
            if line_stripped == "noop":
                parsed_tokens.append(tokens.Noop(filename, line_num))
                line_parsed = True
            # Create a variable
            if line_stripped.startswith("var"):
                expression = line_stripped.lstrip("var ")
                parsed_tokens.append(tokens.VariableAssign(filename, line_num, expression))
                line_parsed = True

            if len(fragments) > 1:
                comment = fragments[1].strip()
                parsed_tokens.append(tokens.Comment(filename, line_num, comment))
                line_parsed = True

            if not line_parsed:
                raise errors.BadgeSyntaxError(f"Unknown syntax: {filename}:{line_num}: `{line_stripped}`")

    return parsed_tokens