<!-- converted from UC7_Qu#U1ea3n l#U00fd t#U00e0i s#U1ea3n.docx -->


| Use Case ID | UC-7 |
| --- | --- |
| Use Case Name | Quản lý tài sản |
| Description | Usecase mô tả quá trình người chơi quản lý tài sản trong game, bao gồm: mua, xây dựng, thế chấp, bán và trao đổi tài sản giữa người chơi. |
| Actor(s) | Người chơi |
| Priority | Esential |
| Pre-condition(s) | Game đã được khởi tạo 
Đang đến lượt người chơi
Người chơi chưa bị phá sản |
| Post-condition(s) | Tài sản được cập nhật
Số tiền người chơi được cập nhật
Trạng thái tài sản thay đổi |
| Basic Flow | 7.1.1. Người chơi mở chức năng quản lý tài sản
7.1.2. Hệ thống hiển thị danh sách tài sản
7.1.3. Người chơi chọn hành động (mua / xây / thế chấp / bán / trao đổi)
7.1.4. Hệ thống kiểm tra điều kiện
7.1.5. Hệ thống cập nhật tài chính – <<include>> UC – 6
7.1.6. Cập nhật tài sản
7.1.7. Kết thúc |
| Alternative Flow | AF7.2 – Mua tài sản
7.2.1. Chọn mua
7.2.2. Kiểm tra chưa có chủ
7.2.3. Trừ tiền – <<include>> UC – 6
7.2.4. Gán quyền sở hữu

AF7.3 – Xây nhà
7.3.1. Chọn xây
7.3.2. Kiểm tra điều kiện xây
7.3.3. Trừ tiền – <<include>> UC – 6
7.3.4. Cập nhật nhà

AF7.4 – Thế chấp
7.4.1. Chọn tài sản
7.4.2. Cộng tiền – <<include>> UC – 6
7.4.3. Đánh dấu thế chấp

AF7.5 – Bán tài sản
7.5.1. Chọn người mua
7.5.2. Thỏa thuận giá
7.5.3. Cập nhật tiền – <<include>> UC – 6
7.5.4. Chuyển quyền sở hữu

AF7.6 – Trao đổi tài sản
7.6.1. Chọn người chơi
7.6.2. Đề xuất tài sản/tiền
7.6.3. Đồng ý → cập nhật | Từ chối → hủy

AF7.7 – Không đủ tiền
7.7.1. Chọn thế chấp / bán / trao đổi |
| Exception Flow | E7.1 – Không đủ điều kiện xây
E7.2 – Tài sản đang thế chấp
E7.3 – Giao dịch bị từ chối
E7.4 – Lỗi hệ thống |
| Business Rules | BR-07: Người chơi có thể mua tài sản khi ô đất chưa có chủ 
BR-12: Chỉ được xây khi sở hữu đầy đủ bộ màu và không có tài sản bị thế chấp 
BR-13: Phải xây nhà đồng đều giữa các ô cùng bộ màu 
BR-14: Tối đa 4 nhà, sau đó nâng cấp thành khách sạn 
BR-19: Người chơi có thể thế chấp tài sản để nhận tiền 
BR-21: Người chơi có thể trao đổi tài sản (tiền, đất) với người chơi khác 
BR-22: Người chơi có thể mua bán tài sản với người chơi khác theo thỏa thuận |
| Non-Functional Requirement | Xử lý ≤ 5s
Cập nhật real-time
Không lỗi logic |