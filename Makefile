prefix ?= /usr/local
bindir = $(prefix)/bin
SYS := $(shell $(CC) -dumpmachine)
SWIFT_FLAGS =

ifneq (, $(findstring linux, $(SYS)))
SWIFT_FLAGS = -c release
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

	install -D "BCheckbook.desktop" "/usr/share/applications"

	install -D "bcheckbook_icon.png" "/usr/share/icons"

	rsync -zavrh --progress ".build/release/bcheckbook_bcheckbook.resources" "$(bindir)"
endif
uninstall:
	rm -rf "$(bindir)/bcheckbook"

	rm -rf "$(bindir)/bcheckbook_bcheckbook.resources"

	rm -f "/usr/share/applications/BCheckbook.desktop"
	rm -f "/usr/share/icons/bcheckbook_icon.png"
clean:
	rm -rf .build
.PHONY: build install uninstall clean