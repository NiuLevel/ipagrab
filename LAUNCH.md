# Launch material

These are drafts only. Review them against the tagged commit before publishing.

## GitHub description

Save complete, validated IPAs from Apple Configurator's temporary cache on macOS.

## Suggested topics

`apple-configurator`, `ipa`, `ios`, `macos`, `app-archiving`, `shell-script`

## Proposed v0.1.0 release notes

`ipagrab` saves the IPA that Apple Configurator downloads to its temporary Mac cache before Configurator removes it.

### Included

- Watches for a new or changed IPA instead of copying an unchanged cache entry.
- Validates the ZIP archive before and after copying without letting an incomplete candidate block later downloads.
- Saves to the Desktop by default and adds a numeric suffix instead of overwriting a collision.
- Provides an interactive terminal watcher, concise `--help`, and clear preflight errors.
- Installs through a guarded symlink and removes only a link to the same checkout.
- Includes framework-free shell tests and a macOS GitHub Actions workflow.

### Requirements and limits

- Requires macOS, Apple Configurator, and an unlocked, trusted iPhone or iPad connected by USB.
- Configurator must be signed in with the Apple ID that owns the app and must offer the app for download.
- Saved IPAs remain FairPlay-encrypted; `ipagrab` does not decrypt, resign, or remove DRM.
- `ipagrab` does not download from Apple or read account credentials. It only copies Configurator's local cache.
- Automated tests cover archive validation, stale files, collisions, preflight errors, and installer safety with temporary fixtures. Real Apple Configurator and device testing has not been performed as part of this release preparation.
