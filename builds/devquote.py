#!/usr/bin/env python3
"""
DevQuote — Random developer/programming quotes for your terminal.

Usage:
    devquote              # random quote
    devquote --list       # list all quotes
    devquote --count N    # show N random quotes
    devquote --json       # output as JSON
"""

import random
import sys
import json
import argparse
from datetime import datetime

# ─── Quote Bank ───────────────────────────────────────────────────────
QUOTES = [
    ("Ken Thompson", "One of my most productive days was throwing away 1000 lines of code."),
    ("Donald Knuth", "Premature optimization is the root of all evil."),
    ("Brian Kernighan", "Debugging is twice as hard as writing the code in the first place."),
    ("Linus Torvalds", "Talk is cheap. Show me the code."),
    ("Grace Hopper", "It's easier to ask forgiveness than it is to get permission."),
    ("Martin Fowler", "Any fool can write code that a computer can understand. Good programmers write code that humans can understand."),
    ("Alan Kay", "The best way to predict the future is to invent it."),
    ("Rich Hickey", "Programmers know the benefits of everything and the tradeoffs of nothing."),
    ("Niklaus Wirth", "Software gets slower faster than hardware gets faster."),
    ("John Carmack", "Low-level programming is good for the programmer's soul."),
    ("Douglas Crockford", "Code is not an asset. It's a liability."),
    ("Gerald Weinberg", "If builders built buildings the way programmers wrote programs, the first woodpecker to come along would destroy civilization."),
    ("Abelson & Sussman", "Programs must be written for people to read, and only incidentally for machines to execute."),
    ("Jamie Zawinski", "Some people, when confronted with a problem, think 'I know, I'll use regular expressions.' Now they have two problems."),
    ("Larry Wall", "Easy things should be easy, and hard things should be possible."),
    ("Jeff Atwood", "Any code of your own that you haven't looked at for six months might as well have been written by someone else."),
    ("Kent Beck", "Make it work, make it right, make it fast."),
    ("Phil Karlton", "There are only two hard things in Computer Science: cache invalidation and naming things."),
    ("Steve Jobs", "The way to get started is to quit talking and begin doing."),
    ("Mark Zuckerberg", "Move fast and break things. Unless you are breaking stuff, you are not moving fast enough."),
    ("Dennis Ritchie", "The only way to learn a new programming language is by writing programs in it."),
    ("Bjarne Stroustrup", "There are only two kinds of languages: the ones people complain about and the ones nobody uses."),
    ("Brendan Eich", "Always bet on JavaScript."),
    ("Yukihiro Matsumoto", "Ruby is designed to make programmers happy."),
    ("Guido van Rossum", "Readability counts."),
    ("Larry Page", "Always deliver more than expected."),
    ("Jeff Bezos", "If you double the number of experiments you do per year, you're going to double your inventiveness."),
    ("Elon Musk", "When something is important enough, you do it even if the odds are not in your favor."),
    ("Reed Hastings", "We're in this world where we have Silicon Valley and Hollywood colliding."),
    ("Steve Wozniak", "If you love what you do, you can't help but be good at it."),
    ("Satoshi Nakamoto", "With e-currency based on cryptographic proof, no trust is required."),
    ("Hal Abelson", "Programs must be written for people to read, and only incidentally for machines to execute."),
    ("Barbara Liskov", "The best programs are written so that computing machines can perform them quickly and so that human beings can understand them clearly."),
    ("Tony Hoare", "There are two ways to write error-free programs; only the third works."),
    ("Edsger Dijkstra", "Simplicity is prerequisite for reliability."),
    ("Grady Booch", "The function of good software is to make the complex appear to be simple."),
    ("Rasmus Lerdorf", "I've never thought of PHP as more than a simple tool to solve problems."),
    ("DHH", "It's not the size of the boat that matters, it's the motion of the ocean."),
    ("Sandi Metz", "Duplication is far cheaper than the wrong abstraction."),
    ("Uncle Bob", "Truth can only be found in one place: the code."),
    ("Rachel by the Bay", "The code you wrote today is technical debt tomorrow."),
    ("Chris Penner", "Haskell is the world's most overrated programming language. And also its most underrated."),
    ("Casey Muratori", "The best code is the code you don't have to write."),
    ("Chris Lattner", "Compilers are the original transpilers."),
    ("Rob Pike", "Value semantics, interfaces, and concurrency — that's Go."),
    ("Bjarne Stroustrup", "C makes it easy to shoot yourself in the foot; C++ makes it harder."),
    ("Anders Hejlsberg", "TypeScript is JavaScript that scales."),
    ("Chris Wilson", "The browser is the new operating system."),
    ("Mitch Kapor", "Getting information off the Internet is like taking a drink from a fire hydrant."),
    ("Vint Cerf", "The internet is a mirror of ourselves."),
    ("Tim Berners-Lee", "The Web does not just connect machines, it connects people."),
    ("Linus Torvalds", "Software is like sex: it's better when it's free."),
    ("Mark Zuckerberg", "We don't build services to make money; we make money to build better services."),
    ("Dave Thomas", "Code is not just code. It's a living, breathing thing."),
    ("Chris Wilson", "The best way to predict the future is to build it."),
    ("Mark Zuckerberg", "The biggest risk is not taking any risk."),
    ("Tim Cook", "You can focus on things that are barriers, or you can focus on scaling the wall."),
    ("Sundar Pichai", "Wear your failure as a badge of honor."),
    ("Satya Nadella", "Our industry does not respect tradition — what it respects is innovation."),
    ("Jeff Bezos", "If you're not stubborn, you'll give up on experiments too soon."),
]

