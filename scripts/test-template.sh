#!/bin/sh
set -eu

template="srcpkgs/wlsunset/template"
[ -s "$template" ] || {
    echo "Missing package template: $template" >&2
    exit 1
}

grep -Eq '^pkgname=wlsunset$' "$template"
grep -Eq '^version=[0-9]+\.[0-9]+\.[0-9]+$' "$template"
grep -Eq '^revision=[0-9]+$' "$template"
grep -Fq 'build_style=meson' "$template"
grep -Fq 'configure_args="-Doptimization=2 -Db_lto=true"' "$template"
grep -Fq 'hostmakedepends="scdoc pkg-config wayland-devel"' "$template"
grep -Fq 'makedepends="pkg-config wayland-devel wayland-protocols"' "$template"
grep -Fq 'archs="x86_64-musl"' "$template"
grep -Fq 'lib32disabled=yes' "$template"
grep -Fq 'CFLAGS+=" -O2 -march=skylake -mtune=skylake -fno-plt"' "$template"
grep -Fq 'https://git.sr.ht/~kennylevinsen/wlsunset/archive/${version}.tar.gz' "$template"
grep -Fq 'license="MIT"' "$template"
grep -Fq 'vlicense LICENSE' "$template"

checksum="$(sed -n 's/^checksum=//p' "$template")"
[ "${#checksum}" -eq 64 ] || {
    echo "Expected a 64-character source SHA-256 checksum." >&2
    exit 1
}
case "$checksum" in
    *[!0-9a-f]*|'')
        echo "Source checksum must be lowercase hexadecimal." >&2
        exit 1
        ;;
esac

if grep -Eq 'march=native|mtune=native|x86_64-glibc|aarch64|i686' "$template"; then
    echo "The package must remain x86_64-musl-only and Skylake-targeted." >&2
    exit 1
fi

echo "wlsunset x86_64-musl / Intel Skylake package checks passed"
