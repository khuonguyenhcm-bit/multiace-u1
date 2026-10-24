# Installing multiACE on a Snapmaker U1 (stock firmware) with an Anycubic ACE Pro / ACE Pro 2

This kit packages a process that was installed and verified stable on a real machine:
Snapmaker U1 (stock firmware 2.0.0.205) + one Anycubic ACE Pro 2 — 4-color printing,
drying, and Bambu spool tag reading all working.
Works with both the **ACE Pro (gen 1)** and the **ACE Pro 2** — differences are called out where they matter.

### Supported setups

- **One ACE straight into 4 toolheads:** the ACE's 4 filaments feed the 4 extruders (slot i → head i).
  This is the configuration verified on the real machine.
- **One ACE + the U1's stock feeders:** **8 filaments** in the system —
  every toolhead has two possible sources: its stock feeder or one ACE slot.
- **Up to 4 ACE units: 16 filaments (16 colors)** — each ACE unit feeds all 4 of its filaments
  into **one extruder** (4 filaments → 1 toolhead); 4 units cover the U1's 4 toolheads.

> Beyond the first (tested) configuration, the other setups are multiACE capabilities
> per the upstream documentation — not yet verified on this machine.

> **Credits:** multiACE is by [decay71](https://github.com/decay71/multiACE); ACE2-Open firmware is community work.
> This kit is only a wrapper script + documentation written from a real install.
> Not affiliated with Snapmaker or Anycubic. Follow at your own risk.
> Verified on exactly one machine — small details may differ on yours.

---

## Read this first (2 minutes, for complete beginners)

- The whole process takes about **20–30 minutes**. You do **not** need to know
  how to code — you only copy and paste commands exactly as written.
- Three words you will keep seeing, in plain terms:
  - **Printer IP**: your U1's network address — find it under Settings → Network on the
    printer's screen (e.g. `192.168.1.12`). Everywhere this guide says `<printer-IP>`, type that address.
  - **SSH**: how your computer "talks" to the printer over the network. On a Mac, open the
    **Terminal** app; on Windows, open **PowerShell** — you type the commands there.
  - **Bundle**: the `multiace` folder downloaded from GitHub (link in section 0).
- How to read this guide: follow the steps **in order**, and after each step check the
  *"You should see"* line to know you are on track. If what you see is completely different,
  stop and jump to the **troubleshooting table** near the end.

## 0. What you need

**Hardware**
- Snapmaker U1 on stock firmware (tested: 2.0.0.205).
- Anycubic ACE Pro or ACE Pro 2 with its own power supply (the ACE runs on mains power, not on the printer).
- ACE ↔ U1 cable per the multiACE community cable guide (USB-to-Molex):
  connect **− / D− / D+ only** — the **VCC pin stays EMPTY**. Wiring VCC is wrong; don't.
- PTFE: the ACE feeds each toolhead directly. **No Y-splitters.**
  Measure your tube length — you will need it for calibration.

**Software**
- Way 1 needs no downloads at all: the script pulls multiACE v1.27b from decay71's GitHub on the printer itself — the printer just needs internet access, and your computer only needs `ssh`.
- Way 2 (by hand) is the one that needs the multiACE bundle downloaded first from https://github.com/decay71/multiACE, plus `scp` on your computer (built into macOS Terminal; Windows has them in PowerShell/Terminal too).

## 1. Enable Root Access on the U1

On the printer's touchscreen:

1. Settings → About → tap the firmware version **10 times** to unlock Advanced Mode.
2. Settings → Advanced Mode → turn on **Root Access**.
3. From your computer: `ssh root@<printer-IP>` — the vendor-published default root password is `snapmaker`.

> After a factory reset/clean, the first SSH may fail with a host-key error —
> run `ssh-keygen -R <printer-IP>` on your computer and try again.

## 2. Install — pick ONE of the two ways

Both ways end at the same result. **Way 1** is for people who want it quick;
**Way 2** is for people who want to see every command that goes into their machine.

### Way 1 — One line (recommended)

No files to download to your computer at all — the install script pulls multiACE from GitHub on the printer itself.

**Step 1.** SSH into the printer as in section 1: `ssh root@<printer-IP>` (password `snapmaker`).

*You should see:* the printer's command prompt — you are "inside" the printer. The printer needs internet access.

**Step 2.** Paste this **one line** and press Enter:

```bash
curl -fsSL https://raw.githubusercontent.com/khuonguyenhcm-bit/multiace-u1/main/cai-multiace-en.sh | bash
```

This line fetches this kit's install script from GitHub and runs it. The script then does everything else itself:
download the official **multiACE v1.27b** bundle from decay71's GitHub (with checksum verification) → extract
→ back up `printer.cfg` → create the `.debug` flag → run the upstream installer (config + Klipper module + Web UI)
→ create the `.fluidd` flag → verify every piece. Answer its questions with `y` + Enter.

*You should see:* the line **"SOFTWARE INSTALL COMPLETE"**, then the script asks whether
to reboot the printer now — answer `y`. Continue to section 3.

> To have the script ask nothing at all (auto-answer `y` to everything), use:
> `curl -fsSL https://raw.githubusercontent.com/khuonguyenhcm-bit/multiace-u1/main/cai-multiace-en.sh | bash -s -- --yes`

### Way 2 — By hand, command by command

**Step 1.** Copy the kit onto the printer (on your computer, in the folder containing `multiace`):

```bash
scp -r multiace root@<printer-IP>:/tmp/multiace
```

*You should see:* file-copy progress lines, with no red errors.

**Step 2.** Log in to the printer:

```bash
ssh root@<printer-IP>
```

Password: `snapmaker`. *You should see:* the prompt change to the printer's — you are now "inside" the printer.

**Step 3.** Create the debug flag (must exist **before** installing):

```bash
touch /oem/.debug
```

*You should see:* nothing at all — that is correct, this command prints nothing.

**Step 4.** Run the upstream multiACE installer:

```bash
bash /tmp/multiace/install_multiace.sh
```

*You should see:* many lines scroll by; a correct run ends with **"All files verified OK"**.

**Step 5.** Install the Web UI:

```bash
bash /tmp/multiace/install_multiace.sh --install-web
```

**Step 6.** Create the anti-config-loss flag — **the most important step, do not skip it:**

```bash
touch /oem/printer_data/.fluidd
```

Without this flag, every cold boot re-copies the stock `printer.cfg` over yours, dropping the
`[include extended/ace.cfg]` line and killing Klipper with
System Anomaly **0003-0522-0000-0002**. With the flag, cold boots are safe.

**Step 7.** Reboot the printer:

```bash
reboot
```

Continue to section 3.

## 3. Reboot and verify

1. Plug the ACE's USB cable into the printer and power the ACE on.
2. Reboot the printer.
3. Open Fluidd (`http://<printer-IP>`) → Console → run **`ACEG__Status`**.
   Pass criteria: **bundle MATCH** and the ACE (Pro / Pro 2) reported **ACTIVE**.

## 4. ACE firmware (ACE2-Open)

multiACE expects the ACE2-Open firmware inside the ACE (tested version: **V1.1.60O**).
That version number is for the **ACE Pro 2** — the gen-1 ACE Pro uses its own corresponding
Open build; check the firmware section of the multiACE README and **never flash one model's file into the other**.

- Check the current version in the Web UI: `http://<printer-IP>/multiace`.
- If the ACE is on low stock firmware (e.g. 1.1.26 / 1.1.31), flash ACE2-Open through that
  same Web UI — the file and download link live in the README of the multiACE repo; follow it exactly.
- If a flash hangs or fails: **power-cycle the ACE** and flash again. Don't panic.
- This firmware lives inside the ACE — a printer factory reset does not touch it.

## 5. First run + load/retract calibration

1. Run the macro **`ACEC__Unload_All`** once before first use.
2. Calibrate in `ace.cfg` (Fluidd → Configuration → `extended/ace.cfg`):
   - Verified starting point on a machine with **1800 mm** tubes: `load_length: 1980`, `retract_length: 2250`, `feed_speed: 80`.
   - Formula for your tubes: **load ≈ tube length + 180**, **retract ≈ load + 270**.
     Treat these as a starting point, not gospel — adjust to your machine.
   - Test: load a head, then unload — the filament tip should stop about **5 cm short of the ACE outlet**.
     Tip pulled too far in → reduce retract. Tip sticking out too far → increase retract. Adjust in ±20 mm steps.
3. Do a 2-color test print first; go 4 colors once that is stable.

## 6. Spools & RFID tags (especially Bambu spools)

- Insert a spool → Web UI → Spools tab → assign it to the slot.
  Genuine Bambu spools decode instantly (type, color, temps) on insert.
- **A Bambu spool carries TWO RFID chips — one per core face — each with a different chip UID.**
  multiACE identifies a spool by chip UID, so flipping the spool makes it look like a stranger.
  Fix: insert face A → assign the spool; flip to face B → open the same spool record and
  **add face B's UID to the same `sku` field, comma-separated**. The spool is then recognized from either face.
  This is a one-time manual step per spool.
- A reader can occasionally **cross-read the neighboring slot's tag** — if a spool looks
  misidentified, test spools one at a time (solo insert) to pin down the real tag.
- If a tag won't decode at all (UID only, no data): stick an **NTAG215** sticker with OpenSpool
  data on the core (e.g. written with the Tag My Spool phone app), one per face, same data.
  Do **not** buy Prusa OpenPrintTag stickers — different radio family (ISO 15693), the ACE can't read them.

## 7. Drying

- Defaults in `ace.cfg`: 55 °C / 240 min. The ACE 2 Pro's config temperature cap is 70 °C.
- Start/stop drying from the Web UI or Fluidd macros (`ACED__Dry_Start_0` / `ACED__Dry_Stop`).
- A drying cycle that has **started** runs on the ACE's own firmware (it has its own power supply) —
  turn the printer off mid-cycle and the ACE still finishes the programmed time.
- **Humidity auto-dry is different:** the monitoring brain lives in multiACE on the printer,
  so auto-dry only works while the **printer stays powered on** (sitting idle is fine).
  Note: humidity auto-dry exists only on the **ACE Pro 2** (it has the humidity sensor to decide);
  a gen-1 ACE Pro cannot measure — in multi-unit setups it can only FOLLOW a master unit's drying.
- The `dry_auto_roll` option (ACE Pro 2 only — the Rotisserie / Auto-roll indicators in the Web UI):
  **leave it OFF**, as shipped. The multiACE author warns the ACE's rotation routine is blind
  (a 5 mm reverse feed every ~4 min on every active slot, with no check for a threaded lane) —
  only enable it with all lanes empty. The two indicators are diagnostics, not buttons.

## 8. Survival rules

- **Before every Snapmaker OTA firmware update for the U1: uninstall multiACE first**, update, then reinstall
  (an update clears the printer's system-file layer — which is exactly where add-ons like multiACE live):
  ```bash
  bash /home/lava/printer_data/config/extended/multiace/uninstall_multiace.sh
  ```
- **After a printer factory reset:** recreate the flag `/oem/printer_data/.fluidd`
  **before the first reboot** (a reset deletes it).
- The yellow factory-style IP text on the touchscreen comes from the `/oem/.debug` flag:
  once everything is stable, `rm /oem/.debug` + reboot removes it.
  Recreate the flag before any future reinstall.
- Do not turn off the "automatic load" option on the printer's touchscreen.

## 9. Troubleshooting (every row is a real incident)

| Symptom | Cause | Fix |
|---|---|---|
| System Anomaly 0003-0522-0000-0002 after a power cycle | Cold boot overwrote `printer.cfg`, include line lost | `touch /oem/printer_data/.fluidd`, reboot. One-time rescue: re-add `[include extended/ace.cfg]` at the top of `printer.cfg` + FIRMWARE_RESTART |
| ACE stuck in `busy`, every operation times out | Serial session desynced | **Power-cycle the ACE first, then FIRMWARE_RESTART** in Fluidd (in that order) |
| Manual extrude (touchscreen/console) grinds and slips | No feed-assist exists for manual extrusion — by design, not a fault | Never hand-extrude an ACE-managed head; use the ACE Load/Unload cycle to move filament |
| Spool identified as the wrong spool | Reader cross-read the neighbor's tag | Solo-insert test; fix the assignment in the Web UI Spools tab |
| Spool unrecognized after flipping it | Each core face is a different chip UID | Add the other face's UID to the same spool's `sku` (comma-separated) |
| Spool shows no filament data on insert | Tag doesn't decode; full data may only appear at Load | Try one Load; if still blank, enter the profile manually or add an NTAG215/OpenSpool sticker |
| ACE firmware flash hangs | ACE stuck in a bad state | Power-cycle the ACE, flash again via the Web UI |
| SSH gone / printer vanished from the network after system tinkering | On stock firmware, SSH is started by the stock screen at boot while Root Access is on; a system-layer problem can take both SSH and WiFi down | Plug a **USB-Ethernet adapter** into the printer — it auto-configures a wired IP from your router → SSH in over the wired IP to uninstall/reinstall (U1 platform rescue trick, referenced from the HelixScreen community) |

## 10. Uninstall / rollback

```bash
bash /home/lava/printer_data/config/extended/multiace/uninstall_multiace.sh
```

Reboot afterwards. The installer script saved your original `printer.cfg` as
`printer.cfg.bak-multiace-*` next to the original, if you ever need it back by hand.

---

*Draft — packaged from a real install on one U1 + ACE 2 Pro, October 2026.*
*Bug reports and improvements: upstream to decay71's multiACE repo, or to this kit's home page.*
