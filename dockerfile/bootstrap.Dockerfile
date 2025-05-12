FROM debian:bookworm-slim

RUN apt-get update
RUN apt-get install -y build-essential git tar wget make gcc perl unzip
WORKDIR /nvim

COPY bootstrap.sh .
COPY pkgs ./pkgs
RUN ./bootstrap.sh

COPY . .

RUN echo 'return require("configs.kanagawa")' > ./lua/configs/init.lua
ENV PATH="/nvim/build/bin:${PATH}"
RUN nvim --headless +Lazy! sync +FullSetup +qa
COPY ./container/.profile /root/.bashrc

WORKDIR /workspace

CMD ["/bin/ash"]
