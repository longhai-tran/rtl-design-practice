# Kiến Trúc Async FIFO - Giải Thích Trực Quan

Async FIFO được dùng để truyền dữ liệu an toàn giữa 2 hệ thống dùng Clock (Xung nhịp) khác nhau.

## 1. Tại sao dùng Mã Gray (Gray Code)?
**Vấn đề với mã nhị phân (Binary):** Khi nhiều bit thay đổi cùng lúc, nếu đồng hồ đọc lấy mẫu lệch một chút (skew), ta có thể đọc ra dữ liệu sai bét.
👉 *Ví dụ:* Bạn đếm từ `7` sang `8` (Nhị phân: `0111` -> `1000`, 4 bit đổi cùng lúc). Nếu hệ thống khác chộp đúng lúc đang đổi, nó có thể đọc nhầm thành `1111` (15) hoặc `0000` (0) -> **LỖI NẶNG**.

**Giải pháp (Gray Code):** Chỉ 1 bit thay đổi mỗi lần đếm.
👉 *Ví dụ:* Đếm từ `7` sang `8` (Gray: `0100` -> `1100`, chỉ bit đầu tiên đổi). Nếu hệ thống chộp nhầm lúc tín hiệu đang đổi, nó sẽ đọc là `0100` (7) hoặc `1100` (8). Cả 2 đều đúng đắn và an toàn -> **KHÔNG BAO GIỜ LỖI**.

## 2. Tại sao dùng 2-FF Synchronizer (Khối đồng bộ 2 FF)?
**Vấn đề:** Bắt tín hiệu từ một Clock lạ có thể làm Flip-Flop bị "ngáo" (trạng thái Metastability - điện áp lơ lửng không phải 0 cũng không phải 1).
👉 *Ví dụ:* Giống như người chuyền bóng (Write Clock) ném cho người bắt bóng (Read Clock) mà không báo trước. Người bắt có thể bắt hụt (bóng rơi vào giữa tay).

**Giải pháp (2-FF):** Dùng 2 người bắt bóng.
- **FF1 (Người số 1):** Bắt bóng, có thể bị lóng ngóng (Metastable).
- **FF2 (Người số 2):** Nhìn FF1 bắt xong, chờ thêm 1 chu kỳ để chắc chắn quả bóng đã nằm yên trong tay FF1, rồi mới lấy bóng đem đi.
👉 *Kết quả:* Tuy bị chậm 1-2 chu kỳ nhưng cực kỳ an toàn.

## 3. Xác định Đầy (Full) và Trống (Empty)
Để biết FIFO đầy hay trống, ta so sánh **Con trỏ Ghi (Write Pointer)** và **Con trỏ Đọc (Read Pointer)**.

- **Trống (Empty):** Khi Đọc đuổi kịp Ghi.
  👉 *Ví dụ:*
  - Đọc: Đang ở ô số 5
  - Ghi: Đang ở ô số 5
  - Nhận xét: Ghi chưa viết thêm gì, không còn gì để đọc -> **Trống (Empty = 1)**.

- **Đầy (Full):** Khi Ghi chạy nhanh hơn và "bắt vòng" (lapped) Đọc.
  👉 *Ví dụ:* (Giả sử rãnh vòng tròn có 16 ô)
  - Đọc: Đang đứng ở ô số 5 (Vòng 0).
  - Ghi: Chạy nhanh quá, đi hết 1 vòng và quay lại ô số 5 (Vòng 1).
  - Nhận xét: Ghi đã đuổi tới đít Đọc, không còn chỗ để ghi -> **Đầy (Full = 1)**.

### Quy tắc Cummings (So sánh mã Gray):
*(Được đặt theo tên của **Clifford E. Cummings** - chuyên gia Verilog đã viết bài báo tiêu chuẩn ngành (SNUG 2002) về thiết kế Async FIFO. Phương pháp này còn có các tên gọi khác như: **Style #2 Async FIFO** hoặc **N+1 bit Gray-code FIFO**).*

- **Empty:** Các bit khớp nhau hoàn toàn (`Ghi == Đọc`).
- **Full:** 2 bit cao nhất (MSB) bị **đảo ngược**, các bit còn lại khớp nhau hoàn toàn.
  👉 *Ví dụ:*
  - Đọc: `00_11` (Vòng 0, ô số 3)
  - Ghi: `11_11` (Vòng 1, ô số 3) -> 2 bit đầu `11` đảo ngược so với `00`. Hệ thống báo Full!

## 4. Tại sao cần thêm 1 bit vào Con trỏ (N+1 bits)?
Nếu FIFO có 16 ô (chỉ cần 4 bit để đếm từ 0-15), nhưng ta lại phải dùng **5 bit** để làm con trỏ.
**Tại sao?** Bit thứ 5 chính là "Đồng hồ đo số vòng".
👉 *Ví dụ:*
- **Nếu chỉ dùng 4 bit:** Ghi đang ở ô số `5` (đã chạy qua vòng 2), Đọc cũng đang ở ô số `5` (mới ở vòng 1). Lúc này `Ghi == Đọc` (5 == 5). Máy tính sẽ lú, không biết đây là **EMPTY** (Ghi chưa đi) hay **FULL** (Ghi đã chạy giáp vòng).
- **Nếu dùng 5 bit:**
  - Đọc = `0_0101` (Vòng 0, ô số 5). Nếu Ghi = `0_0101` (Vòng 0, ô số 5) -> **EMPTY**
  - Đọc = `0_0101` (Vòng 0, ô số 5). Nếu Ghi = `1_0101` (Vòng 1, ô số 5) -> **FULL**
👉 *Kết luận:* Bit phụ thứ 5 giúp ta phân biệt được "Đang đứng chung ở vòng đầu" (Empty) hay "Đã bị bắt vòng" (Full).
