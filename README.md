# Juni's 2025 Neovim Config

Now with a new plugin manager and theme switching! The config should also
self-bootstrap itself.

[Old Config](https://git.junickim.me/junikimm717/nvim2023)

# Docker

```bash
# full-featured debian container (x86 only)
docker run --rm -it junikimm717/nvim2025
# minimal alpine container with JavaScript support (x86 and arm)
docker run --rm -it junikimm717/nvim2025:alpine-js
```

# System Installation

## Requirements

- The latest version of neovim
- Nodejs (and also treesitter cli)
- GCC and Make
- Go
- Git
- Java (for ltex ls)
- RipGrep

## Additional tools that you may want to use

- Fzf
- Tmux and [tmuxs](https://github.com/junikimm717/tmuxs)
