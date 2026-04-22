# TÀI LIỆU ĐẶC TẢ YÊU CẦU NGHIỆP VỤ (BRS)
## Hệ thống Game Monopoly (Offline)

---

## 1. Giới thiệu

### 1.1 Mục đích
Tài liệu này mô tả chi tiết các yêu cầu nghiệp vụ cho hệ thống Game Monopoly chạy offline (không cần internet), tập trung vào logic gameplay, luật chơi và tương tác người dùng.

### 1.2 Phạm vi
Hệ thống là game Monopoly chạy cục bộ trên một thiết bị. Người chơi có thể chơi cùng nhau (hot-seat).

---

## 2. Mục tiêu nghiệp vụ
- Tái hiện đầy đủ luật Monopoly truyền thống
- Hỗ trợ 2–4 người chơi trên cùng thiết bị
- Đảm bảo công bằng và tự động hóa luật

---

## 3. Yêu cầu nghiệp vụ chi tiết (Business Rules)

### 3.1 Luật lượt chơi
- Mỗi người chơi tung 2 xúc xắc trong lượt
- Nếu ra số đôi → được đi thêm lượt
- Nếu ra số đôi 3 lần liên tiếp → vào tù
- Lượt kết thúc khi hoàn thành tất cả hành động

### 3.2 Di chuyển
- Người chơi di chuyển theo tổng số điểm xúc xắc
- Đi qua "GO" → nhận 200$

### 3.3 Ô đất (Property)
- Nếu ô chưa có chủ:
  - Người chơi có quyền mua
  - Nếu không mua → đấu giá
- Nếu đã có chủ:
  - Phải trả tiền thuê (rent)

### 3.4 Tiền thuê (Rent)
- Rent phụ thuộc vào:
  - Số nhà
  - Số khách sạn
  - Bộ màu hoàn chỉnh
- Nếu chủ sở hữu có đủ bộ màu → rent tăng gấp đôi (khi chưa xây nhà)

### 3.5 Xây nhà / khách sạn
- Chỉ xây khi sở hữu full bộ màu
- Xây đều các ô (không lệch)
- Tối đa 4 nhà → nâng cấp thành khách sạn

### 3.6 Nhà tù (Jail)
Người chơi vào tù khi:
- Đi vào ô "Go to Jail"
- Tung 3 lần đôi liên tiếp

Cách ra tù:
- Tung được đôi
- Trả 50$
- Dùng thẻ "Get Out of Jail"

### 3.7 Thẻ Chance / Community Chest
- Khi vào ô → rút thẻ ngẫu nhiên
- Các hiệu ứng:
  - Nhận tiền
  - Mất tiền
  - Di chuyển
  - Vào tù

### 3.9 Thế chấp (Mortgage)
- Người chơi có thể thế chấp tài sản để nhận tiền
- Không thu rent khi đang thế chấp
- Trả thêm lãi để chuộc lại

### 3.10 Phá sản (Bankruptcy)
- Khi không đủ tiền trả:
  - Bán tài sản hoặc thế chấp
- Nếu vẫn không đủ:
  - Bị loại khỏi game

### 3.11 Kết thúc game
- Game kết thúc khi:
  - Chỉ còn 1 người chơi

---

## 4. Yêu cầu chức năng

### FR-01: Tạo game offline
- Chọn số người chơi
- 
### FR-02: Gameplay
- Tung xúc xắc
- Di chuyển
- Thực hiện hành động tự động

### FR-03: Quản lý tài sản
- Mua / bán / xây dựng

## 5. Yêu cầu phi chức năng

### 5.1 Hiệu năng
- Thời gian phản hồi ít nhất 5 giây

### 5.2 Khả dụng
- UI đơn giản, dễ hiểu

### 5.3 Độ tin cậy
- Không crash trong suốt phiên chơi

---

## 7. Giả định
- Người chơi ngồi cùng thiết bị
- Có hiểu biết cơ bản về Monopoly

---

## 8. Rủi ro
- Game kéo dài quá lâu

---

## 9. Phụ lục

### A. Mở rộng tương lai
- Multiplayer online
- Đồng bộ cloud
- Đa dạng lỗi chơi, mở rộng gameplay

---

**Kết thúc tài liệu**
