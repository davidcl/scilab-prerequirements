#!/bin/sh -e

if test $# -ne 1; then
    echo "This script compiles dependencies of Scilab for Linux."
    echo
    echo "Syntax : $0 <dependency> with dependency equal to:"
    echo " - 'versions': display versions of dependencies,"
    echo " - 'download': download all dependencies,"
    echo " - 'all': compile all dependencies,"
    echo " - 'ocaml': compile Ocaml compiler and install it in $HOME/ocaml/,"
    echo " - 'binary': configure dev-tools for binary version of Scilab,"
    echo " - 'fromscratch': 'init' + 'download' + 'all' + 'binary',"
    echo " - 'init': copy some dev-tools from old repository."
    echo
    exit 42
fi

KERNEL=$(uname -s)
MACHINE=$(uname -m)

#########################
##### CONFIGURATION #####
#########################
if [ "$KERNEL" = "Linux" ]; then
    if [ "$MACHINE" = "i686" ]; then
        SPECIFICDIR="linux"
    elif [ "$MACHINE" = "x86_64" ]; then
        SPECIFICDIR="linux_x64"
    else
        echo "Unknown machine $MACHINE"
        exit
    fi
else
    echo "Unknown kernel $KERNEL"
    exit
fi

echo "Scilab prerequirements for $(uname -s)-$(uname -m)"

#INSTALLDIR=$(pwd)/$SPECIFICDIR/$KERNEL-$MACHINE
INSTALLDIR=$(pwd)/$SPECIFICDIR/usr
DEVTOOLSDIR=$(pwd)/../../../../../Dev-Tools

echo
echo "INSTALLDIR     = $INSTALLDIR"
echo "DEVTOOLSDIR    = $DEVTOOLSDIR"
echo

#[ ! -d $DEVTOOLSDIR ] && echo "Dev-tools directory not found" && exit

[ ! -d $INSTALLDIR ] && mkdir $INSTALLDIR -p

################################
##### DEPENDENCIES VERSION #####
################################
ANT_VERSION=1.8.3
ARPACK_VERSION=3.1.5
CURL_VERSION=7.19.7
EIGEN_VERSION=3.2.1
FFTW_VERSION=3.3.3
HDF5_VERSION=1.8.8
LIBXML2_VERSION=2.9.1
MATIO_VERSION=1.5.2
OCAML_VERSION=4.01.0
OPENSSL_VERSION=0.9.8za
PCRE_VERSION=8.35
SUITESPARSE_VERSION=4.2.1
TCL_VERSION=8.5.15
TK_VERSION=8.5.15
ZLIB_VERSION=1.2.8

####################
##### DOWNLOAD #####
####################
function download_dependencies() {
    [ ! -e apache-ant-$ANT_VERSION-bin.tar.gz ] && wget http://archive.apache.org/dist/ant/binaries/apache-ant-$ANT_VERSION-bin.tar.gz
    [ ! -e arpack-ng-$ARPACK_VERSION.tar.gz ] && wget http://forge.scilab.org/index.php/p/arpack-ng/downloads/get/arpack-ng_$ARPACK_VERSION.tar.gz
    [ ! -e curl-$CURL_VERSION.tar.gz ] && wget http://curl.haxx.se/download/curl-$CURL_VERSION.tar.gz
    [ ! -e $EIGEN_VERSION.tar.gz ] && wget http://bitbucket.org/eigen/eigen/get/$EIGEN_VERSION.tar.gz
    [ ! -e fftw-$FFTW_VERSION.tar.gz ] && wget ftp://ftp.fftw.org/pub/fftw/fftw-$FFTW_VERSION.tar.gz
    [ ! -e hdf5-$HDF5_VERSION.tar.gz ] && wget http://www.hdfgroup.org/ftp/HDF5/releases/hdf5-$HDF5_VERSION/src/hdf5-$HDF5_VERSION.tar.gz
    [ ! -e libxml2-$LIBXML2_VERSION.tar.gz ] && wget http://xmlsoft.org/sources/libxml2-$LIBXML2_VERSION.tar.gz
    [ ! -e matio-$MATIO_VERSION.tar.gz ] && wget http://sourceforge.net/projects/matio/files/matio/$MATIO_VERSION/matio-$MATIO_VERSION.tar.gz/download
    [ ! -e ocaml-$OCAML_VERSION.tar.gz ] && wget http://caml.inria.fr/pub/distrib/ocaml-4.01/ocaml-$OCAML_VERSION.tar.gz
    [ ! -e openssl-$OPENSSL_VERSION.tar.gz ] && wget http://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz
    [ ! -e pcre-$PCRE_VERSION.tar.gz ] && wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-$PCRE_VERSION.tar.gz
    [ ! -e SuiteSparse-$SUITESPARSE_VERSION.tar.gz ] && wget http://www.cise.ufl.edu/research/sparse/SuiteSparse/SuiteSparse-$SUITESPARSE_VERSION.tar.gz
    [ ! -e tcl$TCL_VERSION-src.tar.gz ] && wget http://prdownloads.sourceforge.net/tcl/tcl$TCL_VERSION-src.tar.gz
    [ ! -e tk$TK_VERSION-src.tar.gz ] && wget http://prdownloads.sourceforge.net/tcl/tk$TK_VERSION-src.tar.gz
    [ ! -e zlib-$ZLIB_VERSION.tar.gz ] && wget http://sourceforge.net/projects/libpng/files/zlib/$ZLIB_VERSION/zlib-$ZLIB_VERSION.tar.gz/download
}

