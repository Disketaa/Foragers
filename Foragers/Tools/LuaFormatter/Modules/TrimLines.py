import re


def apply(text: str, config: dict) -> str:
    lines = text.split("\n")
    # Strip trailing whitespace from each line, remove trailing empty lines
    stripped = [line.rstrip() for line in lines]
    while stripped and stripped[-1] == "":
        stripped.pop()
    # No trailing newline — file ends with last non-empty line
    return "\n".join(stripped)
