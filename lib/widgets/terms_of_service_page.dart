import 'package:flutter/material.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

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
          'Điều khoản dịch vụ',
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
              'Điều khoản dịch vụ BikeCare',
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
              '1. Chấp nhận điều khoản',
              'Bằng việc tải xuống, cài đặt và sử dụng ứng dụng BikeCare, bạn đồng ý tuân thủ và bị ràng buộc bởi các điều khoản và điều kiện sau đây. Nếu bạn không đồng ý với bất kỳ phần nào của các điều khoản này, vui lòng không sử dụng ứng dụng.',
            ),

            _buildSection(
              '2. Mô tả dịch vụ',
              'BikeCare là ứng dụng quản lý xe máy cá nhân, cung cấp các tính năng:\n\n'
                  '• Quản lý thông tin xe máy\n'
                  '• Theo dõi chi phí bảo dưỡng và sửa chữa\n'
                  '• Tìm kiếm garage gần nhất\n'
                  '• Tra cứu phạt nguội giao thông\n'
                  '• Đánh giá và nhận xét về garage\n'
                  '• Quản lý lịch sử bảo dưỡng',
            ),

            _buildSection(
              '3. Tài khoản người dùng',
              'Khi tạo tài khoản trên BikeCare, bạn cam kết:\n\n'
                  '• Cung cấp thông tin chính xác và đầy đủ\n'
                  '• Bảo mật thông tin đăng nhập của bạn\n'
                  '• Chịu trách nhiệm về mọi hoạt động dưới tài khoản của bạn\n'
                  '• Thông báo ngay cho chúng tôi nếu phát hiện bất kỳ việc sử dụng trái phép nào',
            ),

            _buildSection(
              '4. Quyền sở hữu trí tuệ',
              'Tất cả nội dung, tính năng và chức năng của BikeCare (bao gồm nhưng không giới hạn ở văn bản, đồ họa, logo, biểu tượng, hình ảnh) là tài sản của BikeCare và được bảo vệ bởi luật bản quyền quốc tế.',
            ),

            _buildSection(
              '5. Nội dung người dùng',
              'Bạn giữ quyền sở hữu đối với nội dung bạn đăng tải lên BikeCare (đánh giá, bình luận, hình ảnh). Tuy nhiên, bằng việc đăng tải, bạn cấp cho BikeCare quyền sử dụng, sao chép, phân phối nội dung đó để vận hành và cải thiện dịch vụ.',
            ),

            _buildSection(
              '6. Hành vi bị cấm',
              'Khi sử dụng BikeCare, bạn không được:\n\n'
                  '• Đăng tải nội dung vi phạm pháp luật, xúc phạm, hoặc không phù hợp\n'
                  '• Giả mạo danh tính hoặc thông tin\n'
                  '• Sử dụng ứng dụng cho mục đích thương mại trái phép\n'
                  '• Can thiệp vào hoạt động của ứng dụng\n'
                  '• Thu thập thông tin người dùng khác',
            ),

            _buildSection(
              '7. Thông tin garage và dịch vụ',
              'BikeCare cung cấp thông tin về các garage và dịch vụ sửa chữa xe máy. Chúng tôi không chịu trách nhiệm về chất lượng dịch vụ, giá cả, hoặc bất kỳ tranh chấp nào giữa người dùng và garage.',
            ),

            _buildSection(
              '8. Tra cứu phạt nguội',
              'Tính năng tra cứu phạt nguội chỉ mang tính chất tham khảo. Để có thông tin chính xác và đầy đủ nhất, vui lòng truy cập website chính thức của Cục Cảnh sát giao thông.',
            ),

            _buildSection(
              '9. Giới hạn trách nhiệm',
              'BikeCare được cung cấp "nguyên trạng" và "sẵn có". Chúng tôi không đảm bảo rằng dịch vụ sẽ không bị gián đoạn, không có lỗi, hoặc an toàn tuyệt đối. Chúng tôi không chịu trách nhiệm về bất kỳ thiệt hại trực tiếp, gián tiếp, ngẫu nhiên, hoặc hậu quả nào phát sinh từ việc sử dụng ứng dụng.',
            ),

            _buildSection(
              '10. Thay đổi điều khoản',
              'Chúng tôi có quyền sửa đổi các điều khoản này bất kỳ lúc nào. Các thay đổi sẽ có hiệu lực ngay khi được đăng tải lên ứng dụng. Việc bạn tiếp tục sử dụng BikeCare sau khi có thay đổi đồng nghĩa với việc bạn chấp nhận các điều khoản mới.',
            ),

            _buildSection(
              '11. Chấm dứt',
              'Chúng tôi có quyền tạm ngưng hoặc chấm dứt quyền truy cập của bạn vào BikeCare bất kỳ lúc nào, không cần thông báo trước, nếu bạn vi phạm các điều khoản này.',
            ),

            _buildSection(
              '12. Luật áp dụng',
              'Các điều khoản này được điều chỉnh bởi luật pháp Việt Nam. Mọi tranh chấp phát sinh sẽ được giải quyết tại tòa án có thẩm quyền tại Việt Nam.',
            ),

            _buildSection(
              '13. Liên hệ',
              'Nếu bạn có bất kỳ câu hỏi nào về Điều khoản dịch vụ này, vui lòng liên hệ với chúng tôi qua:\n\n'
                  'Email: support@bikecare.vn\n'
                  'Điện thoại: 1900-xxxx\n'
                  'Địa chỉ: TP. Hồ Chí Minh, Việt Nam',
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
                ),
                child: const Text(
                  'Cảm ơn bạn đã sử dụng BikeCare!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E8EC7),
                  ),
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
