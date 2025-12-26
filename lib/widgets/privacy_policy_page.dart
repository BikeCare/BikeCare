import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E8EC7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chính sách quyền riêng tư',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chính sách quyền riêng tư',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E8EC7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cập nhật lần cuối: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            _buildSection(
              'Giới thiệu',
              'BikeCare cam kết bảo vệ quyền riêng tư của bạn. Chính sách này giải thích cách chúng tôi thu thập, sử dụng, và bảo vệ thông tin cá nhân của bạn khi sử dụng ứng dụng BikeCare.',
            ),

            _buildSection(
              '1. Thông tin chúng tôi thu thập',
              'Chúng tôi có thể thu thập các loại thông tin sau:\n\n'
                  '• Thông tin cá nhân: Họ tên, email, số điện thoại, ảnh đại diện\n'
                  '• Thông tin xe máy: Biển số, loại xe, năm sản xuất, màu sắc\n'
                  '• Thông tin sử dụng: Lịch sử bảo dưỡng, chi phí sửa chữa\n'
                  '• Thông tin vị trí: Để tìm garage gần bạn (chỉ khi bạn cho phép)\n'
                  '• Đánh giá và nhận xét: Về các garage bạn đã sử dụng\n'
                  '• Thông tin thiết bị: Loại thiết bị, hệ điều hành, ID thiết bị',
            ),

            _buildSection(
              '2. Cách chúng tôi sử dụng thông tin',
              'Thông tin của bạn được sử dụng để:\n\n'
                  '• Cung cấp và cải thiện dịch vụ BikeCare\n'
                  '• Quản lý tài khoản và xe máy của bạn\n'
                  '• Gửi thông báo về lịch bảo dưỡng, cập nhật ứng dụng\n'
                  '• Hiển thị garage gần vị trí của bạn\n'
                  '• Phân tích và cải thiện trải nghiệm người dùng\n'
                  '• Ngăn chặn gian lận và lạm dụng\n'
                  '• Tuân thủ nghĩa vụ pháp lý',
            ),

            _buildSection(
              '3. Chia sẻ thông tin',
              'Chúng tôi không bán thông tin cá nhân của bạn. Chúng tôi chỉ chia sẻ thông tin trong các trường hợp sau:\n\n'
                  '• Với garage: Khi bạn đặt lịch hoặc yêu cầu dịch vụ\n'
                  '• Với nhà cung cấp dịch vụ: Để vận hành ứng dụng (lưu trữ dữ liệu, phân tích)\n'
                  '• Theo yêu cầu pháp luật: Khi có lệnh từ cơ quan có thẩm quyền\n'
                  '• Bảo vệ quyền lợi: Để bảo vệ quyền, tài sản, an toàn của BikeCare và người dùng',
            ),

            _buildSection(
              '4. Bảo mật thông tin',
              'Chúng tôi áp dụng các biện pháp bảo mật kỹ thuật và tổ chức để bảo vệ thông tin của bạn:\n\n'
                  '• Mã hóa dữ liệu khi truyền tải (SSL/TLS)\n'
                  '• Lưu trữ an toàn trên máy chủ được bảo vệ\n'
                  '• Kiểm soát truy cập nghiêm ngặt\n'
                  '• Cập nhật bảo mật thường xuyên\n\n'
                  'Tuy nhiên, không có phương thức truyền tải qua Internet nào là 100% an toàn. Chúng tôi không thể đảm bảo tuyệt đối về bảo mật.',
            ),

            _buildSection(
              '5. Quyền của bạn',
              'Bạn có các quyền sau đối với thông tin cá nhân của mình:\n\n'
                  '• Truy cập: Xem thông tin chúng tôi lưu trữ về bạn\n'
                  '• Sửa đổi: Cập nhật thông tin cá nhân trong ứng dụng\n'
                  '• Xóa: Yêu cầu xóa tài khoản và dữ liệu của bạn\n'
                  '• Từ chối: Không đồng ý với một số hoạt động xử lý dữ liệu\n'
                  '• Di chuyển: Yêu cầu xuất dữ liệu của bạn\n\n'
                  'Để thực hiện các quyền này, vui lòng liên hệ với chúng tôi qua email: support@bikecare.vn',
            ),

            _buildSection(
              '6. Quyền truy cập vị trí',
              'BikeCare yêu cầu quyền truy cập vị trí của bạn để:\n\n'
                  '• Tìm garage gần nhất\n'
                  '• Hiển thị khoảng cách đến garage\n'
                  '• Đề xuất dịch vụ phù hợp với khu vực của bạn\n\n'
                  'Bạn có thể tắt quyền truy cập vị trí bất kỳ lúc nào trong cài đặt thiết bị, nhưng một số tính năng có thể bị hạn chế.',
            ),

            _buildSection(
              '7. Cookie và công nghệ theo dõi',
              'Chúng tôi sử dụng các công nghệ tương tự cookie để:\n\n'
                  '• Ghi nhớ tùy chọn của bạn\n'
                  '• Phân tích cách bạn sử dụng ứng dụng\n'
                  '• Cải thiện hiệu suất ứng dụng\n\n'
                  'Bạn có thể quản lý tùy chọn cookie trong cài đặt ứng dụng.',
            ),

            _buildSection(
              '8. Dữ liệu trẻ em',
              'BikeCare không dành cho người dưới 16 tuổi. Chúng tôi không cố ý thu thập thông tin cá nhân từ trẻ em. Nếu bạn là phụ huynh và phát hiện con bạn đã cung cấp thông tin cho chúng tôi, vui lòng liên hệ để chúng tôi xóa dữ liệu đó.',
            ),

            _buildSection(
              '9. Lưu trữ dữ liệu',
              'Chúng tôi lưu trữ thông tin của bạn:\n\n'
                  '• Trong thời gian bạn sử dụng BikeCare\n'
                  '• Sau khi bạn xóa tài khoản: Tối đa 30 ngày (để xử lý yêu cầu và tuân thủ pháp luật)\n'
                  '• Một số dữ liệu có thể được lưu trữ lâu hơn nếu pháp luật yêu cầu',
            ),

            _buildSection(
              '10. Liên kết bên thứ ba',
              'BikeCare có thể chứa liên kết đến website hoặc dịch vụ của bên thứ ba (như Google Maps). Chúng tôi không chịu trách nhiệm về chính sách quyền riêng tư của các bên này. Vui lòng đọc chính sách của họ trước khi cung cấp thông tin.',
            ),

            _buildSection(
              '11. Thay đổi chính sách',
              'Chúng tôi có thể cập nhật Chính sách quyền riêng tư này theo thời gian. Chúng tôi sẽ thông báo cho bạn về các thay đổi quan trọng qua email hoặc thông báo trong ứng dụng. Việc bạn tiếp tục sử dụng BikeCare sau khi có thay đổi đồng nghĩa với việc bạn chấp nhận chính sách mới.',
            ),

            _buildSection(
              '12. Liên hệ',
              'Nếu bạn có câu hỏi về Chính sách quyền riêng tư này hoặc muốn thực hiện quyền của mình, vui lòng liên hệ:\n\n'
                  'Email: privacy@bikecare.vn\n'
                  'Điện thoại: 1900-xxxx\n'
                  'Địa chỉ: TP. Hồ Chí Minh, Việt Nam\n\n'
                  'Chúng tôi sẽ phản hồi trong vòng 7 ngày làm việc.',
            ),

            const SizedBox(height: 40),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E8EC7).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF2E8EC7).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: Color(0xFF2E8EC7),
                      size: 32,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Quyền riêng tư của bạn là ưu tiên hàng đầu',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E8EC7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
