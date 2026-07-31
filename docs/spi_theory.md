# Lý Thuyết Giao Thức SPI

![Chủ đề](https://img.shields.io/badge/Chủ%20đề-Lý%20thuyết%20giao%20thức-blueviolet.svg)
![Giao thức](https://img.shields.io/badge/Giao%20thức-SPI-blue.svg)
![Ngôn ngữ](https://img.shields.io/badge/Ngôn%20ngữ-Tiếng%20Việt-red.svg)

---

## Mục Lục

1. [SPI Là Gì?](#1-spi-là-gì)
2. [Đặc Điểm Cơ Bản](#2-đặc-điểm-cơ-bản)
3. [Các Tín Hiệu Giao Tiếp](#3-các-tín-hiệu-giao-tiếp)
4. [Bốn Chế Độ Clock (Modes 0–3)](#4-bốn-chế-độ-clock-modes-03)
5. [Timing Giao Dịch](#5-timing-giao-dịch)
6. [Cấu Trúc Bus Đa Slave](#6-cấu-trúc-bus-đa-slave)
7. [So Sánh Với UART và I²C](#7-so-sánh-với-uart-và-i²c)
8. [Ứng Dụng Thực Tế](#8-ứng-dụng-thực-tế)
9. [Triển Khai RTL — spi_master.v](#9-triển-khai-rtl--spi_masterv)
10. [Các Lỗi SPI Phổ Biến](#10-các-lỗi-spi-phổ-biến)
11. [Tài Liệu Tham Khảo](#11-tài-liệu-tham-khảo)

---

## 1. SPI Là Gì?

**SPI** *(Serial Peripheral Interface)* là một giao thức truyền thông nối tiếp
**đồng bộ** (synchronous), **song công toàn phần** (full-duplex), và **master–slave**,
được phát triển bởi Motorola vào những năm 1980.

- **Đồng bộ**: có một đường xung nhịp chung (SCLK) do master phát ra, đảm bảo
  cả hai bên đồng bộ hoàn hảo từng bit một.
- **Song công toàn phần**: master và slave trao đổi dữ liệu đồng thời trên hai
  đường riêng biệt (MOSI và MISO).
- **Master–slave**: chỉ một thiết bị (master) điều khiển xung nhịp và khởi tạo
  giao dịch; các slave chỉ phản hồi khi được chọn.

### Sơ Đồ Kết Nối Cơ Bản (1 Slave)

```
   Master                                   Slave
   ┌────────────┐                          ┌────────────┐
   │       MOSI ├─────────────────────────►│ MOSI       │
   │            │                          │            │
   │       MISO │◄─────────────────────────┤ MISO       │
   │            │                          │            │
   │       SCLK ├─────────────────────────►│ SCLK       │
   │            │                          │            │
   │       CS_N ├─────────────────────────►│ CS_N       │
   └────────────┘                          └────────────┘
```

> SPI cần **4 dây** tối thiểu cho một slave: MOSI, MISO, SCLK và CS.
> Với mỗi slave thêm, chỉ cần thêm **1 dây CS** (không cần thêm MOSI/MISO/SCLK).

---

## 2. Đặc Điểm Cơ Bản

### 2.1 Trạng Thái Rỗi (Idle State)

- **CS_N** (chip select, active-low): ở mức **CAO** khi không có giao dịch.
  Khi master kéo CS_N xuống THẤP, slave được chọn và bắt đầu lắng nghe.
- **SCLK**: duy trì ở mức **CPOL** (xem Mục 4) khi rỗi.
- **MOSI / MISO**: trạng thái không xác định khi CS_N = HIGH (thường là trở kháng
  cao hoặc giá trị cuối cùng được ghi).

### 2.2 Giao Dịch (Transaction)

Một giao dịch SPI gồm các bước theo thứ tự:

1. Master kéo **CS_N xuống THẤP** để chọn slave.
2. Master phát **SCLK** — số xung = số bit cần truyền.
3. Tại mỗi chu kỳ SCLK: master đặt bit mới lên **MOSI**, slave đặt bit lên **MISO**.
4. Cả hai bên lấy mẫu dữ liệu của đối phương tại cạnh xung nhịp thích hợp (xem Mục 4).
5. Sau khi truyền xong tất cả bit, master kéo **CS_N lên CAO** để kết thúc giao dịch.

> Vì SPI là **giao thức toàn phần**, master gửi `DATA_WIDTH` bit trên MOSI đồng
> thời nhận `DATA_WIDTH` bit từ slave trên MISO trong một giao dịch.

### 2.3 Thứ Tự Bit

SPI không bắt buộc thứ tự bit — có thể **MSB-first** hoặc **LSB-first** tùy
thiết bị. Tuy nhiên, **MSB-first là quy ước phổ biến nhất** (ví dụ: SPI Flash,
ADC, DAC hầu hết dùng MSB-first).

Module `spi_master.v` trong dự án này sử dụng **MSB-first**.

---

## 3. Các Tín Hiệu Giao Tiếp

| Tín hiệu | Tên đầy đủ | Hướng | Mô tả |
|---|---|---|---|
| **MOSI** | Master Out Slave In | Master → Slave | Dữ liệu từ master gửi tới slave |
| **MISO** | Master In Slave Out | Slave → Master | Dữ liệu từ slave phản hồi về master |
| **SCLK** | Serial Clock | Master → Slave | Xung nhịp đồng bộ do master phát |
| **CS_N** | Chip Select (active-low) | Master → Slave | Chọn slave cụ thể; tích cực mức THẤP |

> **Chú ý về tên gọi:** Một số tài liệu dùng tên khác nhau cho các tín hiệu này.
> Ví dụ: MOSI = SDO (Serial Data Out), MISO = SDI, SCLK = SCK, CS = SS (Slave Select).
> Bản chất tín hiệu là như nhau.

### Sơ Đồ Cổng Module (spi_master.v)

```
                         +----------------------+
       clk ------------->|                      |-----> sclk
     rst_n ------------->|                      |-----> mosi
     start ------------->|      spi_master      |-----> cs_n
tx_data[W-1:0] --------->|                      |-----> busy
      miso ------------->|                      |-----> done
                         |                      |-----> rx_data[W-1:0]
                         +----------------------+
```

| Tín hiệu | Hướng | Mô tả |
|---|---|---|
| `clk` | Vào | Xung nhịp hệ thống |
| `rst_n` | Vào | Reset đồng bộ, tích cực mức THẤP |
| `start` | Vào | Xung 1 clock để bắt đầu giao dịch |
| `tx_data` | Vào | Từ dữ liệu gửi đi trên MOSI |
| `miso` | Vào | Dữ liệu nối tiếp nhận từ slave |
| `sclk` | Ra | Xung nhịp SPI phát ra cho slave |
| `mosi` | Ra | Dữ liệu nối tiếp gửi tới slave |
| `cs_n` | Ra | Chọn slave, tích cực mức THẤP |
| `busy` | Ra | CAO trong suốt giao dịch đang thực hiện |
| `done` | Ra | Xung 1 clock báo hiệu hoàn thành giao dịch |
| `rx_data` | Ra | Từ dữ liệu nhận được từ MISO |

---

## 4. Bốn Chế Độ Clock (Modes 0–3)

Đây là phần **quan trọng và thường gây nhầm lẫn nhất** của SPI. Chế độ clock
được xác định bởi hai tham số:

### CPOL — Clock Polarity (Cực tính xung nhịp)

**CPOL** xác định **trạng thái nghỉ (idle)** của đường dây SCLK khi không có giao dịch nào
đang diễn ra (tức là khi `CS_N = HIGH`):

| Giá trị | Mức SCLK khi idle | Ý nghĩa |
|:-------:|-------------------|---------|
| `CPOL = 0` | **THẤP (LOW)** | SCLK ở mức 0 trước và sau mỗi giao dịch |
| `CPOL = 1` | **CAO (HIGH)** | SCLK ở mức 1 trước và sau mỗi giao dịch |

> Hệ quả: Cạnh đầu tiên của SCLK sau khi CS_N xuống thấp sẽ là **cạnh lên** nếu `CPOL=0`,
> hoặc **cạnh xuống** nếu `CPOL=1`. Đây được gọi là **Leading edge**.

### CPHA — Clock Phase (Pha xung nhịp)

**CPHA** xác định **cạnh SCLK nào được dùng để lấy mẫu dữ liệu** (Sample), tức là thời điểm
Master đọc MISO và Slave đọc MOSI:

| Giá trị | Cạnh lấy mẫu | Cạnh đặt dữ liệu | Ghi chú |
|:-------:|:------------:|:----------------:|---------|
| `CPHA = 0` | **Leading** (cạnh đầu tiên) | **Trailing** (cạnh thứ hai) | Bit đầu tiên phải có mặt trên đường dây **ngay khi CS_N xuống** |
| `CPHA = 1` | **Trailing** (cạnh thứ hai) | **Leading** (cạnh đầu tiên) | Bit đầu tiên được đặt tại **Leading edge** đầu tiên |

> **Tóm tắt nhanh:**
> - `CPOL` → SCLK trông như thế nào khi **đang nghỉ**.
> - `CPHA` → Dữ liệu được **đọc vào** (sample) tại cạnh **thứ mấy** của SCLK.
>
> Hai tham số kết hợp cho ra **4 mode** (Mode 0–3), mỗi mode là một tổ hợp `{CPOL, CPHA}` khác nhau.

- **CPOL** *(Clock Polarity)*: mức logic của SCLK khi rỗi (idle).
- **CPHA** *(Clock Phase)*: cạnh xung nhịp nào được dùng để lấy mẫu (sample)
  và cạnh nào để đặt dữ liệu (launch).

### 4.1 Bảng Chế Độ SPI

| Mode | CPOL | CPHA | SCLK idle | Cạnh lấy mẫu (Sample) | Cạnh đặt dữ liệu (Shift) |
|:---:|:---:|:---:|---|---|---|
| **0** | 0 | 0 | THẤP | Cạnh lên (rising) | Cạnh xuống (falling) |
| **1** | 0 | 1 | THẤP | Cạnh xuống (falling) | Cạnh lên (rising) |
| **2** | 1 | 0 | CAO | Cạnh xuống (falling) | Cạnh lên (rising) |
| **3** | 1 | 1 | CAO | Cạnh lên (rising) | Cạnh xuống (falling) |

> **Cạnh lấy mẫu (Sample edge)** là cạnh mà cả hai bên **đọc dữ liệu** của đối phương:
> Master đọc MISO ⇒ lưu vào `rx_data`; Slave đọc MOSI ⇒ lưu vào `rx_data`.
>
> **Cạnh đặt dữ liệu (Shift edge)** là cạnh ngược lại, cả hai bên **xuất bit tiếp theo** ra đường dây:
> Master cập nhật MOSI; Slave cập nhật MISO. Bit mới phải ổn định *trước khi* cạnh Sample đến.
>
> Nói đơn giản: **Shift = TX (gửi ra)**, **Sample = RX (đọc vào)**. Hai hành động này luôn xảy ra ở cạnh đối nghịch nhau — đơn giản để tránh xung đột.

### 4.2 Giải Thích Chi Tiết

#### CPOL = 0 (SCLK idle LOW)

```
SCLK idle=0:    _____/‾\__/‾\__/‾\__/‾\__/‾\__/‾\__/‾\__/‾\________
CS_N:       ‾‾‾\___________________________________________________/‾‾‾
```

- `CPOL=0, CPHA=0` **(Mode 0)**: lấy mẫu tại **cạnh lên** (leading edge = rising).
  MOSI phải ổn định **trước** cạnh lên đầu tiên — bit đầu tiên phải có mặt ngay
  khi CS_N xuống THẤP.

- `CPOL=0, CPHA=1` **(Mode 1)**: lấy mẫu tại **cạnh xuống** (trailing edge = falling).
  Bit đầu tiên được đặt lên MOSI tại **cạnh lên** và lấy mẫu tại **cạnh xuống**.

#### CPOL = 1 (SCLK idle HIGH)

```
SCLK idle=1:    ‾‾‾‾‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
CS_N:       ‾‾‾\___________________________________________________/‾‾‾
```

- `CPOL=1, CPHA=0` **(Mode 2)**: đảo logic so với Mode 0. Lấy mẫu tại **cạnh
  xuống** (leading edge khi CPOL=1). MOSI phải ổn định trước cạnh xuống đầu tiên.

- `CPOL=1, CPHA=1` **(Mode 3)**: đảo logic so với Mode 1. Lấy mẫu tại **cạnh
  lên** (trailing edge khi CPOL=1).

### 4.3 Quy Tắc Ghi Nhớ

> - **CPOL** = trạng thái của SCLK **khi không làm gì** (0 = THẤP, 1 = CAO).
> - **CPHA = 0** → lấy mẫu tại **cạnh đầu tiên** (leading edge).
> - **CPHA = 1** → lấy mẫu tại **cạnh thứ hai** (trailing edge).
> - Mode **0** và **3** là phổ biến nhất trong thực tế.

### 4.4 Ví Dụ Timing Mode 0 (CPOL=0, CPHA=0)

```
CS_N:  ‾‾‾‾\________________________________________/‾‾‾‾
SCLK:        _____/‾\__/‾\__/‾\__/‾\__/‾\__/‾\__/‾\___
             ^    ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^
MOSI:  ------| B7 | B6 | B5 | B4 | B3 | B2 | B1 | B0 |--
             (valid before 1st rising edge)
MISO:  ------| R7 | R6 | R5 | R4 | R3 | R2 | R1 | R0 |--
             (slave drives after CS_N falls)
```

- MOSI đặt bit **trước** mỗi cạnh lên; slave lấy mẫu tại **cạnh lên**.
- Slave đặt MISO sau mỗi cạnh xuống; master lấy mẫu tại **cạnh lên**.

---

## 5. Timing Giao Dịch

### 5.1 Sơ Đồ Timing Tổng Quát

```
start    ___/\____________________________________________________
busy     ___/------------------------------------------------\____
cs_n     ---\________________________________________________/----
sclk     CPOL  <--- 2 * DATA_WIDTH clock edges --->       CPOL
mosi          B[W-1] ... B[1] B[0]  (held through final edge)
miso          R[W-1] ... R[1] R[0]
done     ____________________________________________________/\___
```

### 5.2 Tần Số SCLK

Với module `spi_master.v`, tần số SCLK được tính theo công thức:

```
f_sclk = f_clk / (2 × CLK_DIV)
```

Mỗi mức SCLK (HIGH hoặc LOW) được duy trì trong đúng `CLK_DIV` chu kỳ clock hệ thống.

| `CLK_DIV` | f_sclk (với f_clk = 50 MHz) |
|:---:|---:|
| 1 | 25 MHz |
| 2 | 12.5 MHz |
| 5 | 5 MHz |
| 25 | 1 MHz |

> Giá trị `CLK_DIV < 1` được kẹp nội bộ về 1 (`EFFECTIVE_DIV = max(CLK_DIV, 1)`).

### 5.3 Handshake Master–Host

```
        clk edge
          |
  idle:   start=1 ──► busy=1, cs_n=0, (bit B[W-1] pre-driven on MOSI for CPHA=0)
          |
  busy:   [2 × DATA_WIDTH SCLK edges with CLK_DIV clock cycles each]
          |
  finish: cs_n=1, busy=0, done=1 (one clock pulse)
          rx_data updated
```

**Quy tắc sử dụng:**
1. Đặt `tx_data` ổn định trước cạnh lên chấp nhận `start`.
2. Duy trì `start = 1` trong **ít nhất 1 chu kỳ clock** khi `busy = 0`.
3. `busy` sẽ lên CAO **ngay chu kỳ tiếp theo** sau khi yêu cầu được chấp nhận.
4. Yêu cầu mới trong khi `busy = 1` bị **bỏ qua hoàn toàn** — `tx_data` được
   chốt (latch) khi bắt đầu giao dịch.
5. `done` xung **1 clock**, đọc `rx_data` sau cạnh lên đó.

---

## 6. Cấu Trúc Bus Đa Slave

### 6.1 Nhiều Slave Trên Cùng Bus

Tất cả slave chia sẻ MOSI, MISO và SCLK. Mỗi slave có một đường CS_N riêng.

```
   Master
   ┌────────────┐
   │       MOSI ├──────────────┬──────────────┬──────────────►
   │       MISO │◄─────────────┼──────────────┼───────────────
   │       SCLK ├──────────────┼──────────────┼──────────────►
   │      CS_N0 ├─────────────►│ Slave 0      │
   │      CS_N1 ├──────────────┼─────────────►│ Slave 1
   │      CS_N2 ├──────────────┼──────────────┼─────────────► Slave 2
   └────────────┘
```

> Chỉ một slave được chọn tại một thời điểm (chỉ một CS_N = THẤP).
> Nếu nhiều CS_N cùng thấp, xung đột bus có thể xảy ra trên đường MISO.

### 6.2 Daisy-Chain (Nối Chuỗi)

Một số thiết bị (ví dụ: shift register, LED driver) hỗ trợ kết nối daisy-chain:
MISO của slave này kết nối với MOSI của slave tiếp theo, tất cả dùng chung một
CS_N.

```
   Master                Slave 0              Slave 1
   ┌──────┐   MOSI  ┌──────────┐   MOSI  ┌──────────┐
   │      ├────────►│          ├────────►│          │
   │      │         │          │         │          │
   │      │◄────────┤          │◄────────┤          │
   │      │   MISO  └──────────┘   MISO  └──────────┘
   │ CS_N ├─────────────────────────────────────────►
   └──────┘
```

Dữ liệu được dịch qua chuỗi, master cần gửi `N × DATA_WIDTH` bit cho N slave.

---

## 7. So Sánh Với UART và I²C

| Tiêu chí | SPI | UART | I²C |
|---|---|---|---|
| **Số dây tối thiểu** | 4 (MOSI, MISO, SCLK, CS) | 2 (TX + RX) | 2 (SDA + SCL) |
| **Xung nhịp** | Có (đồng bộ) | Không (bất đồng bộ) | Có (đồng bộ) |
| **Số thiết bị** | 1 master + N slave (N CS pins) | 2 (point-to-point) | N master + N slave |
| **Địa chỉ thiết bị** | Không (dùng CS riêng) | Không | Có (7 hoặc 10 bit) |
| **Tốc độ điển hình** | 1 – 50+ MHz | 115.2 kbps – 1 Mbps | 100 kHz – 5 MHz |
| **Full-duplex** | ✅ Có | ✅ Có | ❌ Không (half-duplex) |
| **Khoảng cách** | Ngắn (PCB, <1m) | Ngắn–vừa | Ngắn (PCB, <1m) |
| **Độ phức tạp** | Thấp | Thấp | Trung bình |
| **Ứng dụng điển hình** | Flash SPI, ADC, màn hình | Debug console, GPS, BT | Cảm biến, EEPROM, IMU |

### Khi Nào Dùng SPI?

✅ **Nên dùng SPI khi:**
- Cần tốc độ cao (MHz range) — SPI nhanh hơn I²C và UART đáng kể.
- Giao tiếp với bộ nhớ Flash, ADC/DAC, màn hình, bộ điều khiển màn hình.
- Cần song công toàn phần: gửi và nhận cùng lúc.
- Số lượng slave vừa phải (mỗi slave cần thêm 1 chân CS).

❌ **Không nên dùng SPI khi:**
- Cần kết nối nhiều slave nhưng số chân vi điều khiển hạn chế → dùng I²C.
- Cần khoảng cách xa (>1m) → dùng RS-485 hoặc CAN.
- Giao tiếp debug đơn giản với máy tính → dùng UART.

---

## 8. Ứng Dụng Thực Tế

### 8.1 Bộ Nhớ Flash SPI

Là ứng dụng phổ biến nhất của SPI. Hầu hết vi điều khiển hiện đại đều tích hợp
bộ nhớ Flash ngoài qua SPI.

| Thiết bị | Mode SPI | Tốc độ tối đa |
|---|---|---|
| W25Q128 (Winbond Flash 128Mb) | Mode 0 hoặc Mode 3 | 104 MHz |
| S25FL064L (Cypress Flash 64Mb) | Mode 0 hoặc Mode 3 | 133 MHz |
| AT45DB (Adesto Flash) | Mode 0 hoặc Mode 3 | 85 MHz |

### 8.2 ADC / DAC

Nhiều bộ chuyển đổi tương-số và số-tương dùng SPI do tốc độ cao và giao tiếp đơn giản.

| Thiết bị | Loại | Độ phân giải | Mode SPI |
|---|---|---|---|
| MCP3204 (Microchip) | ADC 12-bit, 4-kênh | 12 bit | Mode 0/1 |
| AD7705 (Analog Devices) | ADC 16-bit sigma-delta | 16 bit | Mode 1/3 |
| MCP4921 (Microchip) | DAC 12-bit | 12 bit | Mode 0/1 |

### 8.3 Màn Hình và Cảm Biến IMU

```
MCU ──SPI──► ILI9341 (LCD 240x320, Mode 0/3)
MCU ──SPI──► ST7735  (LCD 128x160, Mode 0/3)
MCU ──SPI──► MPU-9250 (IMU 9-axis, Mode 0 hoac Mode 3)
MCU ──SPI──► L3GD20H (Gyroscope, Mode 3)
```

### 8.4 Trong FPGA / ASIC

SPI thường được dùng để:
- **Cấu hình FPGA** từ Flash SPI ngoài (configuration SPI).
- **Giao tiếp với host MCU** — FPGA/ASIC đóng vai trò slave SPI.
- **Đọc cảm biến ngoại vi** — FPGA/ASIC đóng vai trò master SPI.

---

## 9. Triển Khai RTL — spi_master.v

### 9.1 Tổng Quan Thiết Kế

Module `spi_master.v` là một SPI master tham số hóa hỗ trợ tất cả bốn chế độ
clock (Mode 0–3), được viết bằng Verilog thuần túy, tổng hợp được.

**Tham số:**

| Tham số | Mặc định | Mô tả |
|---|:---:|---|
| `DATA_WIDTH` | `8` | Số bit truyền mỗi giao dịch |
| `CLK_DIV` | `2` | Số chu kỳ clock hệ thống mỗi nửa chu kỳ SCLK |
| `CPOL` | `0` | Cực tính idle của SCLK |
| `CPHA` | `0` | Pha lấy mẫu / đặt dữ liệu |

### 9.2 Kiến Trúc Bộ Điều Khiển

Module sử dụng **một process tuần tự duy nhất** với bốn giai đoạn logic:

```
                ┌───────────────────────────────────────────┐
                │              spi_master FSM               │
                │                                           │
  start=1  ─►   │  IDLE ──────────────────► BUSY            │
  busy=0        │    │                        │             │
                │    │  cs_n=1, sclk=CPOL     │  cs_n=0     │
                │    │                        │  shift bits │
                │    │◄───────────────────────│             │
                │           done pulse    FINISH_PENDING    │
                └───────────────────────────────────────────┘
```

| Giai đoạn | Điều kiện | Hành động |
|---|---|---|
| **IDLE** | `busy=0` | Giữ `cs_n=1`, `sclk=CPOL`, chờ `start=1` |
| **LEADING EDGE** | `sclk == CPOL` | Toggle SCLK; nếu CPHA=0: sample MISO; nếu CPHA=1: đặt MOSI |
| **TRAILING EDGE** | `sclk != CPOL` | Toggle SCLK; nếu CPHA=0: đặt MOSI tiếp; nếu CPHA=1: sample MISO |
| **FINISH_PENDING** | Sau bit cuối | Giải phóng `cs_n`, pulse `done`, cập nhật `rx_data` |

### 9.3 Cơ Chế Đặt Bit Đầu Tiên (CPHA=0)

Đối với `CPHA=0`, bit đầu tiên (MSB) phải có mặt trên MOSI **trước cạnh SCLK
đầu tiên**. Module xử lý điều này bằng cách đặt bit 0 (MSB) lên MOSI **ngay
khi chấp nhận** yêu cầu `start`, trước khi SCLK bắt đầu chạy:

```verilog
if (start) begin
    tx_latched <= tx_data;
    cs_n       <= 1'b0;
    busy       <= 1'b1;
    if (CPHA == 0)
        mosi <= select_tx_bit(tx_data, 0); // MSB san sang truoc canh dau tien
end
```

### 9.4 Chốt Dữ Liệu (tx_latched)

`tx_data` được chốt vào `tx_latched` tại thời điểm chấp nhận `start`. Điều này
đảm bảo **host có thể thay đổi `tx_data` trong khi giao dịch đang chạy** mà
không gây lỗi — dữ liệu đã được bảo vệ bên trong module.

### 9.5 Thanh Ghi Dịch Nhận (rx_shift)

Bit MISO được lấy mẫu và lưu trực tiếp vào vị trí MSB-first trong `rx_shift`:

```verilog
function [DATA_WIDTH-1:0] insert_rx_bit;
    // Ghi miso vao vi tri word[DATA_WIDTH-1-index]
    // => bit 0 (MSB) dat tai vi tri cao nhat, giam dan
endfunction
```

`rx_data` chỉ được cập nhật **sau khi toàn bộ bit đã được nhận** (tại trailing
edge của bit cuối cùng), đảm bảo tính nhất quán của dữ liệu.

### 9.6 Testbench và Kết Quả Xác Minh

Testbench `spi_master_tb.v` khởi tạo **4 master song song** (một cho mỗi mode)
và **4 slave mô hình tương ứng**, kiểm tra toàn diện với 5 nhóm test case:

| Test Case | Nội dung |
|---|---|
| **TC1** | Trạng thái reset và mức idle CPOL của SCLK |
| **TC2** | Trao đổi full-duplex trên cả 4 mode (0, 1, 2, 3) |
| **TC3** | Payload biên: all-zero MOSI + all-one MISO và ngược lại |
| **TC4** | Từ chối yêu cầu thứ hai khi `busy=1` |
| **TC5** | Reset trong khi đang truyền và khôi phục sau đó |

Mỗi giao dịch thành công kiểm tra:
- `rx_data` khớp với từ phản hồi của slave (MISO payload).
- Slave capture chính xác `tx_data` từ MOSI.
- Đúng `2 x DATA_WIDTH` cạnh SCLK.
- Đúng 1 xung `done`.
- `busy`, `cs_n` và mức idle CPOL phục hồi đúng.

Kết quả khi tất cả pass:

```
=== PASS: all 62 checks passed ===
```

---

## 10. Các Lỗi SPI Phổ Biến

### 10.1 Sai Chế Độ Clock (Mode Mismatch)

**Nguyên nhân:** Master và slave dùng CPOL/CPHA khác nhau.

**Triệu chứng:** Dữ liệu nhận được ngẫu nhiên, sai hoàn toàn, hoặc lệch 1 bit.

**Phòng tránh:** Kiểm tra datasheet của slave — thường có ký hiệu như
`"SPI Mode 0"` hoặc ghi rõ `CPOL=0, CPHA=0`. Mode 0 và Mode 3 là phổ biến nhất.

### 10.2 CS_N Không Đúng Thời Điểm

**Nguyên nhân:** CS_N được giải phóng (HIGH) quá sớm, trước khi bit cuối
cùng được lấy mẫu; hoặc CS_N không được kéo xuống trước khi SCLK bắt đầu.

**Triệu chứng:** Byte cuối bị sai, hoặc giao dịch bị cắt ngắn.

**Phòng tránh:** Đảm bảo CS_N ổn định trước cạnh SCLK đầu tiên và chỉ giải
phóng **sau** cạnh SCLK cuối cùng (trailing edge của bit cuối).

### 10.3 Setup/Hold Violation

**Nguyên nhân:** SCLK chạy quá nhanh so với thời gian setup/hold của slave,
hoặc so với thời gian truyền tín hiệu trên board.

**Triệu chứng:** Dữ liệu đúng khi chạy chậm, sai khi tăng tốc độ.

**Phòng tránh:** Chọn `CLK_DIV` phù hợp sao cho `f_sclk <= f_max_slave`. Xem
datasheet slave để biết `t_su` (setup time) và `t_h` (hold time).

### 10.4 Xung Đột Bus MISO (Bus Contention)

**Nguyên nhân:** Hai slave cùng drive đường MISO khi cả hai CS_N đồng thời thấp.

**Triệu chứng:** MISO có giá trị không xác định, có thể gây hỏng thiết bị.

**Phòng tránh:** Đảm bảo chỉ đúng 1 CS_N được kéo thấp tại một thời điểm.
Nhiều slave SPI có ngõ ra MISO là **tri-state** (high-Z khi CS_N = HIGH) — đây
là yêu cầu bắt buộc để dùng nhiều slave trên cùng bus.

### 10.5 Bảng Tóm Tắt Lỗi

| Lỗi | Triệu chứng | Nguyên nhân chính | Cách phòng tránh |
|---|---|---|---|
| **Mode Mismatch** | Dữ liệu sai hoàn toàn | CPOL/CPHA không khớp | Kiểm tra datasheet slave |
| **CS_N timing sai** | Byte cuối bị lỗi | CS_N quá sớm/muộn | CS_N bao quanh toàn bộ SCLK burst |
| **Setup/Hold vi phạm** | Lỗi khi tốc độ cao | CLK_DIV quá nhỏ | Tăng CLK_DIV, giảm f_sclk |
| **Bus contention** | MISO không xác định | Nhiều CS_N thấp cùng lúc | Chỉ kéo 1 CS_N xuống THẤP |

---

## 11. Tài Liệu Tham Khảo

| # | Tên tài liệu | Nguồn | Mô tả |
|---|---|---|---|
| [1] | **Introduction to SPI Interface** | [analog.com](https://www.analog.com/en/analog-dialogue/articles/introduction-to-spi-interface.html) | Giải thích chi tiết SPI modes, timing, và multi-slave topologies |
| [2] | **SPI Block Guide v03.06** | Motorola/Freescale | Tài liệu gốc chuẩn SPI từ Motorola |
| [3] | **Wikipedia — Serial Peripheral Interface** | [wikipedia.org](https://en.wikipedia.org/wiki/Serial_Peripheral_Interface) | Lịch sử, các biến thể, và so sánh giao thức |
| [4] | **Basics of SPI Communication** | [circuitbasics.com](https://www.circuitbasics.com/basics-of-the-spi-communication-protocol/) | Hướng dẫn trực quan cho người mới bắt đầu |
| [5] | **spi_master.v README** | README.md | Tài liệu module RTL, bảng tham số, và hướng dẫn mô phỏng |

---

*Tài liệu lý thuyết giao thức SPI — Tác giả: Long Hai*
