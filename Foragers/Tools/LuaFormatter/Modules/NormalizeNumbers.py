import re

from _lua import _long_string_skip


def apply(text: str, config: dict) -> str:
    collapse = config.get("collapse_integer_floats", True)
    if not collapse:
        return text

    # Collapse `1.0` -> `1` only in code regions — never inside quoted strings
    # or long-bracket strings (e.g. GLSL shader source), where `2.0` is a float.
    out = []
    run = []
    i = 0
    n = len(text)
    in_s = in_d = False

    def flush():
        if run:
            out.append(re.sub(r"\b(\d+)\.0+\b", r"\1", "".join(run)))
            run.clear()

    while i < n:
        ch = text[i]
        if in_d:
            out.append(ch)
            if ch == "\\" and i + 1 < n:
                out.append(text[i + 1])
                i += 2
                continue
            if ch == '"':
                in_d = False
            i += 1
            continue
        if in_s:
            out.append(ch)
            if ch == "\\" and i + 1 < n:
                out.append(text[i + 1])
                i += 2
                continue
            if ch == "'":
                in_s = False
            i += 1
            continue
        if ch == '"':
            flush()
            in_d = True
            out.append(ch)
            i += 1
            continue
        if ch == "'":
            flush()
            in_s = True
            out.append(ch)
            i += 1
            continue
        if ch == "[":
            skip = _long_string_skip(text, i)
            if skip != -1:
                flush()
                out.append(text[i:skip])
                i = skip
                continue
        run.append(ch)
        i += 1
    flush()
    return "".join(out)