####################
##### BUILDERS #####
####################

function build_ant() {
    [ -d $INSTALLDIR/../java/ant ] && rm -fr $INSTALLDIR/../java/ant
    [ -d $INSTALLDIR/../java/apache-ant-$ANT_VERSION ] && rm -fr $INSTALLDIR/../java/apache-ant-$ANT_VERSION

    cd $INSTALLDIR/../java/
    tar -xzf ../../apache-ant-$ANT_VERSION-bin.tar.gz
    ln -s apache-ant-$ANT_VERSION ant
    cd -
}

function build_arpack() {
    [ -d arpack-ng-$ARPACK_VERSION ] && rm -fr arpack-ng-$ARPACK_VERSION

    tar -xzf arpack-ng_$ARPACK_VERSION.tar.gz
    cd arpack-ng-$ARPACK_VERSION
    ./configure "$@" LDFLAGS="-L$INSTALLDIR/lib/" --prefix=
    make -j
    make install DESTDIR=$INSTALLDIR
    cd -

    clean_static
}

function build_eigen() {
    [ -d eigen-eigen* ] && rm -fr eigen-eigen*

    tar -zxf $EIGEN_VERSION.tar.gz
    cd eigen-eigen*
    cp -R Eigen/ $INSTALLDIR/include/
    cd -
}


function build_hdf5() {
    [ -d hdf5-$HDF5_VERSION ] && rm -fr hdf5-$HDF5_VERSION

    tar -xzf hdf5-$HDF5_VERSION.tar.gz
    cd hdf5-$HDF5_VERSION
    sed -i -e 's|//int i1, i2;|/* int i1, i2; */|' tools/lib/h5diff.c
    ./configure "$@" --with-zlib=$INSTALLDIR --prefix=
    make -j
    make install DESTDIR=$INSTALLDIR
    cd -

    clean_static
}

function build_fftw() {
    [ -d fftw-$FFTW_VERSION ] && rm -fr fftw-$FFTW_VERSION

    tar -xzf fftw-$FFTW_VERSION.tar.gz
    cd fftw-$FFTW_VERSION
    ./configure "$@" --enable-shared --prefix=
    make -j
    make install DESTDIR=$INSTALLDIR
    cd -

    clean_static
}

function build_zlib() {
    [ -d zlib-$ZLIB_VERSION ] && rm -fr zlib-$ZLIB_VERSION

    tar -xzf zlib-$ZLIB_VERSION.tar.gz
    cd zlib-$ZLIB_VERSION
    ./configure "$@" --prefix=
    make -j
    make install DESTDIR=$INSTALLDIR
    cd -

    clean_static
}

function build_openssl() {
    [ -d openssl-$OPENSSL_VERSION ] && rm -fr openssl-$OPENSSL_VERSION

    tar -xzf openssl-$OPENSSL_VERSION.tar.gz
    cd openssl-$OPENSSL_VERSION
    ./config shared --openssldir=$INSTALLDIR
    make -j depend all
    make install
    chmod 644 $INSTALLDIR/lib/libcrypto.*
    chmod 644 $INSTALLDIR/lib/libssl.*
    cd -

    clean_static
}

