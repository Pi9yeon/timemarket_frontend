import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/time_post_service.dart';
import 'map_picker_screen.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  String _selectedType = 'sale';
  final TimePostService _timePostService = TimePostService();
  bool _isSubmitting = false;
  bool _locationSelected = false;

  // 당근마켓 스타일 컬러
  static const Color carrotOrange = Color(0xFFFF6F00);
  static const Color carrotLightOrange = Color(0xFFFFE0B2);

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _openMapPicker() async {
    HapticFeedback.lightImpact();
    final LatLng? result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => MapPickerScreen()),
    );

    if (result != null) {
      setState(() {
        _latitudeController.text = result.latitude.toString();
        _longitudeController.text = result.longitude.toString();
        _locationSelected = true;
      });
    }
  }

  Future<void> _submit() async {
    // ... (기존 _submit 함수는 변경 없음) ...
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final latitude = double.tryParse(_latitudeController.text.trim()) ?? 0.0;
    final longitude = double.tryParse(_longitudeController.text.trim()) ?? 0.0;
    final price = int.tryParse(_priceController.text.trim()) ?? 0;
    final type = _selectedType;

    final success = await _timePostService.createPost({
      'title': title,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'type': type,
      'price': price,
    });

    setState(() {
      _isSubmitting = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('게시글이 성공적으로 등록되었습니다.')));
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('게시글 등록에 실패했습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          '게시글 작성',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // 제목 입력
            _buildSectionTitle('제목'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _titleController,
              hintText: '제목을 입력해주세요',
              icon: Icons.title_rounded,
              validator: (value) =>
                  (value == null || value.isEmpty) ? '제목을 입력해주세요' : null,
            ),
            const SizedBox(height: 24),

            // 설명 입력
            _buildSectionTitle('설명'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _descriptionController,
              hintText: '상세한 설명을 입력해주세요',
              icon: Icons.description_rounded,
              maxLines: 5,
              validator: (value) =>
                  (value == null || value.isEmpty) ? '설명을 입력해주세요' : null,
            ),
            const SizedBox(height: 24),

            // 위치 선택
            _buildSectionTitle('거래 위치'),
            const SizedBox(height: 8),
            _buildLocationSelector(),
            const SizedBox(height: 24),

            // 타입 선택
            _buildSectionTitle('거래 유형'),
            const SizedBox(height: 8),
            _buildTypeSelector(),
            const SizedBox(height: 24),

            // 가격 입력
            _buildSectionTitle('가격'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _priceController,
              hintText: '가격을 입력해주세요',
              icon: Icons.attach_money_rounded,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return '가격을 입력해주세요';
                final val = int.tryParse(value);
                if (val == null) return '유효한 숫자를 입력해주세요';
                return null;
              },
            ),
            const SizedBox(height: 32),

            // 등록 버튼
            _buildSubmitButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(icon, color: carrotOrange, size: 22),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: carrotOrange, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[300]!, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }

  Widget _buildLocationSelector() {
    return Column(
      children: [
        // 숨겨진 validator를 위한 필드들
        Opacity(
          opacity: 0,
          child: SizedBox(
            height: 0,
            child: Column(
              children: [
                TextFormField(
                  controller: _latitudeController,
                  validator: (value) =>
                      (value == null || value.isEmpty) ? '위치를 선택해주세요' : null,
                ),
                TextFormField(
                  controller: _longitudeController,
                  validator: (value) =>
                      (value == null || value.isEmpty) ? '위치를 선택해주세요' : null,
                ),
              ],
            ),
          ),
        ),
        // 지도 선택 버튼
        InkWell(
          onTap: _openMapPicker,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _locationSelected ? carrotOrange : Colors.grey[200]!,
                width: _locationSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _locationSelected ? carrotLightOrange : Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.location_on_rounded,
                    color: _locationSelected ? carrotOrange : Colors.grey[600],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _locationSelected ? '위치 선택 완료' : '지도에서 위치 선택',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _locationSelected ? carrotOrange : Colors.black87,
                        ),
                      ),
                      if (_locationSelected) ...[
                        const SizedBox(height: 4),
                        Text(
                          '다시 선택하려면 탭하세요',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 4),
                        Text(
                          '거래할 위치를 지도에서 선택해주세요',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey[400],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTypeOption(
              label: '판매',
              value: 'sale',
              icon: Icons.sell_rounded,
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.grey[200],
          ),
          Expanded(
            child: _buildTypeOption(
              label: '구인',
              value: 'request',
              icon: Icons.person_search_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeOption({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _selectedType == value;
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedType = value;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? carrotOrange : Colors.grey[600],
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? carrotOrange : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return _isSubmitting
        ? Container(
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(carrotOrange),
              ),
            ),
          )
        : Material(
            color: carrotOrange,
            borderRadius: BorderRadius.circular(12),
            elevation: 2,
            child: InkWell(
              onTap: _submit,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 56,
                alignment: Alignment.center,
                child: const Text(
                  '등록하기',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
  }
}