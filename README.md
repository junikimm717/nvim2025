# Juni's 2025 Neovim Config

Now with a new plugin manager and theme switching!

[Old Config](https://git.junickim.me/junikimm717/nvim2023)

## Configuration

Device-specific configuration should be done on ./lua/configs/init.lua.

```lua
return {
  lazy = {
    require("themes.everforest"),
  },
  treesitter = {
    -- list of all treesitter parsers you will use. autoinstall is not supported.
  },
  mason = {
    -- list of all mason packages you will use.
  }
}
```

## Docker

The CI builds these images:

```bash
# full-featured debian container (x86_64)
docker run --rm -it junikimm717/nvim2025
# the same, for arm64
docker run --rm -it junikimm717/nvim2025:arm
# minimal alpine container with C support (x86_64 and arm64)
docker run --rm -it junikimm717/nvim2025:alpine-c
```

## Bootstrapping

You can bootstrap through the Makefile if you're in a server environment
without admin privileges (and the server uses x86_64 or aarch64). It drives
`_bootstrap.sh`, which only requires a few basic utilities and alerts you if
any of them are missing.

```sh
# run the bootstrapping script via the Makefile
make -j$(nproc)
# install plugins, Mason packages and treesitter parsers (once)
./build/bin/setup-nvim
# You should consider adding this to your $PATH
./build/bin/nvim
```

## System Installation

### Requirements

- Git
- GCC and Make
- A very recent version neovim (at least 0.12)
- Nodejs (and also treesitter cli)
- Go
- RipGrep

### Additional tools that you may want to use

- Fzf
- Tmux and [tmuxs](https://github.com/junikimm717/tmuxs)
