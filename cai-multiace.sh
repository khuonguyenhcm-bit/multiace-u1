#!/bin/bash
# ============================================================================
# cai-multiace.sh — Bộ cài multiACE cho Snapmaker U1 (firmware stock)
#
# Script này bọc lại quy trình cài multiACE của decay71 kèm các bước
# rất dễ sót đã được kiểm chứng trên máy thật:
#   1. Tạo cờ /oem/.debug TRƯỚC khi cài (điều kiện của bản firmware stock)
#   2. Chạy bộ cài gốc của multiACE (phần config + phần module Klipper)
#   3. Tạo cờ .fluidd — nếu thiếu, mỗi lần tắt/bật máy in sẽ tự chép đè
#      printer.cfg và làm mất dòng [include extended/ace.cfg]
#      (Klipper báo System Anomaly 0003-0522-0000-0002)
#   4. Kiểm tra sau cài + in sẵn lệnh gỡ (rollback)
#
# CÁCH DÙNG (chạy NGAY TRÊN máy in, qua SSH, bằng root) — chỉ một dòng:
#   curl -fsSL https://raw.githubusercontent.com/khuonguyenhcm-bit/multiace-u1/main/cai-multiace.sh | bash
# Script tự tải bundle multiACE v1.27b chính chủ từ GitHub của decay71
# (kèm kiểm tra checksum khi máy có sha256sum), giải nén vào /tmp/multiace
# rồi mới cài. Máy in cần có internet. Bỏ qua mọi câu hỏi xác nhận:
#   curl -fsSL <link trên> | bash -s -- --yes
# Cách thủ công: chép sẵn bundle vào máy in rồi chạy:
#   bash cai-multiace.sh /tmp/multiace
#
# Tác giả gốc: decay71 (multiACE) + cộng đồng ACE2-Open.
# Script đóng gói này chỉ tự động hoá các bước thủ công — dùng tự chịu trách nhiệm.
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
die()  { echo ""; echo "DỪNG: $*" >&2; exit 1; }

ask() {
  # ask "Câu hỏi?" — trả về 0 nếu đồng ý
  [ "$ASSUME_YES" = "1" ] && return 0
  printf "%s [y/N] " "$1"
  read -r ans </dev/tty
  case "$ans" in y|Y|yes|YES) return 0 ;; *) return 1 ;; esac
}

# ------------------------------------------------------- chuẩn bị bundle
# Chưa có bundle thì tự tải bản multiACE đã kiểm chứng (v1.27b) từ trang
# phát hành chính chủ của decay71 trên GitHub, kèm kiểm tra checksum.
MULTIACE_VER="1.27b"
TARBALL="multiace-${MULTIACE_VER}.tar.gz"
DL_URL="https://github.com/decay71/multiACE/releases/download/v${MULTIACE_VER}/${TARBALL}"

if [ ! -f "$BUNDLE/install_multiace.sh" ]; then
  say "Chưa có bundle multiACE — tải bản v${MULTIACE_VER} từ GitHub của decay71"
  command -v curl >/dev/null 2>&1 || die "Máy in không có curl — hãy dùng Cách 2 (làm tay) trong hướng dẫn."
  command -v tar >/dev/null 2>&1 || die "Máy in không có tar — hãy dùng Cách 2 (làm tay) trong hướng dẫn."
  WORK="$(mktemp -d)"
  curl -fL --retry 3 -o "$WORK/$TARBALL" "$DL_URL" || die "Tải bundle thất bại — kiểm tra internet của máy in rồi chạy lại."
  if command -v sha256sum >/dev/null 2>&1; then
    if curl -fsSL -o "$WORK/$TARBALL.sha256" "$DL_URL.sha256" && ( cd "$WORK" && sha256sum -c "$TARBALL.sha256" >/dev/null 2>&1 ); then
      echo "OK  checksum khớp với bản phát hành của decay71"
    else
      warn "Không kiểm chứng được checksum — vẫn tiếp tục, nhưng hãy cân nhắc."
    fi
  fi
  tar -xzf "$WORK/$TARBALL" -C "$WORK" || die "Giải nén bundle thất bại."
  [ -f "$WORK/multiace/install_multiace.sh" ] || die "Bundle tải về không có install_multiace.sh — cấu trúc bản phát hành có thể đã đổi; hãy dùng Cách 2 trong hướng dẫn."
  mkdir -p "$(dirname "$BUNDLE")"
  rm -rf "$BUNDLE"
  mv "$WORK/multiace" "$BUNDLE"
  rm -rf "$WORK"
  echo "OK  bundle đã sẵn sàng: $BUNDLE"
fi

# ---------------------------------------------------------------- tiền kiểm
say "Kiểm tra điều kiện / Preflight checks"

[ "$(id -u)" = "0" ] || die "Phải chạy bằng root. / Must run as root (SSH vào bằng tài khoản root của máy in)."

[ -n "$CFG" ] || die "Không thấy printer.cfg trong $PD1/config hay $PD2/config — đây có phải Snapmaker U1 không?"
echo "OK  printer.cfg: $CFG"

[ -f "$BUNDLE/install_multiace.sh" ] || die "Vẫn không thấy $BUNDLE/install_multiace.sh sau bước chuẩn bị bundle."
echo "OK  bundle multiACE: $BUNDLE"