function build_tcl() {
    [ -d tcl$TCL_VERSION ] && rm -fr tcl$TCL_VERSION

    tar -xzf tcl$TCL_VERSION-src.tar.gz
    cd tcl$TCL_VERSION/unix
    ./configure "$@" --prefix=
    make -j
    make install DESTDIR=$INSTALLDIR
    chmod 644 $INSTALLDIR/lib/libtcl*.*
    cd -

    clean_static
}

function build_tk() {
    [ -d tk$TK_VERSION ] && rm -fr tk$TK_VERSION

    tar -xzf tk$TK_VERSION-src.tar.gz
    cd tk$TK_VERSION/unix
    ./configure "$@" --prefix=
    make -j
    make install DESTDIR=$INSTALLDIR
    chmod 644 $INSTALLDIR/lib/libtk*.*
    cd -

    clean_static
}

function build_matio() {
    [ -d matio-$MATIO_VERSION ] && rm -fr matio-$MATIO_VERSION

    tar -xzf matio-$MATIO_VERSION.tar.gz
    cd matio-$MATIO_VERSION
    ./configure "$@" --enable-shared --with-hdf5=$INSTALLDIR --with-zlib=$INSTALLDIR --prefix=
    make -j
    make install DESTDIR=$INSTALLDIR
    cd -

    clean_static
}

function build_pcre() {
    [ -d pcre-$PCRE_VERSION ] && rm -fr pcre-$PCRE_VERSION

    tar -xzf pcre-$PCRE_VERSION.tar.gz
    cd pcre-$PCRE_VERSION
    ./configure "$@" --enable-utf8 --enable-unicode-properties --prefix=
    make -j
    make install DESTDIR=$INSTALLDIR
    cd -
    sed -i -e 's|^\prefix=.*|\prefix=`pwd`'"/usr|" $INSTALLDIR/bin/pcre-config

    clean_static
}

function build_libxml2() {
    [ -d libxml2-$LIBXML2_VERSION ] && rm -fr libxml2-$LIBXML2_VERSION

    tar -xzf libxml2-$LIBXML2_VERSION.tar.gz
    cd libxml2-$LIBXML2_VERSION
    ./configure "$@" --without-python --with-zlib=$INSTALLDIR --prefix=
    make -j
    make install DESTDIR=$INSTALLDIR
    cd -
    sed -i -e 's|^\prefix=.*|\prefix=`pwd`'"/usr|" $INSTALLDIR/bin/xml2-config

    clean_static
}

function build_curl() {
    [ -d curl-$CURL_VERSION ] && rm -fr curl-$CURL_VERSION

    tar -zxf curl-$CURL_VERSION.tar.gz
    cd curl-$CURL_VERSION
    ./configure "$@" --disable-dict --disable-imap --disable-ldap --disable-ldaps --disable-pop3 --enable-proxy --disable-rtsp --disable-smtp \
        --disable-telnet --disable-tftp --without-libidn --without-ca-bundle --without-librtmp --without-libssh2 \
        --with-ssl=$INSTALLDIR --without-nss \
        --with-zlib=$INSTALLDIR \
        --prefix= \
        CFLAGS="-O2 -g -DCURL_WANTS_CA_BUNDLE_ENV" # Used in SCI/modules/fileio/etc/fileio.start
    make -j
    make install DESTDIR=$INSTALLDIR
    cd -
    sed -i -e 's|^\prefix=.*|\prefix=`pwd`'"/usr|" $INSTALLDIR/bin/curl-config

    clean_static
}

function build_ocaml() {
    [ -d ocaml-$OCAML_VERSION ] && rm -fr ocaml-$OCAML_VERSION

    tar -zxf ocaml-$OCAML_VERSION.tar.gz
    cd ocaml-$OCAML_VERSION
    ./configure "$@" -prefix $HOME/ocaml/
    make world bootstrap opt
    make install
    cd -
    echo "Do not forget to add $HOME/ocaml/bin/ to your PATH variable."
}

