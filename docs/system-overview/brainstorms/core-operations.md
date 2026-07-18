---
type: brainstorm
feature: system-overview
status: draft
updated: 2026-07-18
links: []
---

# Đăng nhập phân quyền & Luồng vận hành cốt lõi

## 1. Idea Seed

> "Nghiên cứu nghiệp vụ phân quyền đăng nhập cho 3 vai trò (Nhân viên, Cửa hàng trưởng, Chủ chuỗi) để xem báo cáo doanh thu theo ngày/tháng/năm; tích hợp thêm các luồng vận hành cốt lõi: Cửa hàng trưởng xếp lịch, Nhân viên xem lịch, Nhân viên kiểm kho, Nhân viên chuyển kho, Cửa hàng trưởng nhập kho, Nhân viên thanh toán POS đơn giản lưu thành công mặc định."

(Ý tưởng phát triển từ yêu cầu dự án cá nhân CSCM.)

## 2. Context

- Dự án CSCM là hệ thống quản lý chuỗi cửa hàng và bán hàng (POS & Inventory Management) chạy trên môi trường di động/POS sử dụng Flutter và SQLite cục bộ.
- Dự án là dự án cá nhân (không có deadline doanh nghiệp gắt gao), hướng tới sự đơn giản trong vận hành nhưng chặt chẽ trong phân quyền xem doanh thu và thực thi kho bãi để tránh thất thoát.
- Nỗi đau hiện tại: Hệ thống cũ chưa hỗ trợ phân cấp xem báo cáo doanh thu theo chuỗi hoặc cửa hàng cụ thể, dẫn đến việc rò rỉ dữ liệu hoặc thiếu báo cáo tổng hợp Ngày/Tháng/Năm.

## 2.1 Project Structure

Dự án được cấu trúc theo mô hình phân lớp rõ ràng nhằm phục vụ vận hành offline-first:

- **`lib/`** (Mã nguồn Flutter):
  - **`models/`**: Khai báo cấu trúc thực thể tương ứng với các bảng trong SQLite (ví dụ: `account_model.dart`, `employee_model.dart`, `product_model.dart`, `invoice_model.dart`, `transferorder_model.dart`, ...).
  - **`services/`**: Chứa `database_helper.dart` quản lý khởi tạo database SQLite (`app_database.db`) cục bộ, định nghĩa bảng và các hàm thực thi nghiệp vụ thông qua SQLite transactions (lưu hóa đơn, nhập/xuất kho).
  - **`repositories/`**: Lớp trung gian thực hiện giao tiếp dữ liệu giữa controllers và dịch vụ SQLite DB (ví dụ: `auth_repository.dart`, `employee_repository.dart`, `invoice_repository.dart`).
  - **`controllers/`**: Xử lý logic nghiệp vụ, trung chuyển dữ liệu từ repository và cập nhật trạng thái UI (ví dụ: `pos_controller.dart`, `login_controller.dart`, `schedule_controller.dart`).
  - **`screens/`**: Giao diện người dùng Flutter (ví dụ: `login_screen.dart` đăng nhập, `pos_screen.dart` bán hàng POS, `inventory_ops_screen.dart` quản lý kho, `employee_admin_screen.dart` quản trị lịch và nhân viên).
  - **`utils/`**: Các thành phần giao diện dùng chung như chủ đề thiết kế (`app_theme.dart`).
  - **`main.dart`**: Điểm khởi chạy của ứng dụng Flutter POS.

- **`docs/`** (Tài liệu nghiệp vụ & Quy trình):
  - **`system-overview/`**: Định nghĩa kiến trúc hệ thống (`d2-architect`) và ý tưởng cốt lõi (`core-operations.md`).
  - **`authentication/`**: Đặc tả luồng và sơ đồ sequence cho tính năng Đăng nhập.
  - **`pos/`**: Đặc tả luồng và sơ đồ sequence cho nghiệp vụ Bán hàng thanh toán POS cục bộ.
  - **`inventory/`**: Đặc tả luồng và sơ đồ sequence cho quản lý kho (nhập kho, chuyển kho, kiểm kho).
  - **`_shared/`**: Log hoạt động tập trung (`activity.log`) và sơ đồ kiến trúc hệ thống chung.



