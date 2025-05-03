FROM debian:bookworm

WORKDIR /nvim

# run bootstrapping code FIRST.
RUN apt-get update && apt-get install -y git tar wget make gcc perl unzip\
    build-essential libssl-dev zlib1g-dev libffi-dev libbz2-dev libreadline-dev\
    libsqlite3-dev uuid-dev
COPY ./bootstrap.sh ./bootstrap.sh
COPY ./pkgs ./pkgs
RUN ./bootstrap.sh

ENV PATH="/nvim/build/bin:${PATH}"

COPY . .

RUN echo 'return require("configs.debian")' > lua/configs/init.lua
RUN /nvim/build/bin/nvim --headless +Lazy! sync +FullSetup +qa
COPY ./container/.profile /root/.bashrc

WORKDIR /workspace
CMD ["/bin/bash"]
