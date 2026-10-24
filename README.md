# multiACE for Snapmaker U1 — Install Kit / Bộ cài multiACE cho Snapmaker U1

An install kit that packages a verified multiACE setup for the **Snapmaker U1 (stock firmware)** with an **Anycubic ACE Pro / ACE Pro 2**: 4-color printing, dryer control and Bambu spool-tag reading — installed and tested stable on a real machine (U1 stock firmware 2.0.0.205 + one ACE Pro 2).

Bộ cài đóng gói quy trình multiACE đã cài và kiểm chứng ổn định trên máy thật: **Snapmaker U1 (firmware stock)** + **Anycubic ACE Pro / ACE Pro 2** — in 4 màu, sấy, đọc tem cuộn Bambu (U1 firmware stock 2.0.0.205 + 1 bộ ACE Pro 2).

## Guides / Hướng dẫn

- 🇻🇳 Tiếng Việt: [HUONG-DAN.md](HUONG-DAN.md) — script: [cai-multiace.sh](cai-multiace.sh)
- 🇬🇧 English: [GUIDE-EN.md](GUIDE-EN.md) — script: [cai-multiace-en.sh](cai-multiace-en.sh)

Also readable as web pages: https://khuong.cloud/ace/ (Tiếng Việt) · https://khuong.cloud/ace/en.html (English)

## What this is / Đây là gì

[multiACE](https://github.com/decay71/multiACE) by decay71 is the bridge that lets a stock-firmware U1 drive an ACE Pro. This kit wraps its installation in a checked, reversible flow (pre-flight checks, backups, verification, rollback notes) and documents the real-world details that cost us evenings: PTFE tube-length formulas for load/retract, two-sided Bambu spool tags, auto-dry behaviour, and a troubleshooting table built from real failures.

multiACE của decay71 là cầu nối để U1 firmware stock điều khiển ACE Pro. Bộ cài này bọc quá trình cài trong một quy trình có kiểm tra và có đường lui (tiền kiểm, sao lưu, xác minh, hướng dẫn gỡ), và ghi lại những chi tiết thực tế tốn nhiều buổi tối mới rút ra được: công thức độ dài ống PTFE cho load/retract, tem cuộn Bambu hai mặt, hành vi sấy tự động, và bảng tra lỗi từ các sự cố thật.

## Related / Liên quan

- Optional CYD 2.8" display with an ACE control panel (an add-on — the printer works without it): https://github.com/khuonguyenhcm-bit/CYD-U1 · web flasher at https://khuong.cloud
- Màn hình CYD 2.8" tuỳ chọn có panel điều khiển ACE (addon — máy in chạy tốt khi không có): https://github.com/khuonguyenhcm-bit/CYD-U1 · trang nạp tại https://khuong.cloud

## Credits / Ghi công

- [decay71/multiACE](https://github.com/decay71/multiACE) — the bridge itself
- ACE2-Open — the open ACE Pro 2 firmware referenced by the guide

Verified on exactly one machine (the author's). Your mileage may vary — read the guide's pre-flight section first.
Đã kiểm chứng trên đúng một máy (của tác giả). Máy khác có thể khác — đọc kỹ mục tiền kiểm trong hướng dẫn trước khi cài.
