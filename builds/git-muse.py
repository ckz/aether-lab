#!/usr/bin/env python3
"""
git-muse.py — Your repo's personal muse.
Reads git history, finds your coding soul, and writes you a poem.
"""
import subprocess, collections, random, sys, datetime, re

ASCII_MUSE = """
     .   .     .
    .  .  . .  .
     .   ✨   .
    .  .  . .  .
     .   .     .
  Your repo's muse speaks...
"""

def git_log(repo="."):
    try:
        raw = subprocess.check_output(
            ["git", "-C", repo, "log", "--format=%H|%ai|%s", "--all", "--no-merges"],
            stderr=subprocess.DEVNULL, text=True, timeout=10
        )
    except (subprocess.CalledProcessError, FileNotFoundError):
        return []
    commits = []
    for line in raw.strip().split("\n"):
        if "|" not in line:
            continue
        sha, date_str, msg = line.split("|", 2)
        commits.append({"date": date_str, "msg": msg, "hour": int(date_str[11:13])})
    return commits

def analyze(commits):
    if not commits:
        return None
    hours = collections.Counter(c["hour"] for c in commits)
    peak_hour = hours.most_common(1)[0][0]
    total = len(commits)
    words = re.findall(r"\b[a-z]{4,}\b", " ".join(c["msg"].lower() for c in commits))
    stop = {"this","that","with","from","into","just","when","have","been","were",
            "some","more","over","then","them","than","only","also","does","into",
            "back","make","like","time","work","code","push","pull","merge","fixed",
            "update","adding","remove","removed","adding","change","changed","using"}
    top_words = [(w,c) for w,c in collections.Counter(words).most_common(30) if w not in stop]
    types = collections.Counter()
    for msg in (c["msg"].lower() for c in commits):
        if any(k in msg for k in ["fix","bug","patch","resolve"]): types["fixes"] += 1
        elif any(k in msg for k in ["add","feat","new","implement"]): types["features"] += 1
        elif any(k in msg for k in ["refactor","clean","tidy","restructure"]): types["refactors"] += 1
        elif any(k in msg for k in ["doc","readme","comment"]): types["docs"] += 1
        elif any(k in msg for k in ["test","spec","assert"]): types["tests"] += 1
        else: types["other"] += 1
    recent = [c["msg"] for c in commits[:5]]
    return {
        "total": total, "peak_hour": peak_hour, "hours": hours,
        "top_words": top_words[:8], "types": types, "recent": recent,
        "first_date": commits[-1]["date"][:10],
        "last_date": commits[0]["date"][:10],
    }

HOUR_POEMS = {
    0: "You code in the witching hour, where bugs fear to tread.",
    1: "The compiler is your lullaby, syntax your midnight prayer.",
    2: "Insomnia-driven commits — your mind refuses to close its tabs.",
    3: "At this hour, even the terminal is sleepy. You are not.",
    4: "Birds don't sing yet. Your tests do.",
    5: "Dawn commit. You beat the sun again.",
    6: "Coffee in hand, your fingers were typing before you were awake.",
    7: "Morning commits — crisp, optimistic, destined to break by noon.",
    8: "The workday begins, and your git log is already ahead.",
    9: "Peak productivity window. The repo trembles with your output.",
    10: "You are in the flow state. Do not disturb the developer.",
    11: "Still going strong. Lunch is a myth you don't believe in.",
    12: "Midday commits. The code flows between bites.",
    13: "Post-lunch debugging. The food coma hasn't won yet.",
    14: "Afternoon slumber battles a stubborn type error. The type error wins.",
    15: "The 3pm energy is sustained by pure spite and matcha.",
    16: "Late afternoon clarity — you see the architecture now.",
    17: "End-of-day polish. Your commits are tidier than your desk.",
    18: "Evening coding begins. The real work starts now.",
    19: "Dinner can wait. There's a PR to close.",
    20: "Night owl mode activated. The world is quiet, your focus is loud.",
    21: "You've solved three hard problems since sunset.",
    22: "The creative hours — this is where the magic gets committed.",
    23: "Just one more commit. It's never just one.",
}

