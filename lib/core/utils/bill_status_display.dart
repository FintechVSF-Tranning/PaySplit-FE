/// Nhãn tiếng Việt cho `bills.status` của backend — nguồn sự thật duy nhất.
///
/// Bốn màn hình từng tự khai một bảng nhãn riêng, và hai trong số đó ghi
/// `reviewed` là "Đã duyệt". Đó là ngược nghĩa: `reviewed` nghĩa là hóa đơn đã
/// được đối soát xong và đang *chờ* chốt sổ, chưa ai duyệt gì cả. Người dùng mở
/// một hóa đơn mình biết chắc là chưa xong lại thấy nó ghi "Đã duyệt".
///
/// Màu sắc vẫn để từng màn hình tự quyết vì mỗi chỗ một nền khác nhau; chỉ
/// riêng chữ thì phải giống nhau ở mọi nơi.
String billStatusLabel(String status) => switch (status) {
  'draft' => 'Nháp',
  'reviewed' => 'Chờ duyệt',
  'finalized' => 'Đã chốt',
  'voided' => 'Đã hủy',
  // Trả lại nguyên trạng thái lạ thay vì đoán bừa thành 'Nháp': backend thêm
  // trạng thái mới thì phải nhìn thấy ngay, chứ không phải im lặng hiển thị sai.
  _ => status,
};
