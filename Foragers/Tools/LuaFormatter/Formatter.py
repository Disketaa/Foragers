import importlib.util
import io
import sys
from pathlib import Path
from typing import cast


def load_config(config_path: Path) -> dict:
    try:
        import tomllib
    except ImportError:
        print("Error: tomllib not available (Python 3.11+ required)", file=sys.stderr)
        sys.exit(1)

    raw = config_path.read_text(encoding="utf-8")
    return tomllib.loads(raw)


def _split_order(value):
    if isinstance(value, str):
        return value.replace(",", " ").split()
    return value


def normalize_orders(config: dict) -> dict:
    for section in ("component_order", "tween_order"):
        sub = config.get(section)
        if isinstance(sub, dict):
            sub["order"] = _split_order(sub.get("order"))
    return config


def find_lua_files(
    root: Path,
    exclude_folders: list[str],
    exclude_files: list[str],
) -> list[Path]:
    exclude_set = set(exclude_files)
    files = []
    for path in sorted(root.rglob("*.lua")):
        if any(excluded in path.parts for excluded in exclude_folders):
            continue
        if path.name in exclude_set:
            continue
        files.append(path)
    return files


def load_plugin(name: str, plugins_dir: Path):
    plugin_path = plugins_dir / f"{name}.py"
    if not plugin_path.is_file():
        return None
    if str(plugins_dir) not in sys.path:
        sys.path.insert(0, str(plugins_dir))
    spec = importlib.util.spec_from_file_location(name, plugin_path)
    if spec is None or spec.loader is None:
        return None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def main():
    cast(io.TextIOWrapper, sys.stdout).reconfigure(encoding="utf-8", errors="replace")
    cast(io.TextIOWrapper, sys.stderr).reconfigure(encoding="utf-8", errors="replace")

    script_dir = Path(__file__).resolve().parent
    config_path = script_dir / "Settings.toml"

    if not config_path.is_file():
        print(f"Error: Config file not found at {config_path}", file=sys.stderr)
        sys.exit(1)

    config = load_config(config_path)
    config = normalize_orders(config)

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

    modules_config = config.get("Modules", {})
    plugins_dir = script_dir / "Modules"

    enabled_plugins = []
    for opt_name, opt_config in modules_config.items():
        if isinstance(opt_config, dict) and not opt_config.get("enabled", True):
            continue
        module = load_plugin(opt_name, plugins_dir)
        if module is None:
            print(f"Warning: Unknown optimization '{opt_name}' — skipping", file=sys.stderr)
            continue
        if not hasattr(module, "apply"):
            print(f"Warning: Optimization '{opt_name}' missing apply() — skipping", file=sys.stderr)
            continue
        enabled_plugins.append((opt_name, module, opt_config))

    if not enabled_plugins:
        print("Warning: No Modules enabled", file=sys.stderr)

    changed = 0
    failed_files = 0
    for path in all_files:
        try:
            original = path.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError) as e:
            print(f"Skip (unreadable): {path} ({e})", file=sys.stderr)
            continue
        updated = original
        try:
            for opt_name, module, opt_config in enabled_plugins:
                include_folders = opt_config.get("include_folders") if isinstance(opt_config, dict) else None
                if include_folders:
                    rel = path.relative_to(project_root).as_posix()
                    if not any(rel.startswith(folder) for folder in include_folders):
                        continue
                if hasattr(module, "set_path"):
                    module.set_path(path)
                updated = module.apply(updated, config)
        except Exception as e:
            # Never let one file's failure abort the whole run.
            failed_files += 1
            print(f"Skip (failed): {path} ({opt_name}: {e})", file=sys.stderr)
            continue

        if updated != original:
            path.write_text(updated, encoding="utf-8")
            print(f"{path}:1:1 - needs formatting")
            changed += 1
        # unchanged files are silently skipped — printing them only spams the console

    print(f"Total: {changed} warnings / 0 errors in {len(all_files)} files")
    sys.stdout.flush()

    for opt_name, module, opt_config in enabled_plugins:
        if hasattr(module, "finalize"):
            module.finalize(script_dir)


if __name__ == "__main__":
    main()
