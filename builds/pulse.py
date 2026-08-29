#!/usr/bin/env python3
"""
pulse.py — Workspace Pulse Checker
A tiny CLI that takes the "temperature" of any project folder.

Usage:
    python pulse.py [path]

Defaults to current directory if no path given.
Zero dependencies beyond Python stdlib.
"""

import os
import sys
import stat
import math
import subprocess
import hashlib
from pathlib import Path
from collections import Counter
from datetime import datetime, timezone


# ─── Color helpers ───────────────────────────────────────────────
try:
    ANSI = {
        "reset": "\033[0m",
        "bold": "\033[1m",
        "dim": "\033[2m",
        "cyan": "\033[96m",
        "green": "\033[92m",
        "yellow": "\033[93m",
        "magenta": "\033[95m",
        "blue": "\033[94m",
        "red": "\033[91m",
        "gray": "\033[90m",
    }
except Exception:
    ANSI = {k: "" for k in ["reset", "bold", "dim", "cyan", "green", "yellow", "magenta", "blue", "red", "gray"]}


def c(key, text):
    return f"{ANSI.get(key, '')}{text}{ANSI.get('reset', '')}"


# ─── Helpers ─────────────────────────────────────────────────────
def human_size(nbytes: int) -> str:
    """Format bytes into human-friendly string."""
    if nbytes == 0:
        return "0 B"
    units = ["B", "KB", "MB", "GB"]
    i = min(int(math.log(nbytes, 1024)), len(units) - 1)
    return f"{nbytes / (1024 ** i):.1f} {units[i]}"


def human_age(ts: float) -> str:
    """Relative time string from unix timestamp."""
    delta = datetime.now(timezone.utc).timestamp() - ts
    if delta < 60:
        return f"{int(delta)}s ago"
    if delta < 3600:
        return f"{int(delta // 60)}m ago"
    if delta < 86400:
        return f"{int(delta // 3600)}h ago"
    return f"{int(delta // 86400)}d ago"


def extension_stats(root: Path, max_entries=12):
    """Walk files and return Counter of extensions + total bytes."""
    ext_counter: Counter = Counter()
    size_counter: Counter = Counter()
    latest_ts = 0.0
    total_files = 0
    total_bytes = 0

    for dirpath, dirnames, filenames in os.walk(root):
        # Skip hidden dirs like .git, .venv, node_modules
        dirnames[:] = [d for d in dirnames if not d.startswith(".")]
        for fname in filenames:
            if fname.startswith("."):
                continue
            fpath = Path(dirpath) / fname
            try:
                st = fpath.stat()
            except OSError:
                continue
            total_files += 1
            total_bytes += st.st_size
            ext = fpath.suffix.lower() or "(no ext)"
            ext_counter[ext] += 1
            size_counter[ext] += st.st_size
            if st.st_mtime > latest_ts:
                latest_ts = st.st_mtime

    return ext_counter, size_counter, latest_ts, total_files, total_bytes


def git_info(root: Path):
    """Return dict of git info if inside a repo, else None."""
    git_dir = root / ".git"
    if not git_dir.is_dir():
        return None

    info = {"repo": True}

    def run(cmd):
        try:
            out = subprocess.check_output(cmd, cwd=root, stderr=subprocess.DEVNULL, text=True).strip()
            return out
        except (subprocess.CalledProcessError, FileNotFoundError):
            return None

    branch = run(["git", "symbolic-ref", "--short", "HEAD"])
    if branch:
        info["branch"] = branch

    commits = run(["git", "rev-list", "--count", "HEAD"])
    if commits:
        info["commits"] = commits

    since = run(["git", "log", "-1", "--format=%cr", "--date=relative"])
    if since:
        info["last_commit"] = since

    # top contributors
    contributors = run(["git", "shortlog", "-sn", "--all", "--", "."])
    if contributors:
        lines = [l.strip() for l in contributors.splitlines() if l.strip()]
        info["top_contributors"] = lines[:3]

    # dirty?
    status = run(["git", "status", "--porcelain"])
    info["dirty"] = bool(status)

    return info


