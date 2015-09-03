# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5
inherit cmake-utils multilib

DESCRIPTION="An open-source JPEG 2000 library"
HOMEPAGE="https://github.com/uclouvain/openjpeg"
SRC_URI="mirror://sourceforge/${PN}.mirror/${P}.tar.gz"

LICENSE="BSD-2"
SLOT="2"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~amd64-fbsd ~sparc-fbsd ~x86-fbsd ~x64-freebsd ~x86-freebsd ~x86-interix ~amd64-linux ~arm-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~x64-solaris ~x86-solaris"
IUSE="doc static-libs test"

RDEPEND="media-libs/lcms:2=
	media-libs/libpng:0=
	media-libs/tiff:0=
	sys-libs/zlib:="
DEPEND="${RDEPEND}
	doc? ( app-doc/doxygen )"

DOCS=( AUTHORS CHANGES NEWS README THANKS )

PATCHES=( "${FILESDIR}"/${P}-pkgconfig.patch
	"${FILESDIR}"/${P}-pkgconfig-static.patch )

RESTRICT="test" #409263

src_prepare() {
	# Stop installing LICENSE file, and install CHANGES from DOCS instead:
	sed -i -e '/install.*FILES.*DESTINATION.*OPENJPEG_INSTALL_DOC_DIR/d' CMakeLists.txt || die

	# Install doxygen docs to the right directory:
	sed -i -e "s:DESTINATION\s*share/doc:\0/${PF}:" doc/CMakeLists.txt || die
}

src_configure() {
	local mycmakeargs=(
		-DOPENJPEG_INSTALL_LIB_DIR="$(get_libdir)"
		$(cmake-utils_use_build doc)
		$(cmake-utils_use_build test TESTING)
		)

	cmake-utils_src_configure

	if use static-libs; then
		mycmakeargs=(
			-DOPENJPEG_INSTALL_LIB_DIR="$(get_libdir)"
			$(cmake-utils_use_build test TESTING)
			-DBUILD_SHARED_LIBS=OFF
			-DBUILD_CODEC=OFF
			)
		BUILD_DIR=${BUILD_DIR}_static cmake-utils_src_configure
	fi
}

src_compile() {
	cmake-utils_src_compile

	if use static-libs; then
		BUILD_DIR=${BUILD_DIR}_static cmake-utils_src_compile
	fi
}

src_install() {
	if use static-libs; then
		BUILD_DIR=${BUILD_DIR}_static cmake-utils_src_install
	fi

	cmake-utils_src_install
}
