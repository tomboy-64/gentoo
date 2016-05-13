# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

inherit java-pkg-opt-2

if [[ ${PV} == "9999" ]]; then
	EGIT_REPO_URI="https://github.com/perl6/${PN}.git"
	inherit git-r3
	KEYWORDS=""
else
	SRC_URI="https://github.com/perl6/${PN}/tarball/${PV} -> ${P}.tar.gz"
	inherit vcs-snapshot
	KEYWORDS="~x86 ~amd64"
fi

DESCRIPTION="Not Quite Perl, a Perl 6 bootstrapping compiler"
HOMEPAGE="http://rakudo.org/"

LICENSE="Artistic-2"
SLOT="0"
IUSE="doc clang java +moar test"
REQUIRED_USE="|| ( java moar )"

CDEPEND="java? (
		dev-java/asm:4
		dev-java/jline:0
		dev-java/jna:4
	)
	moar? ( ~dev-lang/moarvm-${PV}[clang=] )
	dev-libs/libffi"
RDEPEND="${CDEPEND}
	java? ( >=virtual/jre-1.7:* )"
DEPEND="${CDEPEND}
	clang? ( sys-devel/clang )
	java? ( >=virtual/jdk-1.7:* )
	dev-lang/perl"

java_prepare() {
	# Don't clean stage0 jars.
	java-pkg_clean 3rdparty/

	# Don't use jars we just deleted.
	sed -i -r 's/(:3rdparty[^:]*)+/:${THIRDPARTY_JARS}/g' \
		src/vm/jvm/runners/nqp-j || die
}

src_configure() {
	local backends
	use java && backends+="jvm,"
	use moar && backends+="moar"

	local myconfargs=(
		"--backend=${backends}"
		"--prefix=/usr" )

	perl Configure.pl "${myconfargs[@]}" || die

	if use java; then
		# Export this for the script we sed'd above.
		export THIRDPARTY_JARS=$(java-pkg_getjars --with-dependencies asm-4,jline,jna-4)
	fi
}

src_compile() {
	if use java; then
		emake -j1 \
			  THIRDPARTY_JARS="${THIRDPARTY_JARS}" \
			  JAVAC="$(java-pkg_get-javac) $(java-pkg_javac-args)"
	else
		emake -j1
	fi
}

src_test() {
	emake -j1 test
}

src_install() {
	if use java; then
		# Set JAVA_PKG_JARDEST early.
		java-pkg_init_paths_

		# Upstream sets the classpath to this location. Perhaps it's
		# used to locate the additional libraries?
		java-pkg_addcp "${JAVA_PKG_JARDEST}"

		insinto "${JAVA_PKG_JARDEST}"
		local jar

		for jar in *.jar; do
			if has ${jar} ${PN}.jar ${PN}-runtime.jar; then
				# jars for NQP itself.
				java-pkg_dojar ${jar}
			else
				# jars used by NQP.
				doins ${jar}
			fi
		done

		# Upstream uses -Xbootclasspath/a, which is faster due to lack
		# of verification, but gjl isn't flexible enough yet. :(
		java-pkg_dolauncher ${PN}-j --main ${PN}
		dosym ${PN}-j /usr/bin/${PN}
		dobin tools/jvm/eval-client.pl
	else
		emake DESTDIR="${ED}" install
	fi

	dodoc CREDITS README.pod
	use doc && dodoc -r docs/*
}
