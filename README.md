# Juni's 2025 Neovim Config

Now with a new plugin manager and theme switching!

[Old Config](https://git.junickim.me/junikimm717/nvim2023)

## Docker

The CI builds images for both x86_64 and arm64

```bash
# full-featured debian container
docker run --rm -it junikimm717/nvim2025
# debian container with experimental bootstrapping
docker run --rm -it junikimm717/nvim2025:bootstrap
# minimal alpine container with JavaScript support
docker run --rm -it junikimm717/nvim2025:alpine-js
# container for my UROP work at CSAIL (x86 only)
docker run --rm -it junikimm717/nvim2025:finch
```

## Bootstrapping

You can use the provided `bootstrap.sh` if you're in a server environment
without admin privileges (and the server uses x86_64 or aarch64). The script
only requires a few basic utilities to work properly, and it should alert you if
any of them are missing.

```sh
# run the bootstrapping script
./bootstrap.sh
# You should consider adding this to your $PATH
./build/bin/nvim
```

## System Installation

### Requirements

- Git
- GCC and Make
- A very recent version neovim (at least 0.10)
- Nodejs (and also treesitter cli)
- Go
- Java (for ltex ls)
- RipGrep

### Additional tools that you may want to use

- Fzf
- Tmux and [tmuxs](https://github.com/junikimm717/tmuxs)
