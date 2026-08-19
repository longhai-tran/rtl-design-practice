# Lý Thuyết Giao Thức UART

![Chủ đề](https://img.shields.io/badge/Chủ%20đề-Lý%20thuyết%20giao%20thức-blueviolet.svg)
![Giao thức](https://img.shields.io/badge/Giao%20thức-UART-blue.svg)
![Ngôn ngữ](https://img.shields.io/badge/Ngôn%20ngữ-Tiếng%20Việt-red.svg)

---

## Mục Lục

1. [UART Là Gì?](#1-uart-là-gì)
2. [Đặc Điểm Cơ Bản](#2-đặc-điểm-cơ-bản)
3. [Cấu Trúc Khung Truyền](#3-cấu-trúc-khung-truyền)
4. [Tốc Độ Baud](#4-tốc-độ-baud)
5. [Parity — Phát Hiện Lỗi](#5-parity--phát-hiện-lỗi)
6. [Các Biến Thể Cấu Hình](#6-các-biến-thể-cấu-hình)
7. [So Sánh Với SPI và I²C](#7-so-sánh-với-spi-và-i²c)
8. [Ứng Dụng Thực Tế](#8-ứng-dụng-thực-tế)
9. [Điều Khiển Luồng (Flow Control)](#9-điều-khiển-luồng-flow-control)
10. [Các Lỗi UART Phổ Biến](#10-các-lỗi-uart-phổ-biến)
11. [Tài Liệu Tham Khảo](#11-tài-liệu-tham-khảo)

---

## 1. UART Là Gì?

**UART** *(Universal Asynchronous Receiver/Transmitter)* là một giao thức truyền
thông nối tiếp **điểm-điểm** (point-to-point), **song công toàn phần**
(full-duplex), và **bất đồng bộ** (asynchronous).

- **Nối tiếp**: dữ liệu được gửi từng bit một trên một đường truyền.
- **Song công toàn phần**: hai bên có thể truyền và nhận đồng thời, thông qua
  hai đường độc lập (TX và RX).
- **Bất đồng bộ**: không có đường xung nhịp chung. Hai bên phải thỏa thuận
  trước về **tốc độ baud** (bits per second) và cấu hình khung truyền trước khi
  giao tiếp.

### Sơ Đồ Kết Nối

```
  Thiết bị A                                 Thiết bị B
  ┌───────────┐                              ┌───────────┐
  │        TX ├──────────────────────────────► RX        │
  │           │                              │           │
  │        RX ◄──────────────────────────────┤ TX        │
  │       GND ├──────────────────────────────┤ GND       │
  └───────────┘                              └───────────┘
         Không có đường xung nhịp chung
```

> UART chỉ cần **3 dây**: TX, RX và GND chung. Đây là lý do nó phổ biến trong
> các ứng dụng nhúng nơi số chân vi điều khiển là tài nguyên quý.

---

## 2. Đặc Điểm Cơ Bản

### 2.1 Trạng Thái Rỗi (Idle State)

Khi không có dữ liệu nào được truyền, đường TX duy trì ở mức **logic CAO**
(còn gọi là trạng thái *mark*). Đây là quy ước lịch sử xuất phát từ thời
teletypewriter (TTY), trong đó dòng điện liên tục đồng nghĩa với "đường đang
sống" (line is alive).

Trạng thái rỗi ở mức CAO có hai lợi ích thực tế:

- **Phát hiện đứt dây**: một đường truyền bị đứt hoặc hỏng sẽ có mức thấp
  (do trở kéo xuống bên nhận), dễ phân biệt với trạng thái idle hợp lệ.
- **Phân biệt bit start**: bit start luôn là mức THẤP — sự chuyển tiếp
  rõ ràng từ CAO (idle) xuống THẤP báo hiệu bắt đầu một khung mới.

### 2.2 Truyền Không Đồng Bộ Hoạt Động Như Thế Nào?

Vì không có xung nhịp chung, bên nhận phải **tự đồng bộ** với mỗi khung bằng
cách:

1. Phát hiện cạnh xuống của bit start.
2. Bắt đầu bộ đếm nội bộ dựa trên tốc độ baud đã thỏa thuận.
3. Lấy mẫu từng bit tại **giữa chu kỳ bit** (tại điểm cách xa nhất tính từ
   hai cạnh chuyển tiếp).
4. Lắp ghép các bit lại thành byte hoàn chỉnh sau bit stop.

```
  ← 1 bit period (T) →
  ┌───────────────────┐
  │                   │
  │      lấy mẫu tại đây
  │         ↑         │
──┘         ×         └──
           T/2
```

---

## 3. Cấu Trúc Khung Truyền

### 3.1 Các Thành Phần Của Khung

Một khung UART hoàn chỉnh gồm các trường xếp theo thứ tự thời gian:

```
IDLE   START   D0    D1    D2    D3    D4    D5    D6    D7   [PARITY]  STOP   IDLE

HIGH ──────┐                                                  ┌──────────────────
           │                                                  │
LOW        └────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬───┘
               LSB                 data bits             MSB
```

| Trường | Mức logic | Thời gian | Mô tả |
|---|---|---|---|
| **Idle** | CAO | Không giới hạn | Trạng thái nghỉ; đường dây ở mức *mark* |
| **Bit Start** | THẤP | 1 bit period | Luôn là `0`; đồng bộ bên nhận |
| **Bit Dữ Liệu** | D0–D7 | 1 bit period mỗi bit | Payload; truyền **D0 (LSB) trước** |
| **Bit Parity** | 0 hoặc 1 | 1 bit period | Tùy chọn; phát hiện lỗi đơn bit |
| **Bit Stop** | CAO | 1 hoặc 2 bit period | Luôn là `1`; đảm bảo thời gian high tối thiểu |

### 3.2 Chi Tiết Từng Trường

#### Bit Start

- Luôn là mức **THẤP** (logic `0`), không thể cấu hình.
- Mục đích: báo hiệu cho bộ nhận biết rằng một khung mới bắt đầu và
  kích hoạt bộ đếm nội bộ.
- Kéo dài đúng **1 bit period** (= `1 / baud_rate` giây).

#### Bit Dữ Liệu

- Số lượng: thường là **5, 6, 7, hoặc 8 bit** (cấu hình phổ biến nhất là 8 bit).
- Thứ tự: **LSB trước** (bit có trọng số thấp nhất được truyền đầu tiên).
- Mỗi bit kéo dài đúng 1 bit period.

> **Tại sao LSB trước?**
> Đây là quy ước lịch sử từ thời teletypewriter. Phần cứng TTY ban đầu
> đọc các bit vào thanh ghi dịch từ bit thấp nhất, và chuẩn này được giữ
> nguyên cho đến ngày nay.

**Ví dụ:** Truyền byte `0xA3` = `10100011b`:

```
Thứ tự truyền:  D0  D1  D2  D3  D4  D5  D6  D7
Giá trị bit:     1   1   0   0   0   1   0   1
                LSB                         MSB
```

Bên nhận ghép lại: D7D6D5D4D3D2D1D0 = `10100011` = `0xA3`. ✅

#### Bit Stop

- Luôn là mức **CAO** (logic `1`), không thể cấu hình.
- Mục đích: đảm bảo đường dây trở về mức *mark* (idle), tạo ra
  cạnh xuống rõ ràng cho bit start của khung tiếp theo.
- Kéo dài **1 hoặc 2 bit period** tùy cấu hình.

### 3.3 Ký Hiệu Cấu Hình — Ví Dụ: "8N1"

Cấu hình UART thường được viết tắt theo dạng: **`[Số bit dữ liệu][Parity][Số bit stop]`**

| Ký hiệu | Ý nghĩa |
|---|---|
| `8N1` | 8 bit dữ liệu, **N**o parity, 1 stop bit |
| `8E1` | 8 bit dữ liệu, **E**ven parity, 1 stop bit |
| `8O1` | 8 bit dữ liệu, **O**dd parity, 1 stop bit |
| `7N2` | 7 bit dữ liệu, No parity, 2 stop bit |
| `8N2` | 8 bit dữ liệu, No parity, 2 stop bit |

> **8N1 là chuẩn de-facto** cho hầu hết các ứng dụng nhúng hiện đại.

---

## 4. Tốc Độ Baud

### 4.1 Định Nghĩa

**Tốc độ baud** (baud rate) là số lượng **thay đổi trạng thái tín hiệu** mỗi
giây, đo bằng đơn vị **baud** (Bd). Với UART dùng mã hóa NRZ (Non-Return-to-Zero),
1 baud = 1 bit/giây, nên tốc độ baud và tốc độ bit là tương đương.

### 4.2 Các Tốc Độ Baud Chuẩn

| Tốc độ baud | Thời gian 1 bit | Ứng dụng điển hình |
|---|---|---|
| 1,200 | 833 µs | Thiết bị cũ, đường điện thoại |
| 9,600 | 104 µs | Thiết bị nhúng thấp tốc, GPS |
| 19,200 | 52 µs | Giao tiếp công nghiệp |
| 38,400 | 26 µs | Modem cũ |
| 57,600 | 17.4 µs | Cân bằng tốc độ/ổn định |
| **115,200** | **8.68 µs** | **Phổ biến nhất cho debug console, MCU** |
| 230,400 | 4.34 µs | Ứng dụng cao tốc |
| 921,600 | 1.08 µs | UART tốc độ cao |
| 1,000,000 | 1 µs | UART tốc độ cao đặc biệt |

### 4.3 Thông Lượng Dữ Liệu Thực Tế

Với cấu hình 8N1 (1 start + 8 data + 1 stop = **10 bit mỗi byte**):

```
Thông lượng = Baud_Rate / 10  (byte/giây)

Ví dụ với 115,200 baud:
  Thông lượng = 115,200 / 10 = 11,520 byte/s ≈ 11.25 KB/s
```

### 4.4 Sai Số Baud Và Giới Hạn Chấp Nhận

Vì không có xung nhịp chung, hai bên chạy bộ đếm baud độc lập và không hoàn
toàn đồng bộ. Sai lệch tích lũy được tính theo số bit trong một khung:

```
Tổng sai lệch = Sai số baud (%) × Số bit trong khung

Với 8N1 (10 bit/khung) và sai số ±2%:
  Tổng sai lệch tại bit stop ≈ ±0.2 bit period
```

Điểm lấy mẫu tại giữa bit (T/2) tạo ra biên độ lỗi ±50%. Do đó:

- Sai số **≤ ±2%**: an toàn — điểm lấy mẫu vẫn trong vùng trung tâm.
- Sai số **±3–5%**: cận biên — hoạt động có thể không ổn định.
- Sai số **> ±5%**: không chấp nhận được — sẽ gây lỗi framing.

---

## 5. Parity — Phát Hiện Lỗi

### 5.1 Parity Là Gì?

**Bit parity** là một bit kiểm tra được thêm vào sau các bit dữ liệu để phát
hiện lỗi đơn bit trong quá trình truyền. UART hỗ trợ ba chế độ parity:

| Chế độ | Ký hiệu | Quy tắc | Ví dụ với `0xA3 = 10100011` |
|---|---|---|---|
| Không parity | **N** (None) | Không thêm bit parity | — |
| Parity chẵn | **E** (Even) | Tổng bit `1` trong data + parity là **chẵn** | Đếm 1s: 4 → parity = `0` |
| Parity lẻ | **O** (Odd) | Tổng bit `1` trong data + parity là **lẻ** | Đếm 1s: 4 → parity = `1` |

### 5.2 Hạn Chế Của Parity

- Chỉ phát hiện được **lỗi đơn bit** (1 bit bị lật).
- **Không thể phát hiện** lỗi kép (2 bit bị lật đồng thời).
- **Không thể sửa lỗi** — chỉ phát hiện và yêu cầu truyền lại.

> Vì những hạn chế này, parity thường bị bỏ qua trong thực tế nhúng hiện đại
> (8N1). Các ứng dụng cần kiểm tra lỗi mạnh hơn thường dùng CRC ở lớp giao
> thức cao hơn.

---

## 6. Các Biến Thể Cấu Hình

### 6.1 Số Bit Dữ Liệu

| Số bit | Ứng dụng |
|---|---|
| 5 bit | Baudot code (teletypewriter cổ điển) |
| 7 bit | ASCII (chỉ ký tự in được, bit cao = 0) |
| **8 bit** | **Chuẩn hiện đại — 1 byte truyền mỗi khung** |
| 9 bit | Một số chuẩn công nghiệp (bit thứ 9 để phân biệt địa chỉ/dữ liệu) |

### 6.2 Số Bit Stop

| Số bit stop | Thời gian | Mô tả |
|---|---|---|
| **1 bit** | 1 × T | **Chuẩn — dùng phổ biến nhất** |
| 1.5 bit | 1.5 × T | Chuẩn cũ cho 5-bit data |
| 2 bit | 2 × T | Tăng biên độ lỗi cho thiết bị chậm |

### 6.3 Điện Áp Và Mức Logic

UART là giao thức logic; lớp vật lý (điện áp) phụ thuộc vào chuẩn:

| Chuẩn | Mức điện áp | Khoảng cách | Ứng dụng |
|---|---|---|---|
| TTL (5V) | 0V – 5V | Ngắn (PCB) | Vi điều khiển cũ |
| CMOS (3.3V) | 0V – 3.3V | Ngắn (PCB) | Vi điều khiển hiện đại |
| RS-232 | ±3V đến ±15V | Vài chục mét | Cổng COM máy tính |
| RS-485 | Differential ±200mV | Vài km | Công nghiệp (Modbus) |

> **Chú ý**: Khi kết nối hai thiết bị có mức điện áp khác nhau (ví dụ 5V TTL và
> 3.3V CMOS), cần bộ chuyển mức logic (level shifter) để tránh hỏng thiết bị.

---

## 7. So Sánh Với SPI và I²C

| Tiêu chí | UART | SPI | I²C |
|---|---|---|---|
| **Số dây tối thiểu** | 2 (TX + RX) | 4 (MOSI, MISO, SCK, CS) | 2 (SDA + SCL) |
| **Xung nhịp** | Không (bất đồng bộ) | Có (đồng bộ) | Có (đồng bộ) |
| **Số thiết bị** | 2 (point-to-point) | 1 master + N slave | N master + N slave |
| **Địa chỉ thiết bị** | Không | Không (dùng CS riêng) | Có (7 hoặc 10 bit) |
| **Tốc độ điển hình** | 115.2 kbps – 1 Mbps | 1 – 50+ MHz | 100 kHz – 5 MHz |
| **Full-duplex** | ✅ Có | ✅ Có | ❌ Không (half-duplex) |
| **Khoảng cách** | Ngắn–vừa | Ngắn (PCB) | Ngắn (PCB, <1m) |
| **Độ phức tạp** | Thấp | Thấp | Trung bình |
| **Ứng dụng điển hình** | Debug console, GPS, BT | Flash SPI, ADC, màn hình | Cảm biến, EEPROM, IMU |

### Khi Nào Dùng UART?

✅ **Nên dùng UART khi:**
- Chỉ cần kết nối 2 thiết bị (point-to-point).
- Debug hoặc giao tiếp với terminal trên máy tính.
- Kết nối module có sẵn (GPS, Bluetooth, GSM, RFID) vốn dùng UART.
- Ưu tiên đơn giản, số dây ít.

❌ **Không nên dùng UART khi:**
- Cần kết nối nhiều hơn 2 thiết bị đồng thời.
- Yêu cầu tốc độ rất cao (>1 Mbps) — dùng SPI.
- Cần nhiều slave trên cùng 2 dây — dùng I²C.

---

## 8. Ứng Dụng Thực Tế

### 8.1 Debug Console / Serial Monitor

Ứng dụng phổ biến nhất: in thông tin debug từ vi điều khiển ra terminal máy tính
thông qua USB-to-UART bridge (CH340, CP2102, FT232R).

```
  MCU (UART TX) ──► USB-UART Bridge ──► USB ──► Máy tính
                    (CH340/CP2102)              (PuTTY, minicom)
```

### 8.2 Kết Nối Module Ngoại Vi

Nhiều module thông dụng sử dụng UART làm giao diện giao tiếp:

| Module | Tốc độ baud mặc định | Chức năng |
|---|---|---|
| GPS (NEO-6M, NEO-8M) | 9,600 | Định vị GNSS |
| Bluetooth HC-05/HC-06 | 9,600 – 115,200 | Truyền dữ liệu không dây |
| GSM/GPRS (SIM800L) | 9,600 | Kết nối mạng di động |
| RFID (RC522 UART mode) | 9,600 | Đọc thẻ |
| LoRa (E32, Ra-02 UART) | 9,600 | Truyền tầm xa |
| ESP8266/ESP32 (AT mode) | 115,200 | WiFi |

### 8.3 Giao Tiếp Công Nghiệp

- **RS-232**: chuẩn PC cổ điển, ±12V, khoảng cách vài chục mét.
- **RS-485 (Modbus RTU)**: differential, khoảng cách vài km, hỗ trợ multi-drop
  (nhiều thiết bị trên một bus với địa chỉ phần mềm).

### 8.4 Bootloader / Firmware Update

Nhiều vi điều khiển sử dụng UART để nạp firmware (flash programming) qua
bootloader tích hợp sẵn trong ROM, không cần JTAG:

- STM32: UART bootloader (BOOT0 pin HIGH).
- ESP32: Serial download mode.
- ATmega: UART bootloader (Arduino).

---

## 9. Điều Khiển Luồng (Flow Control)

Khi bên phát gửi dữ liệu nhanh hơn bên nhận có thể xử lý, buffer bên nhận sẽ
bị tràn (**overrun**) và dữ liệu bị mất. **Điều khiển luồng** là cơ chế ngăn
chặn vấn đề này.

UART hỗ trợ hai phương pháp điều khiển luồng:

### 9.1 Điều Khiển Luồng Phần Cứng — RTS/CTS

**RTS** *(Request To Send)* và **CTS** *(Clear To Send)* là hai tín hiệu bổ
ssung ngoài TX/RX. Cơ chế hoạt động:

```
  Thiết bị A                                  Thiết bị B
  ┌────────────┐                              ┌────────────┐
  │         TX ├──────────────────────────────► RX         │
  │         RX ◄──────────────────────────────┤ TX         │
  │        RTS ├──────────────────────────────► CTS        │
  │        CTS ◄──────────────────────────────┤ RTS        │
  └────────────┘                              └────────────┘
```

**Quy tắc:**

| Tín hiệu | Ý nghĩa khi CAO | Hành động |
|---|---|---|
| **RTS** (ngõ ra của A) | "Tôi sẵn sàng nhận dữ liệu" | Bên B có thể gửi |
| **CTS** (ngõ vào của A) | "Bên kia sẵn sàng nhận" | A được phép gửi |

**Luồng hoạt động:**

```
  Thiết bị A muốn gửi:
    1. Kiểm tra CTS — nếu CAO, tiến hành gửi
    2. Gửi dữ liệu qua TX

  Thiết bị B sắp đầy buffer:
    3. Hạ RTS xuống THẤP  →  CTS của A xuống THẤP
    4. A dừng gửi ngay lập tức

  Thiết bị B đã xử lý xong, buffer còn chỗ:
    5. B kéo RTS lên CAO  →  CTS của A lên CAO
    6. A tiếp tục gửi
```

**Ưu điểm:** Phản ứng tức thì (mức phần cứng), không tốn băng thông dữ liệu.
**Nhược điểm:** Cần thêm 2 chân I/O và 2 dây kết nối vật lý.

### 9.2 Điều Khiển Luồng Phần Mềm — XON/XOFF

Thay vì dùng dây phần cứng, bên nhận gửi các **ký tự điều khiển đặc biệt**
nhúng trong luồng dữ liệu TX/RX:

| Ký tự | Mã ASCII | Ý nghĩa |
|---|---|---|
| **XON** | `0x11` (Ctrl+Q) | "Hãy tiếp tục gửi" — buffer còn chỗ |
| **XOFF** | `0x13` (Ctrl+S) | "Dừng gửi ngay" — buffer gần đầy |

**Luồng hoạt động:**

```
  Thiết bị B (nhận) sắp đầy buffer:
    → Gửi XOFF (0x13) qua TX của mình về A
    → A nhận XOFF, dừng gửi

  Thiết bị B đã xử lý xong:
    → Gửi XON (0x11) qua TX của mình về A
    → A nhận XON, tiếp tục gửi
```

**Ưu điểm:** Chỉ cần 2 dây (TX + RX), không cần chân I/O bổ sung.
**Nhược điểm:**
- Tiêu tốn băng thông (ký tự XON/XOFF chiếm slot trong luồng dữ liệu).
- Không thể dùng nếu luồng dữ liệu có thể chứa byte `0x11` hoặc `0x13` (dữ liệu nhị phân).
- Độ trễ cao hơn so với phần cứng.

### 9.3 Khi Nào Cần Điều Khiển Luồng?

| Tình huống | Khuyến nghị |
|---|---|---|
| Debug console đơn giản | Không cần (baud thấp, MCU xử lý kịp) |
| Truyền file lớn qua RS-232 | RTS/CTS phần cứng |
| Terminal không có chân RTS/CTS | XON/XOFF phần mềm |
| Dữ liệu nhị phân tốc độ cao | RTS/CTS phần cứng |

---

## 10. Các Lỗi UART Phổ Biến

UART định nghĩa một số điều kiện lỗi mà bộ nhận phần cứng có thể phát hiện
và báo cáo:

### 10.1 Framing Error (Lỗi Khung)

**Nguyên nhân:** Bit stop được nhận không phải là mức CAO như mong đợi.

```
Khung bình thường:  START | D0 D1 D2 D3 D4 D5 D6 D7 | STOP=1
Khung lỗi framing:  START | D0 D1 D2 D3 D4 D5 D6 D7 | STOP=0  ← sai!
```

**Nguyên nhân điển hình:**
- Hai bên **tốc độ baud không khớp** (nguyên nhân phổ biến nhất).
- Sai số baud tích lũy vượt ±5%, điểm lấy mẫu lệch khỏi bit stop.
- Nhiễu điện từ làm biến dạng tín hiệu.

**Hậu quả:** Byte nhận bị coi là không hợp lệ và thường bị loại bỏ.

### 10.2 Overrun Error (Lỗi Tràn Bộ Đệm)

**Nguyên nhân:** Byte mới đến trong khi byte trước đó trong bộ đệm nhận
chưa được phần mềm đọc kịp.

```
  Thời gian → → →
  [Byte 1 đến] [Byte 2 đến] [Byte 3 đến]
        ↓             ↓
   Lưu vào buffer   Ghi đè Byte 1!
   (chưa được đọc)  → OVERRUN ERROR
```

**Nguyên nhân điển hình:**
- Tốc độ baud quá cao so với khả năng xử lý của phần mềm.
- ISR xử lý ngắt UART quá chậm.
- Không có FIFO đủ sâu ở bộ nhận.

**Phòng tránh:** Dùng FIFO phần cứng, ngắt ưu tiên cao, hoặc điều khiển luồng RTS/CTS.

### 10.3 Parity Error (Lỗi Parity)

**Nguyên nhân:** Bit parity nhận được không khớp với giá trị tính toán từ
các bit dữ liệu nhận được.

**Ví dụ (Even Parity):**

```
Dữ liệu gốc:    0xA3 = 10100011  →  đếm 1s = 4 (chẵn)  →  parity_tx = 0
Dữ liệu nhận:   0xA1 = 10100001  →  đếm 1s = 3 (lẻ)   →  parity_rx = 1
→ parity_tx ≠ parity_rx  ⟹  PARITY ERROR!
```

**Lưu ý quan trọng:**
- Chỉ phát hiện được số lẻ bit bị lật (1, 3, 5... bit).
- **Không phát hiện** được lỗi kép (2 bit bị lật đồng thời).
- Phát hiện lỗi nhưng **không sửa được** — chỉ biết là có lỗi.

### 10.4 Break Condition (Điều Kiện Break)

**Định nghĩa:** Đường TX ở mức THẤP liên tục trong hơn một khung truyền
(tức là dài hơn 1 start bit + 8 data bit + 1 stop bit = 10 bit periods).

```
Bình thường:  ‾‾‾‾|_START_|D0–D7|‾STOP‾|‾‾‾  (idle sau stop)
Break:        ‾‾‾‾|_______________________________THẤP liên tục___
                   ←── dài hơn 10 bit period ──►
```

**Ý nghĩa và ứng dụng:**
- Trên RS-232: điều kiện break từng được dùng để ngắt phiên làm việc
  hoặc reset thiết bị đầu cuối.
- Trong hệ thống nhúng: một số bootloader dùng break condition để kích hoạt
  chế độ nạp firmware.
- Có thể là dấu hiệu của đứt dây (stuck-low) hoặc lỗi phần cứng.

### 10.5 Bảng Tóm Tắt Lỗi

| Lỗi | Phát hiện bởi | Nguyên nhân chính | Cách phòng tránh |
|---|---|---|---|
| **Framing Error** | Phần cứng UART | Baud rate không khớp | Đồng bộ cấu hình baud hai đầu |
| **Overrun Error** | Phần cứng UART | Buffer tràn | FIFO, ngắt ưu tiên cao, flow control |
| **Parity Error** | Phần cứng UART | Lỗi bit trong truyền | Môi trường ít nhiễu; dùng CRC ở lớp cao |
| **Break Condition** | Phần cứng UART | Đứt dây hoặc chủ động | Giám sát đường dây; timeout |

---

## 11. Tài Liệu Tham Khảo

| # | Tên tài liệu | Nguồn | Mô tả |
|---|---|---|---|
| [1] | **Basics of UART Communication** | [circuitbasics.com](https://www.circuitbasics.com/basics-uart-communication/) | Giới thiệu trực quan về UART: cấu trúc khung, tốc độ baud, so sánh với SPI và I²C |
| [2] | **TIA-232-F Standard** | TIA/EIA | Chuẩn RS-232 — định nghĩa mức điện áp và giao thức |
| [3] | **TIA-485-A Standard** | TIA/EIA | Chuẩn RS-485 — truyền thông differential, đa điểm |
| [4] | **Wikipedia — Universal Asynchronous Receiver-Transmitter** | [wikipedia.org](https://en.wikipedia.org/wiki/Universal_asynchronous_receiver-transmitter) | Lịch sử và chi tiết kỹ thuật |

### Về Bài Viết Tham Khảo [1]

Bài viết [Basics of UART Communication](https://www.circuitbasics.com/basics-uart-communication/)
của Scott Campbell (Circuit Basics) cung cấp:

- Sơ đồ trực quan về luồng truyền dữ liệu UART.
- Giải thích dễ hiểu về bit start, data, stop.
- Bảng so sánh UART/SPI/I²C từ góc nhìn thực hành.
- Ví dụ kết nối với Arduino và Raspberry Pi.

---

*Tài liệu lý thuyết giao thức UART — Tác giả: Long Hai*
