# ipagrab

A tiny macOS helper that grabs `.ipa` files out of **Apple Configurator 2**'s
temporary download cache and saves them to your Desktop — before Configurator
deletes them.

It works for **any app your Apple ID owns** (free or previously purchased,
including apps that have since been removed from the App Store). There is
nothing app-specific in it.

---

## What it actually does

`ipagrab` is a ~130-line bash script. It is **not** a downloader and it does
**not** talk to Apple, the network, or your phone. All it does is:

1. Watch one folder on your Mac — Apple Configurator's temp cache:
   `~/Library/Group Containers/K36BKF7T3D.group.com.apple.configurator/Library/Caches/Assets/TemporaryItems/MobileApps`
2. The instant a `.ipa` appears there, wait for it to finish downloading
   (its size has to stop changing), then copy **one** complete, verified copy
   to `~/Desktop` (named `HHMMSS_<AppName>.ipa`) before Configurator removes it.

The actual *download* is done by **Apple Configurator**. `ipagrab` just wins the
race to copy the file. So the rule is simple:

> **Whatever Apple Configurator downloads, `ipagrab` saves.**

---

## The interface

Running `ipagrab` opens a small terminal UI:

```
  ██╗██████╗  █████╗  ██████╗ ██████╗  █████╗ ██████╗
  ██║██╔══██╗██╔══██╗██╔════╝ ██╔══██╗██╔══██╗██╔══██╗
  ██║██████╔╝███████║██║  ███╗██████╔╝███████║██████╔╝
  ██║██╔═══╝ ██╔══██║██║   ██║██╔══██╗██╔══██║██╔══██╗
  ██║██║     ██║  ██║╚██████╔╝██║  ██║██║  ██║██████╔╝
  ╚═╝╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝
       ▓▒░ Apple Configurator .ipa grabber ░▒▓

READY?  (Up/Down to choose, Enter to confirm)
    1. GO!
    2. EXIT
```

- **GO!** starts watching — a scrolling rainbow wave animates with an elapsed
  timer while it scans. Press **`S`** (or `Q` / `Esc`) at any time to **STOP**
  and return to the menu.
- When it grabs a file you get a `✔ GRABBED` confirmation, the saved path, and a
  reminder that the `.ipa` is on your Desktop — then it loops back to the menu.
- **EXIT** quits.

---

## Requirements

- A Mac (this uses macOS-only paths).
- **Apple Configurator 2** — free from the Mac App Store:
  <https://apps.apple.com/app/apple-configurator/id1037126344>
- An **iPhone or iPad** you can connect by **USB** (Configurator only downloads
  apps while adding them to a connected device).
- You must be **signed into Apple Configurator** with the Apple ID that
  **owns the app** (Configurator menu bar → *Account → Sign In…*).

---

## How to use it

1. **Open Apple Configurator** and sign in with the owning Apple ID.
2. **Connect your iPhone/iPad** via USB → unlock it → tap **Trust This Computer**.
3. **Start the watcher** in Terminal *before* you download anything:
   ```sh
   ~/ipagrab/ipagrab
   ```
   Pick **GO!** with the arrow keys + Enter. The wave starts and it watches.
4. In Apple Configurator: select your device → **Add → Apps…**
   (toolbar `+`, or right-click the device) → pick the app you want → **Add**.
5. Watch the Terminal. When you see:
   ```
   ▓▒░ ✔ GRABBED ░▒▓
      153045_AppName.ipa  (84231234 bytes)
   📂 Reminder: your .ipa is on the Desktop →  /Users/<you>/Desktop
   ```
   the `.ipa` is safely on your Desktop.
6. Back at the menu, pick **EXIT** (or press **`S`** during the wave) to stop.

### Tip: apps already installed on the device
If the app is **already installed** on the connected device, Configurator shows
a *"replace existing app?"* prompt. **Leave that prompt open** — the `.ipa` stays
in the cache the whole time it's showing, giving `ipagrab` an easy, unhurried
catch. Cancel the prompt once you've seen `✔ GRABBED`.

---

## Limitations (read these)

- **You can only get apps your Apple ID owns.** `ipagrab` can't conjure apps you
  haven't acquired — Configurator won't download those, so there's nothing to grab.
- **Downloading on the phone itself does NOT work.** If you install an app from
  *Purchased* directly on the iPhone, the app stays on the phone and **no `.ipa`
  is created on the Mac**. The download must be driven by **Apple Configurator on
  the Mac**.
- **The `.ipa` is encrypted** (App Store FairPlay DRM). That's fine for archiving
  and for sideloading back onto *your own* Apple ID's devices. For binary analysis
  you'd need to decrypt it on a jailbroken device (separate process).
- **Start `ipagrab` (and pick GO!) before** clicking *Add*, and keep it running —
  it polls a few times a second and only copies files that exist while it's running.

---

## Troubleshooting

- **Nothing gets grabbed:** make sure the watcher was running (on **GO!**) *before*
  you hit *Add*, and that Configurator actually started downloading (you'll see
  progress in Configurator). STOP, pick **GO!** again, and retry.
- **Watching forever:** confirm the cache folder exists — it's only created after
  Configurator has downloaded at least one app. The path is printed when the
  script starts.
- **App not in the Add-Apps list:** use the search box in that sheet. Removed/
  delisted apps you own are sometimes hidden — search by name. If it's truly
  absent, Configurator can't fetch it.

---

## Make it a global command (optional)

To run it from anywhere as just `ipagrab`:
```sh
# Apple Silicon (Homebrew):
ln -s ~/ipagrab/ipagrab /opt/homebrew/bin/ipagrab
# or Intel / system:
sudo ln -s ~/ipagrab/ipagrab /usr/local/bin/ipagrab
# then simply:
ipagrab
```

## Configuration (optional)

The watched cache and destination can be overridden with environment variables
(handy for testing):

```sh
IPAGRAB_CACHE=/path/to/cache IPAGRAB_DEST=/path/to/dest ipagrab
```

Defaults: Configurator's cache folder and `~/Desktop`.
