import re

def apply(text: str, config: dict) -> str:
    text = re.sub(r"[ \t]+$", "", text, flags=re.MULTILINE)
    return text.rstrip("\n")
