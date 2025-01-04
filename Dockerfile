FROM debian:sid AS builder

WORKDIR /workspace
RUN apt-get update
RUN apt-get install -y ninja-build gettext cmake unzip curl build-essential file
RUN curl -LJ https://github.com/neovim/neovim/archive/refs/tags/nightly.tar.gz\
  -o neovim.tar.gz\
  && tar -xzvf neovim.tar.gz\
  && mv neovim-nightly neovim

WORKDIR /workspace/neovim
RUN make CMAKE_BUILD_TYPE=RelWithDebInfo
RUN cd build && cpack -G DEB && mv *.deb neovim.deb

FROM debian:sid

COPY --from=builder /workspace/neovim/build/neovim.deb /root/packages/neovim.deb
RUN apt-get update
RUN apt-get install -y ripgrep nodejs gcc make golang git fzf npm zip unzip\
  curl wget tar openjdk-24-jre-headless tree-sitter-cli python3-venv\
  /root/packages/neovim.deb

COPY . /root/.config/nvim

WORKDIR /workspace
RUN echo 'return require("configs.container")' > /root/.config/nvim/lua/configs/init.lua
RUN nvim --headless +Lazy! sync +FullSetup +qa

CMD ["/bin/bash"]
