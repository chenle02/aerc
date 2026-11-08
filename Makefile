# Local build & install for aerc
# Usage:
#   make -f Makefile.local          # build
#   make -f Makefile.local install  # build + install to ~/.local
#   make -f Makefile.local clean    # remove build artifacts

PREFIX   = $(HOME)/.local
BINDIR   = $(PREFIX)/bin
SHAREDIR = $(PREFIX)/share/aerc
LIBEXECDIR = $(PREFIX)/libexec/aerc
FILTERDIR  = $(LIBEXECDIR)/filters

VERSION ?= $(shell git describe --long --abbrev=12 --tags --dirty 2>/dev/null || echo 0.22.0)
DATE    ?= $(shell date +%Y-%m-%d)
GO      ?= go
CC      ?= cc
CFLAGS  ?= -O2 -g

GO_LDFLAGS  = -X main.Version=$(VERSION)
GO_LDFLAGS += -X main.Date=$(DATE)
GO_LDFLAGS += -X git.sr.ht/~rjarry/aerc/config.shareDir=$(SHAREDIR)
GO_LDFLAGS += -X git.sr.ht/~rjarry/aerc/config.libexecDir=$(LIBEXECDIR)

GOFLAGS ?= $(shell contrib/goflags.sh)

cfilters_src = $(wildcard filters/*.c)
cfilters     = $(patsubst filters/%.c,%,$(cfilters_src))
filters      = $(filter-out filters/vectors filters/test.sh filters/%.c,$(wildcard filters/*))

.PHONY: all aerc $(cfilters)
all: aerc $(cfilters)

aerc:
	$(GO) build -trimpath $(GOFLAGS) -ldflags "$(GO_LDFLAGS)" -o $@

$(cfilters): %: filters/%.c
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $<

.PHONY: install
install: all
	@mkdir -p $(BINDIR) $(FILTERDIR)
	cp -f aerc $(BINDIR)/aerc
	@for f in $(cfilters); do \
		cp -f $$f $(FILTERDIR)/; \
	done
	@for f in $(filters); do \
		cp -af $$f $(FILTERDIR)/; \
	done
	@# Install this build's own default config, stylesets and templates into
	@# SHAREDIR (baked in via config.shareDir). Without them aerc falls back to
	@# /usr/share/aerc, which pacman upgrades independently -> template fields
	@# this build doesn't know (e.g. .Body in 0.22) break startup.
	@mkdir -p $(SHAREDIR)/stylesets $(SHAREDIR)/templates
	cp -f config/*.conf $(SHAREDIR)/
	cp -f stylesets/* $(SHAREDIR)/stylesets/
	cp -f templates/* $(SHAREDIR)/templates/
	@echo "Installed aerc to $(BINDIR)/aerc"
	@echo "Installed filters to $(FILTERDIR)/"
	@echo "Installed config/stylesets/templates to $(SHAREDIR)/"
	@$(BINDIR)/aerc -v

.PHONY: clean
clean:
	$(RM) aerc $(cfilters)

.PHONY: pull
pull:
	git pull

.PHONY: update
update: pull all install
	@echo "Updated aerc from source"
