---
description: Vẽ sequence diagram Mermaid cho luồng nghiệp vụ BA (như login, checkout, webhook, error recovery) từ mô tả, xác nhận kế hoạch trước khi ghi vào tài liệu flows.md và tự động kiểm tra cú pháp Mermaid trước khi hoàn thành.
---

# Sequence Diagram Workflow

## Steps

### 1. Kích hoạt Diagram Skill
- Sử dụng skill `@sequence` để thực hiện vẽ sơ đồ dựa trên mô tả hoặc yêu cầu của người dùng.
- Thực hiện đầy đủ quy trình nghiệp vụ, các bước phỏng vấn (nếu thiếu thông tin), cơ chế approval gate (L1/L2) và kiểm tra cú pháp (compile/validate/semcheck) theo hướng dẫn của skill.
