# Code Signing Policy — Mindful Key

This document describes how release binaries of **Mindful Key** are code-signed.
It is published as required by the [SignPath Foundation](https://signpath.org/)
free code-signing program for open-source projects.

## Project

- **Name:** Mindful Key (`mindful-key`)
- **Repository:** <https://github.com/theminh207/mindful-key> (public)
- **License:** GPL-3.0 — a fork of the **OpenKey** Vietnamese input method by
  Mai Vũ Tuyên; the original author's copyright and credit are preserved.
- **Website:** <https://key.bketech.xyz>
- **What it is:** a free, open-source Vietnamese input method (Telex/VNI) for
  Windows and macOS, with an on-device mindfulness layer. All typing analysis
  happens locally on the user's machine — no typed content ever leaves the device.

## What is signed

The Windows release artifacts produced by our CI:

- `MindfulKey_<version>_x64-setup.exe` — the Windows x64 installer (built with
  Inno Setup).
- `MindfulKey.exe` — the application executable bundled inside that installer.

macOS builds are signed separately with Apple's toolchain and are out of scope
for SignPath.

## Build and signing process

1. A maintainer pushes a version tag (`v*`) to the public repository.
2. GitHub Actions (`.github/workflows/release.yml`) builds the Windows binaries
   on a GitHub-hosted `windows-latest` runner (MSVC v143), directly from the
   tagged public source. Every build is traceable to a specific public commit.
3. The unsigned installer is submitted to SignPath.io for signing via the
   official SignPath GitHub Action. A signing request must be **approved** before
   a signature is issued.
4. SignPath returns the signed artifact, which is then published on the project's
   [GitHub Releases](https://github.com/theminh207/mindful-key/releases) page and
   mirrored on the website.

No signing keys or certificates are stored in the repository or on any developer
machine; signing is performed entirely on the SignPath platform.

## Roles

Mindful Key is currently maintained by a single maintainer, who therefore holds
all three roles. If the team grows, this policy will be updated.

- **Authors** — write and modify the source code: the project maintainer
  ([@theminh207](https://github.com/theminh207)) and any future contributors
  whose pull requests are reviewed and merged.
- **Reviewers** — review external contributions before they are merged: the
  maintainer.
- **Approvers** — authorize each individual signing request in SignPath: the
  maintainer.

All accounts used for the repository and for SignPath have multi-factor
authentication (MFA) enabled.

## Privacy

- **The application** performs all Vietnamese-input and mindfulness processing on
  the user's device. No typed content, and no derived emotional data, is ever
  transmitted off the device. See the
  [Privacy Note](https://github.com/theminh207/mindful-key/blob/main/docs/PRIVACY-NOTE.md).
- **The signing process** only ever handles the compiled, unsigned binaries built
  from public source code. No end-user data is involved in signing.

## Contact

- Maintainer: **theminh207**
- Email: **app365@gnh.edu.vn**
- Issues: <https://github.com/theminh207/mindful-key/issues>
