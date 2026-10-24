# Hướng dẫn cài multiACE cho Snapmaker U1 (firmware stock) + Anycubic ACE Pro / ACE Pro 2

Bộ cài này đóng gói lại quy trình đã được cài và kiểm chứng chạy ổn định trên máy thật:
Snapmaker U1 (firmware stock 2.0.0.205) + 1 bộ Anycubic ACE Pro 2, in 4 màu, sấy, nhận tem cuộn Bambu.
Dùng được cho cả **ACE Pro (bản 1)** và **ACE Pro 2** — chỗ nào hai bản khác nhau, hướng dẫn có ghi rõ.

> ⭐ **Điểm quan trọng nhất: bộ này chạy trên firmware STOCK của Snapmaker.**
> Không cần cài firmware tùy chỉnh, không thay thế hay "độ" firmware gốc của máy in.
> Mọi thứ thêm vào chỉ là cấu hình + module mà multiACE đặt lên hệ thống stock —
> và chỉ cần gỡ multiACE trước mỗi lần cập nhật OTA là máy in trở lại nguyên trạng như chưa từng cài.

### Các cấu hình multiACE hỗ trợ

- **1 bộ ACE, cắm thẳng 4 đầu in:** 4 filament của ACE vào 4 extruder (slot i → đầu i).
  Đây là cấu hình đã kiểm chứng trên máy thật.
- **1 bộ ACE + feeder mặc định của U1:** tổng **8 filament** trong hệ thống —
  mỗi đầu in có 2 nguồn cấp: feeder zin của máy hoặc 1 slot của ACE.
- **Tối đa 4 bộ ACE: 16 filament (16 màu)** — mỗi bộ ACE cấp cả 4 filament của nó cho **1 extruder**
  (4 filament → 1 đầu in); 4 bộ ứng với 4 đầu in của U1.

> Ngoài cấu hình đầu tiên đã test thật, các cấu hình còn lại là khả năng của multiACE
> theo tài liệu gốc của tác giả — chưa được kiểm chứng trên máy này.

