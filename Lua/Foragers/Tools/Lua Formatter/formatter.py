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

        cur_stripped = line.strip()
        next_line = lines[i + 1]
        next_stripped = next_line.strip()

        is_closing = cur_stripped == "},"
        is_opening = next_stripped == "{"

        same_indent = indent_of(line) == indent_of(next_line)

        if is_closing and is_opening and same_indent:
            result.append("")

    return "\n".join(result)


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

        if updated != original:
            path.write_text(updated, encoding="utf-8")
            print(f"Updated: {path}")
            changed += 1
        else:
            print(f"No changes: {path}")

    print(f"\nDone. {changed} file(s) updated out of {len(files)} total.")


if __name__ == "__main__":
    main()
