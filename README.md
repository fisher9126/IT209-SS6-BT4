# Bài 4: Quản lý tiến trình nền với nohup và tín hiệu Kill

## 1. Mục tiêu
- Chạy một shell script giám sát dưới nền, độc lập với phiên terminal (vẫn chạy khi tắt SSH).
- Giám sát tiến trình bằng `ps`, tìm PID, và tắt an toàn bằng `kill` với tín hiệu SIGTERM/SIGKILL.

## 2. Script `loop-monitor.sh`
```bash
#!/bin/bash
# loop-monitor.sh - ghi thời gian hệ thống vào /tmp/monitor.log mỗi 5 giây
while true; do
  echo "System time: $(date)" >> /tmp/monitor.log
  sleep 5
done
```

## 3. Các bước thực hiện

### B1. Tạo script và gán quyền thực thi
```bash
cat << 'EOF' > loop-monitor.sh
#!/bin/bash
while true; do
  echo "System time: $(date)" >> /tmp/monitor.log
  sleep 5
done
EOF
chmod +x loop-monitor.sh
```

### B2. Chạy nền độc lập bằng nohup
```bash
nohup ./loop-monitor.sh > /dev/null 2>&1 &
```
- `nohup`: tiến trình bỏ qua tín hiệu HUP khi terminal đóng -> vẫn chạy sau khi tắt SSH.
- `> /dev/null 2>&1`: vứt bỏ output chuẩn + lỗi (vì log đã ghi vào /tmp/monitor.log).
- `&`: đẩy tiến trình xuống chạy nền.

### B3. Tìm PID của tiến trình
```bash
pgrep -f loop-monitor.sh
```
(hoặc `ps aux | grep loop-monitor.sh`)

### B4. Kiểm tra log đang được ghi liên tục
```bash
tail -n 10 /tmp/monitor.log
```

### B5. Tắt tiến trình an toàn
```bash
kill -15 <PID>
```
- `-15` = **SIGTERM**: yêu cầu tiến trình tự dọn dẹp và thoát an toàn. Ưu tiên dùng trước.
- Nếu sau vài giây vẫn còn, mới dùng `-9`:
```bash
kill -9 <PID>
```
- `-9` = **SIGKILL**: ép hệ điều hành giết ngay, không cho dọn dẹp (giải pháp cuối).

## 4. Kết quả thực tế

### Lệnh khởi chạy nohup
```
cachiu@Mac ex4 % nohup ./loop-monitor.sh > /dev/null 2>&1 &
[1] 94410
```

### Tìm PID của tiến trình
```
cachiu@Mac ex4 % pgrep -f loop-monitor.sh
94410
```

### Nội dung log (tail -n 10 /tmp/monitor.log)
```
System time: Tue  6 Oct 2026 08:04:37 +07
System time: Tue  6 Oct 2026 08:04:42 +07
System time: Tue  6 Oct 2026 08:04:47 +07
System time: Tue  6 Oct 2026 08:04:52 +07
System time: Tue  6 Oct 2026 08:04:57 +07
System time: Tue  6 Oct 2026 08:05:02 +07
System time: Tue  6 Oct 2026 08:05:07 +07
System time: Tue  6 Oct 2026 08:05:12 +07
```

### Lệnh kill kèm PID (SIGTERM)
```
cachiu@Mac ex4 % kill -15 94410
[1]  + terminated  nohup ./loop-monitor.sh > /dev/null 2>&1
```

### Xác nhận tiến trình đã biến mất
```
cachiu@Mac ex4 % kill -9 94410
kill: kill 94410 failed: no such process
```
Tiến trình đã bị SIGTERM (15) tắt an toàn, nên SIGKILL (9) không còn tiến trình để giết
-> xác nhận đã dừng hoàn toàn.

## 5. Giải thích SIGTERM vs SIGKILL
| Tín hiệu | Số | Hành vi | Khi dùng |
|----------|-----|---------|----------|
| SIGTERM | 15 | Yêu cầu tiến trình tự thoát, cho phép dọn dẹp (đóng file, lưu dữ liệu) | Mặc định, an toàn |
| SIGKILL | 9 | Kernel giết ngay lập tức, không cho dọn dẹp | Chỉ khi SIGTERM thất bại |

Ưu tiên SIGTERM để tránh mất/hỏng dữ liệu; SIGKILL là biện pháp cuối cùng.