## 3. User Types (preliminary)

| User Type | Pain Point | Primary Need |
|-----------|-----------|--------------|
| Nhân viên (Cashier/Staff) | Thao tác POS rườm rà, xem lịch làm thủ công | POS thanh toán 1-click lưu nhanh, xem lịch làm ngay trên app, thực hiện chuyển kho |
| Cửa hàng trưởng (Store Manager) | Khó kiểm kho, nhập kho không khớp, xếp lịch cho staff thủ công | Xem doanh thu store mình, nhập hàng PO từ supplier, xếp lịch làm cho staff, khóa staff nghỉ việc |
| Chủ chuỗi (Chain Owner) | Không thấy doanh thu tổng hợp toàn chuỗi để đối soát | Dashboard doanh thu toàn chuỗi theo Ngày/Tháng/Năm, quyền tối cao cấp và khóa tài khoản |

## 4. Capabilities Breakdown

### P0 — must have
- Đăng nhập chung 1 màn hình và tự động điều hướng theo RoleID.
- Phân quyền xem doanh thu: Nhân viên (0%), Cửa hàng trưởng (100% store mình), Chủ chuỗi (100% toàn chuỗi).
- Luồng POS bán hàng đơn giản: Nhân viên chọn món, số lượng, áp mã giảm giá, bấm lưu mặc định đã thanh toán.
- Luồng Nhập kho (Cửa hàng trưởng) & Chuyển kho (Nhân viên) & Kiểm kho (Nhân viên).
- Cấp tài khoản nhân viên (Chủ chuỗi thực hiện thủ công, tự đặt mật khẩu).
- Khóa tài khoản nhân viên nghỉ việc (Cửa hàng trưởng hoặc Chủ chuỗi khóa).

### P1 — should have
- Cửa hàng trưởng xếp lịch làm việc cho nhân viên.
- Nhân viên xem lịch làm việc cá nhân của mình trên app.
- Xem doanh thu theo biểu đồ cột/đường (Ngày/Tháng/Năm).

### P2 — nice to have
- Log lịch sử chỉnh sửa lịch làm việc và lịch sử thao tác kho.
- Xuất báo cáo doanh thu chuỗi ra file CSV.

## 5. Core Flows (Happy Path)

### 5.1 Luồng Đăng nhập điều hướng tự động

1. Người dùng mở app, nhập Username + Password.
2. Hệ thống kiểm tra trong SQLite:
   - Nếu RoleID = Nhân viên -> Mở thẳng màn hình POS bán hàng (không có menu doanh thu).
   - Nếu RoleID = Cửa hàng trưởng -> Mở Dashboard doanh thu của StoreID tương ứng.
   - Nếu RoleID = Chủ chuỗi -> Mở Dashboard tổng hợp chuỗi và menu Quản trị nhân sự.

```
[User] nhập User/Pass ─▶ [Hệ thống] đối chiếu SQLite
                                │
             ┌──────────────────┼──────────────────┐
             ▼                  ▼                  ▼
     (Role: Nhân viên)   (Role: Cửa hàng trưởng)  (Role: Chủ chuỗi)
             │                  │                  │
             ▼                  ▼                  ▼
       Mở POS Screen      Mở Store Dashboard   Mở Chain Dashboard
     (No revenue view)   (Doanh thu store mình) (Doanh thu toàn chuỗi)
```

### 5.2 Luồng POS bán hàng đơn giản (Nhân viên)

1. Nhân viên chọn các mặt hàng và số lượng khách mua từ danh sách trên màn hình POS.
2. Nhân viên nhập mã giảm giá (nếu có). Hệ thống tự tính toán số tiền giảm và tổng tiền còn lại (`TotalAmount`).
3. Nhân viên nhấn "Xác nhận thanh toán".
4. Hệ thống lưu hóa đơn vào bảng `Invoice` và `InvoiceDetail`, cập nhật trừ số lượng hàng trong bảng `Inventory` cục bộ. Mặc định trạng thái đơn hàng là thành công (đã thanh toán).

