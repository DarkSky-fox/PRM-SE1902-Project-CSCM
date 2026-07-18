---
type: srs-flows
feature: inventory
updated: 2026-07-18
---

# Inventory — Flows

## Flow: Nhập kho (Happy + Error) — Sequence

**Trigger**: Cửa hàng trưởng điền thông tin nhập kho và bấm nút "Nhập hàng".
**Related UC**: [[../usecases/uc-import.md]]
**Related FR**: FR-inventory-001
**Related E**: E-inventory-001, E-inventory-002

```mermaid
sequenceDiagram
    actor Employee as Cửa hàng trưởng
    participant UI as InventoryOpsScreen (UI)
    participant Ctrl as InventoryOpsController
    participant Repo as InventoryOpsRepository
    participant DB as DatabaseHelper (SQLite)

    Employee->>UI: Chọn sản phẩm + Nhập số lượng & đơn giá
    Employee->>UI: Nhấn "Nhập hàng"
    
    alt Dữ liệu nhập không hợp lệ (trống hoặc số lượng/đơn giá <= 0)
        UI-->>Employee: Hiển thị SnackBar báo lỗi dữ liệu
    else Dữ liệu hợp lệ
        UI->>UI: Đặt _isLoading = true
        UI->>Ctrl: handleImport(employeeId, storeId, productId, quantity, importPrice)
        Ctrl->>Ctrl: Đóng gói sản phẩm nhập kho thành items list
        Ctrl->>Repo: createPurchaseOrder(employeeId, storeId, items)
        Repo->>DB: createPurchaseOrder(employeeId, storeId, items)
        
        DB->>DB: Bắt đầu giao dịch (db.transaction)
        DB->>DB: INSERT INTO PurchaseOrder (SupplierID=1, EmployeeID)
        DB-->>DB: Trả về poId
        
        loop Với mỗi mặt hàng trong items
            DB->>DB: INSERT INTO PurchaseOrderDetail (PurchaseOrderID=poId, ExpiredDate = now + 90 ngày)
            DB->>DB: UPDATE Inventory SET Quantity = Quantity + Quantity (cộng kho)
        end
        
        alt Giao dịch thành công
            DB-->>DB: Hoàn tất giao dịch (transaction commit)
            DB-->>Repo: Trả về true
            Repo-->>Ctrl: Trả về true
            Ctrl-->>UI: Trả về true
            
            UI->>UI: Clear text controllers, Reset selection & Đặt _isLoading = false
            UI->>Ctrl: loadInventory(storeId)
            Ctrl->>DB: getInventoryList(storeId) (truy vấn DB)
            DB-->>Ctrl: Trả về danh sách tồn kho mới
            Ctrl-->>UI: Trả về danh sách tồn kho mới
            UI->>UI: Cập nhật giao diện tồn kho (setState)
            UI-->>Employee: Hiển thị Dialog thành công (Nhập hàng thành công)
        else Lỗi ngoại lệ trong quá trình ghi (transaction failure / exception)
            DB-->>DB: Hoàn tác giao dịch (transaction rollback)
            DB-->>Repo: Trả về false
            Repo-->>Ctrl: Trả về false
            Ctrl-->>UI: Trả về false
            
            UI->>UI: Đặt _isLoading = false
            UI-->>Employee: Hiển thị SnackBar lỗi E-inventory-001 (Lỗi hệ thống khi nhập hàng!)
        end
    end
```