WORD_POEMS = {
    "refactor": "You refactor not because it's broken, but because it could be beautiful.",
    "fix": "Your fixes are surgical. Your bugs are stories.",
    "feat": "Every feature is a small universe you built from nothing.",
    "deadline": "Deadlines pass. Your code remains, ghostly and well-tested.",
    "hotfix": "Hotfixes are love letters written in panic.",
    "docker": "You containerize your problems. They cannot escape.",
    "test": "Tests are poems your future self reads with gratitude.",
    "api": "You speak fluent HTTP in your dreams.",
    "deploy": "Every deploy is a small act of faith.",
    "database": "Tables, rows, and the occasional existential query.",
    "async": "You embrace the async. You fear nothing.",
    "cache": "The cache remembers what you forgot.",
    "auth": "You guard the gates. Passwords are your poetry.",
    "config": "Config files: the quiet soul of every project.",
    "ci": "You build in public, fail in private, deploy with confidence.",
    "wip": "Work in progress. The most honest commit message.",
    "revert": "To revert is to admit: even you are human.",
    "merge": "The merge is where histories collide and usually conflict.",
    "style": "You lint your code. Your thoughts may never be so neat.",
    "perf": "Performance: because someone, somewhere, is still on 3G.",
}

TYPE_EMOJI = {"features": "✨", "fixes": "🔧", "refactors": "♻️", "docs": "📖", "tests": "🧪", "other": "🌊"}

def muse(stats):
    lines = []
    lines.append(ASCII_MUSE)
    lines.append(f"📅 {stats['first_date']} → {stats['last_date']}  |  {stats['total']} commits")
    lines.append("")

    # Dominant archetype
    dom_type, dom_count = max(stats["types"].items(), key=lambda x: x[1])
    emoji = TYPE_EMOJI.get(dom_type, "🔮")
    lines.append(f"{emoji} Your spirit: {dom_type.upper()}")
    lines.append("")

    # Type breakdown
    lines.append("  Commit flavors:")
    for t, c in sorted(stats["types"].items(), key=lambda x: -x[1]):
        max_c = max(stats["types"].values())
        bar_len = max(1, round(c / max_c * 20)) if max_c > 0 else 0
        bar = "█" * bar_len + "░" * (20 - bar_len)
        lines.append(f"    {TYPE_EMOJI.get(t,'·')} {t:<10} {bar} {c}")
    lines.append("")

    # Peak hour
    ph = stats["peak_hour"]
    lines.append(f"⏰ Peak coding hour: {ph:02d}:00")
    poem = HOUR_POEMS.get(ph, "You code at an hour that defies categorization.")
    lines.append(f"   \"{poem}\"")
    lines.append("")

    # Word musings
    if stats["top_words"]:
        lines.append("🔤 Your lyrical themes:")
        for w, c in stats["top_words"][:5]:
            if w in WORD_POEMS:
                lines.append(f'   "{WORD_POEMS[w]}"')
        lines.append("")

    # Random musing from top words
    if stats["top_words"]:
        rw = random.choice(stats["top_words"])[0]
        if rw not in WORD_POEMS:
            musings = [
                f"You write about \"{rw}\" often. It means something to you.",
                f"\"{rw}\" appears {random.choice([x[1] for x in stats['top_words'] if x[0]==rw])} times. Some devotions are quiet.",
                f"Between the lines of \"{rw}\", a story waits to be told.",
                f"Your commit messages whisper \"{rw}\". The repo listens.",
            ]
            lines.append(f'   "{random.choice(musings)}"')
        lines.append("")

    # Recent journey
    lines.append("📜 Recent echoes:")
    for msg in stats["recent"]:
        lines.append(f"   · {msg[:70]}")
    lines.append("")

    # Closing verse
    verses = [
        "Your code is a map of your mind. It is intricate. It is beautiful.",
        "Every commit is a heartbeat. Your repo pulses with life.",
        "The terminal is a mirror. Look long enough, and you'll see the muse.",
        "You build worlds in text. Some are ephemeral. Others become infrastructure.",
        "The best code is not written. It is remembered by the machine.",
        "Syntax is grammar. Architecture is poetry. You are the bard.",
    ]
    lines.append(f"\n  🎭 \"{random.choice(verses)}\"")
    lines.append(f"\n   — git-muse, on {datetime.date.today().isoformat()}")
    return "\n".join(lines)

def main():
    repo = sys.argv[1] if len(sys.argv) > 1 else "."
    commits = git_log(repo)
    stats = analyze(commits)
    if not stats:
        print("⚠️  No git history found. The muse is silent in unversioned lands.")
        sys.exit(1)
    print(muse(stats))

if __name__ == "__main__":
    main()
