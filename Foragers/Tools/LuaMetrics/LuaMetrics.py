#!/usr/bin/env python3
"""
LuaMetrics - Code sloppiness metrics for Lua projects.
Reports cyclomatic complexity spikes and code clones.
"""

import datetime
import hashlib
import json
import os
import re
import sys
import tomllib


def load_settings(root):
    settings_path = os.path.join(root, "Tools", "LuaMetrics", "Settings.toml")
    if not os.path.exists(settings_path):
        return {}
    with open(settings_path, "rb") as f:
        return tomllib.load(f)


def find_lua_files(root, settings):
    root = os.path.abspath(root)
    exclude_files = set(settings.get("targets", {}).get("exclude_files", []))
    exclude_folders = set(settings.get("targets", {}).get("exclude_folders", []))
    exclude_functions = set(settings.get("targets", {}).get("exclude_functions", []))
    exclude_clones = set(settings.get("targets", {}).get("exclude_clones", []))

    files = []
    for dirpath, dirnames, filenames in os.walk(root):
        dirpath_abs = os.path.abspath(dirpath)
        dirname = os.path.basename(dirpath_abs)
        if dirname in exclude_folders:
            continue
        if any(dirpath_abs.startswith(os.path.join(root, ef)) for ef in exclude_folders):
            continue
        for f in filenames:
            if f.endswith(".lua") and f not in exclude_files:
                files.append(os.path.join(dirpath, f))
    return sorted(files), exclude_functions


def strip_strings_and_comments(line):
    result = []
    in_string = False
    string_char = None
    i = 0
    while i < len(line):
        c = line[i]
        if not in_string and c in ('"', "'"):
            in_string = True
            string_char = c
            result.append(" ")
        elif in_string and c == string_char:
            in_string = False
            string_char = None
            result.append(" ")
        elif in_string:
            if c == "\\" and i + 1 < len(line):
                result.append(" ")
                i += 2
                continue
            result.append(" ")
        elif not in_string and c == "-" and i + 1 < len(line) and line[i + 1] == "-":
            break
        else:
            result.append(c)
        i += 1
    return "".join(result)


def normalize(lines):
    normalized = []
    for line in lines:
        s = strip_strings_and_comments(line).strip()
        if s:
            normalized.append(s)
    return normalized


def extract_functions(content, filepath):
    lines = content.split("\n")
    functions = []
    func_start = re.compile(r"^\s*(local\s+)?function\s+([\w:\.]+)")
    anon_start = re.compile(r"function\s*\(")

    i = 0
    depth = 0
    while i < len(lines):
        clean = strip_strings_and_comments(lines[i]).strip()

        m = func_start.match(clean)
        is_anon = bool(anon_start.search(clean))
        if (m or is_anon) and depth == 0:
            name = m.group(2) if m else "anonymous"
            start_line = i + 1

            body_depth = 0
            j = i
            while j < len(lines):
                s = strip_strings_and_comments(lines[j]).strip()
                if not s:
                    j += 1
                    continue
                opens = len(re.findall(r"\b(function|if|repeat)\b", s))
                opens += len(re.findall(r"\b(for|while)\b", s))
                if not re.search(r"\b(for|while)\b.*\bdo\b", s):
                    opens += len(re.findall(r"\bdo\b", s))
                closes = len(re.findall(r"\bend\b", s))
                body_depth += opens - closes
                if body_depth == 0 and j > i:
                    break
                j += 1

            body = lines[i : j + 1]
            cc = calculate_cc(body)
            sloc = count_sloc(body)

            functions.append(
                {
                    "file": filepath,
                    "line": start_line,
                    "name": name,
                    "body": body,
                    "cc": cc,
                    "sloc": sloc,
                }
            )
            i = j + 1
            depth = 0
        else:
            if clean:
                opens = len(re.findall(r"\b(function|if|repeat)\b", clean))
                opens += len(re.findall(r"\b(for|while)\b", clean))
                if not re.search(r"\b(for|while)\b.*\bdo\b", clean):
                    opens += len(re.findall(r"\bdo\b", clean))
                closes = clean.count("end")
                depth += opens - closes
            i += 1

    return functions


def calculate_cc(body_lines):
    cc = 1
    for line in body_lines:
        s = strip_strings_and_comments(line).strip()
        if not s:
            continue
        s_no_elseif = s.replace("elseif", "")
        cc += (
            s_no_elseif.count("if ")
            + s.count("elseif ")
            + s.count("while ")
            + s.count("for ")
            + s.count("repeat ")
        )
        for op in [" and ", " or "]:
            idx = 0
            while True:
                idx = s.find(op, idx)
                if idx == -1:
                    break
                before = s[:idx].strip()
                if before.endswith("=") or before.endswith(":") or before.endswith(",") or before.endswith("(") or before == "":
                    idx += len(op)
                    continue
                cc += 1
                idx += len(op)
    return cc


def count_sloc(body_lines):
    count = 0
    for line in body_lines:
        s = strip_strings_and_comments(line).strip()
        if s:
            count += 1
    return count


