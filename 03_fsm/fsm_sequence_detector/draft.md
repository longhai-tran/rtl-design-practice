# Prompt cho fsm_sequence_detector

Đóng vai một RTL Design Engineer dày dặn kinh nghiệm, hãy vẽ một đoạn **ASCII Architecture Diagram** cho module `fsm_sequence_detector` bên dưới.

## Thông số module
- **Tên module:** `fsm_sequence_detector`
- **Mô tả:** Mealy FSM phát hiện chuỗi "1011" với overlap enabled, đồng bộ sườn dương clock, reset bất đồng bộ tích cực thấp.
- **Inputs:**
  - `clk` — clock (sườn dương)
  - `rst_n` — reset bất đồng bộ tích cực thấp
  - `din` — data input (1 bit)
- **Output:**
  - `detected` — cờ phát hiện chuỗi (1 bit, Mealy output)
- **Cấu trúc bên trong:** Gồm 3 khối chính:
  - `Next State Logic`: Logic tổ hợp tính next_state dựa trên state hiện tại và din
  - `State Register`: Thanh ghi 2-bit lưu state (S0, S1, S2, S3), cập nhật posedge clk, reset rst_n
  - `Output Logic`: Logic tổ hợp tính detected dựa trên state và din (Mealy)
  - Dữ liệu chảy: din → Next State Logic → State Register → Output Logic → detected
  - clk và rst_n đi vào State Register

## Yêu cầu bắt buộc về định dạng
1. Chỉ dùng ký tự ASCII cơ bản: `+`, `-`, `|`, `>`, `<`, để không bị lỗi viền khi copy vào README.md.
2. Nhãn tín hiệu phải rõ tên và độ rộng bit (vd: `din[0]`, `detected[0]`).
3. Căn chỉnh thẳng hàng, gọn gàng.
4. Vẽ **2 sơ đồ**:
   - **Top-level Block Diagram** (hộp đen, chỉ thấy ports ngoài)
   - **Internal Architecture Diagram** (hộp trắng, thể hiện 3 khối chính và cách kết nối)
5. Quy định layout cho Internal Diagram:
   - 3 khối xếp **ngang hàng** từ trái sang phải theo thứ tự: `Next State Logic` → `State Register` → `Output Logic`
   - `din` vào từ **bên trên** của `Next State Logic`
   - `detected` ra từ **phía phải** của `Output Logic`
   - `clk` và `rst_n` đi từ **trên xuống**, cắm vuông góc vào đỉnh của `State Register`
   - Mũi tên dữ liệu chạy **từ trái sang phải** giữa các khối
   - State hiện tại từ State Register quay lại Next State Logic (feedback)

# ASCII Architecture Diagrams

## Top-level Block Diagram (Black-box view)

```
+-----------------------------+
|     fsm_sequence_detector   |
|                             |
|  Inputs:                    |
|  - clk                      |
|  - rst_n                    |
|  - din[0]                   |
|                             |
|  Outputs:                   |
|  - detected[0]              |
+-----------------------------+
```

## Internal Architecture Diagram (White-box view)

```
          +-------------------+     +-------------------+     +-------------------+
          | Next State Logic  | --> |   State Register  | --> |   Output Logic    |
          | (Combinational)   |     |   (2-bit: S0-S3)  |     |   (Mealy output)  |
          | - Input: state,   |     |   - posedge clk   |     |   - Input: state, |
          |   din             |     |   - rst_n reset   |     |     din           |
          +-------------------+     +-------------------+     +-------------------+
                  ^                       |                       |
                  |                       |                       |
                  |                       v                       v
                  |             +-------------------+     +-------------------+
                  |             |       clk         |     |    detected[0]    |
                  |             |       rst_n       |     +-------------------+
                  +-------------|                   |
                                +-------------------+
                                |     din[0]        |
                                +-------------------+
```