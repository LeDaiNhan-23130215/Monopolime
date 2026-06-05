# Đặc tả Use Case 09: Xử lý sự kiện

## Use Case ID
UC-09

## Name
Xử lý sự kiện

## Actor
Người chơi

## Description
Use case này mô tả quá trình hệ thống xử lý các sự kiện phát sinh trong lượt chơi của trò chơi Cờ tỷ phú. Sự kiện có thể bao gồm rút thẻ Cơ hội/Khí vận, đi vào ô đặc biệt, nhận tiền, mất tiền, di chuyển đến vị trí khác, vào tù, ra tù hoặc các tình huống ảnh hưởng đến tài chính, tài sản và trạng thái của người chơi.

## Preconditions
- Người chơi đã tạo game hoặc tham gia vào một ván game hợp lệ.
- Ván game đang ở trạng thái đang chơi.
- Người chơi đang trong lượt chơi của mình.
- Hệ thống đã xác định được vị trí hiện tại của người chơi trên bàn cờ.
- Dữ liệu về người chơi, tài chính, tài sản, nhà tù và danh sách sự kiện đã được khởi tạo.

## Postconditions
- Sự kiện được xử lý thành công hoặc được ghi nhận lỗi nếu không thể xử lý.
- Trạng thái người chơi được cập nhật phù hợp với kết quả sự kiện.
- Tài chính, tài sản, vị trí hoặc trạng thái nhà tù của người chơi được cập nhật nếu sự kiện có ảnh hưởng.
- Lịch sử sự kiện trong lượt chơi được lưu lại.
- Hệ thống chuyển tiếp sang bước tiếp theo của lượt chơi hoặc kết thúc lượt nếu cần.

## Main Flow
1. Người chơi thực hiện lượt chơi và di chuyển đến một ô trên bàn cờ.
2. Hệ thống kiểm tra loại ô mà người chơi vừa dừng lại.
3. Hệ thống xác định ô đó có phát sinh sự kiện hay không.
4. Nếu có sự kiện, hệ thống lấy thông tin sự kiện tương ứng từ danh sách sự kiện.
5. Hệ thống hiển thị nội dung sự kiện cho người chơi.
6. Hệ thống phân tích loại ảnh hưởng của sự kiện, ví dụ: cộng tiền, trừ tiền, di chuyển, vào tù, ra tù, nhận thẻ hoặc mất tài sản.
7. Hệ thống kiểm tra điều kiện áp dụng sự kiện đối với người chơi hiện tại.
8. Hệ thống thực hiện cập nhật dữ liệu theo nội dung sự kiện.
9. Nếu sự kiện ảnh hưởng đến tài chính, hệ thống gọi chức năng quản lý tài chính để cập nhật số tiền của người chơi.
10. Nếu sự kiện ảnh hưởng đến tài sản, hệ thống gọi chức năng quản lý tài sản để cập nhật trạng thái tài sản.
11. Nếu sự kiện liên quan đến nhà tù, hệ thống gọi chức năng xử lý nhà tù để cập nhật trạng thái người chơi.
12. Hệ thống ghi lại kết quả xử lý sự kiện vào lịch sử lượt chơi.
13. Hệ thống thông báo kết quả cuối cùng của sự kiện cho người chơi.
14. Hệ thống tiếp tục lượt chơi hoặc kết thúc lượt chơi tùy theo kết quả sự kiện.

## Alternative Flow

### AF-01: Sự kiện yêu cầu người chơi lựa chọn
1. Tại bước 5 của Main Flow, hệ thống hiển thị sự kiện có nhiều lựa chọn cho người chơi.
2. Người chơi chọn một phương án xử lý.
3. Hệ thống kiểm tra tính hợp lệ của lựa chọn.
4. Hệ thống xử lý sự kiện theo phương án người chơi đã chọn.
5. Use case tiếp tục từ bước 8 của Main Flow.

### AF-02: Sự kiện yêu cầu di chuyển đến ô khác
1. Tại bước 6 của Main Flow, hệ thống xác định sự kiện yêu cầu người chơi di chuyển đến vị trí khác.
2. Hệ thống cập nhật vị trí mới của người chơi trên bàn cờ.
3. Hệ thống kiểm tra ô mới có phát sinh thêm hành động hay không.
4. Nếu ô mới có hành động bắt buộc, hệ thống tiếp tục xử lý hành động đó.
5. Use case tiếp tục từ bước 12 của Main Flow.

