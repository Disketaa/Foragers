import re


def apply(text: str, config: dict) -> str:
    collapse = config.get("collapse_integer_floats", True)
    if collapse:
        return re.sub(r"\b(\d+)\.0+\b", r"\1", text)
    return text
