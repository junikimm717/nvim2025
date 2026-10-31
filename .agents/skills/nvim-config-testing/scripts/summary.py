#!/usr/bin/env python3
"""Print only the steps of fuzz runs that produced errors, warnings or messages.

    python3 summary.py WORK/runs/*/out.jsonl          # known noise hidden
    python3 summary.py --all WORK/runs/*/out.jsonl    # everything

Known noise is listed in SKILL.md; each pattern here must stay explained there.
"""
import json
import os
import re
import sys

NOISE = [
    # barbar removes watchers under `silent!`; only lands in v:errmsg.
    r"E116: Invalid arguments for function dictwatcherdel",
    # LuaSnip/gitsigns call vim-repeat under `silent!`; vim-repeat isn't installed.
    r"E117: Unknown function: repeat#set",
    r"E490: No fold found",
    # lua_ls skipping the 1.5MB huge.lua sample is expected.
    r"Too large file: huge\.lua skipped",
    # The harness types "foo", which makes css/go/json/lua invalid, and black
    # gives up on deep.py's 500 levels of nesting: formatters rightly refuse.
    r"Formatter failed\. See :ConformInfo",
    r"W10: Warning: Changing a readonly file",
    # Harness keystrokes: <C-c> in normal mode, `n` after a close that didn't prompt.
    r"Type\s+:qa\s+and press <Enter> to exit Nvim",
    r"E35: No previous regular expression",
]


def is_noise(text):
    return any(re.search(p, text) for p in NOISE)


def main(argv):
    show_all = "--all" in argv
    paths = [a for a in argv if a != "--all"]
    total = 0
    for path in paths:
        name = os.path.basename(os.path.dirname(os.path.abspath(path)))
        print(f"===== {name}")
        shown = 0
        for line in open(path):
            e = json.loads(line)
            bad = {}
            for k in ("errmsg", "messages", "notify"):
                if k not in e:
                    continue
                v = " | ".join(e[k]) if isinstance(e[k], list) else e[k]
                if show_all or not is_noise(v):
                    bad[k] = v
            if bad:
                shown += 1
                print(f"- {e['label']} [ft={e['ft']} mode={e['mode']} lsp={e['clients']}]")
                for k, v in bad.items():
                    print(f"    {k}: {v[:400]}")
        print(f"  ({shown} steps with {'output' if show_all else 'unexplained output'})")
        total += shown
    return 1 if total and not show_all else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
