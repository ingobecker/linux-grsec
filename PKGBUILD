# Original kernel maintainers:
#   Tobias Powalowski <tpowa@archlinux.org>
#   Thomas Baechler <thomas@archlinux.org>
# Contributors:
#   henning mueller <henning@orgizm.net>

pkgname=linux-grsec
_kernelname=${pkgname#linux}
_basekernel=3.3
_grsecver=2.9
_timestamp=201204131715
pkgver=${_basekernel}.2
pkgrel=2
arch=(i686 x86_64)
url="http://www.kernel.org/"
license=(GPL2)
options=(!strip)

_menuconfig=0
[ ! -z $MENUCONFIG ] && _menuconfig=1

# ftp://ftp.kernel.org/pub/linux/kernel/v3.0/linux-$pkgver.tar.bz2
source=(
  ftp://ftp.halifax.rwth-aachen.de/pub/linux/kernel/v3.x/linux-$pkgver.tar.xz
  http://grsecurity.net/test/grsecurity-$_grsecver-$pkgver-$_timestamp.patch
  change-default-console-loglevel.patch
  i915-fix-ghost-tv-output.patch
  fix-acerhdf-1810T-bios.patch
  ext4-options.patch
  config.i686
  config.x86_64
  $pkgname.install
  $pkgname.preset
)
md5sums=(
  aa9b07bbd30ed38607a30795e7628ccf
  ec2602db06c5c9fba9d95dee77e8ca53
  9d3c56a4b999c8bfbd4018089a62f662
  342071f852564e1ad03b79271a90b1a5
  3cb9e819538197398aad5db5529b22d6
  774c6ff0113463ca573de091bba1ef92
  395bed4b472b8f9299c79daf4b78b206
  232d054a18f3b5556d9eecc13bbeb99a
  21c5e7d3428660d90814c6b5cf0ae52d
  2f4e8da2611ce693f5f77806a0ffb858
)

build() {
  cd $srcdir/linux-$pkgver

  # Some chips detect a ghost TV output
  # mailing list discussion: http://lists.freedesktop.org/archives/intel-gfx/2011-April/010371.html
  # Arch Linux bug report: FS#19234
  #
  # It is unclear why this patch wasn't merged upstream, it was accepted,
  # then dropped because the reasoning was unclear. However, it is clearly
  # needed.
  patch -Np1 -i "${srcdir}/i915-fix-ghost-tv-output.patch"

  # set DEFAULT_CONSOLE_LOGLEVEL to 4 (same value as the 'quiet' kernel param)
  # remove this when a Kconfig knob is made available by upstream
  # (relevant patch sent upstream: https://lkml.org/lkml/2011/7/26/227)
  patch -Np1 -i "${srcdir}/change-default-console-loglevel.patch"

  # Patch submitted upstream, waiting for inclusion:
  # https://lkml.org/lkml/2012/2/19/51
  # add support for latest bios of Acer 1810T acerhdf module
  patch -Np1 -i "${srcdir}/fix-acerhdf-1810T-bios.patch"

  # fix ext4 module to mount ext3/2 correct
  # https://bugs.archlinux.org/task/28653
  patch -Np1 -i "${srcdir}/ext4-options.patch"

  # Add grsecurity patches
  patch -Np1 -i $srcdir/grsecurity-$_grsecver-$pkgver-$_timestamp.patch

  cat "${srcdir}/config.${CARCH}" > ./.config

  # remove the sublevel from Makefile
  # this ensures our kernel version is always 3.X-ARCH
  # this way, minor kernel updates will not break external modules
  # we need to change this soon, see FS#16702
  sed -ri 's|^(SUBLEVEL =).*|\1|' Makefile

  # get kernel version
  [ "$_menuconfig" = "0" ] && {
    make prepare
  }

  # load configuration
  # Configure the kernel. Replace the line below with one of your choice.
  [ "$_menuconfig" = "1" ] && {
    make menuconfig # CLI menu for configuration
    #make nconfig # new CLI menu for configuration
    #make xconfig # X-based configuration
    #make oldconfig # using old config from previous kernel version
    # ... or manually edit .config
  }

  ####################
  # stop here
  # this is useful to configure the kernel
  [ "$_menuconfig" = "1" ] && {
    msg "Stopping build"
    return 1
  }
  ####################

  yes "" | make config

  # build!
  make ${MAKEFLAGS} bzImage modules
}

package() {
  pkgdesc="The Linux Kernel and modules with grsecurity patches"
  groups=('base')
  depends=('linux-pax-flags' 'coreutils' 'linux-firmware' 'module-init-tools>=3.16' 'mkinitcpio>=0.7')
  optdepends=('crda: to set the correct wireless channels of your country')
  provides=('kernel26-grsec')
  conflicts=('kernel26-grsec')
  replaces=('kernel26-grsec')
  backup=("etc/mkinitcpio.d/${pkgname}.preset")
  install=$pkgname.install

  cd $srcdir/linux-$pkgver

  KARCH=x86

  # get kernel version
  _kernver="$(make kernelrelease)"

  mkdir -p "${pkgdir}"/{lib/modules,lib/firmware,boot}
  make INSTALL_MOD_PATH="${pkgdir}" modules_install
  cp arch/$KARCH/boot/bzImage "${pkgdir}/boot/vmlinuz-${pkgname}"

  # add vmlinux
  install -D -m644 vmlinux "${pkgdir}/usr/src/linux-${_kernver}/vmlinux"

  # install fallback mkinitcpio.conf file and preset file for kernel
  install -D -m644 "${srcdir}/${pkgname}.preset" "${pkgdir}/etc/mkinitcpio.d/${pkgname}.preset"

  # set correct depmod command for install
  sed \
    -e  "s/KERNEL_NAME=.*/KERNEL_NAME=${_kernelname}/g" \
    -e  "s/KERNEL_VERSION=.*/KERNEL_VERSION=${_kernver}/g" \
    -i "${startdir}/${pkgname}.install"
  sed \
    -e "s|ALL_kver=.*|ALL_kver=\"/boot/vmlinuz-${pkgname}\"|g" \
    -e "s|default_image=.*|default_image=\"/boot/initramfs-${pkgname}.img\"|g" \
    -e "s|fallback_image=.*|fallback_image=\"/boot/initramfs-${pkgname}-fallback.img\"|g" \
    -i "${pkgdir}/etc/mkinitcpio.d/${pkgname}.preset"

  # remove build and source links
  rm -f "${pkgdir}"/lib/modules/${_kernver}/{source,build}
  # remove the firmware
  rm -rf "${pkgdir}/lib/firmware"
  # gzip -9 all modules to safe 100MB of space
  find "${pkgdir}" -name '*.ko' -exec gzip -9 {} \;
  # make room for external modules
  ln -s "../extramodules-${_basekernel}${_kernelname:--ARCH}" "${pkgdir}/lib/modules/${_kernver}/extramodules"
  # add real version for building modules and running depmod from post_install/upgrade
  mkdir -p "${pkgdir}/lib/modules/extramodules-${_basekernel}${_kernelname:--ARCH}"
  echo "${_kernver}" > "${pkgdir}/lib/modules/extramodules-${_basekernel}${_kernelname:--ARCH}/version"
}
