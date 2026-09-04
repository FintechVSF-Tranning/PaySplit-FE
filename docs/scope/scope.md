# Scope: PaySplit FE

PaySplit FE là ứng dụng di động giúp nhóm nhập hóa đơn, gán món, chia tiền và theo dõi thanh toán. Scope hiện tại theo dõi phần hoàn thiện thuế, phí, khuyến mãi và đối soát trên màn chi tiết hóa đơn.

**Build approach:** Tracer Bullet (mỗi lát thay đổi phải nối state, giao diện và kiểm thử thành một luồng chạy thật).
**Workflow:** GA (`/check verify`, `/test`, fresh model `/check review`, rồi `/document`). Đây là mức mặc định cho thay đổi liên quan đến tính toán tiền. `/architect` vẫn là điểm bắt đầu được khuyến nghị khi feature còn quyết định chưa chốt.

_Đây là khuyến nghị để giữ quá trình triển khai rõ ràng. Bạn có thể bỏ qua bước không phù hợp và tự quyết định khi nào feature hoàn tất._

## At a glance

| # | Feature | Phase | Status |
|---|---------|-------|--------|
| 1 | Thuế, phí, khuyến mãi và đối soát Bill Detail | Slice 1 | in-progress |

## Slice 1

### 1. Thuế, phí, khuyến mãi và đối soát Bill Detail · in-progress

Hoàn thiện phần điều chỉnh và cảnh báo chênh lệch theo PaySplit UI. Người dùng chỉ nhập phí, VAT và voucher, còn tổng thanh toán luôn được ứng dụng tự tính.

**Done when:** thẻ và modal hiển thị đúng chuỗi tính tiền; không có ô nhập tổng tiền; cảnh báo khớp, thiếu, dư và món chưa gán hoạt động đúng; bill read only không có hành động sửa.

- [x] Design it (spec): `/architect Thuế, phí, khuyến mãi và đối soát Bill Detail`
- [x] Build it: `/develop Thuế, phí, khuyến mãi và đối soát Bill Detail`
   - [x] Khóa nguồn tính và các hành động local, tổng thanh toán luôn tự tính (AC UI 5, AC UI 6)
   - [x] Hoàn thiện thẻ tóm tắt và modal adjustments theo PaySplit UI (AC UI 5)
   - [x] Gắn đủ trạng thái cùng hành động đối soát vào Bill Detail (AC UI 6, AC UI 7, AC UI 8)
   - [x] Hoàn thiện unit test, widget test, theme và accessibility (AC UI 5 đến AC UI 8)
   - [x] Hỗ trợ nhập VND hoặc phần trăm và định dạng dấu chấm cho các ô tiền (AC UI 4, AC UI 5)
- [ ] Verify it: `/check verify Thuế, phí, khuyến mãi và đối soát Bill Detail`
- [ ] Test it: `/test Thuế, phí, khuyến mãi và đối soát Bill Detail`
- [ ] Review it (fresh model): `/check review Thuế, phí, khuyến mãi và đối soát Bill Detail`
- [x] Document it: `/document Thuế, phí, khuyến mãi và đối soát Bill Detail`

Spec [0004](../specs/0004-bill-detail-ocr-assignment-ui-v1/index.md) · code in `lib/features/bills/`

## Legend

**Feature lifecycle:** `planned` là chưa bắt đầu, `in-progress` là đang thiết kế hoặc xây dựng, `done` là đã hoàn tất các bước được chọn, `existing` là đã có trước workflow, và `dropped` là đã bỏ khỏi phạm vi.

**Next step:** ô chưa đánh dấu đầu tiên là bước tiếp theo được đề xuất. Task chi tiết nằm trong `## 6. Build Plan & Implementation Slices` của spec, scope chỉ giữ các milestone lớn.

**Workflow:** GA đề xuất chạy `/check verify`, `/test`, `/check review` bằng model mới và `/document` sau `/develop`.
