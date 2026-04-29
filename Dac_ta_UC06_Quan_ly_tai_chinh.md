# Đặc tả Use Case: Quản lý tài chính (UC-06)

## 1. Thông tin chung (General Information)

| Thuộc tính | Nội dung chi tiết |
| **Use Case ID** | UC-06 |
| **Tên Use Case** | Quản lý tài chính |
| **Actor** | Người chơi, Hệ thống |
| **Mô tả** | Mô tả quá trình xử lý các giao dịch liên quan đến tiền mặt của người chơi trong game (ví dụ: trả tiền phạt, trả tiền thuê đất, nhận tiền thưởng, thu tiền từ người chơi khác). |
| **Tiền điều kiện** | - Game đang diễn ra và người chơi đang trong quá trình "Thực hiện lượt chơi" (UC-05).<br>- Phát sinh sự kiện yêu cầu cập nhật (tăng/giảm) số dư tiền mặt của người chơi. |
| **Hậu điều kiện** | Số dư tài khoản tiền mặt của người chơi và các bên liên quan (Ngân hàng, người chơi khác) được hệ thống tính toán và cập nhật chính xác. |

---

## 2. Luồng sự kiện chính (Main Flow 6.1)
*Thanh toán tiền thuê đất/tiền phạt khi người chơi di chuyển vào ô yêu cầu chi trả.*

| Bước | Actor | Mô tả hành động |
| 6.1.1 | Người chơi | Kết thúc việc đổ xúc xắc và di chuyển đến một ô yêu cầu thanh toán (VD: đất của người chơi khác, ô đóng thuế). |
| 6.1.2 | Hệ thống | Nhận diện loại giao dịch và đối tượng thụ hưởng (Ngân hàng hoặc người chơi khác). |
| 6.1.3 | Hệ thống | Tính toán tổng số tiền người chơi cần phải thanh toán. |
| 6.1.4 | Hệ thống | Hiển thị bảng thông báo cho người chơi về khoản tiền cần trả và lý do. |
| 6.1.5 | Người chơi | Nhấn nút "Xác nhận thanh toán" trên giao diện. |
| 6.1.6 | Hệ thống | Kiểm tra số dư tiền mặt hiện tại của người chơi. |
| 6.1.7 | Hệ thống | Tiến hành trừ số tiền tương ứng từ tài khoản của người chơi này. |
| 6.1.8 | Hệ thống | Tiến hành cộng số tiền tương ứng vào tài khoản của đối tượng thụ hưởng. |
| 6.1.9 | Hệ thống | Lưu lại lịch sử giao dịch, cập nhật hiển thị số dư mới trên màn hình và thông báo hoàn tất giao dịch. |

---

## 3. Alternative Flows

### Luồng thay thế 1 (6.2): Nhận tiền thưởng
| Bước | Actor | Mô tả hành động |
| 6.2.1 | Người chơi | Di chuyển ngang qua/dừng lại ở ô Bắt Đầu (GO) hoặc rút được Thẻ Cơ Hội có thưởng tiền. |
| 6.2.2 | Hệ thống | Xác định khoản tiền thưởng mà người chơi được nhận. |
| 6.2.3 | Hệ thống | Hiển thị thông báo chúc mừng kèm số tiền nhận được. |
| 6.2.4 | Hệ thống | Trừ tiền từ quỹ của Ngân hàng. |
| 6.2.5 | Hệ thống | Cộng trực tiếp khoản tiền này vào tài khoản của người chơi. |
| 6.2.6 | Hệ thống | Cập nhật hiển thị số dư mới và lưu lịch sử giao dịch. |

### Luồng thay thế 2 (6.3): Thế chấp tài sản để thanh toán
| Bước| Actor | Mô tả hành động |
| :--- | :--- | :--- |
| 6.3.1 | Hệ thống | Tại bước 6.1.6, nếu số dư không đủ, thông báo yêu cầu người chơi bán nhà hoặc thế chấp đất. |
| 6.3.2 | Người chơi | Chọn chức năng "Thế chấp" (liên kết với UC-07: Quản lý tài sản). |
| 6.3.3 | Hệ thống | Hiển thị danh sách tài sản có thể thế chấp và số tiền thu về được. |
| 6.3.4 | Người chơi | Chọn tài sản muốn thế chấp và xác nhận. |
| 6.3.5 | Hệ thống | Cập nhật trạng thái tài sản thành "Đã thế chấp" và cộng tiền từ ngân hàng vào tài khoản người chơi. |
| 6.3.6 | Hệ thống | Quay lại bước 6.1.6 của Luồng cơ bản để tiếp tục tiến trình thanh toán. |

---

## 4. Luồng ngoại lệ (Exception Flow - 6.4)
*Xử lý khi người chơi phá sản.*

| Bước | Actor | Mô tả hành động |
| :--- | :--- | :--- |
| 6.4.1 | Hệ thống | Tại bước 6.1.6, phát hiện người chơi không đủ tiền và không còn tài sản để thế chấp (hoặc chọn "Đầu hàng"). |
| 6.4.2 | Hệ thống | Thông báo người chơi đã rơi vào trạng thái "Phá sản". |
| 6.4.3 | Hệ thống | Chuyển toàn bộ tài sản và số tiền còn lại cho chủ nợ (Người chơi khác hoặc Ngân hàng). |
| 6.4.4 | Hệ thống | Loại bỏ người chơi khỏi bàn cờ (Kết nối sang UC-04: Kết thúc game). |

---

## 5. Quy tắc nghiệp vụ (Business Rules)

| Mã Rule | Ràng buộc nghiệp vụ |
| **BR_6.1.3** | Số tiền thanh toán ở Bước 3 (Luồng 1) phải được tính tự động dựa trên mức giá thuê đã quy định (cộng dồn hệ số nếu có nhà/khách sạn) hoặc đúng số % yêu cầu nếu là ô Đóng Thuế. |
| **BR_6.1.6** | Lệnh thanh toán (Bước 6, Luồng 1) chỉ được chuyển sang Bước 7 khi số dư tiền mặt $\ge$ Số tiền cần thanh toán. Nếu không, bắt buộc rẽ nhánh sang Luồng thay thế 2 hoặc Luồng ngoại lệ 4. |
| **BR_6.2.2** | Số tiền nhận được khi đi qua ô GO là một hằng số cố định theo cấu hình ván đấu (Ví dụ: mặc định là $200). |
| **BR_6.3.3** | Số tiền nhận được khi thế chấp tài sản (Bước 3, Luồng 3) luôn bằng chính xác 50% giá trị gốc lúc mua tài sản đó. |
| **BR_6.4.1** | Điều kiện xác định Phá sản (Bước 1, Luồng 4): (Tổng tiền mặt + Tổng giá trị thế chấp tối đa) < Số tiền nợ. |
