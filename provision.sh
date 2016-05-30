set -ex

x="$(uname -m)"
case "$x" in
    x86_64)
        build=x86_64-pc-cygwin
        host=x86_64-w64-mingw32
        MINGW_TOOL_PREFIX=x86_64-w64-mingw32-
        WODI_ARCH=64
        ;;
    *)
        build=i686-pc-cygwin
        host=i686-w64-mingw32
        MINGW_TOOL_PREFIX=i686-w64-mingw32-
        WODI_ARCH=32
        ;;
esac

export OCAMLROOT=/cygdrive/c/ocaml
export CMD_OCAMLROOT="C:\/ocaml"
export OCAMLLIB="C:/ocaml/lib"

export PATH=$PATH:$OCAMLROOT/bin:/cygdrive/c/cygwin/bin
# Helper to install packages that use substitution & *.install
# See https://github.com/whitequark/ppx_deriving/issues/16
meta_install() {
    package_name=$1
    version=$2
    sed "s/%{version}%/$version/g" pkg/META.in > pkg/META
    ocaml pkg/build.ml native=true native-dynlink=true
    install_targets=`grep -E '^\s+' ${package_name}.install | sed -r -e 's/^\s+"\??([^"]+)".*/\1/'`
    ocamlfind remove $package_name
    ocamlfind install $package_name $install_targets
}

rename_exe() {
    package_name=$1
    extfrom=$2
    extto=$3
    dir=`ocamlfind query $package_name | sed -e 's/\\r$//'`
    mv $dir/${package_name}${extfrom} $dir/${package_name}${extto}
}

unpack_github() {
    user=$1
    repo=$2
    version=$3
	if [ ! -f $version.tar.gz ] ; then
		wget https://github.com/${user}/${repo}/archive/${version}.tar.gz
		tar xzvf ${version}.tar.gz
    fi;
}

unpack_targz(){
	where=$1
	archive=$2.tar.gz
	if [ ! -f $archive ] ; then
		wget ${where}/${archive}
		tar xzvf ${archive}
	fi;
}

make_ocamlroot()
{
	echo "make OCaml root here $OCAMLROOT"
	if [ ! -d $OCAMLROOT ]; then
		mkdir $OCAMLROOT
		mkdir $OCAMLROOT/bin
	fi
}

install_flexdll(){
    echo "Install flexdll"
	wget http://alain.frisch.fr/flexdll/flexdll-bin-0.34.zip
	unzip -o flexdll-bin-0.34.zip -d flexdll-0.34
	#tar --transform=s/^flexdll/flexdll-0.34/ -xzf flexdll-0.34.tar.gz
    cd flexdll-0.34
    for i in flexdll_{initer_,}mingw.o flexdll.h flexlink.exe; do cp $i $OCAMLROOT/bin ; done
    cd ..
}

install_ocaml(){
	echo "Install OCaml"
	unpack_github ocaml ocaml 4.02.1
	cd ocaml-4.02.1
	cp config/m-nt.h config/m.h
    cp config/s-nt.h config/s.h
    sed -e "18s/=.*/=$CMD_OCAMLROOT/" config/Makefile.mingw > config/Makefile
	make -f Makefile.nt world opt opt.opt install
	cd ..
}


install_findlib(){
	echo "Install findlib"
	echo $PATH
	if [ ! -f findlib-1.5.5.tar.gz ] ; then
		wget http://download.camlcity.org/download/findlib-1.5.5.tar.gz
		tar -xzf findlib-1.5.5.tar.gz
	fi;
	cd findlib-1.5.5
	./configure
	make all opt install
	echo $OCAMLLIB\\site-lib\\stublibs>> $OCAMLROOT/lib/ld.conf
	cd ..

}
install_ocamlgraph(){
	unpack_targz http://ocamlgraph.lri.fr/download ocamlgraph-1.8.6
	cd ocamlgraph-1.8.6
	./configure
	make all install-findlib
	cd ..
}