function build_suitesparse() {
    [ -d SuiteSparse ] && rm -fr SuiteSparse

    tar -zxf SuiteSparse-$SUITESPARSE_VERSION.tar.gz
    cd SuiteSparse
    sed -i -e 's|^\INSTALL_LIB = .*|\INSTALL_LIB = '"$INSTALLDIR"'\/lib\/|' SuiteSparse_config/SuiteSparse_config.mk
    sed -i -e 's|^\INSTALL_INCLUDE = .*|\INSTALL_INCLUDE = '"$INSTALLDIR"'\/include\/|' SuiteSparse_config/SuiteSparse_config.mk
    make -j
    make install

    UMFPACK_VERSION=$(grep -m1 VERSION UMFPACK/Makefile | sed -e "s|\VERSION = ||")

    # See http://slackware.org.uk/slacky/slackware-12.2/development/suitesparse/3.1.0/src/suitesparse.SlackBuild
    # libamd.so
    AMD_VERSION=$(grep -m1 VERSION AMD/Makefile | sed -e "s|\VERSION = ||")
    AMD_MAJOR_VERSION=$(echo "$AMD_VERSION" | awk -F \. {'print $1'})
    cd AMD/Lib/
    gcc -shared -Wl,-soname,libamd.so.${AMD_MAJOR_VERSION} -o libamd.so.${AMD_VERSION} `ls *.o`
    cp libamd.so.${AMD_VERSION} $INSTALLDIR/lib/
    cd -

    # libcamd.so
    CAMD_VERSION=$(grep -m1 VERSION CAMD/Makefile | sed -e "s|\VERSION = ||")
    CAMD_MAJOR_VERSION=$(echo "$CAMD_VERSION" | awk -F \. {'print $1'})
    cd CAMD/Lib/
    gcc -shared -Wl,-soname,libcamd.so.${CAMD_MAJOR_VERSION} -o libcamd.so.${CAMD_VERSION} `ls *.o`
    cp libcamd.so.${CAMD_VERSION} $INSTALLDIR/lib/
    cd -

    # libcolamd.so
    COLAMD_VERSION=$(grep -m1 VERSION COLAMD/Makefile | sed -e "s|\VERSION = ||")
    COLAMD_MAJOR_VERSION=$(echo "$COLAMD_VERSION" | awk -F \. {'print $1'})
    cd COLAMD/Lib/
    gcc -shared -Wl,-soname,libcolamd.so.${COLAMD_MAJOR_VERSION} -o libcolamd.so.${COLAMD_VERSION} `ls *.o`
    cp libcolamd.so.${COLAMD_VERSION} $INSTALLDIR/lib/
    cd -

    # libccolamd.so
    CCOLAMD_VERSION=$(grep -m1 VERSION CCOLAMD/Makefile | sed -e "s|\VERSION = ||")
    CCOLAMD_MAJOR_VERSION=$(echo "$CCOLAMD_VERSION" | awk -F \. {'print $1'})
    cd CCOLAMD/Lib/
    gcc -shared -Wl,-soname,libccolamd.so.${CCOLAMD_MAJOR_VERSION} -o libccolamd.so.${CCOLAMD_VERSION} `ls *.o`
    cp libccolamd.so.${CCOLAMD_VERSION} $INSTALLDIR/lib/
    cd -

    # libcholmod.so
    CHOLMOD_VERSION=$(grep -m1 VERSION CHOLMOD/Makefile | sed -e "s|\VERSION = ||")
    CHOLMOD_MAJOR_VERSION=$(echo "$CHOLMOD_VERSION" | awk -F \. {'print $1'})
    cd CHOLMOD/Lib/
    gcc -shared -Wl,-soname,libcholmod.so.${CHOLMOD_MAJOR_VERSION} -o libcholmod.so.${CHOLMOD_VERSION} `ls *.o`
    cp libcholmod.so.${CHOLMOD_VERSION} $INSTALLDIR/lib/
    cd -

    # libumfpack.so
    UMFPACK_VERSION=$(grep -m1 VERSION UMFPACK/Makefile | sed -e "s|\VERSION = ||")
    UMFPACK_MAJOR_VERSION=$(echo "$UMFPACK_VERSION" | awk -F \. {'print $1'})
    cd UMFPACK/Lib
    gcc -shared -Wl,-soname,libumfpack.so.${UMFPACK_MAJOR_VERSION} -o libumfpack.so.${UMFPACK_VERSION} `ls *.o` $INSTALLDIR/lib/libsuitesparseconfig.a \
        -L$INSTALLDIR/lib/ -lblas -llapack -lm -lcholmod -lcolamd -lccolamd -lcamd -lrt
    cp libumfpack.so.${UMFPACK_VERSION} $INSTALLDIR/lib/
    cd -

    cd $INSTALLDIR/lib/
    ln -s libamd.so.${AMD_VERSION} libamd.so
    ln -s libamd.so.${AMD_VERSION} libamd.so.${AMD_MAJOR_VERSION}
    ln -s libcamd.so.${CAMD_VERSION} libcamd.so
    ln -s libcamd.so.${CAMD_VERSION} libcamd.so.${AMD_MAJOR_VERSION}
    ln -s libcolamd.so.${COLAMD_VERSION} libcolamd.so
    ln -s libcolamd.so.${COLAMD_VERSION} libcolamd.so.${COLAMD_MAJOR_VERSION}
    ln -s libccolamd.so.${CCOLAMD_VERSION} libccolamd.so
    ln -s libccolamd.so.${CCOLAMD_VERSION} libccolamd.so.${CCOLAMD_MAJOR_VERSION}
    ln -s libcholmod.so.${CHOLMOD_VERSION} libcholmod.so
    ln -s libcholmod.so.${CHOLMOD_VERSION} libcholmod.so.${CHOLMOD_MAJOR_VERSION}
    ln -s libumfpack.so.${UMFPACK_VERSION} libumfpack.so
    ln -s libumfpack.so.${UMFPACK_VERSION} libumfpack.so.${UMFPACK_MAJOR_VERSION}
    cd -

    cd ..

    clean_static
}