if curl -s --max-time 5 http://127.0.0.1:7125/printer/info >/dev/null 2>&1; then
  echo "OK  Moonraker đang chạy"
  STATE=$(curl -s --max-time 5 "http://127.0.0.1:7125/printer/objects/query?print_stats" 2>/dev/null | grep -o '"state": "[a-z]*"' | head -1)
  case "$STATE" in
    *printing*|*paused*) warn "Máy in có vẻ đang bận ($STATE). Cài đặt cần khởi động lại Klipper — KHÔNG nên làm giữa bản in." ;;
  esac
else
  warn "Moonraker chưa trả lời ở 127.0.0.1:7125 — vẫn tiếp tục được, nhưng hãy chắc chắn máy in đang bật bình thường."
fi

ask "Bắt đầu cài multiACE? / Start installing multiACE?" || die "Đã huỷ theo yêu cầu."

# ------------------------------------------------------------------ sao lưu
say "Sao lưu printer.cfg / Backing up printer.cfg"
BK="$CFG.bak-multiace-$(date +%Y%m%d-%H%M%S)"
cp "$CFG" "$BK" && echo "OK  đã sao lưu: $BK"

# ------------------------------------------------------------- cờ .debug
say "Tạo cờ /oem/.debug (cần có TRƯỚC khi cài; hiệu lực từ lần khởi động tới)"
touch /oem/.debug && echo "OK  /oem/.debug"
echo "    Lưu ý: cờ này làm hiện dòng chữ IP màu vàng kiểu nhà máy trên màn hình cảm ứng."
echo "    Sau khi cài xong và mọi thứ ổn định, xoá cờ + khởi động lại là hết (xem hướng dẫn)."

# ------------------------------------------------------------- chạy bộ cài
say "Chạy bộ cài gốc của multiACE (phần config + module)"
bash "$BUNDLE/install_multiace.sh" || die "Bộ cài gốc báo lỗi — đọc kỹ dòng lỗi phía trên, KHÔNG chạy lại ngay; xem mục tra lỗi trong hướng dẫn."

say "Cài Web UI của multiACE"
bash "$BUNDLE/install_multiace.sh" --install-web || warn "Phần Web UI báo lỗi — phần lõi có thể đã xong; thử chạy lại riêng lệnh này sau."

# ------------------------------------------------- cờ .fluidd chống mất config
say "Tạo cờ .fluidd (chống việc boot lạnh chép đè printer.cfg làm mất dòng include)"
for d in "$PD1" "$PD2"; do
  [ -d "$d" ] && touch "$d/.fluidd" && echo "OK  $d/.fluidd"
done
echo "    Nhớ: nếu sau này factory reset máy in, phải tạo lại cờ này TRƯỚC lần khởi động đầu tiên."

# ----------------------------------------------------------------- kiểm tra
say "Kiểm tra sau cài / Verifying"
FAIL=0
if grep -q "include extended/ace.cfg" "$CFG"; then
  echo "OK  printer.cfg có [include extended/ace.cfg]"
else
  warn "printer.cfg CHƯA có dòng include — bộ cài có thể chưa hoàn tất."
  FAIL=1
fi
ACE_CFG_DIR=$(dirname "$CFG")/extended
[ -f "$ACE_CFG_DIR/ace.cfg" ] && echo "OK  ace.cfg tồn tại" || { warn "Chưa thấy $ACE_CFG_DIR/ace.cfg"; FAIL=1; }
if [ -f /home/lava/klipper/klippy/extras/ace.py ]; then
  echo "OK  module ace.py đã vào klippy/extras"
else
  warn "Chưa thấy module ace.py trong klippy/extras — Klipper sẽ báo lỗi 'Unknown config object ace'."
  FAIL=1
fi
[ "$FAIL" = "0" ] && echo "== CÀI ĐẶT HOÀN TẤT PHẦN MỀM ==" || warn "Còn mục chưa đạt — xem lại các dòng !! phía trên trước khi khởi động lại."

# --------------------------------------------------------------- bước tiếp
cat <<'EOF'

BƯỚC TIẾP THEO (làm theo thứ tự):
  1. Cắm cáp USB từ ACE vào máy in và cấp nguồn riêng cho ACE (nếu chưa cắm).
  2. Khởi động lại máy in.
  3. Mở Fluidd (http://<IP-may-in>) → Console → gõ:  ACEG__Status
     Kết quả đúng phải có: bundle MATCH và ACE Pro / ACE Pro 2 ... ACTIVE.
  4. Nếu firmware trong ACE chưa phải ACE2-Open (V1.1.60O):
     flash qua Web UI tại http://<IP-may-in>/multiace — xem hướng dẫn đi kèm.
  5. Lần dùng đầu tiên: chạy macro  ACEC__Unload_All  trước.
  6. Hiệu chỉnh load_length / retract_length theo chiều dài ống của bạn
     (công thức + cách thử trong hướng dẫn) trước khi in thật.

QUY TẮC SỐNG CÒN:
  * TRƯỚC mỗi lần Snapmaker tung bản cập nhật (OTA) cho U1: gỡ multiACE trước,
    cập nhật xong mới cài lại:
      bash /home/lava/printer_data/config/extended/multiace/uninstall_multiace.sh

GỠ CÀI ĐẶT (rollback):
  bash /home/lava/printer_data/config/extended/multiace/uninstall_multiace.sh
  (printer.cfg gốc còn ở bản sao lưu .bak-multiace-* cạnh file gốc nếu cần khôi phục tay)
EOF

ask "Khởi động lại máy in ngay bây giờ? / Reboot the printer now?" && { say "Đang khởi động lại…"; sync; reboot; }
echo "Đã xong phần script. Nếu chưa khởi động lại, nhớ khởi động lại máy in để hoàn tất."