```
[Nhân viên] chọn mặt hàng + số lượng ─▶ nhập Coupon (nếu có)
                                              │
                                              ▼
                                      [Hệ thống] tính TotalAmount
                                              │
                                              ▼
                                    Nhấn "Xác nhận thanh toán"
                                              │
                                              ▼
                                  [Hệ thống] Lưu Invoice + trừ kho
                                (Mặc định Success, không qua cổng)
```

### 5.3 Luồng Cấp tài khoản & Khóa tài khoản

1. Chủ chuỗi truy cập màn hình "Quản lý nhân sự", chọn "Cấp tài khoản".
2. Chủ chuỗi nhập: Username, Password, Chọn Role (Nhân viên/Cửa hàng trưởng), Chọn Cửa hàng trực thuộc, Họ tên đầy đủ, Giới tính, Số điện thoại.
3. Hệ thống kiểm tra trùng Username trong DB. Nếu không trùng, tạo bản ghi `Account` và bản ghi `Employee` tương ứng, mặc định `Status = 1` (Hoạt động).
4. Khi nhân viên nghỉ việc, Cửa hàng trưởng hoặc Chủ chuỗi vào danh sách nhân viên, chọn tài khoản đó và nhấn "Khóa tài khoản". Hệ thống cập nhật `Status = 0` (Bị khóa). Nhân viên đó sẽ không thể đăng nhập ở lần tiếp theo.

```
[Chủ chuỗi] nhập info ─▶ [Hệ thống] Check trùng Username
                                      │
                         ┌────────────┴────────────┐
                     không trùng                 trùng Username
                         │                         │
                         ▼                         ▼
                 Lưu Account (Status=1)      Báo lỗi trùng, chặn lưu
                 Lưu Employee liên kết
                         │
                         ▼
             (Khi nghỉ việc: Quản lý/Chủ chuỗi bấm Khóa)
                         │
                         ▼
                 Cập nhật Status = 0 (Bị khóa)
```

### 5.4 Luồng Quản lý kho (Nhập - Chuyển - Kiểm)

1. **Nhập kho (Cửa hàng trưởng)**: Cửa hàng trưởng chọn nhà cung cấp, nhập mặt hàng và số lượng nhập, ghi nhận giá nhập. Hệ thống lưu vào bảng `PurchaseOrder` và cộng số lượng vào bảng `Inventory` của store.
2. **Chuyển kho (Nhân viên)**: Nhân viên chọn Store nguồn, Store đích, mặt hàng và số lượng chuyển. Hệ thống lưu vào bảng `TransferOrder`, trừ số lượng ở kho nguồn và cộng số lượng ở kho đích.
3. **Kiểm kho (Nhân viên)**: Nhân viên quét mã/chọn mặt hàng, nhập số lượng tồn kho thực tế đếm được. Hệ thống lưu ghi nhận chênh lệch giữa số lượng thực tế và số lượng trên hệ thống để Cửa hàng trưởng xử lý.

```
Luồng Kho CSCM:
- Nhập kho: [Cửa hàng trưởng] tạo PO ─▶ Cộng kho store tương ứng
- Chuyển kho: [Nhân viên] tạo TransferOrder ─▶ Trừ kho nguồn ─▶ Cộng kho đích
- Kiểm kho: [Nhân viên] đếm số lượng thực tế ─▶ Ghi nhận chênh lệch tồn kho
```

### 5.5 Luồng Xếp lịch & Xem lịch làm việc

1. Cửa hàng trưởng mở màn hình "Quản lý lịch làm", chọn Nhân viên, chọn Ngày làm việc và Ca làm việc (Ca sáng / Ca chiều / Ca tối). Nhấn lưu.
2. Hệ thống cập nhật lịch làm việc vào DB.
3. Nhân viên đăng nhập vào app, mở tab "Lịch làm việc của tôi" để xem danh sách các ngày làm và ca làm việc được phân công trong tuần/tháng hiện tại.

## 6. System Behavior Deep Dive

### 6.1 Decision Points

