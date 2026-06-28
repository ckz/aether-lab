#!/usr/bin/env python3
"""
quickclip.py — tiny text utility toolbox

Usage examples:
  python3 quickclip.py slug "Hello Ken, Ship It!"
  python3 quickclip.py hash "important text"
  python3 quickclip.py b64 "encode me"
  python3 quickclip.py unb64 "ZW5jb2RlIG1l"
  python3 quickclip.py jsonmin '{"a": 1, "b": [1,2,3]}'
  python3 quickclip.py jsonpretty '{"a":1,"b":[1,2,3]}'
"""

import argparse
import base64
import hashlib
import json
import re
import sys
import unicodedata


def slugify(text: str) -> str:
    text = unicodedata.normalize("NFKD", text)
    text = text.encode("ascii", "ignore").decode("ascii")
    text = text.lower()
    text = re.sub(r"[^a-z0-9]+", "-", text).strip("-")
    return text or "n-a"


def main() -> int:
    parser = argparse.ArgumentParser(description="Quick text utilities")
    parser.add_argument("mode", choices=["slug", "hash", "b64", "unb64", "jsonmin", "jsonpretty"])
    parser.add_argument("text", nargs="?", help="Input text; if omitted, reads from stdin")
    args = parser.parse_args()

    data = args.text if args.text is not None else sys.stdin.read()

    try:
        if args.mode == "slug":
            print(slugify(data))
        elif args.mode == "hash":
            print(hashlib.sha256(data.encode()).hexdigest())
        elif args.mode == "b64":
            print(base64.b64encode(data.encode()).decode())
        elif args.mode == "unb64":
            print(base64.b64decode(data.encode()).decode())
        elif args.mode == "jsonmin":
            obj = json.loads(data)
            print(json.dumps(obj, separators=(",", ":"), ensure_ascii=False))
        elif args.mode == "jsonpretty":
            obj = json.loads(data)
            print(json.dumps(obj, indent=2, ensure_ascii=False))
        return 0
    except Exception as e:
        print(f"error: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
