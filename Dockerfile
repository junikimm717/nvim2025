FROM archlinux:latest

RUN pacman -S neovim ripgrep nodejs gcc make go git fzf npm zip unzip curl tar\
              jre17-openjdk-headless

COPY . /root/.config/nvim
RUN nvim --headless +Lazy! sync +qa

CMD ["tail", "-f", "/dev/null"]
