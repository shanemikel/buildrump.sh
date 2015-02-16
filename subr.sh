# Subroutines required by packages which build on top of buildrump.sh
#
# WARNING!  These interfaces are not guaranteed to be stable.  If you
# want to depend on their continued semantics, copypaste.
#

# the parrot routine
die ()
{

	echo '>> ERROR:' >&2
	echo ">> $*" >&2
	exit 1
}

_checkrumpmake ()
{

	[ -n "${RUMPMAKE}" ] || die 'routine requires $RUMPMAKE to be set'
	[ -e "${RUMPMAKE}" ] || die ${RUMPMAKE} is not an executable
}

# adhoc "mtree" required for installaling a subset of userspace
# headers and libraries.  maybe we can migrate to a proper use of
# NetBSD's mtree at some point?
#
# XXX: hardcoded base paths
usermtree ()
{

	destbase=$1

	INCSDIRS='adosfs altq arpa c++ c++/experimental c++/ext crypto
	    dev filecorefs fs i386 isofs miscfs
	    msdosfs net net80211 netatalk netbt netinet netinet6 netipsec
	    netisdn netkey netmpls netnatm netsmb nfs ntfs openssl pcap
	    ppath prop protocols rpc rpcsvc ssp sys ufs uvm x86'
	for dir in ${INCSDIRS}; do
		mkdir -p ${destbase}/include/$dir
	done
	mkdir -p ${destbase}/lib/pkgconfig
}

# echo names of normal libs (including optional prefix)
stdlibs ()
{

	prefix=${1:+${1}/}
	liblibs='libc libcrypt libipsec libm libnpf libpci libprop
	    libpthread librmt libutil liby libz'
	extralibs='external/bsd/flex/lib
	    crypto/external/bsd/openssl/lib/libcrypto
	    crypto/external/bsd/openssl/lib/libdes
	    crypto/external/bsd/openssl/lib/libssl
	    external/bsd/libpcap/lib'
	for lib in ${liblibs}; do
		echo ${prefix}lib/${lib}
	done
	for lib in ${extralibs}; do
		echo ${prefix}${lib}
	done
}

stdlibsxx ()
{
	prefix=${1:+${1}/}
	echo ${prefix}external/bsd/libc++
}

makeuserlib ()
{

	_checkrumpmake

	lib=$1
	shift

	( cd ${lib}
		${RUMPMAKE} obj
		${RUMPMAKE} MKMAN=no MKLINT=no MKPROFILE=no MKYP=no \
		    MKNLS=no NOGCCERROR=1 HAVE_LIBGCC_EH=yes ${STDJ} "$@" dependall
		${RUMPMAKE} MKMAN=no MKLINT=no MKPROFILE=no MKYP=no "$@" install
	)
}

makepci ()
{

	_checkrumpmake

	rumpsrc=$1
	shift
	pcilibs=$(${RUMPMAKE} -f ${rumpsrc}/sys/rump/dev/Makefile.rumpdevcomp \
	    -V '${RUMPPCIDEVS}')

	for lib in ${pcilibs}; do
		( cd ${rumpsrc}/sys/rump/dev/lib/lib${lib}
			${RUMPMAKE} obj
			${RUMPMAKE} $* dependall
			${RUMPMAKE} install
		)
	done
}

userincludes ()
{

	_checkrumpmake

	rumpsrc=$1
	shift

	echo '>> installing userspace headers'
	( cd ${rumpsrc}/include && ${RUMPMAKE} obj && ${RUMPMAKE} includes )
	for lib in $*; do 
		( cd ${lib} && ${RUMPMAKE} obj )
		( cd ${lib} && ${RUMPMAKE} includes )
	done
	echo '>> done installing headers'
}

# echo rumpmake variable $1.  die if $1 is not set
rumpmakevar ()
{

	_checkrumpmake

	_var=$(${RUMPMAKE} -f /dev/null -V "\${$1}")
	[ -n "${_var}" ] || die make variable \"$1\" does not exist
	echo ${_var}
}

havecxx ()
{

	_checkrumpmake

	[ $(${RUMPMAKE} -f bsd.own.mk -V '${_BUILDRUMP_CXX}') = 'yes' ]
}
