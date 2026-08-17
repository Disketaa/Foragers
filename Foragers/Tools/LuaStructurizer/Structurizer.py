import importlib.util
import io
import re
import sys
from pathlib import Path
from typing import cast


def load_config(config_path: Path) -> dict:
    try:
        import tomllib
    except ImportError:
        print("Error: tomllib not available (Python 3.11+ required)", file=sys.stderr)
        sys.exit(1)

    return tomllib.loads(config_path.read_text(encoding="utf-8"))


def find_lua_files(root: Path, exclude_folders: list[str], exclude_files: list[str]) -> list[Path]:
    exclude_set = set(exclude_files)
    files = []
    for path in sorted(root.rglob("*.lua")):
        if any(excluded in path.parts for excluded in exclude_folders):
            continue
        if path.name in exclude_set:
            continue
        files.append(path)
    return files


def load_rule(name: str, rules_dir: Path):
    rule_path = rules_dir / f"{name}.py"
    if not rule_path.is_file():
        return None
    if str(rules_dir) not in sys.path:
        sys.path.insert(0, str(rules_dir))
    spec = importlib.util.spec_from_file_location(name, rule_path)
    if spec is None or spec.loader is None:
        return None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


_ALLOW_TOKEN = "structure:allow-print"
_LONG_OPEN = re.compile(r"\[=*\[")


def _blank_inside(span: str, keep_ends: bool) -> str:
    # Preserve embedded newlines so multi-line --[[ ]] comments and [[ ]] strings
    # don't collapse and shift every later violation's reported line number.
    if keep_ends and len(span) >= 2:
        inner = "".join(c if c == "\n" else " " for c in span[1:-1])
        return span[0] + inner + span[-1]
    return "".join(c if c == "\n" else " " for c in span)


def _strip_span(text, start, end, keep_ends):
    seg = text[start:end]
    if _ALLOW_TOKEN in seg:
        out = list(" " * len(seg))
        idx = seg.index(_ALLOW_TOKEN)
        for off, ch in enumerate(_ALLOW_TOKEN):
            out[idx + off] = ch
        return "".join(out)
    return _blank_inside(seg, keep_ends)


def strip_comments_and_strings(text: str) -> str:
    # Replace comment and string spans with equal-length whitespace so line numbers
    # and column offsets stay valid for downstream regex rules. String literals keep
    # their quotes (inside blanked) so rules that match `== "..."` still see the
    # quote; comment/string content can no longer false-trigger keyword scans.
    # The project opt-out token is preserved so PrintVsLog's allow-print still works.
    out = []
    i = 0
    n = len(text)
    while i < n:
        ch = text[i]
        if ch == "-" and i + 1 < n and text[i + 1] == "-":
            j = text.find("\n", i)
            if j == -1:
                j = n
            out.append(_strip_span(text, i, j, False))
            i = j
            continue
        if ch == "[":
            m = _LONG_OPEN.match(text, i)
            if m:
                eq = m.group(0)
                close = eq[0] + eq[1:-1] + "]"
                j = text.find(close, i + len(eq))
                if j == -1:
                    j = n
                else:
                    j += len(close)
                is_comment = i >= 2 and text[i - 2:i] == "--"
                out.append(_strip_span(text, i, j, not is_comment))
                i = j
                continue
            out.append(ch)
            i += 1
            continue
        if ch == '"' or ch == "'":
            quote = ch
            j = i + 1
            while j < n:
                if text[j] == "\\" and j + 1 < n:
                    j += 2
                    continue
                if text[j] == quote:
                    j += 1
                    break
                j += 1
            out.append(_strip_span(text, i, j, True))
            i = j
            continue
        out.append(ch)
        i += 1
    return "".join(out)


def main():
    cast(io.TextIOWrapper, sys.stdout).reconfigure(encoding="utf-8", errors="replace")
    cast(io.TextIOWrapper, sys.stderr).reconfigure(encoding="utf-8", errors="replace")

    script_dir = Path(__file__).resolve().parent
    config_path = script_dir / "Settings.toml"

    if not config_path.is_file():
        print(f"Error: Config not found at {config_path}", file=sys.stderr)
        sys.exit(1)

    config = load_config(config_path)
    # Private key so rules can resolve relative include_folders without re-deriving root.
    config["_project_root"] = script_dir.parent.parent

    targets = config.get("targets", {})
    folders = targets.get("folders", [])
    exclude_folders = targets.get("exclude_folders", [])
    exclude_files = targets.get("exclude_files", [])

    if not folders:
        print("Error: No target folders specified in config", file=sys.stderr)
        sys.exit(1)

    project_root = script_dir.parent.parent
    resolved_folders = []
    for folder in folders:
        if folder == "*":
            resolved_folders = [project_root]
            break
        resolved = project_root / folder
        if resolved.is_dir():
            resolved_folders.append(resolved)
        else:
            print(f"Warning: Target folder not found: {resolved}", file=sys.stderr)

    if not resolved_folders:
        print("Error: No valid target folders found", file=sys.stderr)
        sys.exit(1)

    all_files = []
    for folder in resolved_folders:
        all_files.extend(find_lua_files(folder, exclude_folders, exclude_files))

    if not all_files:
        print("No .lua files found in target folders")
        sys.exit(0)

    rules_config = config.get("Rules", {})
    rules_dir = script_dir / "Modules"

    enabled_rules = []
    for name, rcfg in rules_config.items():
        if isinstance(rcfg, dict) and not rcfg.get("enabled", True):
            continue
        module = load_rule(name, rules_dir)
        if module is None:
            print(f"Warning: Unknown rule '{name}' — skipping", file=sys.stderr)
            continue
        if not hasattr(module, "check"):
            print(f"Warning: Rule '{name}' missing check() — skipping", file=sys.stderr)
            continue
        enabled_rules.append((name, module, rcfg or {}))

    if not enabled_rules:
        print("Warning: No rules enabled", file=sys.stderr)

    all_violations = []  # (path, line, rule, severity, msg)
    for path in all_files:
        try:
            original = path.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError) as e:
            print(f"Skip (unreadable): {path} ({e})", file=sys.stderr)
            continue
        stripped = strip_comments_and_strings(original)
        for name, module, rcfg in enabled_rules:
            try:
                if hasattr(module, "set_path"):
                    module.set_path(path)
                results = module.check(stripped, path, config)
            except Exception as e:
                print(f"Skip (rule failed): {path} ({name}: {e})", file=sys.stderr)
                continue
            sev_override = rcfg.get("severity") if isinstance(rcfg, dict) else None
            for res in results:
                line, msg, sev = res[0], res[1], res[2]
                if sev_override:
                    sev = sev_override
                all_violations.append((path, line, name, sev, msg))

    all_violations.sort(key=lambda v: (str(v[0]), v[1], v[3]))
    errors = 0
    current = None
    for path, line, name, sev, msg in all_violations:
        if path != current:
            print(f"\n{path}")
            current = path
        print(f"  [{sev.upper()}] {name} (L{line}): {msg}")
        if sev == "error":
            errors += 1

    print(f"\n\u2705 Done. {len(all_violations)} violation(s), {errors} error(s) across {len(all_files)} file(s).")
    sys.stdout.flush()

    if errors > 0:
        sys.exit(1)


if __name__ == "__main__":
    main()
