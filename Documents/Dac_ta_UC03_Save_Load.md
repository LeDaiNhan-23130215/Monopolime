# Đặc tả Use Case: Lưu và Tải ván chơi (UC-03)

## 1. Thông tin chung (General Information)

| Thuộc tính | Nội dung chi tiết |
| :--- | :--- |
| **Use Case ID** | UC-03 |
| **Tên Use Case** | Lưu và Tải ván chơi |
| **Actor** | Người chơi, Hệ thống |
| **Mô tả** | Mô tả quá trình hệ thống ghi lại toàn bộ trạng thái ván đấu (tiền, tài sản, vị trí) vào bộ nhớ và khôi phục lại khi người chơi có nhu cầu tiếp tục ván đấu cũ. |
| **Tiền điều kiện** | - Đối với Lưu: Ván đấu đang diễn ra.<br>- Đối với Tải: Người chơi đang ở màn hình chính hoặc menu quản lý phòng. |
| **Hậu điều kiện** | Trạng thái ván đấu được ghi nhận hoặc khôi phục chính xác, đảm bảo tính liên tục của trải nghiệm. |

---

## 2. Luồng sự kiện chính (Main Flow 3.1)
*Thực hiện lưu ván chơi thủ công.*

| Bước | Actor | Mô tả hành động |
| :--- | :--- | :--- |
| 3.1.1 | Người chơi | Nhấn phím tạm dừng hoặc chọn biểu tượng "Cài đặt" trên màn hình game. |
| 3.1.2 | Người chơi | Chọn chức năng "Lưu ván chơi" từ menu hệ thống. |
| 3.1.3 | Hệ thống | Kiểm tra kết nối server (nếu chơi mạng) và trạng thái bộ nhớ khả dụng. |
| 3.1.4 | Hệ thống | Truy xuất và hiển thị danh sách các ô lưu trữ (Save Slots) hiện có (gồm ô trống và ô đã có dữ liệu). |
| 3.1.5 | Người chơi | Chọn một ô lưu trữ cụ thể để ghi dữ liệu. |
| 3.1.6 | Hệ thống | Hiển thị bảng xác nhận "Bạn có muốn ghi đè lên dữ liệu cũ không?" (nếu ô đã có dữ liệu). |
| 3.1.7 | Người chơi | Nhấn nút "Xác nhận lưu". |
| 3.1.8 | Hệ thống | Thu thập dữ liệu thực tế: tọa độ quân cờ, số dư tiền, danh sách bất động sản, số nhà/khách sạn, và trạng thái các thẻ bài. |
| 3.1.9 | Hệ thống | Thực hiện mã hóa gói dữ liệu (Server-side) để chống các hành vi can thiệp thông số. |
| 3.1.10 | Hệ thống | Ghi file thành công và hiển thị thông báo "Ván chơi đã được lưu an toàn". |

---

## 3. Luồng thay thế (Alternative Flows)

### Luồng thay thế 1 (3.2): Tải ván chơi đã lưu (Load Game)
| Bước | Actor | Mô tả hành động |
| :--- | :--- | :--- |
| 3.2.1 | Người chơi | Tại màn hình chính, chọn mục "Tiếp tục ván đấu". |
| 3.2.2 | Hệ thống | Hiển thị danh sách các bản lưu kèm thông tin tóm tắt (Ngày, giờ, số người chơi, tổng tài sản $V_{total}$). |
| 3.2.3 | Người chơi | Chọn bản lưu mong muốn và nhấn "Tải". |
| 3.2.4 | Hệ thống | Giải mã dữ liệu, kiểm tra tính tương thích của phiên bản game và khôi phục trạng thái bàn cờ. |

### Luồng thay thế 2 (3.3): Tự động lưu (Auto-save)
| Bước | Actor | Mô tả hành động |
| :--- | :--- | :--- |
| 3.3.1 | Hệ thống | Nhận diện sự kiện người chơi cuối cùng trong vòng kết thúc lượt. |
| 3.3.2 | Hệ thống | Tự động thực hiện thu thập dữ liệu và ghi đè vào ô lưu trữ đặc biệt mang tên "Auto-save". |
| 3.3.3 | Hệ thống | Hiển thị thông báo nhỏ ở góc màn hình: "Hệ thống đã tự động lưu". |

---

## 4. Luồng ngoại lệ (Exception Flow - 3.4)

### 3.4.1 Lỗi không gian lưu trữ
* **Sự kiện:** Tại bước 3.1.3 hoặc 3.1.9, hệ thống phát hiện bộ nhớ thiết bị đầy.
* **Xử lý:** Thông báo "Không đủ bộ nhớ để lưu ván đấu. Vui lòng giải phóng không gian và thử lại".

### 3.4.2 Dữ liệu bản lưu bị hỏng (Corrupted Data)
* **Sự kiện:** Tại bước 3.2.4, dữ liệu không thể giải mã hoặc bị sai lệch checksum.
* **Xử lý:** Thông báo "Bản lưu bị hỏng hoặc không tương thích" và gợi ý người chơi chọn bản lưu khác.

---

## 5. Quy tắc nghiệp vụ mapping (Business Rules)

| Mã Rule | Ràng buộc nghiệp vụ | Mapping |
| :--- | :--- | :--- |
| **BR_3.1** | **Bảo mật:** Toàn bộ logic lưu trữ và mã hóa phải xử lý tại Server-side để chống Hack. | Bước 3.1.9 |
| **BR_3.2** | **Tính toàn vẹn:** Dữ liệu lưu phải bao gồm giá trị tài sản tổng kết ($V_{total} = Cash + \sum Value_{Property} + \sum Value_{House}$). | Bước 3.1.8 |
| **BR_3.3** | **Giới hạn:** Mỗi người chơi tối đa có 5 ô lưu thủ công và 1 ô Auto-save duy nhất. | Bước 3.1.4 |
| **BR_3.4** | **Trạng thái xúc xắc:** Không lưu kết quả xúc xắc đang lăn; việc lưu chỉ hợp lệ khi lượt đi hiện tại đang ở trạng thái chờ hành động. | Bước 3.1.3 |