def detect_clones(functions, min_lines=6):
    chunks = []
    for func in functions:
        body = func["body"]
        if len(body) < min_lines:
            continue
        norm = normalize(body)
        if len(norm) < min_lines:
            continue
        for start in range(len(norm) - min_lines + 1):
            window = norm[start : start + min_lines]
            key = "\n".join(window)
            chunks.append(
                {
                    "file": func["file"],
                    "line": func["line"] + start,
                    "key": key,
                    "size": min_lines,
                }
            )

    seen = {}
    clones = []
    for chunk in chunks:
        if chunk["key"] in seen:
            other = seen[chunk["key"]]
            clones.append(
                {
                    "file1": other["file"],
                    "line1": other["line"],
                    "file2": chunk["file"],
                    "line2": chunk["line"],
                    "size": chunk["size"],
                    "key": chunk["key"],
                }
            )
        else:
            seen[chunk["key"]] = chunk

    unique = {}
    for c in clones:
        key = (c["file1"], c["line1"], c["file2"], c["line2"])
        if key not in unique:
            unique[key] = c

    return list(unique.values())


def compute_fingerprint(body_lines):
    norm = normalize(body_lines)
    body = "\n".join(norm)
    return hashlib.sha256(body.encode("utf-8")).hexdigest()


def load_baseline(root):
    path = os.path.join(root, "Tools", "LuaMetrics", "Baseline.json")
    if not os.path.exists(path):
        return {}
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def save_baseline(root, baseline):
    path = os.path.join(root, "Tools", "LuaMetrics", "Baseline.json")
    with open(path, "w", encoding="utf-8") as f:
        json.dump(baseline, f, indent=2)


def main():
    if len(sys.argv) < 2:
        print("Usage: LuaMetrics.py <project_root>", file=sys.stderr)
        sys.exit(1)

    root = sys.argv[1]
    settings = load_settings(root)
    files, exclude_functions = find_lua_files(root, settings)

    all_functions = []
    for f in files:
        try:
            with open(f, "r", encoding="utf-8") as fh:
                content = fh.read()
            funcs = extract_functions(content, f)
            all_functions.extend(funcs)
        except Exception as e:
            print(f"Error reading {f}: {e}", file=sys.stderr)

    warnings = 0
    errors = 0
    files_with_issues = set()
    output_lines = []

    cc_warn = settings.get("metrics", {}).get("cc_warn", 10)
    cc_error = settings.get("metrics", {}).get("cc_error", 20)
    clone_min = settings.get("metrics", {}).get("clone_min_lines", 6)

    baseline = load_baseline(root)
    updated_baseline = {}
    now = datetime.datetime.now().isoformat()

    # Erosion: CC > cc_error error, CC > cc_warn warning
    for f in all_functions:
        rel = os.path.relpath(f["file"], root)
        key = f"{rel}:{f['line']}:{f['name']}"
        fp = compute_fingerprint(f["body"])

        if f["name"] in exclude_functions:
            updated_baseline[key] = {"fingerprint": fp, "updated": now}
            continue

        entry = baseline.get(key)
        if entry and entry.get("fingerprint") == fp:
            updated_baseline[key] = entry
            continue

        if entry and entry.get("fingerprint") != fp:
            output_lines.append(
                f"{rel}:{f['line']}:1 - CC={f['cc']} exceeds warn threshold ({cc_warn}): {f['name']} [BASELINE CHANGED]"
            )
            warnings += 1
            files_with_issues.add(f["file"])
            updated_baseline[key] = {"fingerprint": fp, "updated": now}
            continue

        if f["cc"] > cc_error:
            errors += 1
            files_with_issues.add(f["file"])
            output_lines.append(
                f"{rel}:{f['line']}:1 - CC={f['cc']} exceeds error threshold ({cc_error}): {f['name']}"
            )
        elif f["cc"] > cc_warn:
            warnings += 1
            files_with_issues.add(f["file"])
            output_lines.append(
                f"{rel}:{f['line']}:1 - CC={f['cc']} exceeds warn threshold ({cc_warn}): {f['name']}"
            )

    # Verbosity: clones
    clones = detect_clones(all_functions, min_lines=clone_min)
    for c in clones:
        rel1 = os.path.relpath(c["file1"], root)
        rel2 = os.path.relpath(c["file2"], root)
        bkey = f"clone:{rel1}:{c['line1']}:{rel2}:{c['line2']}"
        fp = hashlib.sha256(c["key"].encode("utf-8")).hexdigest()

        entry = baseline.get(bkey)
        if entry and entry.get("fingerprint") == fp:
            updated_baseline[bkey] = entry
            continue

        updated_baseline[bkey] = {"fingerprint": fp, "updated": now}
        warnings += 1
        files_with_issues.add(c["file1"])
        files_with_issues.add(c["file2"])
        output_lines.append(
            f"{rel1}:{c['line1']}:1 - {c['size']}-line clone, also at {rel2}:{c['line2']}"
        )

    for line in output_lines:
        print(line)

    if output_lines:
        print()
    if errors:
        print(f"{errors} errors / {warnings} warnings in {len(files_with_issues)} files")
    elif warnings:
        print(f"{warnings} warnings in {len(files_with_issues)} files")
    print("Hint: raise thresholds in Settings.toml (cc_warn=10, cc_error=20), extract clones into shared helpers, or add accepted warnings to targets.exclude_functions in Settings.toml.")
    save_baseline(root, updated_baseline)
    sys.exit(errors)


if __name__ == "__main__":
    main()
