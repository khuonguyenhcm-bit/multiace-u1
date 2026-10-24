#!/bin/bash
# ============================================================================
# cai-multiace-en.sh — multiACE installer kit for Snapmaker U1 (stock firmware)
#
# This script wraps decay71's multiACE installer and adds the easy-to-miss
# steps that were verified on a real machine:
#   1. Create the /oem/.debug flag BEFORE installing (stock firmware needs it)
#   2. Run the upstream multiACE installer (config side + Klipper module side)
#   3. Create the .fluidd flag — without it, every cold boot re-copies the
#      stock printer.cfg and drops the [include extended/ace.cfg] line
#      (Klipper dies with System Anomaly 0003-0522-0000-0002)
#   4. Post-install verification + printed rollback instructions
#
# USAGE (run ON the printer, over SSH, as root) — a single line:
#   curl -fsSL https://raw.githubusercontent.com/khuonguyenhcm-bit/multiace-u1/main/cai-multiace-en.sh | bash
# The script downloads the verified multiACE v1.27b bundle straight from
# decay71's GitHub releases (with checksum verification when sha256sum is
# available), extracts it to /tmp/multiace, then installs. The printer
# needs internet access. To skip every confirmation prompt:
#   curl -fsSL <link above> | bash -s -- --yes
# Manual alternative: copy the bundle to the printer yourself, then run:
#   bash cai-multiace-en.sh /tmp/multiace
#
# Upstream author: decay71 (multiACE) + the ACE2-Open community.
# This wrapper only automates manual steps — use at your own risk.
# ============================================================================

set -u

BUNDLE="${1:-/tmp/multiace}"
ASSUME_YES=0
[ "${2:-}" = "--yes" ] && ASSUME_YES=1
[ "${1:-}" = "--yes" ] && { ASSUME_YES=1; BUNDLE="/tmp/multiace"; }

PD1="/home/lava/printer_data"
PD2="/oem/printer_data"
CFG=""
for d in "$PD1" "$PD2"; do
  [ -f "$d/config/printer.cfg" ] && CFG="$d/config/printer.cfg" && break
done

say()  { echo ""; echo "==> $*"; }
warn() { echo "!!  $*"; }
die()  { echo ""; echo "ABORT: $*" >&2; exit 1; }

ask() {
  # ask "Question?" — returns 0 on yes
  [ "$ASSUME_YES" = "1" ] && return 0
  printf "%s [y/N] " "$1"
  read -r ans </dev/tty
  case "$ans" in y|Y|yes|YES) return 0 ;; *) return 1 ;; esac
}

# ------------------------------------------------------- prepare bundle
# If the bundle is missing, download the verified multiACE release
# (v1.27b) from decay71's official GitHub releases, with checksum check.
MULTIACE_VER="1.27b"
TARBALL="multiace-v${MULTIACE_VER}.tar.gz"
DL_URL="https://github.com/decay71/multiACE/releases/download/v${MULTIACE_VER}/${TARBALL}"

if [ ! -f "$BUNDLE/install_multiace.sh" ]; then
  say "No multiACE bundle yet — downloading v${MULTIACE_VER} from decay71's GitHub"
  command -v curl >/dev/null 2>&1 || die "The printer has no curl — use Way 2 (by hand) in the guide."
  command -v tar >/dev/null 2>&1 || die "The printer has no tar — use Way 2 (by hand) in the guide."
  WORK="$(mktemp -d)"
  curl -fL --retry 3 -o "$WORK/$TARBALL" "$DL_URL" || die "Bundle download failed — check the printer's internet connection and re-run."
  if command -v sha256sum >/dev/null 2>&1; then
    if curl -fsSL -o "$WORK/$TARBALL.sha256" "$DL_URL.sha256" && ( cd "$WORK" && sha256sum -c "$TARBALL.sha256" >/dev/null 2>&1 ); then
      echo "OK  checksum matches decay71's release"
    else
      warn "Could not verify the checksum — continuing anyway, but be aware."
    fi
  fi
  tar -xzf "$WORK/$TARBALL" -C "$WORK" || die "Bundle extraction failed."
  [ -f "$WORK/multiace/install_multiace.sh" ] || die "The downloaded bundle has no install_multiace.sh — the release layout may have changed; use Way 2 in the guide."
  mkdir -p "$(dirname "$BUNDLE")"
  rm -rf "$BUNDLE"
  mv "$WORK/multiace" "$BUNDLE"
  rm -rf "$WORK"
  echo "OK  bundle ready: $BUNDLE"
fi

# --------------------------------------------------------------- preflight
say "Preflight checks"

[ "$(id -u)" = "0" ] || die "Must run as root (SSH in with the printer's root account)."

[ -n "$CFG" ] || die "printer.cfg not found under $PD1/config or $PD2/config — is this a Snapmaker U1?"
echo "OK  printer.cfg: $CFG"

