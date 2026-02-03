PREFIX ?= /usr
SYSCONFDIR ?= /etc
DESTDIR ?=

BINDIR ?= $(PREFIX)/bin
LIBDIR ?= $(PREFIX)/lib
DATADIR ?= $(PREFIX)/share/elpkg

.PHONY: all install

all:
	@true

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
