# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "gcc"
version = v"7.3.0"

# Collection of sources required to build gcc
sources = [
    "https://mirrors.kernel.org/gnu/gcc/gcc-7.3.0/gcc-7.3.0.tar.xz" =>
    "832ca6ae04636adbb430e865a1451adf6979ab44ca1c8374f61fba65645ce15c",

]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd gcc-7.3.0/
contrib/download_prerequisites
export LD_LIBRARY_PATH=/usr/local/lib64:/usr/local/lib:/lib:/usr/glibc-compat/lib:/usr/local/lib:/usr/lib:/opt/x86_64-linux-gnu/lib64:/opt/x86_64-linux-gnu/lib:/opt/x86_64-linux-gnu/x86_64-linux-gnu/lib64:/opt/x86_64-linux-gnu/x86_64-linux-gnu/lib
contrib/download_prerequisites
cd ..
mkdir gcc_build
cd gcc_build/
../gcc-7.3.0/configure --host=$target --prefix=$prefix --enable-host-shared --enable-threads=posix --with-system-zlib --enable-multilib --enable-languages=c,c++,fortran,objc,obj-c++
make
ls
ls /workspace/destdir/include/zlib.h 
../gcc-7.3.0/configure --host=$target --prefix=$prefix --enable-host-shared --enable-threads=posix --with-system-zlib --enable-multilib --enable-languages=c,c++,fortran,objc,obj-c++ --help
../gcc-7.3.0/configure --host=$target --prefix=$prefix --enable-host-shared --enable-threads=posix --enable-multilib --enable-languages=c,c++,fortran,objc,obj-c++ --help
../gcc-7.3.0/configure --host=$target --prefix=$prefix --enable-host-shared --enable-threads=posix --enable-multilib --enable-languages=c,c++,fortran,objc,obj-c++ 
make -j20
/workspace/srcdir/gcc_build/./gcc/xgcc
/workspace/srcdir/gcc_build/./gcc/xgcc -B/workspace/srcdir/gcc_build/./gcc/ -nostdinc -x c /dev/null -S -o /dev/null -fself-test=../../gcc-7.3.0/gcc/testsuite/selftests
cd gcc/
/workspace/srcdir/gcc_build/./gcc/xgcc -B/workspace/srcdir/gcc_build/./gcc/ -nostdinc -x c /dev/null -S -o /dev/null -fself-test=../../gcc-7.3.0/gcc/testsuite/selftests
ldd /workspace/srcdir/gcc_build/./gcc/xgcc -B/workspace/srcdir/gcc_build/./gcc/ -nostdinc -x c /dev/null -S -o /dev/null -fself-test=../../gcc-7.3.0/gcc/testsuite/selftests
strace -f /workspace/srcdir/gcc_build/./gcc/xgcc -B/workspace/srcdir/gcc_build/./gcc/ -nostdinc -x c /dev/null -S -o /dev/null -fself-test=../../gcc-7.3.0/gcc/testsuite/selftests
apk add strace
strace -f /workspace/srcdir/gcc_build/./gcc/xgcc -B/workspace/srcdir/gcc_build/./gcc/ -nostdinc -x c /dev/null -S -o /dev/null -fself-test=../../gcc-7.3.0/gcc/testsuite/selftests
ls /usr/
ls /usr/glibc-compat/lib/gconv/gconv-modules 
echo $GCONV_PATH
export GCONV_PATH=/usr/glibc-compat/lib/gconv/
/workspace/srcdir/gcc_build/./gcc/xgcc -B/workspace/srcdir/gcc_build/./gcc/ -nostdinc -x c /dev/null -S -o /dev/null -fself-test=../../gcc-7.3.0/gcc/testsuite/selftests
cd ..
make -j20
ls
ls
cd ..
ls
cd ..
ls
cd destdir/
ls
ls
ls -la
ls x86_64-linux-gnu/
ls
ls
mv bin/ lib/ include/ x86_64-linux-gnu/
cd ..
cd srcdir/gcc_build/
make
locate gnu/stubs-32.h
find / -name gnu/stubs-32.h
find $WORKSPACE -name gnu/stubs-32.h
find $WORKSPACE -name stubs-32.h
find $WORKSPACE -name stubs-64.h
ls
mkdir ../../destdir/bin
mv /workspace/srcdir/gcc_build/./gcc/xgcc ../../destdir/bin/
cd ../../destdir/bin/
ls

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:x86_64, :glibc)
]

# The products that we will ensure are always built
products(prefix) = [
    ExecutableProduct(prefix, "", :xgcc)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "https://github.com/staticfloat/GlibcBuilder/releases/download/v2.27-0/build_Glibc.v2.12.2.jl",
    "https://github.com/bicycle1885/ZlibBuilder/releases/download/v1.0.1/build_Zlib.v1.2.11.jl"
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

