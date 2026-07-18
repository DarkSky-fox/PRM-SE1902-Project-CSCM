---
type: srs-flows
feature: authentication
updated: 2026-07-18
---

# Authentication — Flows

## Flow: Login/Authentication

**Trigger**: Người dùng mở ứng dụng và nhập thông tin đăng nhập (username, password).
**Related UC**: [[../usecases/uc-login.md]]
**Related FR**: FR-authentication-001
**Related E**: E-authentication-001, E-authentication-002

```mermaid
sequenceDiagram
    actor Employee as Nhân viên
    participant App as Flutter POS App
    participant DB as SQLite DB
    participant API as Central API

    Employee->>App: Nhập Username và Password
    App->>App: Kiểm tra dữ liệu đầu vào (không rỗng)
    
    App->>DB: Query Account bằng Username
    DB-->>App: Trả về Account (Password hash, Status, RoleID)

    alt Account không tồn tại hoặc sai Password
        App-->>Employee: Hiển thị lỗi E-authentication-001 (Thông tin đăng nhập không chính xác)
    else Account tồn tại
        alt Status = 0 (Tài khoản bị khóa)
            App-->>Employee: Hiển thị lỗi E-authentication-002 (Tài khoản đã bị khóa)
        else Status = 1 (Tài khoản hoạt động)
            App->>DB: Query Employee chi tiết bằng AccountID
            DB-->>App: Trả về Employee (FullName, StoreID)
            App->>App: Khởi tạo session đăng nhập thành công
            App-->>Employee: Chuyển đến màn hình Dashboard / POS bán hàng
            
            opt Kết nối Internet khả dụng
                App->>API: Gửi log đăng nhập & sync trạng thái session (HTTPS POST)
                API-->>App: Xác nhận thành công (HTTP 200)
            end
        end
    end
```
