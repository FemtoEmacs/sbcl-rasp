# C-owned editor with embedded femtoscheme; optional native GUI.
.DEFAULT_GOAL := all
CC ?= cc
CFLAGS ?= -O2 -Wall
CPPFLAGS += -Isrc -Ifemtoscheme -Ifemtoscheme/llt
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
CURSES_LIBS ?= -lncurses
PDF_LIBS = -framework CoreGraphics -framework ImageIO -framework CoreFoundation
else
CURSES_LIBS ?= -lncursesw
endif
SDL_CFLAGS := $(shell pkg-config --cflags sdl2 SDL2_ttf 2>/dev/null)
SDL_LIBS := $(filter-out -lSDL2main,$(shell pkg-config --libs sdl2 SDL2_ttf 2>/dev/null))
# All C sources live in src/. term.c and gui.c are the two screen backends;
# app.c is compiled twice (terminal and GUI).
# irene-dixe.c is a program of its own (the C-c p plot window).
CORE = $(filter-out src/term.c src/gui.c src/app.c src/irene-dixe.c,$(wildcard src/*.c))
OBJECTS = $(CORE:.c=.o)
WASMTIME_ROOT ?= runtime/wasmtime
CPPFLAGS += -I$(WASMTIME_ROOT)/include
WASMTIME_LIBS = -L$(WASMTIME_ROOT)/lib -lwasmtime -Wl,-rpath,'$$ORIGIN/runtime/wasmtime/lib'
ifeq ($(UNAME_S),Darwin)
WASMTIME_LIBS = -L$(WASMTIME_ROOT)/lib -lwasmtime -Wl,-rpath,@loader_path/runtime/wasmtime/lib
endif
OBJECTS += schemer/native-host.o
RUNTIME = femtoscheme/libfemtoscheme.a femtoscheme/llt/libllt.a
.PHONY: all runtime check check-compiled fetch-wasmtime clean
fetch-wasmtime:
	WASMTIME_ROOT="$(WASMTIME_ROOT)" sh tools/fetch-wasmtime.sh
$(WASMTIME_ROOT)/include/wasmtime.h:
	WASMTIME_ROOT="$(WASMTIME_ROOT)" sh tools/fetch-wasmtime.sh
src/compiled.o schemer/native-host.o: $(WASMTIME_ROOT)/include/wasmtime.h
all: schemer-compile schememax $(if $(SDL_LIBS),schememax-gui irene-dixe)
runtime:
	$(MAKE) -C femtoscheme release CC="$(CC)"
schememax: $(OBJECTS) src/term.o src/app.o runtime schemer-compile
	$(CC) $(LDFLAGS) $(OBJECTS) src/term.o src/app.o $(RUNTIME) $(CURSES_LIBS) $(PDF_LIBS) $(WASMTIME_LIBS) -lm -o $@
schememax-gui: $(OBJECTS) src/gui.o src/app-gui.o runtime schemer-compile
	$(CC) $(LDFLAGS) $(OBJECTS) src/gui.o src/app-gui.o $(RUNTIME) $(SDL_LIBS) $(PDF_LIBS) $(WASMTIME_LIBS) -lm -o $@
irene-dixe: src/irene-dixe.c
	$(CC) $(CFLAGS) $(SDL_CFLAGS) $< $(LDFLAGS) $(SDL_LIBS) -lm -o $@
src/gui.o: src/gui.c src/screen.h
	$(CC) $(CPPFLAGS) $(CFLAGS) $(SDL_CFLAGS) -c $< -o $@
src/app-gui.o: src/app.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -DSBEMACS_GUI -c $< -o $@
src/assistant.o src/pdf-pages.o: src/pdf-pages.h
$(CORE:.c=.o) src/term.o src/app.o src/app-gui.o: src/header.h src/public.h
schemer/native-host.o: schemer/native-host.c schemer/native-host.h
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@
src/compiled.o: schemer/native-host.h
%.o: %.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@
tests/native-host-test: tests/native-host-test.c schemer/native-host.o
	$(CC) $(CPPFLAGS) $(CFLAGS) $< schemer/native-host.o $(WASMTIME_LIBS) -Wl,-rpath,$(abspath $(WASMTIME_ROOT))/lib -lm -o $@
check-compiled: schememax tests/native-host-test
	sh tests/run-compiled.sh
check: schememax check-compiled
	$(MAKE) -C femtoscheme test
	./schememax --eval '(+ 20 22)' | grep -x 42
	./schememax --eval '(get-version-string)' | grep femtoscheme
	SCHEMEMAX_NO_INIT=1 ./schememax --eval '(load "tests/run-tests.scm")'
	! ./schememax --eval '(error "expected test error")'
clean:
	rm -f src/*.o schemer/*.o tests/native-host-test tests/fileprompt-test tests/filename-completion-test schememax schememax-gui irene-dixe tests/search-test
	$(MAKE) -C femtoscheme clean

.PHONY: app
app: schememax-gui irene-dixe
	rm -rf Schememax.app/Contents/MacOS/scheme
	mkdir -p Schememax.app/Contents/MacOS/femtoscheme Schememax.app/Contents/MacOS/ttfy \
	    Schememax.app/Contents/MacOS/scheme/languages Schememax.app/Contents/MacOS/scheme/extensions \
	    Schememax.app/Contents/MacOS/scheme/modes
	cp packaging/Info.plist Schememax.app/Contents/Info.plist
	cp schememax-gui Schememax.app/Contents/MacOS/schememax-gui.new
	mv -f Schememax.app/Contents/MacOS/schememax-gui.new Schememax.app/Contents/MacOS/schememax-gui
	cp irene-dixe Schememax.app/Contents/MacOS/irene-dixe.new
	mv -f Schememax.app/Contents/MacOS/irene-dixe.new Schememax.app/Contents/MacOS/irene-dixe
	cp scheme/*.scm Schememax.app/Contents/MacOS/scheme/
	cp scheme/languages/*.scm Schememax.app/Contents/MacOS/scheme/languages/
	cp scheme/extensions/*.scm Schememax.app/Contents/MacOS/scheme/extensions/
	cp scheme/modes/*.scm Schememax.app/Contents/MacOS/scheme/modes/
	cp ttfy/plots-guidelines.md Schememax.app/Contents/MacOS/ttfy/
	cp femtoscheme/femtoscheme.boot Schememax.app/Contents/MacOS/femtoscheme/
	rm -f Schememax.app/Contents/MacOS/femtoscheme/femtoscheme \
	    Schememax.app/Contents/MacOS/schemer/native-compile.scm \
	    Schememax.app/Contents/MacOS/schemer/page.scm
	cp schemer-compile Schememax.app/Contents/MacOS/schemer-compile
	mkdir -p Schememax.app/Contents/MacOS/runtime/wasmtime/lib Schememax.app/Contents/MacOS/schemer
	cp $(WASMTIME_ROOT)/lib/libwasmtime.dylib Schememax.app/Contents/MacOS/runtime/wasmtime/lib/
	cp schemer/*.scm schemer/compiler.wasm Schememax.app/Contents/MacOS/schemer/
	cp $(WASMTIME_ROOT)/LICENSE Schememax.app/Contents/MacOS/runtime/wasmtime/

.PHONY: check-ui
check-ui: schememax
	$(CC) $(CPPFLAGS) $(CFLAGS) tests/filename-completion.c src/complete.c src/fileprompt.c -o tests/filename-completion-test
	./tests/filename-completion-test
	$(CC) $(CFLAGS) tests/fileprompt.c src/fileprompt.c -o tests/fileprompt-test
	./tests/fileprompt-test
	$(CC) $(CFLAGS) tests/search.c src/search.c -o tests/search-test
	./tests/search-test
	sh tests/provider-protocol.sh
	sh tests/ttfy-protocol.sh

# The compiler is compiled Scheme hosted by Wasmtime, independent of femtoscheme.
schemer-compile: schemer/compiler-driver.c schemer/native-host.o schemer/native-host.h
	$(CC) $(CPPFLAGS) $(CFLAGS) schemer/compiler-driver.c schemer/native-host.o $(WASMTIME_LIBS) -lm -o $@
.PHONY: rebuild-compiler check-selfhost
rebuild-compiler: schemer-compile
	sh schemer/build-compiler.sh
check-selfhost: schemer-compile tests/native-host-test
	sh tests/selfhost-compiler.sh
