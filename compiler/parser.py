# Parser

import errors
import intermediate

def parse(filename):
    """Parse source file text"""

    expressions = []

    with open(filename, "r") as source_file:
        for line_num_0, line_text in enumerate(source_file.readlines()):
            # People are used to file line numbers being one-indexed
            line_num = line_num_0 + 1
            # Remove leading/trailing whitespace
            line_stripped = line_text.strip()

            # Skip empty lines
            if not line_stripped:
                # expressions.append(intermediate.Empty(filename, line_num))
                continue

            # Comments
            if line_stripped.startswith("#"):
                comment = line_stripped[1:].strip()
                expressions.append(intermediate.Comment(filename, line_num, comment))
                continue
            if line_stripped.startswith("//"):
                comment = line_stripped[2:].strip()
                expressions.append(intermediate.Comment(filename, line_num, comment))
                continue

            raise errors.BadgeSyntaxError(f"Unknown syntax: {filename}:{line_num}: `line_stripped`")

    return expressions