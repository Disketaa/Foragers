import re


def apply(text: str, config: dict) -> str:
    lines = text.split("\n")
    result = []
    for line in lines:
        result.append(line.rstrip())
    return "\n".join(result) + "\n"
