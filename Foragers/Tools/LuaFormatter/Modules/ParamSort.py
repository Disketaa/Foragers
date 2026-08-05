import re
import sys
from pathlib import Path

from _lua import matching_brace, split_top_level

_found = []
_current_path = None


def set_path(path) -> None:
    global _current_path
    _current_path = path


def finalize(base_dir) -> None:
    if not _found:
        return
    by_param = {}
    for path, key in _found:
        by_param.setdefault(key, []).append(Path(path).name)
    print("\n\u26a0\ufe0f [Error] Unknown params not in [param_order]:", file=sys.stderr)
    for key, names in sorted(by_param.items()):
        print(f"  {key}: {', '.join(sorted(names))}", file=sys.stderr)


def apply(text: str, config: dict) -> str:
    order = config.get("param_order", {}).get("order", [])
    if not order:
        return text

    pattern = re.compile(r"^([ \t]*)return\s*\{$", re.MULTILINE)
    m = pattern.search(text)
    if not m:
        return text

    indent = m.group(1)
    open_idx = m.end() - 1
    close_idx = matching_brace(text, open_idx)
    inner = text[open_idx + 1: close_idx]

    entries = split_top_level(inner)
    if len(entries) < 2:
        return text

    order_index = {name: i for i, name in enumerate(order)}

    def param_key(entry: str):
        # Only single-line `key = value` entries are sortable params.
        # Multi-line blocks (e.g. `components = {...}`) are kept after params.
        if "\n" in entry:
            return None
        km = re.match(r"(\w+)\s*=", entry)
        return km.group(1) if km else None

    def sort_key(item):
        entry, key = item
        if key is None:
            return (1, 0)
        return (0, order_index.get(key, len(order)))

    keyed = [(e, param_key(e)) for e in entries]

    # stable sort: known order first, unknown params after, blocks last
    sorted_entries = [e for e, _ in sorted(keyed, key=sort_key)]

    for _, key in keyed:
        if key is not None and key not in order_index:
            _found.append((_current_path, key))

    entry_indent = indent + "\t"
    joined = f",\n{entry_indent}".join(sorted_entries)
    return (
        text[:m.start()]
        + f"{indent}return {{\n{entry_indent}{joined},\n{indent}}}"
        + text[close_idx + 1:]
    )
