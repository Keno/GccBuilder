# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

version = v"7.3.0"

# Collection of sources required to build gcc
sources = Any[
    "https://mirrors.kernel.org/gnu/gcc/gcc-7.3.0/gcc-7.3.0.tar.xz" =>
    "832ca6ae04636adbb430e865a1451adf6979ab44ca1c8374f61fba65645ce15c",
]

common_setup = raw"""
    cd $WORKSPACE/srcdir
    cd gcc-7.3.0/
    contrib/download_prerequisites
    export LD_LIBRARY_PATH=/usr/local/lib64:/usr/local/lib:/lib:/usr/glibc-compat/lib:/usr/local/lib:/usr/lib:/opt/x86_64-linux-gnu/lib64:/opt/x86_64-linux-gnu/lib:/opt/x86_64-linux-gnu/x86_64-linux-gnu/lib64:/opt/x86_64-linux-gnu/x86_64-linux-gnu/lib
    cd ..
    mkdir gcc_build
    cd gcc_build
"""

bootstrap_configure = raw"""
../gcc-7.3.0/configure \
    --prefix=/opt/x86_64-linux-gnu \
    --target=x86_64-linux-gnu \
    --host=x86_64-alpine-linux-musl \
    --build=x86_64-alpine-linux-musl \
    --disable-multilib \
    --disable-werror \
    --disable-shared \
    --disable-threads \
    --disable-libatomic \
    --disable-decimal-float \
    --disable-libffi \
    --disable-libgomp \
    --disable-libitm \
    --disable-libmpx \
    --disable-libquadmath \
    --disable-libssp \
    --disable-libsanitizer \
    --without-headers \
    --with-newlib \
    --disable-bootstrap \
    --enable-languages=c \
    --with-sysroot="/opt/x86_64-linux-gnu/x86_64-linux-gnu/sys-root" \
    ${GCC_CONF_ARGS}
"""

main_configure = raw"""
../gcc-7.3.0/configure --prefix=/opt/x86_64-linux-gnu \
    --target=x86_64-linux-gnu \
    --host=x86_64-alpine-linux-musl \
    --build=x86_64-alpine-linux-musl \
    --disable-multilib \
    --disable-werror \
    --enable-languages=c,c++,fortran \
    --with-sysroot=/opt/x86_64-linux-gnu/x86_64-linux-gnu/sys-root \
    --enable-host-shared \
    --enable-threads=posix \
    LD=/opt/super_binutils/bin/
"""

# Bash recipe for building across all platforms
common_suffix = raw"""
make -j${nprocs}
DESTDIR=$WORKSPACE/destdir make install -j20
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:x86_64, :musl)
]

# The products that we will ensure are always built
products(prefix) = [
    ExecutableProduct(prefix, "", :xgcc)
]

# Dependencies that must be installed before this package can be built
dependencies = [
#    "https://github.com/staticfloat/GlibcBuilder/releases/download/v2.27-0/build_Glibc.v2.12.2.jl",
    "https://github.com/bicycle1885/ZlibBuilder/releases/download/v1.0.1/build_Zlib.v1.2.11.jl"
]

# Build a boostrap configure
bootstrap_script = """
$common_setup
$bootstrap_configure
$common_suffix
"""
bootstrap_path = joinpath(@__DIR__, "products", "gcc_boostrap.v7.3.0.x86_64-linux-gnu.tar.gz")
if !isfile(bootstrap_path)
    product_hashes = build_tarballs(ARGS, "gcc_boostrap", version, sources, bootstrap_script, platforms, products, dependencies)
    _, bootstrap_hash = product_hashes["x86_64-linux-gnu"]
else
    using SHA: sha256
    bootstrap_hash = open(bootstrap_path) do f
        bytes2hex(sha256(f))
    end
end

push!(sources, Ref("../GlibcBuilder/products/Glibc.v2.12.2.x86_64-linux-gnu.tar.gz" => "7d81df29ec9dfe858244b12a03eb4cc403da84637f458f6e12b6e482dace8d30"))

# Build the tarballs, and possibly a `build.jl` as well.
main_script = """
mkdir -p /opt/x86_64-linux-gnu
tar -C /opt/x86_64-linux-gnu -xvf Glibc.v2.12.2.x86_64-linux-gnu.tar.gz
$common_setup
$main_configure
$common_suffix
"""
build_tarballs(ARGS, "gcc", version, sources, main_script, platforms, products, dependencies)
