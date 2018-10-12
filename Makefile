# hlibc makefile
# Use GNU make. "gmake" on the BSDs and simply "make" on linux systems
# `cp' is used instead of `install' in order to provide portability across
# operating systems. Likewise, `cp -R' is used instead of `cp -a' or `cp -r'
# in order to cater to OpenBSD's unique `cp' command.

binaries = $(exec_prefix)/bin
prefix = /usr/local/hlibc
includes = $(prefix)/include
libraries = $(prefix)/lib

SRCS = $(sort $(wildcard src/*/*.c))
OBJS = $(SRCS:.c=.o)


CPPFLAGS =
FREESTANDING = -std=c99 -ffreestanding -nostdinc
CFLAGS_STATIC = $(FREESTANDING)
#CFLAGS_STATIC += -D_XOPEN_SOURCE=700 -I./include -I./machine/$(ARCH) -I./os/$(OPERATING_SYSTEM)/$(ARCH)
CFLAGS_STATIC += -D_XOPEN_SOURCE=700 -I./include 
CFLAGS_STATIC += $(CPPFLAGS) $(CFLAGS)

AR = ar
RANLIB = ranlib
ALL_INCLUDES = $(sort $(wildcard include/*.h include/*/*.h))

CRT_LIBS = lib/crt1.o lib/crti.o lib/crtn.o
TOOL_LIBS = lib/gcc-wrap.specs
EMPTY_LIBS = lib/libm.a
STATIC_LIBS = lib/libc.a

ALL_LIBS = $(CRT_LIBS) $(STATIC_LIBS) $(EMPTY_LIBS) $(TOOL_LIBS)
ALL_TOOLS = tools/compiler tools/compiler-handlink

-include config.mak

WRAP_OPT = -fno-stack-protector -static -D_GNU_SOURCE
start:

	-mkdir -p include/bits/
	-cp -R machine/$(ARCH)/bits/* include/bits/
	-cp -R os/$(OPERATING_SYSTEM)/$(ARCH)/bits/* include/bits/
	-cp -R os/$(OPERATING_SYSTEM)/$(ARCH)/operating_system.h include/bits/

all: start
#	most

#most: $(ALL_TOOLS) $(ALL_TOOLS:tools/%=/lib)

install: $(ALL_LIBS:lib/%=$(DESTDIR)$(libraries)/%) $(ALL_INCLUDES:include/%=$(DESTDIR)$(includes)/%) $(ALL_TOOLS:tools/%=$(DESTDIR)$(binaries)/%)

clean:
	-$(RM) -f machine/crt/*.o
	-$(RM) -f $(OBJS)
	-$(RM) -f $(ALL_LIBS) lib/*.[ao]
	-$(RM) -f $(ALL_TOOLS)
	-$(RM) -rf include/bits
	-$(RM) -f config.mak

cleanall:
	-rm -rf system-root

include/bits:
	@test "$(ARCH)" || echo "\n\tPlease run ./configure first\n"
	@test "$(ARCH)" || echo "\tOr use 'make test' to invoke the test suite\n"
	@test "$(ARCH)" || exit 1

%.o: $(ARCH)/%.s
	$(CC) $(CFLAGS_STATIC) -c -o $@ $<

%.o: %.c 
	$(CC) $(CFLAGS_STATIC) -c -o $@ $<

lib/libc.a: $(OBJS)
	$(RM) -f $@
	$(AR) rc $@ $(OBJS)
	$(RANLIB) $@

$(EMPTY_LIBS):
	$(RM) -f $@
	$(AR) rc $@

lib/%.o: machine/crt/%.o
	cp $< $@

tools/compiler: config.mak
	printf '#!/bin/sh\n' > $@
	printf 'printf "cc = "\n' >> $@
	printf 'set -x\n' >> $@
ifeq ($(CC_IS_CLANG),yes)
	printf 'clang $(WRAP_OPT) -nostdinc -isystem $(prefix)/include --sysroot $(prefix) "$$@" ' >> $@
else
	printf 'exec gcc $(DISABLE_PIE) $(WRAP_OPT) "$$@" -specs %s/gcc-wrap.specs\n' "$(libraries)" >> $@
endif
	chmod +x $@

tools/compiler-handlink: config.mak
	printf '#!/bin/sh\n' > $@
	printf 'printf "cc = "\n' >> $@
	printf 'set -x\n' >> $@
	printf -- '$(CC) $(DISABLE_PIE) $(WRAP_OPT) -nostdinc -nostdlib -I$(prefix)/include "$$@" $(prefix)/lib/crt1.o $(prefix)/lib/libc.a ' >> $@
	chmod +x $@

$(DESTDIR)$(binaries)/%: tools/%
	mkdir -p $(prefix)/bin
	cp -R $< $@

$(DESTDIR)$(libraries)/%: lib/%
	mkdir -p $(prefix)/lib
	cp -R $< $@

$(DESTDIR)$(includes)/%: include/%
	cp -R include $(prefix)

lib/gcc-wrap.specs: tools/gcc-wrap.specs.sh config.mak
	sh $< "$(includes)" "$(libraries)"  > $@

test:
	-$(MAKE) -C system-root/hlibc-test/ clean
	-$(RM) -rf system-root/bin system-root/lib system-root/include
	./tools/build.sh $(CC) $(PWD)/system-root/

release:
	./tools/.release

.PRECIOUS: $(CRT_LIBS:lib/%=machine/crt/%)

.PHONY: all clean install