def mood(total_files, ext_count, latest_ts, git):
    """Determine a fun one-word 'vibe' of the project."""
    now = datetime.now(timezone.utc).timestamp()
    age = now - latest_ts if latest_ts else now

    if total_files == 0:
        return "empty", "💨"
    if age < 300:
        heat = "🔥"
    elif age < 86400:
        heat = "✨"
    elif age < 604800:
        heat = "🌤️"
    else:
        heat = "❄️"

    if git and git.get("dirty"):
        return "tinkering", f"{heat} 🔧"
    if ext_count > 30:
        return "busy", f"{heat} 🚧"
    if total_files < 20:
        return "minimal", f"{heat} 🍃"
    if age < 300:
        return "active", f"{heat} ⚡"
    return "quiet", f"{heat} 🧘"


# ─── Main ────────────────────────────────────────────────────────
def pulse(path: str = "."):
    root = Path(path).resolve()
    if not root.is_dir():
        print(c("red", f"✗ Not a directory: {root}"))
        sys.exit(1)

    name = root.name or str(root)
    ext_counter, size_counter, latest_ts, total_files, total_bytes = extension_stats(root)
    git = git_info(root)
    vibe, vibe_emoji = mood(total_files, len(ext_counter), latest_ts, git)

    # ── Header ────────────────────────────────────────────────────
    print()
    print(c("bold", "╭─ ") + c("cyan", f"PULSE: {name}") + c("bold", " ──────────────────────────╮"))
    print()

    # ── Vibe ──────────────────────────────────────────────────────
    print(f"  {c('bold', 'Vibe:')}  {vibe_emoji}  {c('magenta', vibe.upper())}")

    # ── File summary ──────────────────────────────────────────────
    print(f"  {c('bold', 'Files:')}  {total_files}  ({c('cyan', human_size(total_bytes))})")

    if latest_ts:
        print(f"  {c('bold', 'Last:')}  {c('gray', human_age(latest_ts))}  ({c('gray', datetime.fromtimestamp(latest_ts, tz=timezone.utc).strftime('%Y-%m-%d %H:%M UTC'))})")

    # ── Top extensions ────────────────────────────────────────────
    if ext_counter:
        print()
        print(c("bold", "  ── File Types ──────────────────────────────────"))
        top = ext_counter.most_common(12)
        max_count = top[0][1] if top else 1
        max_size = max(size_counter.get(ext, 0) for ext, _ in top) if top else 1
        for ext, count in top:
            bar_len = int((count / max_count) * 18)
            bar = c("cyan", "█" * bar_len) + c("dim", "░" * (18 - bar_len))
            pct = count / total_files * 100
            size_str = human_size(size_counter.get(ext, 0))
            ext_label = c("yellow", f"{ext:<12s}") if len(ext) < 12 else c("yellow", ext)
            print(f"  {ext_label} {bar} {c('gray', f'{count:>4d} ({pct:4.1f}%)')}  {c('dim', size_str)}")

    # ── Git info ──────────────────────────────────────────────────
    if git:
        print()
        print(c("bold", "  ── Git ──────────────────────────────────────────"))
        branch = git.get("branch", "?")
        branch_str = c("green", branch) if branch != "main" else c("cyan", branch)
        print(f"  {c('bold', 'Branch:')} {branch_str}")
        if "commits" in git:
            print(f"  {c('bold', 'Commits:')} {git['commits']}")
        if "last_commit" in git:
            print(f"  {c('bold', 'Last:')} {c('gray', git['last_commit'])}")
        if "top_contributors" in git:
            contribs = ", ".join(git["top_contributors"])
            print(f"  {c('bold', 'Top:')} {c('gray', contribs)}")
        if git.get("dirty"):
            print(f"  {c('bold', 'Status:')} {c('yellow', '⚠  uncommitted changes')}")

    # ── Footer ────────────────────────────────────────────────────
    print()
    print(c("bold", "╰───────────────────────────────────────────────╯"))
    print()


def main():
    target = sys.argv[1] if len(sys.argv) > 1 else "."
    pulse(target)


if __name__ == "__main__":
    main()
