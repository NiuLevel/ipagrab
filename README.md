# ipagrab

`ipagrab` is a tiny tool to quickly download an IPA of an app you own from the App Store on macOS. Run it locally and privately, with no auth, no credentials, no tokens, no API calls. 

---

## ipatool or iMazing not working?

You're not alone. Many users are running into these lately:

**ipatool**
- `download` fails with `something went wrong` or `invalid response`
- Auth returns `ERR error="something went wrong" success=false`
- 2FA code never arrives, or fails after entry (`MZFinance.BadLogin.Configurator_message`)
- `list-versions` returns `FailureType: 5002` or "An unknown error has occurred"
- HTTP 200 but `Items: []` or `Items: null` — empty response
- Downloads stall at `0%` then die with `unknown error`
- HTTP 429 rate limiting (`mzauth|global|all`)
- Apple changed the login endpoint — ipatool auth is broken for many accounts

**iMazing**
- The IPA download button is greyed out and can't be clicked

These are Apple-side restrictions that third-party tools can't easily work around. `ipagrab` lets Apple Configurator (Apple's own app) handle the download, then instantly saves the `.ipa` to your Desktop. No credentials exposed to any third-party tool, no broken API calls.

---

## Install

**Step 1 — Open Terminal.**
Press `Command + Space`, type `Terminal`, press Enter.

**Step 2 — Paste this and press Enter:**

```sh
git clone https://github.com/NiuLevel/ipagrab.git && cd ipagrab && ./install.sh
```

**Step 3 — Open a new Terminal window.** You can now type `ipagrab` to launch.

> Don't want to install? Just run `./ipagrab` from the folder.

To uninstall: `cd ipagrab && ./install.sh uninstall`

---

## Requirements

- A **Mac**
- **Apple Configurator** — free on the Mac App Store:
  <https://apps.apple.com/app/apple-configurator/id1037126344>
- An **iPhone or iPad** connected via **USB** (Configurator needs a device to trigger the download)
- Signed into Apple Configurator with the Apple ID that owns the app
  (*Configurator menu bar → Account → Sign In…*)

---

## How to use it

1. Open **Apple Configurator** and sign in.
2. Connect your iPhone/iPad via USB → unlock it → tap **Trust This Computer**.
3. In Terminal, start the watcher **before** you download:
   ```sh
   ipagrab
   ```
   Select **GO!** with arrow keys and press Enter.
4. In Apple Configurator: select your device → **Add → Apps…** → find the app → **Add**.
5. When you see:
   ```
   ▓▒░ ✔ GRABBED ░▒▓
      153045_AppName.ipa  (84231234 bytes)
   📂 Reminder: your .ipa is on the Desktop
   ```
   the `.ipa` is on your Desktop.
6. Press **`S`** or pick **EXIT** from the menu to stop.

**Tip:** If the app is already on the device, Configurator will show a *"replace existing app?"* prompt. Leave it open — the `.ipa` stays in the cache the whole time, so `ipagrab` has plenty of time to copy it. Cancel the prompt once you see `✔ GRABBED`.

---

## What it actually does

`ipagrab` is a ~130-line bash script. It does **not** download anything, talk to Apple, or touch your credentials. It watches one folder on your Mac — Apple Configurator's temp download cache — and the moment a `.ipa` appears, it copies it to your Desktop before Configurator deletes it.

> **Whatever Apple Configurator downloads, `ipagrab` saves.**

Cache folder watched:
`~/Library/Group Containers/K36BKF7T3D.group.com.apple.configurator/Library/Caches/Assets/TemporaryItems/MobileApps`

---

## Limitations

- **You can only get apps your Apple ID owns.** If Configurator won't download it, there's nothing to grab.
- **Downloading on the phone itself does NOT work.** The download must be driven by Apple Configurator on the Mac.
- **The `.ipa` is FairPlay-encrypted.** Fine for archiving and sideloading back onto your own devices. Decryption requires a separate process on a jailbroken device.
- **Start `ipagrab` before clicking Add** — it only catches files that appear while it's running.

---

## Troubleshooting

- **Nothing grabbed:** make sure the watcher was on **GO!** *before* you clicked Add, and that Configurator actually started downloading (you'll see a progress bar in Configurator). Retry.
- **Watching forever:** the cache folder is only created after Configurator has downloaded at least one app. The path is printed at startup — check that it exists.
- **App missing from the Add list:** use the search box. Delisted apps you own may be hidden — search by exact name.

---

## Configuration (optional)

Override the cache path or destination with environment variables:

```sh
IPAGRAB_CACHE=/path/to/cache IPAGRAB_DEST=/path/to/dest ipagrab
```

Defaults: Configurator's cache folder and `~/Desktop`.

---

## ⚠️ Responsible use & disclaimer

`ipagrab` is a personal backup/archive tool only. By using it you agree to:

- Only grab apps you legitimately own with your own Apple ID.
- Not distribute the `.ipa` files it saves.
- Not decrypt them or strip their DRM.

This tool is provided **"as is", without warranty of any kind** (see [LICENSE](LICENSE)). You are solely responsible for how you use it and for complying with all applicable laws and Apple's terms of service. The author accepts no liability for any misuse, damages, or legal consequences.