### AF-03: Sự kiện không ảnh hưởng đến trạng thái người chơi
1. Tại bước 6 của Main Flow, hệ thống xác định sự kiện chỉ mang tính thông báo.
2. Hệ thống hiển thị nội dung sự kiện cho người chơi.
3. Hệ thống không thay đổi tiền, tài sản, vị trí hoặc trạng thái nhà tù.
4. Use case tiếp tục từ bước 12 của Main Flow.

## Exception Flow

### EF-01: Không tìm thấy dữ liệu sự kiện
1. Hệ thống không tìm thấy sự kiện tương ứng với ô hoặc thẻ được kích hoạt.
2. Hệ thống hiển thị thông báo lỗi.
3. Hệ thống ghi log lỗi để phục vụ kiểm tra và sửa lỗi.
4. Hệ thống bỏ qua sự kiện và cho phép lượt chơi tiếp tục nếu không ảnh hưởng nghiêm trọng.

### EF-02: Người chơi không đủ tiền để thực hiện sự kiện
1. Sự kiện yêu cầu người chơi trả tiền nhưng số dư hiện tại không đủ.
2. Hệ thống kiểm tra khả năng xử lý thiếu tiền theo luật game.
3. Hệ thống yêu cầu người chơi bán tài sản, thế chấp tài sản hoặc tuyên bố phá sản tùy theo luật đã thiết kế.
4. Nếu người chơi vẫn không thể thanh toán, hệ thống cập nhật trạng thái thua cuộc hoặc phá sản.
5. Hệ thống ghi nhận kết quả vào lịch sử game.

### EF-03: Lỗi cập nhật dữ liệu
1. Hệ thống gặp lỗi khi cập nhật tiền, tài sản, vị trí hoặc trạng thái người chơi.
2. Hệ thống hủy thao tác đang thực hiện hoặc khôi phục dữ liệu về trạng thái trước đó.
3. Hệ thống hiển thị thông báo lỗi cho người chơi.
4. Hệ thống ghi log lỗi để phục vụ xử lý kỹ thuật.

## Business Rules Mapping

| Mã quy tắc | Business Rule | Mô tả áp dụng trong Use Case |
|---|---|---|
| BR-01 | Mỗi sự kiện chỉ được kích hoạt khi người chơi dừng tại ô hoặc rút thẻ tương ứng | Hệ thống chỉ xử lý sự kiện sau khi xác định vị trí hoặc thẻ hợp lệ. |
| BR-02 | Sự kiện tài chính phải cập nhật chính xác số dư người chơi | Các sự kiện cộng tiền, trừ tiền, nhận thưởng hoặc nộp phạt phải gọi chức năng quản lý tài chính. |
| BR-03 | Người chơi không được có số tiền âm nếu luật game không cho phép | Khi không đủ tiền, hệ thống phải chuyển sang quy trình bán tài sản, thế chấp hoặc phá sản. |
| BR-04 | Sự kiện di chuyển phải cập nhật đúng vị trí mới của người chơi | Nếu sự kiện yêu cầu di chuyển, hệ thống phải thay đổi vị trí người chơi trên bàn cờ. |
| BR-05 | Sự kiện vào tù hoặc ra tù phải cập nhật trạng thái nhà tù | Các sự kiện liên quan đến nhà tù phải gọi chức năng xử lý nhà tù. |
| BR-06 | Mọi sự kiện đã xử lý phải được lưu vào lịch sử game | Hệ thống cần ghi lại nội dung sự kiện, người chơi bị ảnh hưởng và kết quả xử lý. |
| BR-07 | Sự kiện ảnh hưởng đến tài sản phải kiểm tra quyền sở hữu tài sản | Trước khi thay đổi tài sản, hệ thống phải kiểm tra người chơi có quyền với tài sản đó hay không. |
| BR-08 | Sự kiện phải được xử lý theo đúng thứ tự trong lượt chơi | Hệ thống không được cho phép người chơi kết thúc lượt khi sự kiện bắt buộc chưa hoàn tất. |
