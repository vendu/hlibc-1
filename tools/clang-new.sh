#!/bin/sh
cc="clang"
libc="/home/cgraff1/musl-testing/usr"
libc_inc="/home/cgraff1/musl-testing/usr/include"
libc_lib="/home/cgraff1/musl-testing/usr/lib"
thisdir="`cd "$(dirname "$0")"; pwd`"

# prevent clang from running the linker (and erroring) on no input.
sflags=
eflags=
for x ; do
    case "$x" in
        -l*) input=1 ;;
        *) input= ;;
    esac
    if test "$input" ; then
        sflags="-l-user-start"
        eflags="-l-user-end"
        break
    fi
done

exec $cc \
    -B"$thisdir" \
    -fuse-ld=musl-clang \
    -static-libgcc \
    -nostdinc \
    --sysroot "$libc" \
    -isystem "$libc_inc" \
    -L-user-start \
    $sflags \
    "$@" \
    $eflags \
    -L"$libc_lib" \
    -L-user-end
