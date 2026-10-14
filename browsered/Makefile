# Browsered inside sbcl-rasp: the finished editor (Browsered.html) and the
# small native helper that serves it and connects it to the rest of
# sbcl-rasp.  On macOS, make builds Browsered.app; elsewhere Browsered.html
# opens directly in Chrome or Edge.  To change the editor itself, work in
# https://github.com/FemtoEmacs/browsered (rebuilding it needs Emscripten).

UNAME := $(shell uname -s)
APP := Browsered.app
# Homebrew prefix, if any, for libcmark-gfm
BREW := $(shell brew --prefix 2>/dev/null)
LIBDIRS := $(if $(BREW),-I$(BREW)/include -L$(BREW)/lib)
RESOURCES := Browsered.html keys.js scheme.js editor.scm init.scm \
    femtoscheme/wasm/femtoscheme.js assistant-schema.json formatting.xml \
    browser-tests.html browser-tests.js

.PHONY: all check clean

ifeq ($(UNAME),Darwin)
all: $(APP)/Contents/MacOS/browsered
else
all:
	@echo "Browsered: open browsered/Browsered.html in Chrome or Edge (the helper is built on macOS and Windows)."
endif

$(APP)/Contents/MacOS/browsered: browsered.c assistant.c sources.c pdf.c $(RESOURCES)
	mkdir -p $(APP)/Contents/MacOS $(APP)/Contents/Resources
	cc -std=c11 -Wall -Wextra -Werror -O2 browsered.c assistant.c sources.c pdf.c \
	    -framework CoreFoundation -framework CoreGraphics -framework CoreText -framework PDFKit \
	    $(LIBDIRS) -lxml2 -lcmark-gfm -o $@
	cp $(RESOURCES) $(APP)/Contents/Resources/

check:
	@echo "Browsered: browser tests are in browser-tests.html (open it in Chrome)."

clean:
	rm -rf $(APP)
