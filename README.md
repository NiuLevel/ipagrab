# ipagrab

**Save the IPA Apple Configurator downloads—before it deletes it.**

Requires **macOS**, **Apple Configurator**, an **iPhone or iPad connected by USB**, and an **Apple ID that owns the app**. The saved IPA remains **FairPlay-encrypted**.

`ipagrab` does not download apps, call Apple services, bypass ownership, or read credentials. Apple Configurator performs the download; this shell script watches its local temporary cache and copies the completed IPA to your Mac.

## Requirements

- macOS
- [Apple Configurator](https://apps.apple.com/app/apple-configurator/id1037126344)
- An unlocked, trusted iPhone or iPad connected by USB
- Apple Configurator signed in with the Apple ID that owns the app
- Apple Configurator opened at least once, plus a writable destination folder

## Install

```sh
git clone https://github.com/NiuLevel/ipagrab.git
cd ipagrab
./install.sh
```

The installer creates an `ipagrab` symlink in a writable command directory. It will not replace an unrelated file or symlink. If its fallback directory is not on `PATH`, it prints the exact line to add.

Run without installing:

```sh
./ipagrab
```

Show command help without opening the interactive interface:

```sh
ipagrab --help
```

Uninstall from the same checkout:

```sh
./install.sh uninstall
```

Uninstall removes only a link that points to this checkout.

## Use

1. Open Apple Configurator and sign in.
2. Connect the device by USB, unlock it, and trust the Mac.
3. Run `ipagrab`. Confirm the displayed cache and destination, choose **GO!**, and leave the watcher running.
4. In Configurator, select the device, then choose **Add → Apps…**, find the app, and choose **Add**.
5. Wait for `GRABBED`. The validated IPA is now in the destination folder, and `ipagrab` returns to its menu.
6. Choose **EXIT**. To stop before a grab finishes, press `S`, `Q`, or Escape.

Start the watcher before choosing **Add**. Files already in the cache when watching starts are ignored unless Configurator changes them afterward.

Saved files use `HHMMSS_<original-name>.ipa`. If that name exists, `ipagrab` adds `_1`, `_2`, and so on instead of overwriting it.

The interface labels each state as `READY`, `WATCHING`, `VALIDATING`, `GRABBED`, `STOPPED`, or `ERROR`. A successful result shows the filename, readable and exact size, destination, and elapsed time.

## How it works

`ipagrab` watches this Configurator cache:

```text
~/Library/Group Containers/K36BKF7T3D.group.com.apple.configurator/Library/Caches/Assets/TemporaryItems/MobileApps
```

When watching starts, it records the IPAs already present. For each new or changed IPA, it verifies that the file is a complete, readable ZIP archive. Incomplete candidates are reconsidered when they change, without blocking other downloads. A valid candidate is copied through a temporary file, validated again, and published without overwriting an existing file.

Unlike tools that authenticate with App Store services themselves, `ipagrab` has no network or account integration. That keeps its role small, but also means it cannot work without Configurator, a connected device, and an eligible Apple account.

## Limitations

- Configurator must offer and download the app. `ipagrab` cannot obtain an app the signed-in Apple ID does not own.
- The download must be initiated in Configurator with a USB-connected device; downloading on the device does not enter this Mac cache.
- Saved IPAs remain FairPlay-encrypted. `ipagrab` does not decrypt, resign, or remove DRM.
- If Configurator has not created its download cache yet, `ipagrab` waits for it while you start the download.
- Only a new or changed IPA is grabbed; unchanged cache files are deliberately ignored.
- The interactive watcher requires a Terminal. `--help` remains available in non-interactive environments.
- Apple can change Configurator or its cache layout, which may require this project to change.

## Troubleshooting

- **Waiting for Configurator to create its cache:** leave `ipagrab` watching and start the app download in Configurator.
- **`Configurator cache does not exist`:** open Configurator once. If using `IPAGRAB_CACHE`, make sure that custom directory already exists.
- **Nothing is grabbed:** confirm the watcher says `WATCHING` before choosing **Add**, and confirm Configurator is actually downloading the app.
- **Destination error:** make sure the destination exists and is writable, or set `IPAGRAB_DEST` to another existing folder.
- **Installer refuses an existing path:** an unrelated `ipagrab` command is already there. Leave it untouched and run this checkout with `./ipagrab`, or resolve the conflict yourself.
- **App is missing in Configurator:** `ipagrab` cannot make Configurator offer an unavailable or ineligible app.

## Configuration

The defaults are Configurator's cache folder and `~/Desktop`. Override either for testing or a different destination:

```sh
IPAGRAB_CACHE=/path/to/cache IPAGRAB_DEST=/path/to/destination ipagrab
```

Custom cache and destination paths must be absolute, and those directories must already exist. The default Configurator cache may appear after watching starts. The cache must be readable and the destination writable.

Set `NO_COLOR=1` to disable optional ANSI colors:

```sh
NO_COLOR=1 ipagrab
```

## Responsible use

Use `ipagrab` only to archive apps you legitimately own. Do not distribute saved IPAs or use this project to bypass licensing, ownership, or DRM controls. You are responsible for complying with applicable laws and Apple's terms.

This project is provided as-is under the [MIT License](LICENSE).
