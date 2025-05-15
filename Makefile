INSTALLED = ./build/installed

# The only reason for this Makefile to exist is to parallelize the entire
# bootstrapping process.


.PHONY: all docker

all: $(INSTALLED) $(INSTALLED)/node \
	$(INSTALLED)/python $(INSTALLED)/go $(INSTALLED)/neovim \
	$(INSTALLED)/tmuxs $(INSTALLED)/ripgrep

docker: $(INSTALLED) $(INSTALLED)/node \
	$(INSTALLED)/python $(INSTALLED)/go $(INSTALLED)/neovim \
	$(INSTALLED)/ripgrep

$(INSTALLED):
	mkdir -p $@

$(INSTALLED)/stow:
	./_bootstrap.sh install_stow
	touch $@

$(INSTALLED)/node: $(INSTALLED)/stow
	./_bootstrap.sh install_node
	touch $@

$(INSTALLED)/go: $(INSTALLED)/stow
	./_bootstrap.sh install_go
	touch $@

$(INSTALLED)/tmuxs: $(INSTALLED)/go
	./_bootstrap.sh install_tmuxs
	touch $@

$(INSTALLED)/ripgrep: $(INSTALLED)/stow
	./_bootstrap.sh install_ripgrep
	touch $@

$(INSTALLED)/python: $(INSTALLED)/stow
	./_bootstrap.sh install_python
	touch $@

$(INSTALLED)/neovim: $(INSTALLED)/stow
	./_bootstrap.sh install_neovim
	touch $@
