import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../helpers/utils.dart';

class GarageDetailPage extends StatefulWidget {
  final Map<String, dynamic> garage;
  const GarageDetailPage({super.key, required this.garage});

  @override
  State<GarageDetailPage> createState() => _GarageDetailPageState();
}

class _GarageDetailPageState extends State<GarageDetailPage> {
  // === STATE DATA ===
  List<Map<String, dynamic>> _reviews = [];
  List<String> _garageImages = [];
  bool _isLoading = true;

  // Rating Stats
  double _dynamicRating = 0.0;
  int _dynamicReviewCount = 0;
  Map<int, int> _starCounts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

  // State Yêu thích
  bool _isFavorited = false;

  // === THÔNG TIN USER (QUAN TRỌNG ĐỂ HIỆN CHỮ "BẠN") ===
  final String _currentUserId = "user_001";
  final String _currentUserName = "Minh Tùng"; // Tên người dùng đang đăng nhập

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // =========================================================
  // 1. LOAD DATA
  // =========================================================
  Future<void> _loadData() async {
    final garageId = widget.garage['id'];

    // 1. Xử lý ảnh
    String? jsonImg = widget.garage['images'];
    if (jsonImg != null && jsonImg.isNotEmpty) {
      try {
        _garageImages = List<String>.from(jsonDecode(jsonImg));
      } catch (e) {
        _garageImages = [];
      }
    }
    if (_garageImages.isEmpty && widget.garage['image'] != null) {
      _garageImages.add(widget.garage['image']);
    }

    // 2. Check Yêu thích
    bool favStatus = await isFavorite(_currentUserId, garageId);

    // 3. Review & Rating
    final reviews = await getReviews(garageId);
    double total = 0;
    _starCounts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

    if (reviews.isNotEmpty) {
      for (var r in reviews) {
        int rating = r['rating'] as int;
        total += rating;
        if (_starCounts.containsKey(rating))
          _starCounts[rating] = _starCounts[rating]! + 1;
      }
      _dynamicRating = total / reviews.length;
    } else {
      _dynamicRating = widget.garage['rating'] != null
          ? double.parse(widget.garage['rating'].toString())
          : 0.0;
    }

    if (mounted) {
      setState(() {
        _reviews = reviews;
        _dynamicReviewCount = reviews.length;
        _isFavorited = favStatus;
        _isLoading = false;
      });
    }
  }

