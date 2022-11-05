# Parser

import errors
import tokens

def parse(filename):
    """Parse source file text"""

    expressions = []

    with open(filename, "r") as source_file:
        for line_num_0, line_text in enumerate(source_file.readlines()):
            # People are used to file line numbers being one-indexed
            line_num = line_num_0 + 1
            # Remove leading/trailing whitespace
            line_stripped = line_text.strip()
            line_parsed = False

            # Skip empty lines
            if not line_stripped:
                # expressions.append(tokens.Empty(filename, line_num))
                continue

            # Comments
            fragments = line_stripped.split("#", 1)
            line_stripped = fragments[0].strip()
            if line_stripped == "noop":
                expressions.append(tokens.Noop(filename, line_num))
                line_parsed = True

            if len(fragments) > 1:
                comment = fragments[1].strip()
                expressions.append(tokens.Comment(filename, line_num, comment))
                line_parsed = True

            if not line_parsed:
                raise errors.BadgeSyntaxError(f"Unknown syntax: {filename}:{line_num}: `line_stripped`")

    return expressions