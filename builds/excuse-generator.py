#!/usr/bin/env python3
"""
Developer Excuse Generator
============================
Because "it works on my machine" is so last quarter.

Usage:
    python3 excuse-generator.py [category]

Categories:
    pr          — excuses for late PRs
    deploy      — excuses for production breakage
    deadline    — excuses for missing deadlines
    meeting     — excuses for being late or unprepared
    all         — random from any category (default)
    help        — show this message
"""

import sys, random, textwrap

CATEGORIES = {
    "pr": [
        "I was refactoring the whole module and it accidentally became a framework.",
        "The linter kept rewriting my code while I was in the bathroom.",
        "It works, but the tests were too depressed to run.",
        "I’m waiting on a dependency that I may have invented.",
        "My code is self-documenting. The docs are just… on sabbatical.",
        "The PR is 90% done — the last 10% is just hard feelings.",
        "I deployed it to production but forgot to git push.",
        "My IDE crashed and took my will to live with it.",
    ],
    "deploy": [
        "It was a feature, not a bug. The users just weren’t cultured enough.",
        "The previous engineer used tabs. I’m still deprogramming the codebase.",
        "This is the expected behavior in the timezone of the previous developer.",
        "The database got tired and took a nap. It’s fine now.",
        "It’s not down — it’s just… aggressively caching.",
        "We’re experiencing higher-than-expected traffic from… ants?",
        "The server is technically responding, just not to humans.",
        "I’m 60% sure this is DNS and 100% sure I’m not touching it.",
    ],
    "deadline": [
        "I finished it, but my cat walked on the Enter key and now it’s in the cloud somewhere.",
        "The scope kept growing. It’s not a project anymore, it’s an ecosystem.",
        "I’ve been interviewing interns to help but they keep asking about the stack.",
        "The deadline and I are in an open relationship. Neither of us is committed.",
        "I had to rewrite the whole thing because the first version was too elegant.",
        "I’m currently blocked on a decision I made three days ago.",
        "The last task is dependent on a task I keep inventing.",
        "I could ship it today, but then I’d have to work on two projects at once.",
    ],
    "meeting": [
        "I was in a different meeting about this meeting.",
        "My calendar sync is religious and refuses to mix with Outlook.",
        "I prepared so well I forgot what day it was.",
        "I had a critical insight that I now cannot remember.",
        "The invite went to spam and my spam folder is very opinionated.",
        "I joined late because I was networking in the waiting room.",
        "I thought this was optional. It’s not. That’s on me.",
        "My tunnel vision from the previous call hasn’t cleared yet.",
    ],
    "coffee": [
        "The machine blinked at me and I took it personally.",
        "I’m on my fifth cup. My productivity graph now looks like a heartbeat monitor.",
        "The barista knows my order better than my manager knows my OKRs.",
        "My coffee is still being brewed in another dimension.",
        "I ran out and now I’m running on three hours of sleep and spite.",
        "I’ve been standing by the machine like it owes me money.",
        "Cold brew is hot take advocacy. I’m not ready for that conversation today.",
    ],
}

def pick(category: str) -> str:
    pool = CATEGORIES.get(category, list(CATEGORIES.values()))
    if isinstance(pool[0], list):
        pool = [item for sub in pool for item in sub]
    return random.choice(pool)

def print_help():
    print(textwrap.dedent("""
    Developer Excuse Generator
    ─────────────────────────
    Usage:  python3 excuse-generator.py [category]

    Categories:  pr | deploy | deadline | meeting | coffee | all (default)
    """))

def main():
    category = "all"
    if len(sys.argv) > 1:
        arg = sys.argv[1].lower().strip()
        if arg in ("help", "-h", "--help"):
            print_help()
            sys.exit(0)
        if arg not in CATEGORIES:
            print(f"Unknown category '{arg}'. Try: {', '.join(CATEGORIES.keys())}")
            sys.exit(1)
        category = arg

    excuse = pick(category)
    cat_display = category.upper() if category != "all" else "RANDOM"
    print(f"\n  [{cat_display}] → {excuse}\n")

if __name__ == "__main__":
    main()