function build_blas() {
    cp $DEVTOOLSDIR/lib/thirdparty/libblas.so.3gf.0 $INSTALLDIR/lib/libblas.so.3gf.0
    cd $INSTALLDIR/lib/
    ln -s libblas.so.3gf.0 libblas.so
    ln -s libblas.so.3gf.0 libblas.so.3gf
    cd -

    clean_static
}

function build_lapack() {
    cp $DEVTOOLSDIR/lib/thirdparty/liblapack.so.3gf.0 $INSTALLDIR/lib/liblapack.so.3gf.0
    cd $INSTALLDIR/lib/
    ln -s liblapack.so.3gf.0 liblapack.so
    ln -s liblapack.so.3gf.0 liblapack.so.3gf
    cd -

    clean_static
}

function clean_static() {
        rm $INSTALLDIR/lib/*.la # Avoid message about moved library while compiling
        rm $INSTALLDIR/lib/*.a # No more needed
}

#########################
##### DEFAULT FLAGS #####
#########################
export CFLAGS="-O2 -g"
export CXXFLAGS="-O2 -g"
export FFLAGS="-O2 -g"

###################################
##### GIT CLONE CONFIGURATION #####
###################################
#ln -s ../../linux-prerequisites-sources/linux/Linux-i686/ .
#ln -s ../../linux-prerequisites-sources/linux/lib/ .
#ln -s ../../linux-prerequisites-sources/linux/java/ .
#ln -s ../../linux-prerequisites-sources/linux/thirdparty/ .


###############################
##### ARGUMENT MANAGEMENT #####
###############################
DEPENDENCY=$1
case $DEPENDENCY in

    "versions")
        echo "ANT_VERSION         = $ANT_VERSION"
        echo "ARPACK_VERSION      = $ARPACK_VERSION"
        echo "CURL_VERSION        = $CURL_VERSION"
	echo "EIGEN_VERSION       = $EIGEN_VERSION"
        echo "FFTW_VERSION        = $FFTW_VERSION"
        echo "HDF5_VERSION        = $HDF5_VERSION"
        echo "LIBXML2_VERSION     = $LIBXML2_VERSION"
        echo "MATIO_VERSION       = $MATIO_VERSION"
        echo "OCAML_VERSION       = $OCAML_VERSION"
        echo "OPENSSL_VERSION     = $OPENSSL_VERSION"
        echo "PCRE_VERSION        = $PCRE_VERSION"
        echo "SUITESPARSE_VERSION = $SUITESPARSE_VERSION"
        echo "TCL_VERSION         = $TCL_VERSION"
        echo "TK_VERSION          = $TK_VERSION"
        echo "ZLIB_VERSION        = $ZLIB_VERSION"
        exit 0;
        ;;

    "fromscratch")
        sh $0 init
        sh $0 download
        sh $0 all
        sh $0 binary
        exit 0;
        ;;

    "init")
        rsync -rl --exclude=.svn $DEVTOOLSDIR/java $INSTALLDIR/..
        if [ "$MACHINE" = "x86_64" ]; then
            rm -rf $INSTALLDIR/../java/apache-ant $INSTALLDIR/../java/apache-ant-1.7.1
        fi
        rsync -rl --exclude=.svn $DEVTOOLSDIR/thirdparty $INSTALLDIR/..
        rsync -rl --exclude=.svn $DEVTOOLSDIR/modules $INSTALLDIR/..
        mkdir $INSTALLDIR/../lib/
        rsync -rl --exclude=.svn $DEVTOOLSDIR/lib/thirdparty $INSTALLDIR/../lib
        exit 0;
        ;;

    "download")
        download_dependencies
        exit 0;
        ;;

    "ant" | "arpack" | "curl" | "eigen" | "fftw" | "hdf5" | "libxml2" | "matio" | "openssl" | "pcre" | "suitesparse" | "tcl" | "tk" | "zlib")
        build_$DEPENDENCY
        exit 0;
        ;;

    "binary")
        ########################
        ##### TCL/TK stuff #####
        ########################
        rsync -rl --exclude=.svn $INSTALLDIR/lib/tcl* $INSTALLDIR/../modules/tclsci/tcl
        rsync -rl --exclude=.svn $INSTALLDIR/lib/tk* $INSTALLDIR/../modules/tclsci/tcl
        rm $INSTALLDIR/../modules/tclsci/tcl/tclConfig.sh
        rm $INSTALLDIR/../modules/tclsci/tcl/tkConfig.sh
        rm -rf $INSTALLDIR/../modules/tclsci/tk8.5/demos/ # See bug #3869

        #################
        ##### EIGEN #####
        #################
        mkdir -p $INSTALLDIR/../lib/Eigen/include/
        cp -R $INSTALLDIR/include/Eigen/ $INSTALLDIR/../lib/Eigen/include/

        #####################################
        ##### lib/thirdparty/ directory #####
        #####################################
        if [ "$MACHINE" = "i686" ]; then
            USRDIR="/usr/lib"
            LIBDIR="/lib"
        elif [ "$MACHINE" = "x86_64" ]; then
            USRDIR="/usr/lib64"
            LIBDIR="/lib64"
        fi

        LIBTHIRDPARTYDIR=$INSTALLDIR/../lib/thirdparty

        rm $LIBTHIRDPARTYDIR/libamd.*
        cp -d $INSTALLDIR/lib/libamd.* $LIBTHIRDPARTYDIR/

        rm $LIBTHIRDPARTYDIR/libarpack.*
        cp -d $INSTALLDIR/lib/libarpack.* $LIBTHIRDPARTYDIR/

        rm $LIBTHIRDPARTYDIR/libcrypto.*
        cp -d $INSTALLDIR/lib/libcrypto.* $LIBTHIRDPARTYDIR/

        rm $LIBTHIRDPARTYDIR/libcurl.*
        cp -d $INSTALLDIR/lib/libcurl.* $LIBTHIRDPARTYDIR/

        rm $LIBTHIRDPARTYDIR/libfftw3.*
        cp -d $INSTALLDIR/lib/libfftw3.* $LIBTHIRDPARTYDIR/

        rm $LIBTHIRDPARTYDIR/libhdf5_hl.*
        cp -d $INSTALLDIR/lib/libhdf5_hl.* $LIBTHIRDPARTYDIR/

        rm $LIBTHIRDPARTYDIR/libhdf5.*
        cp -d $INSTALLDIR/lib/libhdf5.* $LIBTHIRDPARTYDIR/

        rm $LIBTHIRDPARTYDIR/libmatio.*
        cp -d $INSTALLDIR/lib/libmatio.* $LIBTHIRDPARTYDIR/

        rm $LIBTHIRDPARTYDIR/libpcreposix.*
        cp -d $INSTALLDIR/lib/libpcreposix.* $LIBTHIRDPARTYDIR/

        rm $LIBTHIRDPARTYDIR/libpcre.*
        cp -d $INSTALLDIR/lib/libpcre.* $LIBTHIRDPARTYDIR/

        rm $LIBTHIRDPARTYDIR/libssl.*
        cp -d $INSTALLDIR/lib/libssl.* $LIBTHIRDPARTYDIR/

        rm $LIBTHIRDPARTYDIR/libtcl*.*
        cp -d $INSTALLDIR/lib/libtcl*.* $LIBTHIRDPARTYDIR/

        rm $LIBTHIRDPARTYDIR/libtk*.*
        cp -d $INSTALLDIR/lib/libtk*.* $LIBTHIRDPARTYDIR/

        rm $LIBTHIRDPARTYDIR/libumfpack.*
        cp -d $INSTALLDIR/lib/libumfpack.* $LIBTHIRDPARTYDIR/
        cp -d $INSTALLDIR/lib/libcholmod.* $LIBTHIRDPARTYDIR/
        cp -d $INSTALLDIR/lib/libcolamd.* $LIBTHIRDPARTYDIR/
        cp -d $INSTALLDIR/lib/libccolamd.* $LIBTHIRDPARTYDIR/
        cp -d $INSTALLDIR/lib/libcamd.* $LIBTHIRDPARTYDIR/

        rm $LIBTHIRDPARTYDIR/libxml2.*
        cp -d $INSTALLDIR/lib/libxml2.* $LIBTHIRDPARTYDIR/

        rm $LIBTHIRDPARTYDIR/libz.*
        cp -d $INSTALLDIR/lib/libz.* $LIBTHIRDPARTYDIR/

        # In case these libraries ar enot found on the system
        mkdir $LIBTHIRDPARTYDIR/redist/
        # libgfortran.so
        rm -rf $LIBTHIRDPARTYDIR/libquadmath.*
        rm $LIBTHIRDPARTYDIR/libgfortran.*
        rm $LIBTHIRDPARTYDIR/redist/libgfortran.*
        cp -d $USRDIR/libgfortran.so.3.0.0 $LIBTHIRDPARTYDIR/redist/
        cp -d $USRDIR/libgfortran.so.3 $LIBTHIRDPARTYDIR/redist/
        cd $LIBTHIRDPARTYDIR/redist/
        ln -s libgfortran.so.3.0.0 libgfortran.so
        cd -
        # libgcc_s.so
        rm $LIBTHIRDPARTYDIR/libgcc_s.*
        rm $LIBTHIRDPARTYDIR/redist/libgcc_s.*
        cp $LIBDIR/libgcc_s.so.1 $LIBTHIRDPARTYDIR/redist/
        cd $LIBTHIRDPARTYDIR/redist/
        ln -s libgcc_s.so.1 libgcc_s.so
        cd -

        rm $LIBTHIRDPARTYDIR/libgomp.*
        cp -d $USRDIR/libgomp.so.1.0.0 $LIBTHIRDPARTYDIR/
        cd $LIBTHIRDPARTYDIR/
        ln -s libgomp.so.1.0.0 libgomp.so.1.0
        ln -s libgomp.so.1.0.0 libgomp.so.1
        ln -s libgomp.so.1.0.0 libgomp.so
        cd -

        if [ "$MACHINE" = "i686" ]; then
            cp /lib/ld-linux.so.2 $LIBTHIRDPARTYDIR/ld-linux.so.2
        elif [ "$MACHINE" = "x86_64" ]; then
            cp /lib64/ld-linux-x86-64.so.2 $LIBTHIRDPARTYDIR/ld-linux-x86-64.so.2
        fi

        exit 0;
        ;;

    "all")
        build_ant
        build_eigen
        build_zlib
        build_hdf5
        build_pcre
        build_fftw
        build_libxml2
        build_blas
        build_lapack
        build_arpack
        build_suitesparse
        build_tcl
        build_tk
        build_matio
        build_openssl
        build_curl

        exit 0;
        ;;

        "ocaml")
        build_ocaml

        exit 0;
        ;;
    *)
        echo "Unknown dependency name $DEPENDENCY"
        exit 42
        ;;
esac;
