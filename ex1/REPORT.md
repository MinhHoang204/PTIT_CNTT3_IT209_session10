# Báo cáo kỹ thuật: Phân tích kiến trúc Container vs Virtual Machine
## 1. Giới thiệu bối cảnh
Trong những năm gần đây, phần lớn doanh nghiệp đang dần chuyển đổi hạ tầng từ mô hình VPS sử dụng máy ảo (Virtual Machine -
VM) truyền thống sang kiến trúc container hóa với Docker. Lý do cốt lõi đến từ sự khác biệt cơ bản về kiến trúc ảo hóa: VM 
thực hiện ảo hóa ở tầng phần cứng thông qua hypervisor, trong khi Container thực hiện ảo hóa ở tầng hệ điều hành, dùng chung
nhân (kernel) của máy chủ để tối ưu hóa tài nguyên và tốc độ triển khai.

Báo cáo này phân tích chi tiết sự khác biệt giữa hai mô hình, giải thích cơ chế hoạt động lõi của container và trích xuất 
thông số thực tế từ môi trường Docker.

## 2. Bảng so sánh Container vs VM theo 5 tiêu chí chính
| Tiêu chí | Virtual Machine (VM) | Container (Docker) |
|---|---|---|
| **Dung lượng Image** | Từ vài GB đến hàng chục GB, do bao gồm toàn bộ hệ điều hành khách (Guest OS) riêng cho mỗi VM. | Từ vài MB đến vài chục MB, chỉ đóng gói ứng dụng và các thư viện phụ thuộc cần thiết, không bao gồm hệ điều hành riêng. |
| **Thời gian khởi động** | Từ vài giây đến vài phút, cần thời gian khởi tạo toàn bộ hệ điều hành khách và các dịch vụ bên trong VM. | Từ vài mili giây đến vài giây, chỉ cần khởi tạo môi trường thực thi riêng biệt bên trên kernel đang chạy của máy chủ. |
| **Hao phí tài nguyên OS** | Hao phí rất cao: mỗi VM tiêu tốn tài nguyên riêng cho hệ điều hành, quy trình nền và bộ nhớ đệm của Guest OS, thường chiếm 20-50% tài nguyên phân bổ ngay cả khi không chạy ứng dụng. | Hao phí gần như không đáng kể: tất cả container dùng chung hệ điều hành của máy chủ, không có chi phí vận hành hệ điều hành riêng biệt cho từng container. |
| **Mức độ cô lập** | Cô lập hoàn toàn và mạnh mẽ: mỗi VM hoạt động độc lập, tách biệt hoàn toàn phần cứng, kernel và tài nguyên với các VM khác. Lỗ hổng trên một VM không ảnh hưởng đến các VM còn lại. | Cô lập ở mức quy trình: các container dùng chung kernel của máy chủ, được tách biệt bởi các cơ chế của Linux. Mức độ cô lập yếu hơn VM, phù hợp với các khối công việc không yêu cầu bảo mật cấp độ cao nhất. |
| **Khả năng mở rộng** | Mở rộng chậm và tốn kém: cần tạo mới hoặc khởi động lại toàn bộ VM, khó mở rộng chi tiết theo từng thành phần ứng dụng. | Mở rộng tức thời và chi tiết: có thể nhân bản hoặc thu hẹp số lượng container trong vài giây, phù hợp với kiến trúc microservices mở rộng theo yêu cầu thực tế. |

## 3. Vai trò của Namespaces và Control Groups (cgroups) trong Container
Hai cơ chế lõi của nhân Linux tạo ra môi trường thực thi cô lập và được quản lý tài nguyên cho container là **Namespaces** 
và **Control Groups (cgroups)**:

### Namespaces - Cơ chế cô lập môi trường
Namespaces chịu trách nhiệm tạo ra một khung nhìn hệ thống hoàn toàn riêng biệt cho từng container, các loại chính bao gồm:
- **PID Namespace**: Cô lập không gian quy trình, quy trình bên trong container không thể nhìn thấy hay tương tác với quy 
trình của máy chủ hoặc các container khác, có PID bắt đầu từ 1 như một hệ thống độc lập.
- **Network Namespace**: Cô lập toàn bộ mạng, mỗi container có giao diện mạng riêng, bảng định tuyến, quy tắc tường lửa và
cổng nghe hoàn toàn tách biệt với máy chủ và các container khác.
- **Mount Namespace**: Cô lập hệ thống tệp, mỗi container có cây thư mục gốc riêng, không thể truy cập hệ thống tệp của máy
chủ trừ khi được gắn kết rõ ràng thông qua volume.
- Ngoài ra còn có UTS Namespace (cô lập hostname và tên miền) và User Namespace (cô lập quyền người dùng, người dùng root
bên trong container không có quyền root thực tế trên máy chủ).

### Control Groups (cgroups) - Cơ chế quản lý tài nguyên
cgroups chịu trách nhiệm giới hạn và theo dõi lượng tài nguyên hệ thống mà nhóm quy trình (tương ứng với một container) được 
phép sử dụng:
- **Giới hạn CPU**: Đặt giới hạn tỷ lệ sử dụng lõi CPU, ưu tiên phân bổ thời gian xử lý giữa các container khác nhau, tránh 
tình trạng một container chiếm toàn bộ tài nguyên CPU của máy chủ.
- **Giới hạn RAM**: Đặt giới hạn lượng bộ nhớ tối đa container được phép sử dụng, ngăn chặn rò rỉ bộ nhớ trên một container 
làm ảnh hưởng đến các container khác hoặc toàn bộ máy chủ.
- Ngoài ra cgroups còn cho phép giới hạn băng thông đĩa, băng thông mạng và theo dõi thống kê sử dụng tài nguyên của từng 
container một cách chi tiết.

Tất cả các cơ chế này được kernel Linux cung cấp sẵn, Docker chỉ là lớp công cụ bọc lại để đơn giản hóa việc tạo, quản lý 
và kết hợp các namespace và cgroups thành một container hoàn chỉnh.

## 4. Thông số thực tế từ đầu ra lệnh `docker info`
Kết quả thực thi lệnh `docker info` trên môi trường thử nghiệm trả về các thông số cơ bản:
- **Server Version**: 27.0.3
- **Cgroup Driver**: systemd (đây là trình điều khiển cgroups mặc định trên các bản phân phối Linux hiện đại sử dụng systemd 
như Ubuntu, Debian)
- **Containers đang chạy**: 0
- **Tổng số Containers**: 2
- **Tổng số Images**: 5

Kết quả kiểm tra: cả hai lệnh `docker version` và `docker info` đều thực thi thành công bằng người dùng thường mà không cần
gõ `sudo`, sau khi người dùng được thêm vào nhóm `docker` của hệ thống.

## 5. Kết luận
Chuyển đổi từ VPS/VM sang Docker giúp doanh nghiệp giảm chi phí hạ tầng từ 30-70% nhờ tối ưu tài nguyên, tăng tốc triển khai
ứng dụng từ mức phút xuống mức giây và đơn giản hóa quy trình DevOps CI/CD. Hai công nghệ không thay thế hoàn toàn lẫn nhau: 
VM vẫn phù hợp cho các khối công việc yêu cầu cô lập cao hoặc chạy hệ điều hành khác, trong khi Container là lựa chọn tối ưu 
cho kiến trúc microservices và các ứng dụng cloud-native.