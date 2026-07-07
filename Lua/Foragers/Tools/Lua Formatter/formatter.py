import re
import sys
from pathlib import Path


def find_sprite_lua_files(root: Path) -> list[Path]:
    return sorted(root.rglob("*.lua"))


def add_blank_lines(text: str) -> str:
    lines = text.split("\n")
    result = []

    def indent_of(line: str) -> str:
        return line[: len(line) - len(line.lstrip(" \t"))]

    for i, line in enumerate(lines):
        result.append(line)
        if i + 1 >= len(lines):
            continue
        nxt = lines[i + 1]
        if (line.strip() == "},"
                and nxt.strip() == "{"
                and indent_of(line) == indent_of(nxt)):
            result.append("")
    return "\n".join(result)


def matching_brace(text: str, open_idx: int) -> int:
    depth = 0
    for i in range(open_idx, len(text)):
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
            if depth == 0:
                return i
    raise ValueError("Unbalanced braces")


def split_top_level(inner: str) -> list[str]:
    parts, depth, cur = [], 0, ""
    for ch in inner:
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
        if ch == "," and depth == 0:
            if cur.strip():
                parts.append(cur.strip())
            cur = ""
        else:
            cur += ch
    if cur.strip():
        parts.append(cur.strip())
    return parts


def collapse(s: str) -> str:
    return re.sub(r"\s+", " ", s.strip())


def format_value_list(items: list[str], indent: str) -> str:
    flat = [collapse(it) for it in items]
    if len(flat) == 1:
        item = flat[0]
        if item.startswith("{") and item.endswith("}"):
            inner = item[1:-1].strip()
            item = "{ " + inner + " }"
        return "{ " + item + " }"
    body = ",\n".join(f"{indent}\t{it}" for it in flat)
    return "{\n" + body + ",\n" + indent + "}"


def format_key_entries(inner: str, indent: str) -> str:
    out = []
    for entry in split_top_level(inner):
        m = re.match(r"^(\w+)\s*=\s*\{", entry)
        if not m:
            out.append(f"{indent}\t{collapse(entry)},")
            continue
        key = m.group(1)
        open_idx = m.end() - 1
        close_idx = matching_brace(entry, open_idx)
        items = split_top_level(entry[open_idx + 1: close_idx])
        if not items:
            out.append(f"{indent}\t{key} = {{}},")
            continue
        value_str = format_value_list(items, indent + "\t")
        out.append(f"{indent}\t{key} = {value_str},")
    return "\n".join(out)


def stringify_tags(text: str) -> str:
    pattern = re.compile(r"^[ \t]*tags\s*=\s*\{$", re.MULTILINE)
    out, pos = [], 0
    for m in pattern.finditer(text):
        if m.start() < pos:
            continue
        out.append(text[pos:m.start()])
        indent = re.match(r"[ \t]*", m.group()).group()
        open_idx = m.end() - 1
        close_idx = matching_brace(text, open_idx)
        inner = text[open_idx + 1: close_idx]
        if inner.strip():
            body = format_key_entries(inner, indent)
            out.append(f"{indent}tags = {{\n{body}\n{indent}}}")
        else:
            out.append(f"{indent}tags = {{}}")
        pos = close_idx + 1
    out.append(text[pos:])
    return "".join(out)


def main():
    sprites_dir = Path(__file__).resolve().parent.parent.parent / "Content" / "Assets" / "Sprites"

    if not sprites_dir.is_dir():
        print(f"Error: Sprites directory not found at {sprites_dir}", file=sys.stderr)
        sys.exit(1)

    files = find_sprite_lua_files(sprites_dir)
    if not files:
        print(f"No .lua files found in {sprites_dir}")
        sys.exit(0)

    changed = 0
    for path in files:
        original = path.read_text(encoding="utf-8")
        updated = add_blank_lines(original)
        updated = stringify_tags(updated)
        updated = add_blank_lines(updated)

        if updated != original:
            path.write_text(updated, encoding="utf-8")
            print(f"Updated: {path}")
            changed += 1
        else:
            print(f"No changes: {path}")

    print(f"\nDone. {changed} file(s) updated out of {len(files)} total.")


if __name__ == "__main__":
    main()