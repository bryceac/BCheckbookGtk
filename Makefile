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
	$(shell ./run-gir2swift.sh)
	swift build $(SWIFT_FLAGS)
install: build
ifneq (, $(findstring darwin, $(SYS)))
	test ! -d $(bindir) && mkdir -p $(bindir)

	install ".build/release/actual" "$(bindir)/actual"

	rsync -zavrh --progress ".build/release/actual_actual.resources" "$(bindir)"
else
	install -D ".build/release/actual" "$(bindir)/actual"

	rsync -zavrh --progress ".build/release/actual_actual.resources" "$(bindir)"
endif
uninstall:
	rm -rf "$(bindir)/actual"

	rm -rf "$(bindir)/actual_actual.resources"
clean:
	rm -rf .build
.PHONY: build install uninstall clean