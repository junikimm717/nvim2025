INSTALLED = ./build/installed

# The only reason for this Makefile to exist is to parallelize the entire
# bootstrapping process. Each rule touches a marker in $(INSTALLED), so it is an
# order-only prerequisite: with -j a touch must not run before the mkdir.


.PHONY: all docker

all: $(INSTALLED) $(INSTALLED)/zig $(INSTALLED)/node \
	$(INSTALLED)/python $(INSTALLED)/go $(INSTALLED)/neovim \
	$(INSTALLED)/tmuxs $(INSTALLED)/ripgrep

docker: $(INSTALLED) $(INSTALLED)/zig $(INSTALLED)/node \
	$(INSTALLED)/python $(INSTALLED)/go $(INSTALLED)/neovim \
	$(INSTALLED)/ripgrep

$(INSTALLED):
	mkdir -p $@

$(INSTALLED)/stow: | $(INSTALLED)
	./_bootstrap.sh install_stow
	touch $@

$(INSTALLED)/node: $(INSTALLED)/stow | $(INSTALLED)
	./_bootstrap.sh install_node
	touch $@

$(INSTALLED)/zig: | $(INSTALLED)
	./_bootstrap.sh install_zig
	touch $@

$(INSTALLED)/go: $(INSTALLED)/stow | $(INSTALLED)
	./_bootstrap.sh install_go
	touch $@

$(INSTALLED)/tmuxs: $(INSTALLED)/go | $(INSTALLED)
	./_bootstrap.sh install_tmuxs
	touch $@

$(INSTALLED)/ripgrep: $(INSTALLED)/stow | $(INSTALLED)
	./_bootstrap.sh install_ripgrep
	touch $@

$(INSTALLED)/python: $(INSTALLED)/stow | $(INSTALLED)
	./_bootstrap.sh install_python
	touch $@

$(INSTALLED)/neovim: $(INSTALLED)/stow | $(INSTALLED)
	./_bootstrap.sh install_neovim
	touch $@