[ -f "$BUNDLE/install_multiace.sh" ] || die "$BUNDLE/install_multiace.sh still not found after the bundle preparation step."
echo "OK  multiACE bundle: $BUNDLE"

if curl -s --max-time 5 http://127.0.0.1:7125/printer/info >/dev/null 2>&1; then
  echo "OK  Moonraker is up"
  STATE=$(curl -s --max-time 5 "http://127.0.0.1:7125/printer/objects/query?print_stats" 2>/dev/null | grep -o '"state": "[a-z]*"' | head -1)
  case "$STATE" in
    *printing*|*paused*) warn "The printer looks busy ($STATE). Installing restarts Klipper — do NOT do this mid-print." ;;
  esac
else
  warn "Moonraker did not answer on 127.0.0.1:7125 — continuing anyway, but make sure the printer is on and healthy."
fi

ask "Start installing multiACE?" || die "Cancelled by user."

# ------------------------------------------------------------------ backup
say "Backing up printer.cfg"
BK="$CFG.bak-multiace-$(date +%Y%m%d-%H%M%S)"
cp "$CFG" "$BK" && echo "OK  backup: $BK"

# -------------------------------------------------------------- .debug flag
say "Creating the /oem/.debug flag (must exist BEFORE installing; effective from next boot)"
touch /oem/.debug && echo "OK  /oem/.debug"
echo "    Note: this flag makes the touchscreen show the yellow factory-style IP overlay."
echo "    Once the install is verified stable, remove the flag + reboot to clear it (see the guide)."

# ------------------------------------------------------------- run installer
say "Running the upstream multiACE installer (config + module)"
bash "$BUNDLE/install_multiace.sh" || die "The upstream installer reported an error — read its output above carefully and do NOT just re-run; see the guide's troubleshooting section."

say "Installing the multiACE Web UI"
bash "$BUNDLE/install_multiace.sh" --install-web || warn "The Web UI part reported an error — the core may be fine; you can re-run just this step later."

# ------------------------------------------------- .fluidd cold-boot guard
say "Creating the .fluidd flag (stops cold boots from overwriting printer.cfg and losing the include line)"
for d in "$PD1" "$PD2"; do
  [ -d "$d" ] && touch "$d/.fluidd" && echo "OK  $d/.fluidd"
done
echo "    Remember: after any future factory reset, recreate this flag BEFORE the first reboot."

# ------------------------------------------------------------------ verify
say "Verifying"
FAIL=0
if grep -q "include extended/ace.cfg" "$CFG"; then
  echo "OK  printer.cfg has [include extended/ace.cfg]"
else
  warn "printer.cfg does NOT have the include line yet — the install may be incomplete."
  FAIL=1
fi
ACE_CFG_DIR=$(dirname "$CFG")/extended
[ -f "$ACE_CFG_DIR/ace.cfg" ] && echo "OK  ace.cfg exists" || { warn "$ACE_CFG_DIR/ace.cfg not found"; FAIL=1; }
if [ -f /home/lava/klipper/klippy/extras/ace.py ]; then
  echo "OK  ace.py module is in klippy/extras"
else
  warn "ace.py module not found in klippy/extras — Klipper will fail with 'Unknown config object ace'."
  FAIL=1
fi
[ "$FAIL" = "0" ] && echo "== SOFTWARE INSTALL COMPLETE ==" || warn "Some checks failed — review the !! lines above before rebooting."

# --------------------------------------------------------------- next steps
cat <<'EOF'

NEXT STEPS (in order):
  1. Plug the ACE's USB cable into the printer and power the ACE on (if not already).
  2. Reboot the printer.
  3. Open Fluidd (http://<printer-IP>) -> Console -> run:  ACEG__Status
     A good result shows: bundle MATCH and ACE Pro / ACE Pro 2 ... ACTIVE.
  4. If the ACE is not on ACE2-Open firmware (V1.1.60O) yet:
     flash it via the Web UI at http://<printer-IP>/multiace — see the guide.
  5. Before first use: run the macro  ACEC__Unload_All  once.
  6. Calibrate load_length / retract_length for YOUR tube length
     (formula + test method in the guide) before real prints.

SURVIVAL RULE:
  * Before EVERY Snapmaker OTA firmware update for the U1: uninstall multiACE
    first, update, then reinstall:
      bash /home/lava/printer_data/config/extended/multiace/uninstall_multiace.sh

UNINSTALL (rollback):
  bash /home/lava/printer_data/config/extended/multiace/uninstall_multiace.sh
  (your original printer.cfg is kept in the .bak-multiace-* backup next to it)
EOF

ask "Reboot the printer now?" && { say "Rebooting…"; sync; reboot; }
echo "Script done. If you did not reboot, remember to reboot the printer to finish."
