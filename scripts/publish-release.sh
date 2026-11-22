#!/bin/sh
set -eu

dist=${1:-dist}
: "${GH_TOKEN:?GH_TOKEN is required}"
: "${GH_REPO:?GH_REPO is required}"
: "${VERSION:?VERSION is required}"
: "${REVISION:?REVISION is required}"
: "${TAG:?TAG is required}"
: "${RELEASE_COMMIT:?RELEASE_COMMIT is required}"

printf '%s\n' "$VERSION" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' || {
    echo "Invalid package version: $VERSION" >&2
    exit 1
}
case "$REVISION" in
    ''|*[!0-9]*) echo "Invalid package revision: $REVISION" >&2; exit 1 ;;
esac
case "$RELEASE_COMMIT" in
    *[!0-9a-f]*|'') echo "Invalid release commit SHA." >&2; exit 1 ;;
esac
[ "${#RELEASE_COMMIT}" -eq 40 ] || {
    echo "Release commit must be a 40-character SHA." >&2
    exit 1
}

expected_tag="${VERSION}_${REVISION}"
[ "$TAG" = "$expected_tag" ] || {
    echo "Unexpected tag: $TAG (expected $expected_tag)" >&2
    exit 1
}

package_name="wlsunset-${VERSION}_${REVISION}.x86_64-musl.xbps"
package_path="$dist/$package_name"
[ -s "$package_path" ] || {
    echo "Expected package was not found: $package_path" >&2
    exit 1
}

notes="Automated Void Linux XBPS package release for wlsunset ${VERSION} (revision ${REVISION}).

Target:
- Void Linux x86_64-musl
- Intel Skylake instruction set (-O2 -march=skylake -mtune=skylake -fno-plt)
- Reference processor: Intel Core i3-6100U

Packaging:
- Upstream source: https://sr.ht/~kennylevinsen/wlsunset/
- Void Linux recipe baseline: https://github.com/void-linux/void-packages/tree/master/srcpkgs/wlsunset
- Build system: Meson (optimization level 2, LTO enabled)
- Wayland client and wayland-protocols support
- Package asset: $package_name

This is a hardware-specific standalone XBPS package, not a signed, indexed XBPS repository. It is not intended for pre-Skylake CPUs, glibc systems, or other architectures."

if gh release view "$TAG" --repo "$GH_REPO" >/dev/null 2>&1; then
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT HUP INT TERM
    if ! gh release download "$TAG" --repo "$GH_REPO" --pattern "$package_name" --dir "$tmp"; then
        echo "Release $TAG exists but its expected package asset could not be downloaded; refusing to modify it." >&2
        exit 1
    fi
    if [ ! -s "$tmp/$package_name" ] || ! cmp -s "$package_path" "$tmp/$package_name"; then
        echo "Release $TAG already contains different package bytes." >&2
        echo "Increment revision in srcpkgs/wlsunset/template before publishing changed output." >&2
        exit 1
    fi
    echo "Release $TAG already contains the identical package."
else
    gh release create "$TAG" "$package_path" --repo "$GH_REPO" \
        --title "wlsunset ${VERSION}-${REVISION} (x86_64-musl / Skylake)" \
        --notes "$notes" --target "$RELEASE_COMMIT"
fi

release_url="$(gh release view "$TAG" --repo "$GH_REPO" --json url --jq .url)"
published_assets="$(gh release view "$TAG" --repo "$GH_REPO" --json assets --jq '.assets[].name')"
printf '%s\n' "$published_assets" | grep -Fxq "$package_name" || {
    echo "Published release is missing the package asset $package_name." >&2
    exit 1
}

{
    echo "## wlsunset release published"
    echo
    echo "- Release: [$TAG]($release_url)"
    echo "- Package: $package_name"
    echo "- Target: x86_64-musl / Intel Skylake"
} >> "${GITHUB_STEP_SUMMARY:-/dev/null}"
