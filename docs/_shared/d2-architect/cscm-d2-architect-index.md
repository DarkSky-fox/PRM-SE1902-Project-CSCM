---
type: d2-architect-index
status: draft
updated: 2026-07-18
---

# CSCM — System Architecture Index

## Diagrams

| Slug | Khối chính | Dịch vụ ngoài | File liên kết | Updated |
|---|---|---|---|---|
| `cscm-architecture` | Client (Flutter App), Backend (Central Cloud), DB (SQLite & PostgreSQL) | Cổng thanh toán, Nhà cung cấp API | [cscm-architecture.svg](./cscm-architecture.svg) | 2026-07-18 |

## System Overview

Bức tranh tổng quan kiến trúc hệ thống của dự án CSCM (Chain Store & Custody Management). Hệ thống bao gồm 3 phân hệ chính:
1. **Phân hệ Client (Flutter POS/Mobile App)**: Chạy trên thiết bị tại cửa hàng, lưu trữ dữ liệu offline trực tiếp vào cơ sở dữ liệu SQLite cục bộ (`app_database.db`). Thực hiện các nghiệp vụ: Bán hàng (POS), Quản lý kho, Điều chuyển hàng hóa giữa các cửa hàng, Nhập hàng.
2. **Phân hệ Central Cloud System (Backend)**: Đóng vai trò đồng bộ hóa dữ liệu từ các cửa hàng thành viên về cơ sở dữ liệu tập trung (PostgreSQL), cung cấp các báo cáo tổng hợp và cấu hình hệ thống từ xa.
3. **Phân hệ Dịch vụ ngoài**: Tương tác với Cổng thanh toán (thực hiện thanh toán hóa đơn POS) và API của Nhà cung cấp (gửi PO tự động).