| ID | Flow | Khi nào | YES (nhánh đồng ý) | NO (nhánh từ chối) |
|---|---|---|---|---|
| D1 | Đăng nhập | Đăng nhập thành công? | Kiểm tra RoleID để điều hướng màn hình phù hợp | Hiển thị thông báo sai thông tin đăng nhập, dừng |
| D2 | Đăng nhập | Status tài khoản = 1 (Active)? | Cho phép đăng nhập và điều hướng | Báo lỗi tài khoản bị khóa, chặn đăng nhập |
| D3 | Cấp tài khoản | Username đã tồn tại trong DB? | Báo lỗi Username trùng, chặn không cho lưu | Cho phép tạo tài khoản mới |
| D4 | Khóa tài khoản | Người thao tác là Cửa hàng trưởng? | Cho phép khóa nếu nhân viên đó trực thuộc store của mình | Từ chối khóa (nếu khóa nhân viên store khác hoặc khóa Chủ chuỗi) |
| D5 | Bán hàng | Giỏ hàng POS trống? | Báo lỗi "Vui lòng chọn ít nhất 1 mặt hàng" | Cho phép thanh toán |
| D6 | Chuyển kho | Số lượng chuyển > Số lượng tồn kho nguồn? | Báo lỗi tồn kho không đủ, chặn giao dịch | Thực hiện trừ kho nguồn, cộng kho đích |

### 6.2 Scenario Matrix (has_multi_role)

| From State | To State | Rule | Action | Result |
|------------|----------|------|--------|--------|
| Đang đăng nhập | Dashboard POS | Người dùng là Nhân viên | Điều hướng đến POS bán hàng | Nhân viên bán hàng, không thấy nút báo cáo |
| Đang đăng nhập | Dashboard Store | Người dùng là Cửa hàng trưởng | Điều hướng đến Dashboard store | Xem doanh thu của store mình phụ trách |
| Đang đăng nhập | Dashboard Chain | Người dùng là Chủ chuỗi | Điều hướng đến Dashboard chuỗi | Xem tổng hợp doanh thu tất cả các store |
| Đang hoạt động | Bị khóa | Trưởng cửa hàng hoặc Chủ chuỗi bấm Khóa | Cập nhật Status = 0 trong SQLite | Tài khoản không thể đăng nhập từ thời điểm đó |

### 6.3 State Transitions (has_state_machine)

```
Account: Active (1) ──[Khóa thủ công]──▶ Locked (0)
        Locked (0) ──[Mở khóa thủ công]──▶ Active (1)
```

| Entity | Từ | Sang | Trigger | Quay lại được? |
|--------|------|----|---------|-------------|
| Account | Active (1) | Locked (0) | Trưởng cửa hàng hoặc Chủ chuỗi thực hiện khóa nhân viên nghỉ việc | Có (mở lại được) |
| Account | Locked (0) | Active (1) | Trưởng cửa hàng hoặc Chủ chuỗi thực hiện mở khóa lại tài khoản | Có |

### 6.4 Interrupted Transactions (Hệ thống cục bộ SQLite)

| Tình huống | Hệ thống còn lại gì | Resume | Cleanup |
|---|---|---|---|
| Thiết bị sập nguồn giữa lúc lưu Invoice | Hóa đơn lưu dở, DB có thể bị lock hoặc rollback | SQLite transaction tự động rollback dữ liệu về trạng thái trước khi bấm xác nhận | Không cần dọn dẹp nhờ cơ chế Transaction của SQLite |
| Thiết bị mất mạng khi Nhân viên bán hàng | App hoạt động bình thường vì DB hoàn toàn nằm offline trên thiết bị | Không ảnh hưởng đăng nhập hay bán hàng | Dữ liệu sẽ tự động đồng bộ khi có kết nối Internet trở lại (kịch bản đồng bộ tương lai) |

### 6.5 Other Edge Cases

- **Nhân viên cố tình truy cập link báo cáo**: Vì đây là ứng dụng Flutter native chạy cục bộ, phân quyền được kiểm tra trực tiếp ở mức giao diện (không vẽ Widget báo cáo nếu RoleID không khớp), đảm bảo an toàn tuyệt đối ở client-side.
- **Trưởng cửa hàng tự khóa tài khoản chính mình**: Hệ thống chặn không cho phép tài khoản tự khóa chính mình trên giao diện.

## 7. Validation, Limits & Wording

### 7.1 Validation rules

