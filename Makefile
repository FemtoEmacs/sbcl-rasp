# sbcl-rasp: the RASP parser for English (release 3.3a), ported to SBCL and
# repaired.  Building needs only SBCL, a C compiler and make; flex comes with
# the sources (third_party/) and is built once.
#
#   make          build everything into bin/<arch>/
#   make check    run the tests (tests/check.lisp)
#   make clean    remove what make built

ARCH := $(shell uname -m | sed "s/i.86/ix86/")_$(shell uname -s | tr "[:upper:]" "[:lower:]")
B := bin/$(ARCH)

SBCL ?= sbcl
SBCL_HEAP ?= 4096
FLEXVER := 2.6.4

.PHONY: all check clean

all: $(B)/sentence $(B)/token $(B)/label $(B)/morpha \
     tag/auxiliary_files/seclarge-c2s.lex $(B)/gde-sbcl

$(B):
	mkdir -p $@

# flex, built from the bundled sources, so that every scanner is generated
# from its .flex file by the same version on every machine.
$(B)/flex: third_party/flex-$(FLEXVER).tar.gz | $(B)
	rm -rf $(B)/flex-$(FLEXVER)
	cd $(B) && tar xzf ../../third_party/flex-$(FLEXVER).tar.gz
	cd $(B)/flex-$(FLEXVER) && ./configure --quiet --disable-shared --disable-nls \
	    CFLAGS="-O2 -D_GNU_SOURCE" && $(MAKE) -C src flex
	cp $(B)/flex-$(FLEXVER)/src/flex $@

# The four C programs of the pipeline.
$(B)/sentence: sentence/sentence.flex enc/charclasses.flex $(B)/flex
	$(MAKE) -C $(B) -f ../../sentence/Makefile sentence

$(B)/token: tokenise/token.flex enc/charclasses.flex $(B)/flex
	$(MAKE) -C $(B) -f ../../tokenise/Makefile token

# morpha.lex is large: flex takes a minute or two to generate its scanner.
$(B)/morpha: morph/morpha.lex enc/charclasses.flex $(B)/flex
	$(MAKE) -C $(B) -f ../../morph/Makefile morpha

$(B)/label: $(wildcard tag/src/*.c tag/src/*.h) tag/Makefile | $(B)
	$(MAKE) -C $(B) -f ../../tag/Makefile label

# The tagger's dictionary: the original word list plus our additions.
tag/auxiliary_files/seclarge-c2s.lex: tag/auxiliary_files/seclarge.lex \
    tag/auxiliary_files/c2s-additions.lex tag/auxiliary_files/make-c2s-lex.sh
	sh tag/auxiliary_files/make-c2s-lex.sh

# The parser: an SBCL executable with the grammar loaded.
$(B)/gde-sbcl: gde/build-sbcl.lisp $(wildcard gde/cgde/*.lsp gde/cpar/*.lsp prob/code/*.lsp) \
    $(wildcard prob/data/tsg15*) | $(B)
	$(SBCL) --dynamic-space-size $(SBCL_HEAP) --non-interactive --load gde/build-sbcl.lisp

check: all
	$(SBCL) --script tests/check.lisp

clean:
	rm -rf $(B) tag/auxiliary_files/seclarge-c2s.lex
