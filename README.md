# wlsunset for Void Linux (x86_64-musl / Intel Skylake)

A hardware-specific Void Linux XBPS package for [wlsunset](https://sr.ht/~kennylevinsen/wlsunset/), targeting **x86_64-musl** and Intel Skylake. The reference processor is the Intel Core i3-6100U.

This repository packages upstream wlsunset; it does not fork or patch the application source. The package recipe follows Void Linux's [`srcpkgs/wlsunset/template`](https://github.com/void-linux/void-packages/tree/master/srcpkgs/wlsunset).

## Target and compatibility

- Void Linux XBPS target: `x86_64-musl` only.
- CPU target: Intel Skylake (`-O2 -march=skylake -mtune=skylake -fno-plt`).
- Reference processor: Intel Core i3-6100U.
- C library: musl.
- Build system: Meson.

This is not a generic x86_64 binary. Skylake compiler flags may emit instructions unsupported by older x86_64 processors. It is not intended for pre-Skylake CPUs, glibc systems, or other architectures. The target CPU flags are set by the package recipe; the GitHub Actions runner is only the build host and does not determine the generated instruction set.

wlsunset adjusts display gamma through the Wayland `wlr-gamma-control-unstable-v1` protocol. Whether it can control a display depends on the active Wayland compositor exposing that protocol; the Intel GPU model alone does not guarantee compositor support. No GPU-specific compiler flags or source patches are used.

## Package source and build

- Upstream release: **0.4.0**.
- Source archive: `https://git.sr.ht/~kennylevinsen/wlsunset/archive/0.4.0.tar.gz`.
- SHA-256: `a86ffb1793fe622802ec25795b69df864715986ecc175f7734e739c9e264ed72`.
- License: MIT.
- Build style: Meson, with optimization level 2.
- Build dependencies: `scdoc`, `pkg-config`, `wayland-devel`, and `wayland-protocols` (matching the Void package recipe).
- Compiler flags: `-O2 -march=skylake -mtune=skylake -fno-plt`.

`scdoc` generates the manual page. Wayland's scanner and protocol definitions are used to build the gamma-control client. The recipe keeps the upstream Meson configuration and does not add patches or unrelated runtime dependencies.

## Build and release

GitHub Actions builds the actual `.xbps` package through `xbps-src -A x86_64-musl`. The build runs on a GitHub-hosted runner; its CPU count controls build parallelism, while `-march=skylake` selects the target CPU architecture. A successful build from `main` publishes an immutable versioned GitHub Release containing:

```text
wlsunset-0.4.0_1.x86_64-musl.xbps
```

Download the package from [GitHub Releases](https://github.com/rnicro/wlsunset/releases). Install the downloaded package locally:

```sh
sudo xbps-install ./wlsunset-0.4.0_1.x86_64-musl.xbps
wlsunset -h
```

These are standalone XBPS package files, not a signed, indexed XBPS repository. The release workflow refuses to replace an existing package asset with different bytes; increment `revision` in `srcpkgs/wlsunset/template` whenever a packaging change alters the generated package.

## Build locally

On Void Linux, or on a compatible x86_64 glibc build host, clone both repositories and overlay this recipe into Void's source package tree:

```sh
git clone https://github.com/rnicro/wlsunset.git
git clone https://github.com/void-linux/void-packages.git

rm -rf void-packages/srcpkgs/wlsunset
cp -a wlsunset/srcpkgs/wlsunset void-packages/srcpkgs/

cd void-packages
./xbps-src -A x86_64-musl binary-bootstrap
./xbps-src -A x86_64-musl pkg wlsunset
```

The generated package is placed under `hostdir/binpkgs/`. Keep `-A x86_64-musl` on both commands when building the target ABI from a glibc host; do not replace the target CPU flags with `-march=native`.

Run the repository checks before pushing:

```sh
bash -n srcpkgs/wlsunset/template
sh -n scripts/publish-release.sh
sh -n scripts/test-template.sh
sh scripts/test-template.sh
```

## Maintenance

When updating wlsunset, verify the upstream release archive and its SHA-256, then update `version` and `checksum` in the package template. Start a new upstream version at revision 1; increment the revision for packaging-only changes that alter package output. Re-check Void's wlsunset recipe for dependency or musl compatibility changes, run the validation checks, and confirm the complete `./xbps-src -A x86_64-musl pkg wlsunset` build succeeds before publishing.

## References

- [wlsunset upstream](https://sr.ht/~kennylevinsen/wlsunset/)
- [wlsunset upstream source mirror](https://github.com/kennylevinsen/wlsunset)
- [Void Linux wlsunset package](https://github.com/void-linux/void-packages/tree/master/srcpkgs/wlsunset)
- [Void Linux musl build instructions](https://github.com/void-linux/void-packages#building-packages-natively-for-the-musl-c-library)
- [rnicro/linux](https://github.com/rnicro/linux), [rnicro/tofi](https://github.com/rnicro/tofi), [rnicro/brightnessctl](https://github.com/rnicro/brightnessctl), and [rnicro/aria2](https://github.com/rnicro/aria2), used as references for the x86_64-musl / Skylake package target and CI release workflow.