| Field | Rule |
|---|---|
| Username | Bắt buộc; độ dài >= 3 ký tự; không chứa khoảng trắng; không chứa ký tự đặc biệt |
| Password | Bắt buộc; độ dài >= 6 ký tự |
| FullName | Bắt buộc; không để trống |
| StoreID | Bắt buộc đối với Nhân viên và Cửa hàng trưởng |
| Phone | Tùy chọn; nếu nhập phải đúng định dạng số điện thoại |

### 7.2 Limits & Quotas (exact values)

| Tham số | Giá trị | Window | Behavior khi vượt |
|---|---|---|---|
| Số lần nhập sai mật khẩu | Vô hạn | / session | Vì là dự án cá nhân, không tự động khóa tài khoản để tránh phiền phức thử nghiệm. Chỉ khóa thủ công |

### 7.3 Wording samples (exact strings)

#### Error messages

| Tình huống | Wording | Code |
|---|---|---|
| Đăng nhập sai | "Tên đăng nhập hoặc mật khẩu không chính xác." | E-auth-001 |
| Tài khoản bị khóa | "Tài khoản của bạn đã bị khóa. Vui lòng liên hệ Quản lý hoặc Chủ chuỗi để mở lại." | E-auth-002 |
| Tạo trùng Username | "Tên đăng nhập đã tồn tại trong hệ thống. Vui lòng chọn tên khác." | E-auth-003 |
| Chuyển kho vượt tồn | "Số lượng hàng tồn kho nguồn không đủ để thực hiện chuyển." | E-stock-001 |

#### Success messages

| Tình huống | Wording |
|---|---|
| Đăng nhập thành công | "Đăng nhập thành công." |
| Cấp tài khoản thành công | "Tạo tài khoản nhân viên thành công." |
| Thanh toán POS lưu | "Lưu hóa đơn thành công." |

## 8. Assumptions

- Ứng dụng chạy offline hoàn toàn trên thiết bị thông qua SQLite cục bộ làm nguồn lưu trữ chính thức.
- Mật khẩu lưu trong DB được mã hóa hash đơn giản (như SHA-256) để đảm bảo an toàn cơ bản.
- Doanh thu hiển thị trên Dashboard được tính tức thì từ việc truy vấn SUM(`TotalAmount`) trong bảng `Invoice` lọc theo StoreID và thời gian tương ứng.

## 9. Risks

| Rủi ro | Khả năng | Hậu quả nghiệp vụ | Cách phòng |
|--------|----------|-------------------|-----------|
| Mất thiết bị / Hỏng cơ sở dữ liệu SQLite cục bộ | thỉnh thoảng | Mất toàn bộ dữ liệu bán hàng và hóa đơn chưa đồng bộ | Phát triển tính năng backup/đồng bộ database định kỳ lên cloud backend |
| Cửa hàng trưởng cố tình sửa lịch làm việc của nhân viên store khác | hiếm | Gây lộn xộn ca kíp, nhân viên khiếu nại | Ràng buộc chặt chẽ điều kiện StoreID của Cửa hàng trưởng phải khớp StoreID của Nhân viên khi sửa lịch |

## 10. Success Criteria (preliminary)

- Thời gian đăng nhập và điều hướng màn hình < 1 giây.
- 100% hóa đơn POS lưu thành công và cập nhật trừ kho chính xác lập tức.
- Không xảy ra lỗi khóa chết (deadlock) DB SQLite khi bán hàng đồng thời với kiểm kho.

## 11. Open Questions

- [ ] OQ-1: Có cần lưu lịch sử đăng nhập của nhân viên phục vụ việc đối soát ca kíp hay không?
- [ ] OQ-2: Khi Nhân viên chuyển kho, có cần bước "Xác nhận đã nhận hàng" từ Store đích không, hay tự động trừ kho nguồn cộng kho đích luôn (P0 hiện tại đang tự động cộng trừ luôn)?

## 12. Next Steps

Sau brainstorm này (sau khi approve):
- `/urd authentication` — đặc tả góc nhìn người dùng về ca làm việc & POS.
- `/brd authentication` — đánh giá hiệu quả kiểm soát chuỗi.
- `/prd-epic authentication` — chốt scope phát triển giao diện POS và Dashboard.
