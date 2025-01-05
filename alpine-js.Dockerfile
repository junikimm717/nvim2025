FROM alpine:latest

RUN apk add ripgrep nodejs gcc make git fzf npm yarn zip unzip curl tar\
            tree-sitter-cli musl-dev neovim

COPY . /root/.config/nvim

WORKDIR /workspace
RUN echo 'return require("configs.alpine-js")' > /root/.config/nvim/lua/configs/init.lua
RUN nvim --headless +Lazy! sync +FullSetup +qa

CMD ["/bin/ash"]