> **Tác giả gốc:** multiACE là của [decay71](https://github.com/decay71/multiACE), firmware ACE2-Open là công sức của cộng đồng.
> Bộ này chỉ là script đóng gói + hướng dẫn tiếng Việt dựa trên kinh nghiệm cài thật.
> Không liên quan tới Snapmaker hay Anycubic. Tự chịu trách nhiệm khi làm theo.
> Đã kiểm chứng trên đúng 1 máy — máy của bạn có thể khác ở chi tiết nhỏ.

---

## Đọc 2 phút trước khi bắt đầu (cho người mới)

- Toàn bộ quá trình mất khoảng **20–30 phút**. Bạn **không cần biết lập trình** —
  chỉ cần copy và dán lệnh đúng như hướng dẫn.
- Ba từ sẽ gặp suốt, hiểu đơn giản thế này:
  - **IP máy in**: địa chỉ mạng của U1, xem tại Settings → Network trên màn hình máy in
    (ví dụ `192.168.1.12`). Mọi chỗ viết `<IP-may-in>` trong tài liệu này, bạn thay bằng dãy số đó.
  - **SSH**: cách máy tính "nói chuyện" với máy in qua mạng. Trên Mac mở app **Terminal**,
    trên Windows mở **PowerShell** — gõ lệnh vào đó.
  - **Bundle**: thư mục `multiace` tải từ GitHub (mục 0 có link).
- Cách đọc: làm **đúng thứ tự**, xong mỗi bước nhìn dòng *"Bạn sẽ thấy"* để biết mình đang đúng đường.
  Thấy khác hẳn → đừng làm tiếp, nhảy xuống **bảng tra lỗi** ở gần cuối.

## 0. Chuẩn bị

**Phần cứng**
- Snapmaker U1, firmware stock (bản đã test: 2.0.0.205).
- Anycubic ACE Pro hoặc ACE Pro 2 + nguồn riêng đi kèm (ACE ăn điện lưới riêng, không lấy điện từ máy in).
- Cáp nối ACE ↔ U1 theo hướng dẫn đấu cáp của cộng đồng multiACE (USB-to-Molex):
  chỉ nối **− / D− / D+**, chân **VCC (pin 3) để trống**. Nối VCC là sai, đừng nối.
- Ống PTFE: ACE cấp thẳng từng đầu in, **không dùng chạc chữ Y (Y-splitter)**.
  Đo chiều dài ống của bạn — sẽ cần ở bước hiệu chỉnh.

**Phần mềm**
- Cách 1 không cần tải gì hết: script tự kéo multiACE v1.27b từ GitHub của decay71 ngay trên máy in — máy in chỉ cần có internet, máy tính chỉ cần `ssh`.
- Cách 2 (làm tay) mới cần tải trước bundle multiACE từ https://github.com/decay71/multiACE, và máy tính có thêm `scp` (Mac có sẵn trong Terminal).

---

## 1. Bật Root Access trên U1

Trên màn hình cảm ứng của máy in:

1. Settings → About → chạm vào dòng firmware version **10 lần** để mở Advanced Mode.
2. Settings → Advanced Mode → bật **Root Access**.
3. Từ máy tính, SSH vào máy in: `ssh root@<IP-may-in>` — mật khẩu root mặc định do hãng công bố là `snapmaker`.

> Sau mỗi lần máy in thay đổi (clean/factory reset), lần SSH đầu từ máy tính có thể báo lỗi host key —
> chạy `ssh-keygen -R <IP-may-in>` trên máy tính rồi SSH lại.

## 2. Cài đặt — chọn MỘT trong hai cách

Hai cách cho cùng một kết quả. **Cách 1** cho người muốn nhanh gọn;
**Cách 2** cho người muốn nhìn rõ từng lệnh chạy vào máy mình.

### Cách 1 — Một dòng lệnh (khuyên dùng)

Không cần tải file gì về máy tính hết — script cài tự kéo multiACE từ GitHub về ngay trên máy in.

**Bước 1.** SSH vào máy in như mục 1: `ssh root@<IP-may-in>` (mật khẩu `snapmaker`).

*Bạn sẽ thấy:* dấu nhắc lệnh của máy in — bạn đang "ở trong" máy in. Máy in cần đang có internet.

**Bước 2.** Dán đúng **một dòng** này rồi Enter:

```bash
curl -fsSL https://raw.githubusercontent.com/khuonguyenhcm-bit/multiace-u1/main/cai-multiace.sh | bash
```

Dòng này tải script cài của bộ này từ GitHub và chạy ngay. Script tự làm hết phần còn lại:
tải bundle **multiACE v1.27b** chính chủ từ GitHub của decay71 (có kiểm tra checksum) → giải nén
→ sao lưu `printer.cfg` → tạo cờ `.debug` → chạy bộ cài gốc (config + module Klipper + Web UI)
→ tạo cờ `.fluidd` → tự kiểm tra lại từng mục. Script hỏi gì thì gõ `y` + Enter.

*Bạn sẽ thấy:* dòng chữ **"CÀI ĐẶT HOÀN TẤT PHẦN MỀM"**, rồi script hỏi có khởi động lại
máy in ngay không — gõ `y`. Xong, đi tiếp mục 3.

> Muốn script không hỏi gì hết (tự trả lời `y` mọi câu), dùng dòng:
> `curl -fsSL https://raw.githubusercontent.com/khuonguyenhcm-bit/multiace-u1/main/cai-multiace.sh | bash -s -- --yes`

### Cách 2 — Làm tay, gõ từng lệnh

**Bước 1.** Chép bộ cài lên máy in (trên máy tính, ở thư mục chứa `multiace`):

```bash
scp -r multiace root@<IP-may-in>:/tmp/multiace
```

*Bạn sẽ thấy:* các dòng chép file chạy qua, không báo lỗi đỏ.

**Bước 2.** Đăng nhập vào máy in:

```bash
ssh root@<IP-may-in>
```

Mật khẩu: `snapmaker`. *Bạn sẽ thấy:* dấu nhắc lệnh đổi thành của máy in — bạn đã "ở trong" máy in.

**Bước 3.** Tạo cờ debug (bắt buộc phải có **trước** khi cài):

```bash
touch /oem/.debug
```

*Bạn sẽ thấy:* không hiện gì cả — vậy là đúng, lệnh này không có thông báo.

**Bước 4.** Chạy bộ cài gốc của multiACE:

```bash
bash /tmp/multiace/install_multiace.sh
```

*Bạn sẽ thấy:* nhiều dòng chạy qua; kết thúc đúng phải có dòng **"All files verified OK"**.

**Bước 5.** Cài thêm Web UI:

```bash
bash /tmp/multiace/install_multiace.sh --install-web
```

**Bước 6.** Tạo cờ chống mất config — **bước quan trọng nhất, đừng bỏ qua:**

```bash
touch /oem/printer_data/.fluidd
```

Thiếu cờ này, mỗi lần tắt/bật máy in, hệ thống sẽ chép đè `printer.cfg` từ bản gốc,
làm mất dòng `[include extended/ace.cfg]` và Klipper sập với lỗi
System Anomaly **0003-0522-0000-0002**. Có cờ này là boot lạnh bao nhiêu lần cũng yên.

**Bước 7.** Khởi động lại máy in:

```bash
reboot
```

Xong, đi tiếp mục 3.

## 3. Khởi động lại và kiểm tra

1. Cắm cáp USB của ACE vào máy in, cấp nguồn cho ACE.
2. Khởi động lại máy in.
3. Mở Fluidd (`http://<IP-may-in>`) → Console → gõ **`ACEG__Status`**.
   Kết quả đạt yêu cầu: báo **bundle MATCH** và ACE (Pro / Pro 2) ở trạng thái **ACTIVE**.

## 4. Firmware trong ACE (ACE2-Open)

multiACE cần firmware ACE2-Open chạy trong con ACE (bản đã test: **V1.1.60O**).
Số bản này là của **ACE Pro 2** — ACE Pro (bản 1) dùng bản Open tương ứng dành cho Pro 1;
xem đúng mục firmware trong README của multiACE và **đừng flash nhầm file của nhau**.

- Kiểm tra phiên bản trong Web UI: `http://<IP-may-in>/multiace`.
- Nếu ACE đang ở firmware stock thấp (ví dụ 1.1.26/1.1.31), hãy flash lên ACE2-Open
  bằng chính Web UI đó — file và link tải nằm trong README của repo multiACE, làm đúng theo đó.
- Flash mà treo/lỗi: **tắt nguồn ACE, bật lại**, rồi flash lại. Đừng hoảng.
- Firmware này nằm trong con ACE — factory reset máy in không đụng tới nó.

## 5. Lần chạy đầu + hiệu chỉnh nạp/rút

1. Chạy macro **`ACEC__Unload_All`** một lần trước khi dùng đầu tiên.
2. Hiệu chỉnh trong `ace.cfg` (mở qua Fluidd → Configuration → `extended/ace.cfg`):
   - Điểm bắt đầu đã kiểm chứng trên máy dùng ống **1800mm**: `load_length: 1980`, `retract_length: 2250`, `feed_speed: 80`.
   - Công thức suy ra cho ống của bạn: **load ≈ chiều dài ống + 180**, **retract ≈ load + 270**.
     Đây là điểm bắt đầu, không phải số chết — ống khác, máy khác thì tinh chỉnh tiếp.
   - Cách thử: nạp 1 đầu rồi rút ra — đầu sợi dừng cách miệng ra của ACE khoảng **5cm** là đẹp.
     Sợi bị kéo tuột vào trong sâu quá → giảm retract. Sợi còn thò dài → tăng retract. Chỉnh từng nấc ±20mm.
3. Sau khi chỉnh xong, thử in 2 màu trước, ổn rồi mới in 4 màu.

## 6. Cuộn nhựa & tem RFID (đặc biệt là cuộn Bambu)

- Gắn cuộn vào slot → mở Web UI → tab Spools → gán cuộn cho slot.
  Cuộn Bambu xịn sẽ tự đọc ra loại/màu/nhiệt độ ngay khi gắn.
- **Cuộn Bambu có 2 chip RFID, mỗi mặt lõi một chip, mỗi chip một mã UID khác nhau.**
  multiACE nhận diện cuộn theo UID của chip, nên lật mặt cuộn là nó "thấy người lạ".
  Cách xử lý: gắn mặt A → gán cuộn; lật mặt B → mở đúng hồ sơ cuộn đó, **thêm UID của mặt B vào cùng trường `sku`, cách nhau dấu phẩy**.
  Từ đó cuộn được nhận ở cả hai mặt. Mỗi cuộn mới phải làm tay 1 lần.
- Đầu đọc đôi khi **đọc chéo tem của slot bên cạnh** — nếu thấy cuộn "nhận sai người",
  hãy rút các cuộn kề bên ra và gắn thử từng cuộn một mình để xác định đúng tem.
- Cuộn nào tem không giải mã được (chỉ đọc được UID, không ra thông tin):
  dán thêm **tem NTAG215** ghi dữ liệu OpenSpool (ví dụ bằng app Tag My Spool trên điện thoại),
  mỗi mặt lõi 1 tem giống nhau là xong. Đừng mua nhầm tem OpenPrintTag của Prusa (khác họ sóng, ACE không đọc được).

## 7. Sấy

- Mặc định trong `ace.cfg`: 55°C / 240 phút. Trần nhiệt độ của ACE 2 Pro trong config là 70°C.
- Bật/tắt sấy ở Web UI hoặc Fluidd (macro `ACED__Dry_Start_0` / `ACED__Dry_Stop`).
- Chu trình sấy đã bắt đầu thì chạy bằng firmware trong ACE (ACE có nguồn riêng) —
  tắt máy in giữa chừng, ACE vẫn sấy hết giờ đã đặt.
- **Auto-dry theo độ ẩm thì khác:** bộ não theo dõi độ ẩm nằm ở multiACE trên máy in,
  nên muốn auto-dry hoạt động phải **để máy in bật** (để nghỉ/idle cũng được).
  Lưu ý: auto-dry theo độ ẩm chỉ có ở **ACE Pro 2** (bản có cảm biến đo ẩm để tự ra quyết định);
  ACE Pro 1 không tự đo — trong hệ nhiều ACE, unit Pro 1 chỉ sấy "follow" theo unit chính.
- Tuỳ chọn `dry_auto_roll` (xoay cuộn khi sấy, chỉ ACE Pro 2 — đèn báo Rotisserie / Auto-roll trong Web UI):
  **cứ để tắt** như mặc định. Chính tác giả multiACE cảnh báo cơ chế xoay của ACE khá "mù"
  (cứ ~4 phút kéo ngược sợi 5mm mà không kiểm tra lane có đang nạp sợi hay không) —
  chỉ bật khi các lane trống hoàn toàn. Hai đèn báo đó chỉ để chẩn đoán, không phải nút bấm.

## 8. Quy tắc sống còn

- **Trước mỗi lần Snapmaker cập nhật firmware (OTA) cho U1: gỡ multiACE trước**, cập nhật xong cài lại
  (bản cập nhật sẽ xoá lớp file hệ thống của máy — mọi thứ cài thêm như multiACE đều nằm ở lớp này):
  ```bash
  bash /home/lava/printer_data/config/extended/multiace/uninstall_multiace.sh
  ```
- **Sau factory reset máy in:** tạo lại cờ `/oem/printer_data/.fluidd` **trước lần khởi động đầu tiên** (reset xoá cờ này).
- Dòng chữ IP màu vàng kiểu nhà máy trên màn hình cảm ứng là do cờ `/oem/.debug`:
  khi mọi thứ đã ổn định, xoá cờ đó (`rm /oem/.debug`) + khởi động lại là hết.
  Lần nào cài lại multiACE cũng phải tạo lại cờ trước khi cài.
- Đừng tắt tuỳ chọn "automatic load" trên màn hình cảm ứng của máy in.

## 9. Bảng tra lỗi (toàn bộ là sự cố đã gặp thật)

| Hiện tượng | Nguyên nhân | Cách xử lý |
|---|---|---|
| Klipper báo System Anomaly 0003-0522-0000-0002 sau khi tắt/bật máy | Boot lạnh chép đè `printer.cfg`, mất dòng include | Tạo cờ: `touch /oem/printer_data/.fluidd` rồi khởi động lại. Cứu cháy một lần: chèn lại dòng `[include extended/ace.cfg]` vào đầu `printer.cfg` + FIRMWARE_RESTART |
| ACE kẹt trạng thái busy, thao tác nào cũng timeout | Module mất đồng bộ serial với ACE | **Tắt nguồn ACE → bật lại → rồi mới FIRMWARE_RESTART** trong Fluidd (đúng thứ tự này) |
| Extrude bằng tay (màn hình/console) kêu cạch cạch, tuột sợi | ACE không có feed-assist khi extrude tay — đó là thiết kế, không phải lỗi | Đừng extrude tay ở đầu do ACE quản; muốn xả/nạp sợi hãy dùng chu trình Load/Unload của ACE |
| Cuộn bị nhận sai / slot này hiện tem slot kia | Đầu đọc đọc chéo tem kề bên | Gắn thử từng cuộn một mình; sửa lại gán trong Web UI (tab Spools) |
| Lật mặt cuộn là mất nhận diện | Mỗi mặt lõi là 1 chip UID khác nhau | Thêm UID mặt còn lại vào cùng trường `sku` của cuộn (dấu phẩy ngăn cách) |
| Gắn cuộn vào mà không hiện thông tin nhựa | Tem không giải mã được, hoặc dữ liệu chỉ hiện đầy đủ ở bước Load | Thử Load 1 lần; nếu vẫn trống, nhập tay hồ sơ hoặc dán tem NTAG215/OpenSpool |
| Flash firmware ACE bị treo | ACE kẹt trạng thái | Tắt/bật nguồn ACE rồi flash lại qua Web UI |
| Mất SSH / máy biến mất khỏi mạng sau khi can thiệp hệ thống | Trên firmware stock, SSH do chính màn hình gốc khởi động lúc boot khi Root Access bật; sự cố ở lớp hệ thống có thể làm mất cả SSH lẫn WiFi | Cắm adapter **USB-Ethernet** vào máy in — máy tự nhận IP có dây từ router → SSH qua IP có dây đó để gỡ/cài lại (mẹo cứu hộ nền tảng U1, tham khảo từ cộng đồng HelixScreen) |

## 10. Gỡ cài đặt

```bash
bash /home/lava/printer_data/config/extended/multiace/uninstall_multiace.sh
```

Khởi động lại máy in sau khi gỡ. File `printer.cfg` gốc còn ở bản sao lưu
`printer.cfg.bak-multiace-*` (script cài tự tạo) nếu cần khôi phục bằng tay.

---

*Bản nháp — đóng gói từ kinh nghiệm cài thật trên 1 máy U1 + ACE 2 Pro, tháng 10/2026.*
*Mọi đóng góp/báo lỗi xin gửi về repo multiACE gốc của decay71 hoặc trang chủ của bộ cài này.*
