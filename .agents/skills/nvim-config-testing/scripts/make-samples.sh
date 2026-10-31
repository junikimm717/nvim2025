#!/usr/bin/env bash
# Write the fuzz sample files into DIR: one small file per filetype the config
# cares about, plus edge cases. DIR is made a git repo because several servers
# (tailwindcss, lazydev) only attach inside one.
set -euo pipefail
D="${1:?usage: make-samples.sh DIR}"
rm -rf "$D"
mkdir -p "$D"
cd "$D"
git init -q

printf 'local M = {}\nfunction M.f(a)\n  return a\nend\nreturn M\n' > a.lua
printf 'import os\n\ndef f(x):\n    return x\n' > a.py
printf 'export function f(x: number): number {\n  return x\n}\n' > a.ts
printf 'export const C = () => <div className="p-2">hi</div>\n' > a.tsx
printf 'const x = 1\nconsole.log(x)\n' > a.js
printf '{"a": [1, 2, {"b": null}]}\n' > a.json
printf '<!doctype html>\n<html><body><div class="p-2">x</div></body></html>\n' > a.html
printf 'body { color: red; }\n' > a.css
printf '# Title\n\n- item\n\n```lua\nprint(1)\n```\n' > a.md
printf '# Title\n\nimport X from "./x"\n\n<X a={1} />\n' > a.mdx
printf '\\documentclass{article}\n\\begin{document}\nHi $x^2$\n\\end{document}\n' > a.tex
printf '#include <stdio.h>\nint main(void) {\n  printf("hi");\n}\n' > a.c
printf '#include <vector>\nint main() { std::vector<int> v; }\n' > a.cpp
printf 'package main\n\nfunc main() {\n}\n' > a.go
printf 'fn main() {\n    println!("hi");\n}\n' > a.rs
printf '#!/bin/sh\necho $1\n' > a.sh
printf 'all:\n\techo hi\n' > Makefile
printf 'a:\n  - 1\n  - b: 2\n' > a.yaml
printf '[a]\nb = 1\n' > a.toml
printf '{ pkgs }: pkgs.hello\n' > a.nix
printf 'module m(input logic a);\nendmodule\n' > a.sv
printf 'module m(a);\ninput a;\nendmodule\n' > a.v
printf 'FROM alpine\nRUN echo hi\n' > Dockerfile
printf 'use strict;\nprint "hi";\n' > a.pl
printf '.TH X 1\n.SH NAME\n' > a.ms
printf 'const x = 1;\n' > a.zig
printf 'resource "x" "y" {}\n' > a.tf
printf 'fix: thing\n' > COMMIT_EDITMSG

# edge cases
: > empty.txt
printf 'no extension here\n' > noext
seq 1 100000 | sed 's/^/local x = /' > huge.lua
head -c 20000 /dev/urandom > binary.bin
mkdir -p "dir with spaces" "ünïcødé"
printf 'x = 1\n' > "dir with spaces/a b.py"
printf 'local y = 2\n' > "ünïcødé/ü.lua"
printf 'local ro = 1\n' > readonly.lua
chmod 444 readonly.lua
printf 'line\r\nline2\r\n' > crlf.txt
python3 -c "print('x = ' + '('*500 + ')'*500)" > deep.py