  // =========================================================
  // 2. YÊU THÍCH (TIM)
  // =========================================================
  Future<void> _toggleFavorite() async {
    setState(() => _isFavorited = !_isFavorited);
    await toggleFavorite(_currentUserId, widget.garage['id']);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFavorited ? "Đã thêm vào yêu thích ❤️" : "Đã bỏ yêu thích 💔",
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  // =========================================================
  // 3. GỌI ĐIỆN (POPUP + GỌI THẬT)
  // =========================================================
  void _showCallPopup() {
    final phone = widget.garage['phone'];
    if (phone == null || phone.toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Chưa cập nhật số điện thoại")),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Liên hệ cửa hàng"),
        content: Text("Bạn muốn gọi đến số:\n$phone"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              final Uri launchUri = Uri(scheme: 'tel', path: phone);
              if (await canLaunchUrl(launchUri)) await launchUrl(launchUri);
            },
            icon: const Icon(Icons.call),
            label: const Text("Gọi ngay"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // 4. GỬI ĐÁNH GIÁ (LOGIC HIỆN TÊN "BẠN")
  // =========================================================
  void _submitReview(int star, String comment) async {
    // [FIX] Lưu tên thật của User (_currentUserName) thay vì chuỗi cứng
    await addReview(widget.garage['id'], _currentUserName, star, comment);

    if (mounted) Navigator.pop(context);
    setState(() => _isLoading = true);
    await _loadData(); // Load lại để thấy ngay

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Đánh giá thành công!")));
    }
  }

  void _showRatingForm() {
    int selectedStar = 5;
    TextEditingController controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Viết đánh giá",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            StatefulBuilder(
              builder: (context, setStateSheet) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (i) => IconButton(
                    onPressed: () => setStateSheet(() => selectedStar = i + 1),
                    icon: Icon(
                      i < selectedStar ? Icons.star : Icons.star_border,
                      size: 40,
                      color: Colors.amber,
                    ),
                  ),
                ),
              ),
            ),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: "Nhập trải nghiệm...",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _submitReview(selectedStar, controller.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Gửi đánh giá"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // 5. HELPER: MAP & GALLERY
  // =========================================================
  Future<void> _openMap() async {
    final id = widget.garage['id'];
    final lat = widget.garage['lat'];
    final lng = widget.garage['lng'];
    Uri googleUrl;
    if (id.length > 15) {
      googleUrl = Uri.parse("https://www.google.com/maps/search/...4");
    } else if (lat != null && lng != null) {
      googleUrl = Uri.parse(
        "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Chưa có vị trí")));
      return;
    }
    try {
      if (await canLaunchUrl(googleUrl))
        await launchUrl(googleUrl, mode: LaunchMode.externalApplication);
      else
        await launchUrl(googleUrl);
    } catch (e) {
      print(e);
    }
  }

  void _openGallery(int initialIndex) {
    if (_garageImages.isEmpty) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            PageView.builder(
              itemCount: _garageImages.length,
              controller: PageController(initialPage: initialIndex),
              itemBuilder: (context, index) => InteractiveViewer(
                child: _buildImg(_garageImages[index], fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // BUILD UI
  // =========================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.garage['name'],
          style: const TextStyle(fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // INFO HEADER
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildImg(
                            widget.garage['image'] ?? '',
                            width: 80,
                            height: 80,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.garage['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  Text(
                                    " ${widget.garage['distance'] ?? '?'} km từ bạn",
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.garage['address'],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _toggleFavorite,
                          icon: Icon(
                            _isFavorited
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _isFavorited ? Colors.red : Colors.grey,
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // BUTTONS (Style List Page)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _showCallPopup,
                            child: _actionButton(
                              Icons.call,
                              "Gọi điện",
                              const Color(0xFFA5D6A7),
                              Colors.green.shade900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () {},
                            child: _actionButton(
                              Icons.calendar_today,
                              "Đặt lịch",
                              const Color(0xFF90CAF9),
                              Colors.blue.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // MAP
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.map, color: Colors.blue),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.garage['address'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _openMap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blue,
                            elevation: 0,
                          ),
                          child: const Text("Dẫn đường"),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // GALLERY
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _garageImages.isEmpty
                        ? const SizedBox()
                        : SizedBox(
                            height: 200,
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: GestureDetector(
                                    onTap: () => _openGallery(0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: _buildImg(
                                        _garageImages[0],
                                        height: double.infinity,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (_garageImages.length > 1)
                                  Expanded(
                                    flex: 1,
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () => _openGallery(1),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: _buildImg(
                                                _garageImages[1],
                                                width: double.infinity,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        if (_garageImages.length > 2)
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () => _openGallery(2),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: _buildImg(
                                                  _garageImages[2],
                                                  width: double.infinity,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),

                  // SERVICES
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "Danh mục dịch vụ",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      "Thay phụ tùng chính hãng, vá lốp, bơm bánh xe, thay nhớt...",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const Divider(
                    thickness: 8,
                    color: Color(0xFFF5F5F5),
                    height: 30,
                  ),

                  // RATING SUMMARY
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            Text(
                              _dynamicRating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: List.generate(
                                5,
                                (i) => Icon(
                                  i < _dynamicRating.round()
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 20,
                                ),
                              ),
                            ),
                            Text(
                              "($_dynamicReviewCount đánh giá)",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            children: [5, 4, 3, 2, 1].map((star) {
                              int count = _starCounts[star] ?? 0;
                              double percent = _dynamicReviewCount == 0
                                  ? 0
                                  : count / _dynamicReviewCount;
                              return Row(
                                children: [
                                  Text(
                                    "$star",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.star,
                                    size: 10,
                                    color: Colors.grey,
                                  ),
                                  Expanded(
                                    child: LinearProgressIndicator(
                                      value: percent,
                                      color: Colors.amber,
                                      backgroundColor: Colors.grey[200],
                                      minHeight: 6,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: _showRatingForm,
                          icon: const Icon(Icons.add),
                          label: const Text("Đánh giá"),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // LIST REVIEWS (CÓ LOGIC HIỆN CHỮ "BẠN")
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "Bài đánh giá",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  _reviews.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            "Chưa có đánh giá nào.",
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: _reviews.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final rv = _reviews[index];

                            // [FIX] LOGIC SO SÁNH TÊN NGƯỜI DÙNG
                            String userName = rv['user_name'];
                            bool isMe = userName == _currentUserName;
                            String displayName = isMe
                                ? "Bạn"
                                : userName; // Nếu trùng tên thì hiện "Bạn"

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: isMe
                                    ? Colors.blue
                                    : Colors.grey.shade300,
                                child: Text(
                                  displayName[0].toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isMe ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                              title: Text(
                                displayName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isMe ? Colors.blue : Colors.black,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: List.generate(
                                      5,
                                      (i) => Icon(
                                        i < rv['rating']
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: Colors.amber,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(rv['comment']),
                                  if (rv['created_at'] != null)
                                    Text(
                                      rv['created_at'].toString().split('T')[0],
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  // WIDGET HELPER: NÚT BẤM STYLE CŨ
  Widget _actionButton(
    IconData icon,
    String label,
    Color bgColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET HELPER: ẢNH
  Widget _buildImg(
    String url, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    if (url.startsWith('http')) {
      return Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: const Icon(Icons.image),
        ),
      );
    }
    return Image.asset(
      url,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: const Icon(Icons.image),
      ),
    );
  }
}
