#!/bin/bash

./ios.sh -x \
--disable-armv7 \
--disable-armv7s \
--disable-arm64e \
--disable-i386 \
--disable-x86-64 \
--disable-x86-64-mac-catalyst \
--disable-arm64-mac-catalyst \
--enable-lame \
--enable-libvorbis \
--enable-opus \
--enable-libogg \
--enable-opencore-amr \
--enable-libass
