PREFIX ?= /usr
SYSCONFDIR ?= /etc
DESTDIR ?=

BINDIR ?= $(PREFIX)/bin
LIBDIR ?= $(PREFIX)/lib
DATADIR ?= $(PREFIX)/share/elpkg

.DEFAULT_GOAL := help

.PHONY: all install uninstall help

all:
	@true

help:
	@echo "Elpkg Makefile"
	@echo ""
	@echo "Usage:"
	@echo "  make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  all        Do nothing"
	@echo "  install    Install Elpkg"
	@echo "  uninstall  Remove installed Elpkg files"
	@echo "  help       Show this help message"
	@echo ""
	@echo "Installation variables:"
	@echo "  PREFIX     Installation prefix (default: $(PREFIX))"
	@echo "  BINDIR     Binary directory (default: $(BINDIR))"
	@echo "  LIBDIR     Library directory (default: $(LIBDIR))"
	@echo "  SYSCONFDIR Configuration directory (default: $(SYSCONFDIR))"
	@echo "  DATADIR    Data directory (default: $(DATADIR))"
	@echo "  DESTDIR    Staging directory (default: $(DESTDIR))"
	@echo ""
	@echo "Example: make install PREFIX=/usr SYSCONFDIR=/etc DESTDIR=/tmp/pkg"

install:
	install -d $(DESTDIR)$(BINDIR)
	install -d $(DESTDIR)$(LIBDIR)/Elpkg
	install -d $(DESTDIR)$(SYSCONFDIR)/elpkg
	install -d $(DESTDIR)$(DATADIR)/patches
	install -d $(DESTDIR)$(DATADIR)
	install -m 0755 bin/elpkg $(DESTDIR)$(BINDIR)/elpkg
	install -m 0644 lib/Elpkg/*.pm $(DESTDIR)$(LIBDIR)/Elpkg/
	install -m 0644 etc/elpkg.conf $(DESTDIR)$(SYSCONFDIR)/elpkg/elpkg.conf
	install -m 0644 patches/*.patch $(DESTDIR)$(DATADIR)/patches/
	@if [ -f trusted.pem ]; then \
		install -m 0644 trusted.pem $(DESTDIR)$(DATADIR)/trusted.pem; \
		if [ ! -f $(DESTDIR)$(SYSCONFDIR)/elpkg/trusted.pem ]; then \
			install -m 0644 trusted.pem $(DESTDIR)$(SYSCONFDIR)/elpkg/trusted.pem; \
		fi; \
	fi

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/elpkg
	rm -f $(DESTDIR)$(LIBDIR)/Elpkg/*.pm
	rm -f $(DESTDIR)$(SYSCONFDIR)/elpkg/elpkg.conf
	rm -f $(DESTDIR)$(DATADIR)/trusted.pem
	rm -f $(DESTDIR)$(DATADIR)/patches/*.patch
	@rmdir $(DESTDIR)$(LIBDIR)/Elpkg 2>/dev/null || true
	@rmdir $(DESTDIR)$(DATADIR)/patches 2>/dev/null || true
	@rmdir $(DESTDIR)$(DATADIR) 2>/dev/null || true
	@rmdir $(DESTDIR)$(SYSCONFDIR)/elpkg 2>/dev/null || true
