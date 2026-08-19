# Lý Thuyết Giao Thức I²C

![Chủ đề](https://img.shields.io/badge/Chủ%20đề-Lý%20thuyết%20giao%20thức-blueviolet.svg)
![Giao thức](https://img.shields.io/badge/Giao%20thức-I²C-blue.svg)
![Ngôn ngữ](https://img.shields.io/badge/Ngôn%20ngữ-Tiếng%20Việt-red.svg)

---

## Mục Lục

1. [I²C Là Gì?](#1-ic-là-gì)
2. [Đặc Điểm Cơ Bản](#2-đặc-điểm-cơ-bản)
3. [Các Tín Hiệu Giao Tiếp](#3-các-tín-hiệu-giao-tiếp)
4. [Cấu Trúc Frame Dữ Liệu](#4-cấu-trúc-frame-dữ-liệu)
5. [Timing Giao Dịch](#5-timing-giao-dịch)
6. [Cấu Trúc Bus Đa Thiết Bị](#6-cấu-trúc-bus-đa-thiết-bị)
7. [So Sánh Với UART và SPI](#7-so-sánh-với-uart-và-spi)
8. [Ứng Dụng Thực Tế](#8-ứng-dụng-thực-tế)
9. [Triển Khai RTL — i2c_master.v và i2c_slave.v](#9-triển-khai-rtl--i2c_masterv-và-i2c_slavev)
10. [Các Lỗi I²C Phổ Biến](#10-các-lỗi-ic-phổ-biến)
11. [Tài Liệu Tham Khảo](#11-tài-liệu-tham-khảo)

---

## 1. I²C Là Gì?

**I²C** *(Inter-Integrated Circuit)*, phát âm là *"I-squared-C"*, là một giao thức
truyền thông nối tiếp **đồng bộ** (synchronous), **bán song công** (half-duplex),
và **đa master / đa slave**, được phát triển bởi Philips Semiconductor (nay là NXP)
vào năm 1982.

- **Đồng bộ**: có một đường xung nhịp chung (SCL) do master phát ra, đảm bảo
  cả hai bên đồng bộ từng bit một.
- **Bán song công (half-duplex)**: chỉ có một đường dữ liệu duy nhất (SDA), tại
  một thời điểm chỉ một phía gửi dữ liệu.
- **Đa master / đa slave**: nhiều thiết bị có thể chia sẻ cùng một bus 2 dây nhờ
  cơ chế định địa chỉ và phân xử bus (arbitration).

### Sơ Đồ Kết Nối Cơ Bản

```
              ┌─────────────┐   ┌────────────┐   ┌──────────┐
              │   Master    │   │  Slave 0   │   │ Slave 1  │
              │ (i2c_master)│   │ addr=0x42  │   │addr=0x43 │
              └──┬──────┬───┘   └──┬─────┬───┘   └──┬────┬──┘
                 │      │          │     │          │    │
VCC──[Rp]────────┴──────┼──────────┴─────┼──────────┴────┼──── SDA
                        │                │               │
VCC──[Rp]───────────────┴────────────────┴───────────────┴──── SCL
```

> I²C chỉ cần **2 dây** (SDA và SCL) cho toàn bộ bus, bất kể có bao nhiêu thiết bị.
> Mỗi slave được phân biệt bằng **địa chỉ 7-bit** (hoặc 10-bit) thay vì dùng chân CS riêng.

---

## 2. Đặc Điểm Cơ Bản

### 2.1 Bus Open-Drain (Cực Máng Hở)

Đây là đặc điểm **quan trọng và khác biệt nhất** của I²C so với SPI/UART.

Mỗi thiết bị trên bus chỉ có thể **kéo đường dây xuống THẤP** (drive low) hoặc
**thả ra** (release / tri-state). Điện trở kéo lên bên ngoài (pull-up resistor)
sẽ đưa đường dây về mức CAO khi không thiết bị nào kéo xuống.

```
Thiết bị A kéo xuống:  SDA = 0  (dù B thả ra)
Thiết bị A thả ra:     SDA = 1  (nếu B cũng thả ra)
Cả A và B cùng kéo:    SDA = 0  (wired-AND)
```

> **Wired-AND**: kết quả logic trên bus là AND của tất cả các driver. Nếu bất kỳ
> thiết bị nào kéo xuống, bus sẽ ở mức THẤP. Đây là nền tảng của cơ chế ACK và
> phân xử bus (arbitration).

Trong mô hình RTL của dự án này, open-drain được mô phỏng như sau:

```verilog
assign scl = master_scl_drive_low ? 1'b0 : 1'b1;
assign sda = (master_sda_drive_low || slave_sda_drive_low) ? 1'b0 : 1'b1;
```

### 2.2 Trạng Thái Rỗi (Idle State)

Khi bus rảnh (idle), cả SCL và SDA đều ở mức **CAO** nhờ điện trở kéo lên.
Không thiết bị nào được phép bắt đầu giao dịch trừ khi bus đang ở trạng thái idle.

### 2.3 Điều Kiện START và STOP

I²C dùng hai điều kiện đặc biệt để báo hiệu bắt đầu và kết thúc giao dịch —
đây là cách nhận biết khác biệt hoàn toàn so với SPI (dùng CS_N):

| Điều kiện | Định nghĩa | Mô tả |
|---|---|---|
| **START** | SDA xuống THẤP trong khi SCL đang CAO | Báo hiệu bắt đầu giao dịch |
| **STOP** | SDA lên CAO trong khi SCL đang CAO | Báo hiệu kết thúc giao dịch |

```
START:               STOP:
SCL:  ‾‾‾‾‾‾‾‾      SCL:  ‾‾‾‾‾‾‾‾
SDA:  ‾‾‾\____      SDA:  ____/‾‾‾
         ↑ START              ↑ STOP
```

> **Điểm quan trọng:** Trong suốt quá trình truyền dữ liệu thông thường, SDA
> chỉ được phép thay đổi khi SCL ở mức **THẤP**. Khi SCL ở mức CAO, SDA phải
> ổn định — bất kỳ sự thay đổi nào của SDA khi SCL = CAO đều bị hiểu là
> START hoặc STOP.

### 2.4 Giao Dịch (Transaction)

Một giao dịch I²C đầy đủ gồm các bước:

**Giao dịch Ghi (Write):**
```
START | [ADDR 7-bit] [W=0] | ACK | [DATA byte] | ACK | STOP
```

**Giao dịch Đọc (Read):**
```
START | [ADDR 7-bit] [R=1] | ACK | [DATA byte] | NACK | STOP
```

Trong đó:
1. **START** — master tạo điều kiện START.
2. **Address Frame** — master gửi 7-bit địa chỉ slave + 1-bit R/W̄ (8 bit tổng).
3. **ACK từ slave** — slave được chọn kéo SDA xuống trong clock ACK.
4. **Data Frame** — master gửi (W) hoặc nhận (R) 1 byte dữ liệu.
5. **ACK/NACK** — slave ACK khi nhận xong (W); master NACK sau byte đọc cuối (R).
6. **STOP** — master tạo điều kiện STOP để giải phóng bus.

### 2.5 Thứ Tự Bit

I²C luôn truyền **MSB trước** (Most Significant Bit first) — đây là quy ước
bắt buộc của chuẩn I²C, khác với SPI (có thể MSB hoặc LSB tùy thiết bị).

---

## 3. Các Tín Hiệu Giao Tiếp

| Tín hiệu | Tên đầy đủ | Hướng | Mô tả |
|---|---|---|---|
| **SCL** | Serial Clock | Master → Slave | Xung nhịp đồng bộ do master phát |
| **SDA** | Serial Data | Hai chiều (bidirectional) | Đường dữ liệu dùng chung, open-drain |

> I²C chỉ dùng **2 dây**! SDA là đường dữ liệu hai chiều — cả master lẫn slave
> đều có thể drive SDA xuống thấp tùy từng giai đoạn giao dịch.

### Sơ Đồ Cổng Module (i2c_master.v)

```
                         +----------------------+
       clk ------------->|                      |-----> scl_drive_low
     rst_n ------------->|                      |-----> sda_drive_low
     start ------------->|      i2c_master      |-----> busy
        rw ------------->|                      |-----> done
 target_addr[6:0] ------>|                      |-----> ack_error
   tx_data[7:0] -------->|                      |-----> rx_data[7:0]
       sda ------------->|                      |
                         +----------------------+
```

| Tín hiệu | Hướng | Mô tả |
|---|---|---|
| `clk` | Vào | Xung nhịp hệ thống |
| `rst_n` | Vào | Reset đồng bộ, tích cực mức THẤP |
| `start` | Vào | Xung 1 clock để bắt đầu giao dịch |
| `rw` | Vào | `0` = ghi (write), `1` = đọc (read) |
| `target_addr` | Vào | Địa chỉ 7-bit của slave cần giao tiếp |
| `tx_data` | Vào | Byte dữ liệu gửi đi (chỉ dùng khi ghi) |
| `sda` | Vào | Giá trị hiện tại của đường SDA (bus) |
| `scl_drive_low` | Ra | `1` = kéo SCL xuống THẤP; `0` = thả SCL |
| `sda_drive_low` | Ra | `1` = kéo SDA xuống THẤP; `0` = thả SDA |
| `busy` | Ra | CAO trong suốt giao dịch đang thực hiện |
| `done` | Ra | Xung 1 clock báo hiệu hoàn thành giao dịch |
| `ack_error` | Ra | CAO nếu nhận NACK từ slave (địa chỉ hoặc dữ liệu) |
| `rx_data` | Ra | Byte dữ liệu nhận được từ slave (chỉ dùng khi đọc) |

### Sơ Đồ Cổng Module (i2c_slave.v)

```
                         +----------------------+
       clk ------------->|                      |-----> sda_drive_low
     rst_n ------------->|                      |-----> rx_data[7:0]
       scl ------------->|      i2c_slave       |-----> rx_valid
       sda ------------->|                      |-----> busy
   tx_data[7:0] -------->|                      |-----> done
                         +----------------------+
```

| Tín hiệu | Hướng | Mô tả |
|---|---|---|
| `clk` | Vào | Xung nhịp hệ thống |
| `rst_n` | Vào | Reset đồng bộ, tích cực mức THẤP |
| `scl` | Vào | Đường clock đã được giải quyết (resolved bus SCL) |
| `sda` | Vào | Đường dữ liệu đã được giải quyết (resolved bus SDA) |
| `tx_data` | Vào | Byte dữ liệu slave cần gửi khi master đọc |
| `sda_drive_low` | Ra | `1` = kéo SDA xuống (ACK hoặc gửi data); `0` = thả SDA |
| `rx_data` | Ra | Byte dữ liệu nhận được từ master (khi master ghi) |
| `rx_valid` | Ra | Xung 1 clock khi `rx_data` chứa byte mới hợp lệ |
| `busy` | Ra | CAO khi slave đang xử lý giao dịch |
| `done` | Ra | Xung 1 clock khi giao dịch kết thúc (STOP nhận được) |

---

## 4. Cấu Trúc Frame Dữ Liệu

### 4.1 Address Frame (Khung Địa Chỉ)

Đây là khung đầu tiên sau mỗi START condition. Master gửi 8 bit:

```
Bit: [7]  [6]  [5]  [4]  [3]  [2]  [1]  [0]
      A6   A5   A4   A3   A2   A1   A0   R/W
      └──────────── 7-bit address ────────┘  └─ 0=Write, 1=Read
```

- **A6–A0**: địa chỉ 7-bit của slave, gửi MSB trước.
- **R/W (bit 0)**: `0` = Write (master gửi data), `1` = Read (slave gửi data).

Sau khi slave nhận đủ 8 bit và nhận ra địa chỉ của mình, slave sẽ kéo SDA
xuống THẤP trong clock thứ 9 để xác nhận **(ACK)**.

### 4.2 Data Frame (Khung Dữ Liệu)

Sau address ACK, master hoặc slave (tùy chiều) gửi 8 bit dữ liệu, MSB trước:

```
Bit: [7]  [6]  [5]  [4]  [3]  [2]  [1]  [0]
      D7   D6   D5   D4   D3   D2   D1   D0
```

Sau 8 bit, một clock ACK/NACK nữa xuất hiện:
- **Write**: slave kéo SDA xuống = **ACK** (nhận thành công).
- **Read**: master **thả** SDA = **NACK** (kết thúc đọc, không cần thêm byte).

### 4.3 Timing Bit Trên Bus

```
SCL:   ___/‾\___/‾\___/‾\___/‾\___
            |   |   |   |   |   |
SDA:   --[D7]--[D6]--[D5]-- ... --[D0]--
           ↑           ↑
        (SDA thay đổi khi SCL=0)
        (SDA ổn định khi SCL=1 → đây là giá trị được đọc)
```

> **Quy tắc vàng của I²C:** SDA chỉ được thay đổi khi SCL = THẤP.
> Khi SCL = CAO, SDA phải giữ nguyên (đây là bit hợp lệ được lấy mẫu).

### 4.4 Sơ Đồ Timing Đầy Đủ (Giao Dịch Ghi)

```
         S   A6  A5  A4 ... A0  R/W  [ACK]  D7  D6 ...  D0  [ACK]   P
SCL:   ‾‾\_/‾\_/‾\_ ... _/‾\_/‾\_/‾‾‾‾‾\_/‾\_/‾\_ ... _/‾\_/‾‾‾‾\___/‾‾‾‾
SDA:   ‾\___A6__A5_ ... _A0___0___0________D7__D6_ ... _D0___0_______/‾‾‾
        ↑ START                         ↑ ACK by slave                ↑ STOP
```

---

## 5. Timing Giao Dịch

### 5.1 Tần Số SCL

Với module `i2c_master.v`, tần số SCL được tính theo công thức:

```
f_scl = f_clk / (2 × HALF_PERIOD)

trong đó: HALF_PERIOD = max(CLK_DIV, 2)
```

Mỗi nửa chu kỳ SCL (HIGH hoặc LOW) được duy trì trong đúng `HALF_PERIOD` chu kỳ clock hệ thống.

| `CLK_DIV` | `HALF_PERIOD` | f_scl (với f_clk = 50 MHz) | Chế độ I²C |
|:---:|:---:|---:|---|
| 2 | 2 | 12.5 MHz | — (vượt chuẩn, dùng trong simulation) |
| 4 | 4 | 6.25 MHz | — (vượt chuẩn) |
| 25 | 25 | 1 MHz | Fast-mode Plus (Fm+) |
| 50 | 50 | 500 kHz | Fast-mode (Fm) |
| 250 | 250 | 100 kHz | Standard-mode (Sm) |

> Chuẩn I²C định nghĩa Standard-mode (100 kHz), Fast-mode (400 kHz),
> Fast-mode Plus (1 MHz), và High-speed mode (3.4 MHz). Module này không
> triển khai clock stretching nên phù hợp nhất cho simulation và PCB đơn giản.

### 5.2 Số Cạnh SCL Trên Mỗi Giao Dịch

| Giao dịch | Cấu trúc | Số cạnh lên SCL |
|---|---|:---:|
| Write | START + 7-bit addr + R/W + ACK + 8-bit data + ACK + STOP | **18** |
| Read  | START + 7-bit addr + R/W + ACK + 8-bit data + NACK + STOP | **18** |
| NACK (sai địa chỉ) | START + 7-bit addr + R/W + NACK + STOP | **9** |

> Testbench xác minh chính xác các giá trị trên: 18 cạnh lên cho giao dịch
> thành công, 9 cạnh lên khi địa chỉ NACK.

### 5.3 Handshake Master–Host

```
        clk edge
          |
  idle:   start=1 ──► busy=1, sda_drive_low=1 (START condition bắt đầu)
          |
  busy:   [address frame: 8 SCL cycles]
          [ACK clock:      1 SCL cycle]
          [data frame:     8 SCL cycles]
          [ACK/NACK clock: 1 SCL cycle]
          [STOP sequence:  3 half-ticks]
          |
  finish: busy=0, done=1 (xung 1 clock)
          rx_data cập nhật (nếu là giao dịch đọc)
```

**Quy tắc sử dụng:**
1. Đặt `target_addr`, `rw`, và `tx_data` ổn định trước khi pulse `start`.
2. Duy trì `start = 1` trong **ít nhất 1 chu kỳ clock** khi `busy = 0`.
3. `busy` sẽ lên CAO **ngay chu kỳ tiếp theo** sau khi yêu cầu được chấp nhận.
4. Yêu cầu mới trong khi `busy = 1` bị **bỏ qua hoàn toàn** — các tín hiệu
   đầu vào được chốt (latch) khi bắt đầu giao dịch.
5. `done` xung **1 clock**, đọc `rx_data` (nếu đọc) hoặc kiểm tra `ack_error` sau cạnh lên đó.

---

## 6. Cấu Trúc Bus Đa Thiết Bị

### 6.1 Nhiều Slave Trên Cùng Bus

Tất cả slave chia sẻ chỉ 2 đường dây SCL và SDA. Mỗi slave được phân biệt
bằng địa chỉ 7-bit duy nhất.

```
          ┌──────────┐   ┌─────────┐   ┌─────────┐   ┌─────────┐
          │  Master  │   │ Slave 0 │   │ Slave 1 │   │ Slave 2 │
          │          │   │  0x42   │   │  0x43   │   │  0x44   │
          └──┬───┬───┘   └──┬──┬───┘   └──┬──┬───┘   └──┬──┬───┘
             │   │          │  │          │  │          │  │
VCC──[Rp]────┴───┼──────────┴──┼──────────┴──┼──────────┴──┼──── SDA
                 │             │             │             │
VCC──[Rp]────────┴─────────────┴─────────────┴─────────────┴──── SCL
```

> Khác với SPI, I²C không cần thêm dây khi thêm slave. Toàn bộ 127 địa chỉ
> (2⁷ - 1, trừ các địa chỉ dành riêng) có thể dùng trên cùng 2 dây.

### 6.2 Địa Chỉ Dành Riêng (Reserved Addresses)

Chuẩn I²C dành một số địa chỉ cho mục đích đặc biệt:

| Địa chỉ (7-bit) | Mục đích |
|:---:|---|
| `0x00` | General Call (broadcast tới tất cả slave) |
| `0x01` | CBUS compatibility |
| `0x02–0x03` | Reserved |
| `0x04–0x07` | Hs-mode master code |
| `0x78–0x7B` | 10-bit addressing extension |
| `0x7C–0x7F` | Reserved for future use |

> Module trong dự án này hỗ trợ địa chỉ 7-bit nhưng **không** xử lý General Call.

### 6.3 Phân Xử Bus (Arbitration)

Khi hai master cùng cố gắng chiếm bus:
- Cả hai phát START và bắt đầu gửi địa chỉ.
- Mỗi master đọc lại SDA sau khi drive — nếu SDA ≠ bit mình gửi (vì master
  kia đang kéo xuống), master biết mình **thua** và dừng lại.
- Master thua sẽ chờ cho đến khi bus idle rồi thử lại.

> Module `i2c_master.v` trong dự án này **không triển khai** cơ chế arbitration
> (một master duy nhất trong thiết kế tích hợp).

---

## 7. So Sánh Với UART và SPI

| Tiêu chí | I²C | SPI | UART |
|---|---|---|---|
| **Số dây tối thiểu** | 2 (SDA + SCL) | 4 (MOSI, MISO, SCLK, CS) | 2 (TX + RX) |
| **Xung nhịp** | Có (đồng bộ) | Có (đồng bộ) | Không (bất đồng bộ) |
| **Số thiết bị** | N master + N slave | 1 master + N slave (N CS pins) | 2 (point-to-point) |
| **Địa chỉ thiết bị** | Có (7 hoặc 10 bit) | Không (dùng CS riêng) | Không |
| **Tốc độ điển hình** | 100 kHz – 5 MHz | 1 – 50+ MHz | 115.2 kbps – 1 Mbps |
| **Full-duplex** | ❌ Không (half-duplex) | ✅ Có | ✅ Có |
| **Kéo lên (pull-up)** | ✅ Bắt buộc | ❌ Không cần | ❌ Không cần |
| **Khoảng cách** | Ngắn (PCB, <1m) | Ngắn (PCB, <1m) | Ngắn–vừa |
| **Độ phức tạp** | Trung bình | Thấp | Thấp |
| **Ứng dụng điển hình** | Cảm biến, EEPROM, IMU | Flash SPI, ADC, màn hình | Debug console, GPS, BT |

### Khi Nào Dùng I²C?

✅ **Nên dùng I²C khi:**
- Cần kết nối nhiều slave nhưng số chân MCU/FPGA hạn chế — chỉ cần 2 dây cho cả bus.
- Giao tiếp với cảm biến tốc độ thấp/vừa: nhiệt độ, độ ẩm, IMU, EEPROM, RTC.
- Mạch PCB nội bộ, khoảng cách ngắn (<1m).

❌ **Không nên dùng I²C khi:**
- Cần tốc độ cao (>1 MHz) → dùng SPI.
- Cần truyền đồng thời hai chiều (full-duplex) → dùng SPI.
- Giao tiếp debug đơn giản với máy tính → dùng UART.
- Khoảng cách xa (>1m) → dùng RS-485 hoặc CAN.

---

## 8. Ứng Dụng Thực Tế

### 8.1 Cảm Biến Môi Trường

Ứng dụng phổ biến nhất của I²C. Hầu hết cảm biến nhiệt độ/độ ẩm/áp suất hiện đại đều dùng I²C.

| Thiết bị | Loại | Địa chỉ I²C | Tốc độ |
|---|---|:---:|---|
| SHT31 (Sensirion) | Nhiệt độ + Độ ẩm | 0x44 / 0x45 | Fast-mode (400 kHz) |
| BME280 (Bosch) | Nhiệt + Ẩm + Áp suất | 0x76 / 0x77 | Fast-mode (400 kHz) |
| LM75 (NXP) | Nhiệt độ | 0x48–0x4F | Fast-mode (400 kHz) |
| BMP280 (Bosch) | Áp suất + Nhiệt độ | 0x76 / 0x77 | Fast-mode (400 kHz) |

### 8.2 Cảm Biến Chuyển Động (IMU)

| Thiết bị | Loại | Địa chỉ I²C | Tốc độ |
|---|---|:---:|---|
| MPU-6050 (InvenSense) | Gia tốc + Con quay 6-axis | 0x68 / 0x69 | Fast-mode (400 kHz) |
| ICM-42688 (TDK) | IMU 6-axis | 0x68 / 0x69 | Fast-mode Plus (1 MHz) |
| LSM6DS3 (ST) | IMU 6-axis | 0x6A / 0x6B | Fast-mode (400 kHz) |

### 8.3 Bộ Nhớ EEPROM

```
MCU ──I²C──► AT24C256  (EEPROM 256Kbit, addr: 0x50–0x57)
MCU ──I²C──► M24M02    (EEPROM 2Mbit,   addr: 0x50–0x57)
MCU ──I²C──► 24FC1025  (EEPROM 1Mbit,   addr: 0x50–0x53)
```

### 8.4 Đồng Hồ Thời Gian Thực (RTC) và Thiết Bị Khác

```
MCU ──I²C──► DS3231    (RTC chính xác cao,      addr: 0x68)
MCU ──I²C──► PCA9685   (16-kênh PWM/Servo,      addr: 0x40–0x7F)
MCU ──I²C──► ADS1115   (ADC 16-bit 4-kênh,      addr: 0x48–0x4B)
MCU ──I²C──► MCP4725   (DAC 12-bit,             addr: 0x60/0x61)
```

### 8.5 Trong FPGA / ASIC

I²C thường được dùng để:
- **Cấu hình/điều khiển FPGA** — đọc cảm biến hoặc ghi thanh ghi cấu hình.
- **Giao tiếp với host MCU** — FPGA/ASIC đóng vai trò slave I²C để nhận lệnh.
- **Quản lý điện (PMBus/SMBus)** — các giao thức dựa trên I²C để quản lý nguồn điện.

---

## 9. Triển Khai RTL — i2c_master.v và i2c_slave.v

### 9.1 Tổng Quan Thiết Kế

Dự án triển khai ba module:

| Module | Vai trò | File |
|---|---|---|
| `i2c_master` | I²C controller: tạo START/STOP, gửi địa chỉ và data, xử lý ACK | `i2c_master.v` |
| `i2c_slave` | I²C target: lắng nghe bus, decode địa chỉ, phản hồi ACK/data | `i2c_slave.v` |
| `i2c_top` | Wrapper tích hợp: giải quyết open-drain, kết nối master và slave | `i2c_top.v` |

**Tham số:**

| Tham số | Module | Mặc định | Mô tả |
|---|---|:---:|---|
| `CLK_DIV` | `i2c_master`, `i2c_top` | `4` | Số chu kỳ clock hệ thống mỗi nửa chu kỳ SCL |
| `SLAVE_ADDR` | `i2c_slave`, `i2c_top` | `7'h42` | Địa chỉ 7-bit mà slave phản hồi |

### 9.2 Kiến Trúc Master FSM

Master sử dụng **một process tuần tự duy nhất** với bộ đếm chia clock nội bộ (`div_count`).
Mỗi trạng thái FSM chờ `half_tick` (khi `div_count == HALF_PERIOD - 1`) để chuyển tiếp.

```
                       start=1, busy=0
                             |
                             v
  +----------+       +-----------+       +------------+       +-------------+
  | ST_IDLE  | ----> | ST_START  | ----> | ST_ADDRESS | ----> | ST_ADDR_ACK |
  +----------+       +-----------+       +------------+       +-------------+
       ^                                                        |         |
       |                                                   ACK, rw=1  ACK, rw=0
       |                                                        |         |
       |                                                        v         v
       |                                                  +---------+ +-----------+
       |                                    NACK          | ST_READ | | ST_WRITE  |
       |                                      |           +---------+ +-----------+
       |                                      |                |          |
       |                                      |                v          v
       |                                      |       +--------------+ +---------------+
       |                                      |       | ST_READ_NACK | | ST_WRITE_ACK  |
       |                                      |       +--------------+ +---------------+
       |                                      |                |          |
       |                                      +--------+-------+----------+
       |                                               |
       |                                               v
       |                                         +------------+
       |                                         | ST_STOP_LOW|
       |                                         +------------+
       |                                               |
       |                                               v
       |                                        +-------------+
       |                                        | ST_STOP_HIGH|
       |                                        +-------------+
       |                                               |
       |                                               v
       |          done=1                        +-------------+
       +--------------------------------------- | ST_STOP_FREE|
                                                +-------------+
```

| Trạng thái | Hành động |
|---|---|
| `ST_IDLE` | Giữ SCL và SDA thả ra (bus idle), chờ `start=1` |
| `ST_START` | Kéo SDA xuống (trong khi SCL vẫn CAO = START), sau đó kéo SCL xuống |
| `ST_ADDRESS` | Xuất 8 bit (`{target_addr, rw}`) trên SDA, MSB trước, toggle SCL |
| `ST_ADDR_ACK` | Thả SDA, đọc SDA khi SCL lên cao; `sda=0` → ACK, `sda=1` → NACK |
| `ST_WRITE` | Xuất 8 bit `tx_data` trên SDA, MSB trước |
| `ST_WRITE_ACK` | Thả SDA, đọc ACK từ slave |
| `ST_READ` | Thả SDA, đọc từng bit từ slave khi SCL cao, lưu vào `rx_shift` |
| `ST_READ_NACK` | Thả SDA (NACK) để báo master không muốn thêm byte |
| `ST_STOP_LOW` | Kéo SCL lên CAO trong khi SDA vẫn THẤP |
| `ST_STOP_HIGH` | Thả SDA (lên CAO) trong khi SCL CAO = STOP condition |
| `ST_STOP_FREE` | Phát `done=1`, xóa `busy`, quay về `ST_IDLE` |

### 9.3 Kiến Trúc Slave FSM

Slave **không dùng SCL làm clock RTL**. Thay vào đó, slave chạy hoàn toàn trong
domain của `clk` hệ thống và phát hiện các sự kiện bus thông qua tín hiệu trễ
1 clock:

```verilog
reg scl_d, sda_d;          // Giá trị trễ 1 clock của SCL và SDA
always @(posedge clk) begin
    scl_d <= scl;
    sda_d <= sda;
end

wire scl_rising  = !scl_d &&  scl;       // Cạnh lên SCL
wire scl_falling =  scl_d && !scl;       // Cạnh xuống SCL
wire start_event =  sda_d && !sda && scl; // SDA xuống khi SCL=HIGH → START
wire stop_event  = !sda_d &&  sda && scl; // SDA lên khi SCL=HIGH  → STOP
```

```
                      start_event
                           |
                           v
  +----------+      +------------+      +-------------+
  | ST_IDLE  | ---> | ST_ADDRESS | ---> | ST_ADDR_ACK |
  +----------+      +------------+      +-------------+
       ^                                  |          |
       |                            not selected   selected
       |                                  |      rw=0 |  rw=1
       |                                  |        |       |
       |                                  v        v       v
       |                          +-----------+ +----------+ +----------+
       |                          |ST_WAIT_STOP| | ST_WRITE | | ST_READ  |
       |                          +-----------+ +----------+ +----------+
       |                                |            |            |
       |                                |            v            v
       |                                |   +---------------+ +--------------+
       |                                |   | ST_WRITE_ACK  | | ST_READ_NACK |
       |                                |   +---------------+ +--------------+
       |                                |            |            |
       |                                +------+-----+------------+
       |                                       |
       |                                  stop_event
       |          done=1                       |
       +---------------------------------------+
```

| Trạng thái | Hành động |
|---|---|
| `ST_IDLE` | Chờ `start_event`; bất kỳ START nào sẽ kích hoạt slave |
| `ST_ADDRESS` | Shift 8 bit vào `address_shift` trên `scl_rising`; bit cuối (R/W) xác định hướng |
| `ST_ADDR_ACK` | Nếu địa chỉ khớp → kéo SDA xuống (ACK); nếu không → thả (NACK) |
| `ST_WRITE` | Shift 8 bit data vào `rx_shift` trên `scl_rising`; khi xong → cập nhật `rx_data` |
| `ST_WRITE_ACK` | Kéo SDA xuống (ACK) trên `scl_falling`, thả sau khi SCL xuống lần tiếp |
| `ST_READ` | Drive từng bit của `tx_latched` ra SDA trên `scl_falling`, MSB trước |
| `ST_READ_NACK` | Thả SDA — đợi master gửi NACK (master tự kéo lên) |
| `ST_WAIT_STOP` | Chờ `stop_event`; phát `done=1` khi STOP được phát hiện |

### 9.4 Cơ Chế Open-Drain trong i2c_top.v

`i2c_top.v` giải quyết bus open-drain bằng logic wired-AND đơn giản:

```verilog
// Wired-AND: ai kéo xuống thì bus xuống thấp
assign scl = master_scl_drive_low ? 1'b0 : 1'b1;
assign sda = (master_sda_drive_low || slave_sda_drive_low) ? 1'b0 : 1'b1;
```

Giá trị `sda` đã giải quyết được kết nối trở lại cả master lẫn slave, cho phép:
- Master đọc ACK của slave (slave kéo SDA xuống khi SCL cao).
- Slave đọc bit data từ master.
- Slave phát hiện START/STOP dựa trên giá trị SDA giải quyết.

### 9.5 Chốt Dữ Liệu (Data Latching)

**Master side:** `address_frame` và `tx_latched` được chốt khi `start=1` được
chấp nhận trong `ST_IDLE`. Host có thể thay đổi `target_addr`/`tx_data` tự do
trong khi giao dịch đang chạy mà không gây lỗi.

**Slave side:** `tx_latched` (byte trả lời khi master đọc) được chốt trong `i2c_top.v`
ngay khi `start=1` được chấp nhận:

```verilog
// i2c_top.v
always @(posedge clk) begin
    if (!rst_n)
        slave_tx_latched <= 8'h00;
    else if (start && !master_busy)
        slave_tx_latched <= slave_tx_data; // Chốt trước khi giao dịch bắt đầu
end
```

### 9.6 Testbench và Kết Quả Xác Minh

Testbench `i2c_top_tb.v` tự kiểm tra (self-checking) với **6 nhóm test case**:

| Test Case | Nội dung |
|---|---|
| **TC1** | Reset và idle: SCL=1, SDA=1, không có busy/done/error |
| **TC2** | 3 giao dịch ghi có hướng: `0xA5`, `0x00`, `0xFF` |
| **TC3** | 3 giao dịch đọc có hướng: `0x3C`, `0x00`, `0xFF` |
| **TC4** | Xử lý địa chỉ NACK: sai địa chỉ → `ack_error=1`, 9 SCL rising edges |
| **TC5** | Bỏ qua yêu cầu khi `busy=1`: dữ liệu đang giao dịch không bị ghi đè |
| **TC6** | Reset abort và phục hồi: reset giữa chừng, giao dịch tiếp theo hoạt động OK |

Mỗi giao dịch thành công kiểm tra:
- `slave_rx_data` khớp với byte master ghi; `master_rx_data` khớp với byte slave cung cấp.
- Đúng **18** cạnh lên SCL cho giao dịch thành công; **9** cạnh cho NACK địa chỉ.
- Đúng **1** điều kiện START và **1** điều kiện STOP.
- Đúng 1 xung `master_done` và 1 xung `slave_done`.
- `busy`, SCL, SDA phục hồi về trạng thái idle đúng sau STOP.

Kết quả khi tất cả pass:

```
=== PASS: all 96 checks passed ===
```

---

## 10. Các Lỗi I²C Phổ Biến

### 10.1 Không Có Điện Trở Kéo Lên (Missing Pull-up)

**Nguyên nhân:** Thiếu điện trở kéo lên trên SDA hoặc SCL (lỗi phần cứng).

**Triệu chứng:** Bus kẹt ở mức THẤP. Oscilloscope thấy dạng sóng không lên được
mức HIGH, hoặc rise time cực kỳ chậm.

**Phòng tránh:** Thêm điện trở kéo lên phù hợp (thường 4.7 kΩ cho 100 kHz,
2.2 kΩ cho 400 kHz). Giá trị nhỏ hơn → rise time nhanh hơn nhưng tiêu thụ dòng nhiều hơn.

### 10.2 Địa Chỉ Sai (Address Mismatch)

**Nguyên nhân:** Master gửi địa chỉ không khớp với bất kỳ slave nào trên bus.

**Triệu chứng:** Không có ACK sau address frame → `ack_error = 1`. Giao dịch
kết thúc sớm (chỉ 9 cạnh SCL thay vì 18).

**Phòng tránh:** Kiểm tra địa chỉ slave trong datasheet. Một số thiết bị có
địa chỉ configurable qua chân ADDR. Trong RTL, kiểm tra tham số `SLAVE_ADDR`.

### 10.3 Bus Kẹt (Bus Hang / Stuck SDA)

**Nguyên nhân:** Slave đang giữ SDA xuống thấp (ví dụ: reset bất ngờ giữa giao
dịch, slave đang chờ ACK mà không nhận được thêm clock nào).

**Triệu chứng:** SDA bị kẹt ở mức THẤP, master không thể tạo START condition
hợp lệ (START yêu cầu SDA đang HIGH).

**Phòng tránh:** Gửi **9 clock pulse** trên SCL để hoàn thành bất kỳ byte nào
đang giữa chừng, sau đó tạo STOP condition. Đây là thủ tục "bus recovery" theo chuẩn I²C.

### 10.4 Clock Stretching Không Được Xử Lý

**Nguyên nhân:** Slave kéo SCL xuống để yêu cầu master chờ (clock stretching),
nhưng master không đọc lại SCL để phát hiện.

**Triệu chứng:** Dữ liệu bị sai hoặc mất đồng bộ vì master tiếp tục chạy đồng hồ
trong khi slave chưa sẵn sàng.

**Phòng tránh:** Master cần đọc lại SCL sau khi thả ra và chỉ tiếp tục khi SCL
thực sự lên cao. Module `i2c_master.v` trong dự án **không hỗ trợ** clock stretching.

### 10.5 Vi Phạm Setup/Hold (Setup/Hold Violation)

**Nguyên nhân:** SCL chạy quá nhanh so với thời gian setup/hold của slave,
hoặc điện trở kéo lên quá lớn làm rise time quá dài.

**Triệu chứng:** Dữ liệu đúng khi chạy chậm, sai khi tăng tốc độ.

**Phòng tránh:** Chọn `CLK_DIV` phù hợp để `f_scl` nằm trong giới hạn của
slave. Chọn điện trở kéo lên nhỏ đủ để rise time < 1/5 chu kỳ SCL.

### 10.6 Xung Đột SDA (SDA Contention)

**Nguyên nhân:** Cả master và slave cùng drive SDA theo hướng ngược nhau tại
cùng một thời điểm (vi phạm giao thức).

**Triệu chứng:** Trong phần cứng thực tế có thể gây hỏng GPIO driver. Trong
simulation, SDA xuất hiện giá trị không xác định (X).

**Phòng tránh:** Đảm bảo đúng phía mới được drive SDA tại mỗi giai đoạn. Trong
RTL, logic FSM phải thả `sda_drive_low` trước khi phía kia bắt đầu drive.

### 10.7 Bảng Tóm Tắt Lỗi

| Lỗi | Triệu chứng | Nguyên nhân chính | Cách phòng tránh |
|---|---|---|---|
| **Thiếu pull-up** | Bus kẹt ở THẤP, rise time xấu | Không có Rp | Thêm điện trở kéo lên phù hợp |
| **Sai địa chỉ** | `ack_error=1`, chỉ 9 SCL | Địa chỉ không khớp | Kiểm tra datasheet / `SLAVE_ADDR` |
| **Bus hang** | SDA kẹt THẤP | Slave treo giữa chừng | Bus recovery: 9 clock pulse + STOP |
| **Clock stretching** | Data sai lúc nhanh | Master không đọc lại SCL | Đọc lại SCL sau khi thả, chờ HIGH |
| **Setup/Hold vi phạm** | Lỗi khi tốc độ cao | `CLK_DIV` nhỏ / Rp lớn | Tăng `CLK_DIV`, chọn Rp nhỏ hơn |
| **SDA contention** | Data X (simulation) | Hai phía cùng drive SDA | Tuân thủ đúng giao thức drive SDA |

---

## 11. Tài Liệu Tham Khảo

| # | Tên tài liệu | Nguồn | Mô tả |
|---|---|---|---|
| [1] | **I²C-bus specification and user manual Rev. 7.0** | [NXP UM10204](https://www.nxp.com/docs/en/user-guide/UM10204.pdf) | Tài liệu chuẩn gốc từ NXP, bao gồm tất cả các chế độ và timing |
| [2] | **Understanding the I²C Bus** | [Texas Instruments SLVA704](https://www.ti.com/lit/an/slva704/slva704.pdf?ts=1699596969514&ref_url=https%3A%2F%2Fwww.google.com%2F) | Giải thích trực quan về giao thức, pull-up, và timing |
| [3] | **Wikipedia — I²C** | [wikipedia.org](https://en.wikipedia.org/wiki/I%C2%B2C) | Lịch sử, các biến thể, và so sánh giao thức |
| [4] | **I²C Bus Pullup Resistor Calculation** | [TI SLVA689](https://www.ti.com/lit/an/slva689/slva689.pdf) | Hướng dẫn tính toán điện trở kéo lên tối ưu |
| [5] | **i2c_top README** | README.md | Tài liệu module RTL, bảng tham số, và hướng dẫn mô phỏng |
| [6] | **Giao thức I2C — E-Lab** | [blog.deviot.vn](https://blog.deviot.vn/posts/lap-trinh-vi-dieu-khien/giao-thuc-i2c) | Bài viết tiếng Việt: giải thích giao thức I2C, cách hoạt động và triển khai |

*Tài liệu lý thuyết giao thức I²C — Tác giả: Long Hai*
