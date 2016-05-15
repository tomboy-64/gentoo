# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

inherit java-pkg-opt-2

DESCRIPTION="A compiler for the Perl 6 programming language"
HOMEPAGE="http://rakudo.org"

if [[ ${PV} == "9999" ]]; then
	EGIT_REPO_URI="https://github.com/rakudo/${PN}.git"
	inherit git-r3
	KEYWORDS=""
else
	SRC_URI="${HOMEPAGE}/downloads/${PN}/${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

LICENSE="Artistic-2"
SLOT="0"
# TODO: add USE="javascript" once that's usable in nqp
IUSE="clang java +moar test"
REQUIRED_USE="|| ( java moar )"

CDEPEND="~dev-lang/nqp-${PV}:${SLOT}=[java=,moar=,clang=]"

RDEPEND="${CDEPEND}
	java? ( >=virtual/jre-1.7:* )"

DEPEND="${CDEPEND}
	clang? ( sys-devel/clang )
	java? ( >=virtual/jdk-1.7:* )
	>=dev-lang/perl-5.10"

PATCHES=(
	"${FILESDIR}/${PN}-2016.04-Makefile.in.patch"
	"${FILESDIR}/${PN}-jna-lib.patch"
)

src_prepare() {
	eapply "${PATCHES[@]}"

	# yup, this is ugly. but emake doesn't respect DESTDIR.
	for i in Moar JVM; do
		echo "DESTDIR   = ${D}" > "${T}/Makefile-${i}.in" || die
		cat "${S}/tools/build/Makefile-${i}.in" >> "${T}/Makefile-${i}.in" || die
		mv "${T}/Makefile-${i}.in" "${S}/tools/build/Makefile-${i}.in" || die
	done

	eapply_user
	java-pkg-opt-2_src_prepare
}

src_configure() {
	local backends
	use java && backends+="jvm,"
	use moar && backends+="moar,"

	local myargs=(
		"--prefix=/usr"
		"--sysroot=/"
		"--sdkroot=/"
		"--backends=${backends}"
	)

	perl Configure.pl "${myargs[@]}"

	if use java; then
		NQP=$(java-pkg_getjars --with-dependencies nqp)
	fi
}

src_compile() {
	emake DESTDIR="${D}" NQP_JARS="${NQP}" BLD_NQP_JARS="${NQP}"
}

src_install() {
	emake DESTDIR="${D}" NQP_JARS="${NQP}" BLD_NQP_JARS="${NQP}" install
}

src_test() {
	RAKUDO_PRECOMP_PREFIX=$(mktemp -d) default
}
