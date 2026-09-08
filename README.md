## Trình cài driver máy in Canon LBP cho Ubuntu

Công cụ này giúp cài **driver máy in Canon CAPT dành cho Linux** để sử dụng các máy in dòng Canon LBP trên Ubuntu. Công cụ hỗ trợ cả Ubuntu 32-bit và 64-bit.

### Cài đặt

#### Bật hỗ trợ gói 32-bit (i386)

Trên Ubuntu 64-bit, driver Canon cần thêm hỗ trợ cho các gói 32-bit. Hãy kiểm tra file nguồn phần mềm APT:

```text
/etc/apt/sources.list.d/ubuntu.sources
```

Mở file bằng quyền quản trị:

```bash
sudo nano /etc/apt/sources.list.d/ubuntu.sources
```

Trong mỗi khối cấu hình Ubuntu, tìm dòng bắt đầu bằng `Architectures:` và bảo đảm dòng đó có **cả** `amd64` và `i386`:

```
Types: deb
URIs: http://archive.ubuntu.com/ubuntu/
Suites: noble noble-updates noble-backports
Components: main universe restricted multiverse
Architectures: amd64 i386
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
```

Nếu dòng `Architectures:` chưa tồn tại, thêm dòng `Architectures: amd64 i386` bên dưới dòng `Components:`. Nếu file đã có sẵn cả `amd64 i386` thì không cần sửa.

Trong `nano`, nhấn `Ctrl+O`, nhấn Enter để lưu, rồi nhấn `Ctrl+X` để thoát. Sau đó cập nhật danh sách gói:

```bash
sudo dpkg --add-architecture i386
sudo apt update
```

Nếu `apt update` hoàn tất mà không báo lỗi, bạn có thể tiếp tục cài driver bên dưới. Script cũng tự kiểm tra và thêm kiến trúc `i386` trong quá trình cài đặt.


#### Cách 1: Cài đặt trực tiếp từ Internet

Mở **Terminal** (Cửa sổ dòng lệnh), dán lệnh dưới đây rồi nhấn Enter:

```
wget https://github.com/linhdhvn/canon_printer/raw/master/canon_lbp_setup.sh -O /tmp/canon_lbp_setup.sh && sudo bash /tmp/canon_lbp_setup.sh
```

Ubuntu có thể yêu cầu nhập mật khẩu đăng nhập. Khi gõ mật khẩu trong Terminal, màn hình sẽ không hiển thị ký tự nào; đây là hành vi bình thường.

#### Cách 2: Tải script về trước rồi chạy

Sử dụng cách này nếu bạn muốn lưu script về máy trước khi cài:

```
wget https://github.com/linhdhvn/canon_printer/raw/master/canon_lbp_setup.sh
chmod +x canon_lbp_setup.sh
./canon_lbp_setup.sh
```

Trong quá trình cài đặt, chương trình sẽ yêu cầu bạn:

1. Chọn model máy in.
2. Chọn cách kết nối máy in: qua USB hoặc qua mạng LAN.
3. Nếu dùng mạng LAN, nhập địa chỉ IP của máy in (ví dụ: `192.168.1.25`).

Để cài đặt thành công, hãy bật máy in trước. Nếu kết nối USB, hãy cắm cáp USB vào máy tính khi chương trình yêu cầu.

### Kiểm tra sau khi cài đặt

Sau khi cài xong, một lối tắt sẽ được tạo trên **Màn hình nền (Desktop)**. Mở lối tắt này để xem trạng thái máy in.

- Nếu hiển thị **Ready to Print** (Sẵn sàng in), máy in đã có thể sử dụng.
- Nếu máy in chưa sẵn sàng, hãy kiểm tra lại nguồn điện, cáp USB hoặc địa chỉ IP mạng rồi khởi động lại máy tính.

Script `canon_restart.sh` có thể được dùng để khởi động lại dịch vụ máy in và CUPS khi máy in không phản hồi. Hãy chạy script này trong Terminal từ thư mục dự án:

```
sudo bash canon_restart.sh
```

### Các model được hỗ trợ

- LBP-810
- LBP1120
- LBP1210
- LBP2900
- LBP3000
- LBP3010
- LBP3018
- LBP3050
- LBP3100
- LBP3108
- LBP3150
- LBP3200
- LBP3210
- LBP3250
- LBP3300
- LBP3310
- LBP3500
- LBP5000
- LBP5050
- LBP5100
- LBP5300
- LBP6000
- LBP6018
- LBP6020
- LBP6020B
- LBP6200
- LBP6300n
- LBP6300
- LBP6310
- LBP7010C
- LBP7018C
- LBP7200C
- LBP7210C
- LBP9100C
- LBP9200C

### Script gốc và tài liệu tham khảo

https://github.com/hieplpvip/canon_printer
http://help.ubuntu.ru/wiki/canon_capt
