import importlib.util
import sys
from pathlib import Path


def load_config(config_path: Path) -> dict:
    """Load formatter configuration from TOML file."""
    try:
        import tomllib
    except ImportError:
        print("Error: tomllib not available (Python 3.11+ required)", file=sys.stderr)
        sys.exit(1)

    raw = config_path.read_text(encoding="utf-8")
    return tomllib.loads(raw)


def find_lua_files(
    root: Path,
    exclude_folders: list[str],
    exclude_files: list[str],
) -> list[Path]:
    """Find all .lua files under root, respecting exclusions."""
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
    """Dynamically load an optimization plugin by name."""
    plugin_path = plugins_dir / f"{name}.py"
    if not plugin_path.is_file():
        return None
    spec = importlib.util.spec_from_file_location(name, plugin_path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def main():
    script_dir = Path(__file__).resolve().parent
    config_path = script_dir / "Settings.toml"

    if not config_path.is_file():
        print(f"Error: Config file not found at {config_path}", file=sys.stderr)
        sys.exit(1)

    config = load_config(config_path)

    # --- Resolve target folders ---
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

    # --- Collect files ---
    all_files = []
    for folder in resolved_folders:
        all_files.extend(find_lua_files(folder, exclude_folders, exclude_files))

    if not all_files:
        print("No .lua files found in target folders")
        sys.exit(0)

    # --- Load enabled optimizations ---
    optimizations_config = config.get("optimizations", {})
    plugins_dir = script_dir / "optimizations"

    enabled_plugins = []
    for opt_name, opt_config in optimizations_config.items():
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
        print("Warning: No optimizations enabled", file=sys.stderr)

    # --- Process files ---
    changed = 0
    for path in all_files:
        original = path.read_text(encoding="utf-8")
        updated = original
        for opt_name, module, opt_config in enabled_plugins:
            updated = module.apply(updated, config)

        if updated != original:
            path.write_text(updated, encoding="utf-8")
            print(f"Updated: {path}")
            changed += 1
        else:
            print(f"No changes: {path}")

    print(f"\nDone. {changed} file(s) updated out of {len(all_files)} total.")


if __name__ == "__main__":
    main()
