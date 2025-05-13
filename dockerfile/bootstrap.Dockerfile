FROM debian:bookworm-slim

RUN apt-get update
RUN apt-get install -y git tar wget make perl unzip
WORKDIR /nvim

COPY _bootstrap.sh .
COPY Makefile .
COPY pkgs ./pkgs
RUN make -j$(nproc)

COPY . .

RUN echo 'return require("configs.kanagawa")' > ./lua/configs/init.lua
ENV PATH="/nvim/build/bin:${PATH}"
RUN nvim --headless +Lazy! sync +FullSetup +qa
COPY ./container/.profile /root/.bashrc

WORKDIR /workspace

CMD ["/bin/ash"]
