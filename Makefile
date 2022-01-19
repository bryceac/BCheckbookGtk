prefix ?= /usr/local
bindir = $(prefix)/bin
icondir ?= /usr/share/icons
launcherdir ?= /usr/share/applications
SYS := $(shell $(CC) -dumpmachine)
SWIFT_FLAGS =

ifneq (, $(findstring linux, $(SYS)))
SWIFT_FLAGS = -c release -Xswiftc -static-stdlib
else
SWIFT_FLAGS = -c release --disable-sandbox
endif

build:
	./run-gir2swift.sh
	swift build $(SWIFT_FLAGS)
install:
ifneq (, $(findstring darwin, $(SYS)))
	test ! -d $(bindir) && mkdir -p $(bindir)

	install ".build/release/bcheckbook" "$(bindir)/bcheckbook"

	rsync -zavrh --progress ".build/release/bcheckbook_bcheckbook.resources" "$(bindir)"
else
	install -D ".build/release/bcheckbook" "$(bindir)/bcheckbook"

	install -D "BCheckbook.desktop" "${launcherdir}"

	install -D "bcheckbook_icon.png" "${icondir}"

	rsync -zavrh --progress ".build/release/bcheckbook_bcheckbook.resources" "$(bindir)"
endif
uninstall:
	rm -rf "$(bindir)/bcheckbook"

	rm -rf "$(bindir)/bcheckbook_bcheckbook.resources"

	rm -f "${launcherdir}/BCheckbook.desktop"
	rm -f "${icondir}/bcheckbook_icon.png"
clean:
	rm -rf .build
.PHONY: build install uninstall clean
