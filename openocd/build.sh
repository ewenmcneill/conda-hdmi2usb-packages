#! /bin/bash

set -e
set -x

if [ x"$TRAVIS" = xtrue ]; then
	CPU_COUNT=2
fi

#export GIT_AUTHOR_NAME="Conda Build"
#export GIT_AUTHOR_EMAIL="robot@timvideos.us"
#export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
#export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"
#git commit -a -m "Changes for conda."

# We need fairly new pkg-config, from conda, to be able to complete bootstrap
# but we also need pkg-config to find the host OS package locations, so add
# those into the pkg-config search path too.
#
export PKG_CONFIG_PATH=/usr/lib/x86_64-linux-gnu/pkgconfig

# Conda's pkg-config is compiled with --enable-define-prefix, which
# guesses the wrong prefix from the system .pc files (/usr/lib/include/...)
# so we need a wrapper to inhibit that behaviour.
#
export PKG_CONFIG="${RECIPE_DIR}/pkg-config-no-prefix"

# NOTE: We rely on building with the host OS gcc, etc, *not* Conda gcc,
# in order that the host OS include paths, etc, are used (eg, for libusb).

git status

./bootstrap
mkdir build
cd build
../configure \
  --prefix=$PREFIX \
  --enable-static \
  --disable-shared \
  --enable-usb-blaster-2 \
  --enable-usb_blaster_libftdi \
  --enable-jtag_vpi \
  --enable-remote-bitbang \


make -j$CPU_COUNT

echo "---------------------------"
ldd ./src/openocd
ls -l ./src/openocd
du -h ./src/openocd
echo "---------------------------"
gcc -Wall -Wstrict-prototypes -Wformat-security -Wshadow -Wextra -Wno-unused-parameter -Wbad-function-cast -Wcast-align -Wredundant-decls -Werror -g -O2 -o src/openocd src/main.o -Wl,-Bstatic src/.libs/libopenocd.a ./jimtcl/libjim.a -lusb-1.0 -lusb -lftdi -Wl,-Bdynamic -Wl,--no-whole-archive -ludev -lpthread -ldl -lm
ldd ./src/openocd
ls -l ./src/openocd
du -h ./src/openocd
echo "---------------------------"
strip ./src/openocd
ls -l ./src/openocd
du -h ./src/openocd

make install
