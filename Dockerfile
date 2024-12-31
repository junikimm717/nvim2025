FROM fedora:latest

RUN dnf install -y neovim ripgrep nodejs gcc make go git fzf npm zip unzip\
  curl tar java-latest-openjdk-headless

COPY . /root/.config/nvim

WORKDIR /workspace
RUN echo 'return require("themes.container")' > /root/.config/nvim/lua/themes/init.lua
RUN nvim --headless +Lazy! sync +FullSetup +qa

CMD ["/bin/bash"]
