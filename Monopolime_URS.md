# USER REQUIREMENT SPECIFICATION (URS) - MONOPOLIME (CỜ TỶ PHÚ)

## 1. Giới thiệu dự án
Dự án nhằm phát triển ứng dụng trò chơi **Cờ Tỷ Phú (Monopolime)** phiên bản kỹ thuật số, hỗ trợ chơi đa nền tảng. Trò chơi kết hợp luật chơi truyền thống với giao diện hiện đại và hệ thống kết nối trực tuyến.

---

## 2. Yêu cầu Chức năng (Functional Requirements)

### 2.1 Hệ thống Quản lý Ván chơi
* **Chế độ chơi:** Hỗ trợ Chơi đơn (với AI) và Chơi mạng (Multiplayer).
* **Số lượng người chơi:** Từ 2 đến 4 người chơi mỗi ván.
* **Hệ thống phòng:** Cho phép tạo phòng, đặt mật khẩu và mời bạn bè qua ID hoặc mạng xã hội.

### 2.2 Cơ chế Gameplay Cốt lõi
* **Xúc xắc:** - Hệ thống RNG (Random Number Generator) để đảm bảo tính minh bạch.
    - Quy tắc "Đổ đôi" (Double): Cho phép đi thêm lượt; đổ đôi 3 lần liên tiếp sẽ phải vào tù.
* **Di chuyển:** Quân cờ tự động di chuyển trên bàn cờ 40 ô theo số nút xúc xắc.
* **Quản lý Tài sản:**
    - **Mua đất:** Người chơi mua ô đất chưa sở hữu.
    - **Thu phí:** Tự động trừ tiền khi người chơi khác dẫm vào đất của mình.
    - **Xây dựng:** Nâng cấp nhà và khách sạn khi sở hữu đủ bộ màu (Color Set).
    - **Đấu giá:** Tự động kích hoạt đấu giá nếu người chơi hiện tại từ chối mua đất.

### 2.3 Hệ thống Kinh tế & Sự kiện
* **Ngân hàng:** Tự động cấp lương khi đi qua ô "Bắt đầu" (GO).
* **Thẻ bài:** Hệ thống thẻ **Cơ hội** và **Khí vận** với các hiệu ứng ngẫu nhiên (thưởng/phạt tiền, di chuyển tức thời).
* **Giao dịch (Trade):** Cho phép người chơi trao đổi tài sản, tiền mặt hoặc thẻ "Ra tù" thông qua giao diện thương lượng.
* **Thế chấp (Mortgage):** Người chơi có thể thế chấp tài sản để lấy tiền mặt bằng 50% giá trị gốc.

---

## 3. Yêu cầu Giao diện & Trải nghiệm (UI/UX)
* **Bàn cờ:** Hiển thị 2.5D hoặc 3D với các địa danh Việt Nam (Hồ Gươm, Landmark 81, v.v.).
* **Bảng trạng thái:** Hiển thị số tiền, danh sách tài sản và thẻ bài hiện có của tất cả người chơi.
* **Hiệu ứng:** Hoạt ảnh xúc xắc lăn, quân cờ nhảy và các hiệu ứng ăn mừng khi thắng cuộc.
* **Thông báo:** Hệ thống Log hiển thị lịch sử các bước đi (Ví dụ: "Người chơi A đã mua ô Đà Lạt").

---

## 4. Yêu cầu Kỹ thuật & Phi chức năng
* **Nền tảng:** Web (React/Vue/Unity), Mobile (Android/iOS).
* **Kết nối:** Duy trì kết nối thời gian thực qua WebSockets (Socket.io).
* **Bảo mật:** Chống gian lận (Hack) bằng cách xử lý logic hoàn toàn ở phía máy chủ (Server-side).
* **Ngôn ngữ:** Tiếng Việt (mặc định) và Tiếng Anh.

---

## 5. Quy tắc Tính toán (Logic)
Khi kết thúc thời gian hoặc chỉ còn 1 người sống sót, người thắng cuộc được xác định dựa trên tổng giá trị tài sản ($V_{total}$):

$$V_{total} = Cash + \sum (Value_{Property}) + \sum (Value_{House})$$

---

## 6. Danh mục ô trên bàn cờ
| Nhóm ô | Số lượng | Chức năng chính |
| :--- | :--- | :--- |
| Đất nền | 22 | Xây dựng và thu tiền thuê |
| Nhà ga | 4 | Thu phí vận chuyển |
| Tiện ích | 2 | Thu phí Điện & Nước |
| Thuế | 2 | Phạt tiền người chơi |
| Đặc biệt | 4 | Bắt đầu, Nhà tù, Bãi đỗ xe, Vào tù |
| Thẻ bài | 6 | Cơ hội và Khí vận |