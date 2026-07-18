---
type: srs-flows
feature: pos
updated: 2026-07-18
---

# POS — Flows

## Flow: Thanh toán POS cục bộ (Happy + Error) — Sequence

**Trigger**: Nhân viên nhấn nút "Xác nhận thanh toán" trên màn hình POS sau khi chọn món.
**Related UC**: [[../usecases/uc-checkout.md]]
**Related FR**: FR-pos-001
**Related E**: E-pos-001, E-pos-002

```mermaid
sequenceDiagram
    actor Employee as Nhân viên
    participant UI as PosScreen (UI)
    participant Ctrl as PosController
    participant Repo as InvoiceRepository
    participant DB as DatabaseHelper (SQLite)

    Employee->>UI: Chọn mặt hàng + số lượng
    opt Nhập mã giảm giá
        Employee->>UI: Nhập mã giảm giá
        UI->>UI: Tính toán tiền giảm giá
    end
    UI-->>Employee: Hiển thị Subtotal, Discount & TotalAmount

    Employee->>UI: Nhấn "Xác nhận thanh toán"
    
    alt Giỏ hàng trống (cart.isEmpty)
        UI-->>Employee: Hiển thị SnackBar lỗi E-pos-001 (Vui lòng chọn ít nhất 1 mặt hàng!)
    else Giỏ hàng hợp lệ
        UI->>Ctrl: handleCheckout(storeId, employeeId, cart, products, discountPercent, totalAmount)
        Ctrl->>Ctrl: Trích xuất danh sách chi tiết hóa đơn (items)
        Ctrl->>Repo: createInvoice(storeId, employeeId, items, totalAmount)
        Repo->>DB: createInvoice(storeId, employeeId, items, totalAmount)
        
        DB->>DB: Bắt đầu giao dịch (db.transaction)
        
        DB->>DB: INSERT INTO Invoice
        DB-->>DB: Trả về invoiceId
        
        loop Với mỗi mặt hàng trong items
            DB->>DB: INSERT INTO InvoiceDetail
            DB->>DB: UPDATE Inventory SET Quantity = MAX(0, Quantity - Quantity) (trừ kho)
        end
        
        alt Giao dịch thành công
            DB-->>DB: Hoàn tất giao dịch (transaction commit)
            DB-->>Repo: Trả về true
            Repo-->>Ctrl: Trả về true
            Ctrl-->>UI: Trả về true
            
            UI->>UI: Xóa sạch giỏ hàng & Đặt lại discount
            UI->>Ctrl: loadStoreProducts(storeId)
            Ctrl->>DB: getInventoryList(storeId) (truy vấn DB)
            DB-->>Ctrl: Trả về danh sách sản phẩm mới
            Ctrl-->>UI: Trả về danh sách sản phẩm mới
            UI->>UI: Cập nhật giao diện (setState)
            UI-->>Employee: Hiển thị Dialog thành công (Lưu hóa đơn thành công)
        else Lỗi ngoại lệ trong quá trình ghi (transaction failure / exception)
            DB-->>DB: Hoàn tác giao dịch (transaction rollback)
            DB-->>Repo: Trả về false
            Repo-->>Ctrl: Trả về false
            Ctrl-->>UI: Trả về false
            
            UI-->>Employee: Hiển thị Dialog lỗi E-pos-002 (Lưu hóa đơn thất bại)
        end
    end
```

