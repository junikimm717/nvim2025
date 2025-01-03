FROM alpine:latest

RUN apk add ripgrep nodejs gcc make go git fzf npm zip unzip curl wget tar\
            openjdk23-jre-headless tree-sitter-cli py3-pip musl-dev neovim\
            libstdc++-dev

COPY . /root/.config/nvim

WORKDIR /workspace
RUN echo 'return require("themes.container")' > /root/.config/nvim/lua/themes/init.lua
RUN nvim --headless +Lazy! sync +FullSetup +qa

CMD ["/bin/ash"]
