def apply(text: str, config: dict) -> str:
    lines = text.split("\n")
    result = []

    def indent_of(line: str) -> str:
        return line[: len(line) - len(line.lstrip(" \t"))]

    for i, line in enumerate(lines):
        result.append(line)
        if i + 1 >= len(lines):
            continue
        nxt = lines[i + 1]
        if (
            line.strip() == "},"
            and nxt.strip() == "{"
            and indent_of(line) == indent_of(nxt)
        ):
            result.append("")
    return "\n".join(result)