install_cmdliner(){
	unpack_github dbuenzli cmdliner v0.9.7
	cd cmdliner-0.9.7
	ocaml pkg/build.ml native=true native-dynlink=true
	ocamlfind install cmdliner _build/pkg/META _build/src/cmdliner.{a,mli} _build/src/cmdliner.cm{a,i,x,xa,xs}
	cd ..
}

install_uutf(){
	unpack_github dbuenzli uutf v0.9.4
	cd uutf-0.9.4
	ocaml pkg/build.ml native=true native-dynlink=true cmdliner=true
	ocamlfind install uutf _build/pkg/META _build/src/uutf.{a,mli} _build/src/uutf.cm{a,i,ti,x,xa,xs}
	cp _build/test/utftrip.native $OCAMLROOT/bin/utftrip.exe
	cd ..
}

install_jsonm(){
	wget http://erratique.ch/software/jsonm/releases/jsonm-0.9.1.tbz
	tar xjf jsonm-0.9.1.tbz
	cd jsonm-0.9.1
	ocaml setup.ml -configure --prefix $CMD_OCAMLROOT
	ocaml setup.ml -build
	ocaml setup.ml -install
	cd ..
}

install_camlp4(){
	unpack_github ocaml camlp4 4.02+3
	cd camlp4-4.02-3
	wget https://gist.githubusercontent.com/braibant/2aec4a03e99f97ce0a51/raw/c809239db266284a3742dff4f412dbb09e33004e/camlp4 -O camlp4.patch
	patch -p1 < camlp4.patch
	./configure
	make all install
	cd ..
}

install_extlib(){
	unpack_github ygrek ocaml-extlib 1.6.1
	cd ocaml-extlib-1.6.1/extlib/
	make all opt cmxs install
	cd ../..
}

install_re(){
	unpack_github ocaml ocaml-re ocaml-re-1.4.1
	cd ocaml-re-ocaml-re-1.4.1/
	ocaml setup.ml -configure --prefix $CMD_OCAMLROOT
	ocaml setup.ml -build
	ocaml setup.ml -install
	cd ..
}

install_cudf(){
	wget https://gforge.inria.fr/frs/download.php/file/34659/cudf-0.8.tar.gz
	tar -xzf cudf-0.8.tar.gz
	cd cudf-0.8
	make BINDIR='cygdrive/c/ocaml/bin' all opt install
	cd ..
}

install_cppo(){
	wget http://mjambon.com/releases/cppo/cppo-0.9.4.tar.gz
	tar -xzf cppo-0.9.4.tar.gz
	cd cppo-0.9.4
	make
	make install
	cd ..
}


install_dose(){
	wget https://gforge.inria.fr/frs/download.php/file/34277/dose3-3.3.tar.gz
	tar -xzf dose3-3.3.tar.gz
	cd dose3-3.3
	PATCHES=../../patches
	patch -p1 < $PATCHES/dose3-3.3-failures.patch
	patch -p1 < $PATCHES/dose3-3.3-ocamlgraph-1.8.6.patch
	patch -p1 < $PATCHES/dose3-3.3-windows.patch
	rm doseparseNoRpm
    cp -R doseparse doseparseNoRpm
    rm doseparseNoRpm/doseparseNoRpm.mlpack
	cp --remove-destination doseparseNoRpm/doseparse.mlpack doseparseNoRpm/doseparseNoRpm.mlpack
	./configure CC=i686-w64-mingw32-gcc --with-ocamlgraph --prefix=$CMD_OCAMLROOT --libdir=$OCAMLLIB/site-lib
	find . -iname '*.ml' | xargs sed -i 's/let options = OptParser.make ~description\(.*\)/let status = None let options = OptParser.make ~description\1 ?status/'
    make OCAMLLIB=$OCAMLLIB
	make install
	cd ..
}

install()
{
    mkdir src
	cd src
	make_ocamlroot
	install_flexdll
	install_ocaml
	install_findlib
	install_ocamlgraph
	install_cmdliner
	install_uutf
	install_jsonm
	install_camlp4
	install_extlib
	install_re
	install_cudf
	install_dose
}