CATEGORIES = {
    "classic": ["Ken Thompson", "Donald Knuth", "Brian Kernighan", "Linus Torvalds", "Grace Hopper"],
    "modern": ["DHH", "Sandi Metz", "Uncle Bob", "Jeff Atwood", "Rich Hickey"],
    "founders": ["Steve Jobs", "Mark Zuckerberg", "Jeff Bezos", "Elon Musk", "Larry Page"],
    "language-creators": ["Bjarne Stroustrup", "Guido van Rossum", "Yukihiro Matsumoto", "Larry Wall", "Anders Hejlsberg"],
}


# ─── Helpers ──────────────────────────────────────────────────────────
def box(text, width=56, pad=1, style="ascii"):
    """Wrap text in a nice box."""
    inner = width - 2 * pad - 2  # account for │
    lines = []
    for paragraph in text.split("\n"):
        words = paragraph.split()
        current = ""
        for word in words:
            if len(current) + len(word) + 1 > inner:
                lines.append(current.strip())
                current = word + " "
            else:
                current += word + " "
        if current.strip():
            lines.append(current.strip())

    # Pad all lines
    lines = [l.ljust(inner) for l in lines]

    top = "╭" + "─" * (width - 2) + "╮"
    mid = "│" + " " * (width - 2) + "│"
    bot = "╰" + "─" * (width - 2) + "╯"

    result = [top]
    for line in lines:
        result.append("│" + " " * pad + line + " " * pad + "│")
    result.append(bot)
    return "\n".join(result)


def quote_box(author, text, width=56):
    """Wrap a quote with attribution."""
    inner_width = width - 4  # space inside ││
    text_lines = []
    words = text.split()
    current = ""
    for word in words:
        if len(current) + len(word) + 1 > inner_width:
            text_lines.append(current.strip())
            current = word + " "
        else:
            current += word + " "
    if current.strip():
        text_lines.append(current.strip())
    text_lines = [l.ljust(inner_width) for l in text_lines]

    quote_box_str = "┌" + "─" * (width - 2) + "┐"
    for line in text_lines:
        quote_box_str += "\n│ " + line + " │"
    quote_box_str += "\n└" + "─" * (width - 2) + "┘"

    attribution = "—— " + author
    attribution = attribution.ljust(inner_width + 2)
    return quote_box_str + "\n" + attribution


def timestamp():
    return datetime.now().strftime("%H:%M")


def random_quote():
    return random.choice(QUOTES)


def get_quotes_by_category(cat):
    if cat not in CATEGORIES:
        return None
    authors = set(CATEGORIES[cat])
    return [q for q in QUOTES if q[0] in authors]


# ─── CLI ──────────────────────────────────────────────────────────────
def main():
    parser = argparse.ArgumentParser(description="DevQuote — Random developer wisdom for your terminal")
    parser.add_argument("--list", action="store_true", help="List all quotes")
    parser.add_argument("--count", type=int, default=1, help="Show N random quotes")
    parser.add_argument("--json", action="store_true", help="Output as JSON")
    parser.add_argument("--category", type=str, help="Filter by category: classic, modern, founders, language-creators")
    parser.add_argument("--author", type=str, help="Filter by author name (partial match)")
    args = parser.parse_args()

    if args.list:
        for author, text in sorted(QUOTES, key=lambda q: q[0]):
            print(f"  \033[36m{author}\033[0m")
            print(f"    {text}\n")
        print(f"\n  Total: {len(QUOTES)} quotes")
        return

    if args.category:
        quotes = get_quotes_by_category(args.category)
        if quotes is None:
            print(f"\033[31mUnknown category: {args.category}\033[0m")
            print(f"Available: {', '.join(CATEGORIES.keys())}")
            sys.exit(1)
    elif args.author:
        quotes = [q for q in QUOTES if args.author.lower() in q[0].lower()]
        if not quotes:
            print(f"\033[31mNo quotes found for author: {args.author}\033[0m")
            sys.exit(1)
    else:
        quotes = [random_quote()]

    selected = random.sample(quotes, min(args.count, len(quotes)))

    if args.json:
        print(json.dumps([{"author": a, "quote": t, "ts": timestamp()} for a, t in selected], indent=2))
        return

    for i, (author, text) in enumerate(selected):
        if i > 0:
            print()
        banner = "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
        banner += "\n┃  DevQuote — random wisdom for developers              ┃"
        banner += "\n┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
        print(banner)
        print()
        print(quote_box(author, text))
        print()


if __name__ == "__main__":
    main()
