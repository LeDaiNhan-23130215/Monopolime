# TÀI LIỆU ĐẶC TẢ YÊU CẦU NGHIỆP VỤ (BRS)
## Hệ thống Game Monopolime (Offline)

---

## 1. Giới thiệu

### 1.1 Mục đích
Tài liệu này mô tả chi tiết các yêu cầu nghiệp vụ của hệ thống game Monopoly offline, bao gồm:
- Luật chơi  
- Quy trình gameplay  
- Các chức năng hỗ trợ (lưu/tải game)  

### 1.2 Phạm vi
- Game chạy **offline trên 1 thiết bị**  
- Hỗ trợ **2–4 người chơi (hot-seat)**  
- Tự động hóa toàn bộ luật Monopoly  

---

## 2. Mục tiêu nghiệp vụ

- Tái hiện đầy đủ luật Monopoly truyền thống  
- Đảm bảo tính công bằng và tự động hóa  
- Hỗ trợ lưu và tiếp tục game đang chơi dở  
- Dễ sử dụng cho người chơi mới  

---

## 3. Yêu cầu nghiệp vụ chi tiết (Business Rules)

### 3.1 Setup & Turn Order

**BR-01: Xác định thứ tự lượt chơi**
- Tất cả người chơi tung 2 xúc xắc trước khi bắt đầu  
- Hệ thống sắp xếp thứ tự theo điểm giảm dần  
- Nếu bằng điểm → tung lại  
- Thứ tự giữ nguyên suốt game  

**BR-02: Tung xúc xắc trong lượt**
- Mỗi lượt bắt đầu bằng việc tung 2 xúc xắc  

**BR-03: Luật số đôi (Doubles)**
- Tung số đôi → được thêm 1 lượt  
- Tung 3 lần đôi liên tiếp → vào tù ngay  
- Không di chuyển ở lần tung thứ 3  

**BR-04: Kết thúc lượt**
- Hoàn thành hành động bắt buộc  
- Người chơi xác nhận kết thúc lượt  

---

### 3.2 Movement

**BR-05: Di chuyển**
- Di chuyển theo tổng xúc xắc  
- Theo một chiều trên bàn cờ  

**BR-06: Ô GO**
- Đi qua hoặc dừng tại GO → nhận 200$  

---

### 3.3 Property

**BR-07: Ô chưa có chủ**
- Người chơi có quyền mua  
- Nếu không mua hoặc không đủ tiền mua → bỏ qua, ô đất vẫn chưa có chủ  

**BR-08: Ô có chủ**
- Phải trả tiền thuê  
- Không trả nếu tài sản đang thế chấp  

---

### 3.4 Rent Logic

**BR-09: Tính tiền thuê**
- Phụ thuộc:
  - Số nhà  
  - Khách sạn  

**BR-10: Bộ màu hoàn chỉnh**
- Sở hữu đủ bộ màu (chưa xây nhà) → rent x2  

---

### 3.5 Building Rules

**BR-11: Xây từ xa**
- Có thể xây ở bất kỳ ô nào thuộc quyền sở hữu  

**BR-12: Điều kiện xây**
- Phải sở hữu đủ bộ màu  
- Không có ô nào bị thế chấp  

**BR-13: Xây đồng đều**
- Phải xây số nhà đều giữa các ô  

**BR-14: Giới hạn xây**
- Tối đa 4 nhà  
- Sau đó nâng cấp thành khách sạn  

---

### 3.6 Jail Rules

**BR-15: Điều kiện vào tù**
- Ô "Go to Jail"  
- Thẻ bài  
- Tung 3 lần đôi liên tiếp  

**BR-16: Trạng thái trong tù**
- Tối đa 3 lượt  
- Không di chuyển  
- Vẫn được:
  - Thu rent  
  - Xây nhà  
  - Giao dịch  

**BR-17: Ra tù**
- Trả 50$  
- Dùng thẻ "Get Out of Jail Free"  
- Tung được số đôi  
- Lượt 3: bắt buộc trả tiền  