install_opam(){
	git clone https://github.com/dra27/opam.git
	cd opam
	git checkout windows-checkpoint
	./configure CC=i686-w64-mingw32-gcc --prefix=$CMD_OCAMLROOT
	AR=i686-w64-mingw32-ar CC=i686-w64-mingw32-gcc make
	make install
	cd ..
}

# Complete install
install
install_opam

install_cryptokit() {
    wget https://forge.ocamlcore.org/frs/download.php/1229/cryptokit-1.9.tar.gz
    tar -xzf cryptokit-1.9.tar.gz
    cd cryptokit-1.9
    make
    make install
    cd ..
}

install_pprint() {
    wget https://opam.ocaml.org/archives/pprint.20140424+opam.tar.gz
    tar -xzf pprint.20140424+opam.tar.gz
    cd pprint.20140424/src
    make
    make install
    cd ../..
}

install_ctypes() {
    export CYGWIN=winsymlinks

    type -p ocamlc
    ocamlc -version

    export AR=${MINGW_TOOL_PREFIX}ar.exe
    export AS=${MINGW_TOOL_PREFIX}as.exe
    export CC=${MINGW_TOOL_PREFIX}gcc.exe
    export CPP=${MINGW_TOOL_PREFIX}cpp.exe
    export CPPFILT=${MINGW_TOOL_PREFIX}c++filt.exe
    export CXX=${MINGW_TOOL_PREFIX}g++.exe
    export DLLTOOL=${MINGW_TOOL_PREFIX}dlltool.exe
    export DLLWRAP=${MINGW_TOOL_PREFIX}dllwrap.exe
    export GCOV=${MINGW_TOOL_PREFIX}gcov.exe
    export LD=${MINGW_TOOL_PREFIX}ld.exe
    export NM=${MINGW_TOOL_PREFIX}nm.exe
    export OBJCOPY=${MINGW_TOOL_PREFIX}objcopy.exe
    export OBJDUMP=${MINGW_TOOL_PREFIX}objdump.exe
    export RANLIB=${MINGW_TOOL_PREFIX}ranlib.exe
    export RC=${MINGW_TOOL_PREFIX}windres.exe
    export READELF=${MINGW_TOOL_PREFIX}readelf.exe
    export SIZE=${MINGW_TOOL_PREFIX}size.exe
    export STRINGS=${MINGW_TOOL_PREFIX}strings.exe
    export STRIP=${MINGW_TOOL_PREFIX}strip.exe
    export WINDMC=${MINGW_TOOL_PREFIX}windmc.exe
    export WINDRES=${MINGW_TOOL_PREFIX}windres.exe

    # findlib is already installed

    # libffi:  we need a static version and only a static version
    (
    #  rm -rf /usr/local
      mkdir -p /usr/local/include
      wget ftp://sourceware.org/pub/libffi/libffi-3.1.tar.gz
      rm -rf libffi-3.1
      tar xfvz libffi-3.1.tar.gz
      cd libffi-3.1
      (./configure --build="$build" --host="$host" --prefix /usr/local --disable-shared --enable-static </dev/null && make </dev/null && make install </dev/null) || cat config.log
      mkdir -p /usr/local/include/
      rm -rf /usr/local/include/ffi*
      ln -s -t /usr/local/include/ /usr/local/lib/libffi-3.1/include/* || true
    )

    export LIBFFI_CFLAGS="-I/usr/local/include"
    export LIBFFI_LIBS="-L/usr/local/lib -lffi"

    # workaround for https://github.com/ocamllabs/ocaml-ctypes/pull/287
    export LBIFFI_LIBS="$LIBFFI_LIBS"

    rm -Rf ocaml-ctypes
    git clone https://github.com/cryptosense/ocaml-ctypes.git
    cd ocaml-ctypes
    touch setup.data
    make distclean || true
    rm -f setup.data
    make all
    make date date-stubs date-stub-generator date-cmd-build date-cmd
    ./_build/date-cmd.native
    ./_build/date.native
    # if ! (make -k test 2>&1 | tee test.log; test ${PIPESTATUS[0]} -eq 0) ; then
    #     echo "test case failure" >&2
    #     exit 1
    # fi
    ocamlfind remove ctypes || true
    make install
    cd ..
}

need_cygwin_installer() {
    if [ ! -x setup-x86.exe ] ; then
        wget https://cygwin.com/setup-x86.exe
        chmod +x setup-x86.exe
    fi
}

cygwin_install() {
    need_cygwin_installer
    ./setup-x86.exe -q -P "$1"
}

install_asn1_combinators() {
    unpack_github mirleft ocaml-asn1-combinators 0.1.1
    cd ocaml-asn1-combinators-0.1.1
    ocaml setup.ml -configure
    ocaml setup.ml -build
    ocaml setup.ml -install
    cd ..
}

install_optcomp() {
    unpack_github diml optcomp 1.6
    cd optcomp-1.6
    ./configure
    make
    make install
    cd ..
}

install_sexplib() {
    wget https://ocaml.janestreet.com/ocaml-core/112.06.00/individual/sexplib-112.06.00.tar.gz
    tar xzvf sexplib-112.06.00.tar.gz
    cd sexplib-112.06.00
    sed -i "s/cpp/${MINGW_TOOL_PREFIX}cpp.exe/" _tags
    ./configure
    make
    make install
    cd ..
}

install_ocplib_endian() {
    unpack_github OCamlPro ocplib-endian 0.7
    cd ocplib-endian-0.7
    ocaml setup.ml -configure --disable-debug
    ocaml setup.ml -build
    ocaml setup.ml -install
    cd ..
}

install_cstruct() {
    wget https://github.com/mirage/ocaml-cstruct/archive/v1.5.0.tar.gz
    tar xzvf v1.5.0.tar.gz
    cd ocaml-cstruct-1.5.0
    make
    make install
    cd ..
}


install_ppx_deriving() {
    wget https://github.com/whitequark/ppx_deriving/archive/v2.0.tar.gz
    tar xzvf v2.0.tar.gz
    cd ppx_deriving-2.0
    meta_install ppx_deriving 2.0
    rename_exe ppx_deriving _main.native .exe
    cd ..
}

install_ppx_deriving_yojson() {
    git clone https://github.com/cryptosense/ppx_deriving_yojson -b cryptosense
    cd ppx_deriving_yojson
    meta_install ppx_deriving_yojson 2.2
    cd ..
}

install_re() {
    wget https://github.com/ocaml/ocaml-re/archive/ocaml-re-1.3.1.tar.gz
    tar xzvf ocaml-re-1.3.1.tar.gz
    cd ocaml-re-ocaml-re-1.3.1
    ocaml setup.ml -configure
    ocaml setup.ml -build
    ocaml setup.ml -install
    cd ..
}

install_alcotest() {
    need_pkg re
    unpack_github samoht alcotest 0.2.0
    cd alcotest-0.2.0
    export ocamlfind='ocamlfind.exe'
    ocaml setup.ml -configure
    ocaml setup.ml -build
    ocaml setup.ml -install
    unset ocamlfind
    cd ..
}

install_ppx_const() {
    wget https://github.com/mcclure/ppx_const/archive/ppx_const-1.0.tar.gz
    tar xzvf ppx_const-1.0.tar.gz
    cd ppx_const-ppx_const-1.0
    meta_install ppx_const 1.0
    rename_exe ppx_const .native .exe
    cd ..
}

install_ppx_getenv() {
    wget https://github.com/whitequark/ppx_getenv/archive/v1.1.tar.gz
    tar xzvf v1.1.tar.gz
    cd ppx_getenv-1.1
    meta_install ppx_getenv 1.1
    rename_exe ppx_getenv .native .exe
    cd ..
}

install_hex() {
    unpack_github mirage ocaml-hex 0.1.0
    cd ocaml-hex-0.1.0
    make
    make install
    cd ..
}
