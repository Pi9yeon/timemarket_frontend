import "user_model.dart";

class Post {
  final int id;
  final String title;
  final String description;
  final double latitude;
  final double longitude;
  final String type;
  final int price;
  final DateTime createdAt;
  final User author;

  Post({
    required this.id,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.price,
    required this.createdAt,
    required this.author, // ✅ 여기에 required 추가
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    assert(json['user'] != null, "author 필드는 null일 수 없습니다");
    
    // 디버깅: 백엔드에서 받은 user 데이터 확인
    print('📦 [Post.fromJson] 게시글 ID ${json['id']} 파싱:');
    print('   - user 데이터: ${json['user']}');
    print('   - profile_image 필드: ${json['user']['profile_image']}');

    return Post(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      type: json['type'],
      price: json['price'],
      createdAt: DateTime.parse(json['created_at']),
      author: User.fromJson(json['user']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'type': type,
      'price': price,
      'created_at': createdAt.toIso8601String(),
      'user': author.toJson(),
    };
  }
}