---

### 3.7 Event Rules

**BR-18: Chance / Community Chest**
- Rút ngẫu nhiên  
- Thực hiện ngay  
- Bao gồm:
  - Nhận tiền  
  - Mất tiền  
  - Di chuyển  
  - Vào tù  

---

### 3.8 Mortgage

**BR-19: Thế chấp**
- Chỉ thế chấp đất trống  
- Nhận 50% giá trị  

**BR-20: Chuộc lại**
- Trả tiền + 10% lãi  

---

### 3.9 Trading

**BR-21: Trao đổi tài sản**
- Người chơi có thể trao đổi với người chơi khác  
- Nội dung trao đổi bao gồm:
  - Tiền  
  - Ô đất (Property)  
- Không bao gồm:
  - Thẻ Chance / Community Chest  

- Một giao dịch gồm:
  - Người đề xuất  
  - Người nhận  
  - Nội dung trao đổi  

- Người nhận có quyền:
  - Đồng ý → giao dịch được thực hiện  
  - Từ chối → giao dịch bị hủy  

- Sau khi giao dịch:
  - Cập nhật quyền sở hữu tài sản  
  - Cập nhật tiền của hai bên  

**BR-22: Mua bán tài sản giữa người chơi**
- Người chơi có thể bán tài sản cho người chơi khác  
- Giá do hai bên tự thỏa thuận  
- Sau khi giao dịch:
  - Quyền sở hữu chuyển sang người mua  
  - Tiền được chuyển cho người bán  

---

### 3.10 Bankruptcy & End Game

**BR-23: Phá sản**
- Khi không thể trả nợ  
- Bị loại khỏi game  

**BR-24: Kết thúc game**
- Khi còn 1 người chơi  

---

## 4. Save / Load Game

### 4.1 Save Game

**BR-25: Tự động lưu**
- Khi kết thúc mỗi lượt  
- Khi người chơi thoát game  

**BR-26: Nội dung lưu**
Bao gồm:
- Danh sách người chơi  
- Số tiền  
- Tài sản  
- Vị trí  
- Trạng thái nhà tù  
- Lượt hiện tại  
- Thứ tự chơi  

**BR-27: Ghi đè dữ liệu**
- Chỉ lưu 1 phiên gần nhất  
- Lần lưu mới ghi đè dữ liệu cũ  

---

### 4.2 Load Game

**BR-28: Continue Game**
- Nếu có save → hiển thị "Continue"  

**BR-29: Hành vi Continue**
- Load toàn bộ trạng thái  
- Tiếp tục đúng lượt  

**BR-30: Không có save**
- Nút Continue bị ẩn hoặc disable  

---

### 4.3 Thoát giữa chừng

**BR-31: Thoát game**
- Auto-save khi thoát  
- Không mất tiến trình  

---

## 5. Yêu cầu chức năng (Functional Requirements)

**FR-01: Tạo game**
- Chọn số người chơi  
- Nhập tên  

**FR-02: Gameplay**
- Tung xúc xắc  
- Di chuyển  
- Xử lý luật tự động  

**FR-03: Quản lý tài sản**
- Mua  
- Bán  
- Xây dựng  
- Thế chấp  
- Trao đổi tài sản  

**FR-04: Save / Load**
- Tự động lưu  
- Continue game  

---

## 6. Yêu cầu phi chức năng

### 6.1 Hiệu năng
- Thời gian phản hồi < 5 giây  

### 6.2 Khả dụng
- UI đơn giản  
- Dễ thao tác  

### 6.3 Độ tin cậy
- Không crash khi đang chơi  

---

## 7. Giả định
- Người chơi ngồi cùng thiết bị  
- Có hiểu luật cơ bản  

---

## 8. Rủi ro
- Game kéo dài  
- Mất dữ liệu nếu lỗi save  

---

## 9. Mở rộng tương lai
- Online multiplayer  
- Cloud save  
- AI player  

---
