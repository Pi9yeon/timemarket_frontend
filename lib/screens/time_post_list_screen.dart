// lib/screens/time_post_list_screen.dart

import 'package:flutter/material.dart';
import 'package:timemarket_frontend/screens/login_screen.dart';
import 'package:timemarket_frontend/screens/time_post_map_screen.dart';
import '../services/time_post_service.dart';
import '../services/auth_service.dart';
import 'create_post_screen.dart';
import 'edit_post_screen.dart';
import 'post_detail_screen.dart';
import '../models/post_model.dart';

class TimePostListScreen extends StatefulWidget {
  const TimePostListScreen({super.key});

  @override
  State<TimePostListScreen> createState() => _TimePostListScreenState();
}

class _TimePostListScreenState extends State<TimePostListScreen> {
  final TimePostService _timePostService = TimePostService();
  final AuthService _authService = AuthService();

  List<dynamic>? _posts;
  bool _loading = true;

  // ✅ 1. '전체' 상태를 추가하고 기본값으로 설정
  String? _currentPostType; // null 또는 빈 문자열이 '전체'를 의미
  List<bool> _isSelected = [true, false, false]; // [전체, 판매, 구인]

  final double _lat = 37.5;
  final double _lng = 127.0;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _loading = true;
    });

    // ✅ 2. _currentPostType으로 API 요청 (null이면 전체 조회)
    final posts = await _timePostService.fetchNearbyPosts(
      lat: _lat,
      lng: _lng,
      type: _currentPostType,
    );
    setState(() {
      _posts = posts ?? [];
      _loading = false;
    });
  }

  // 상단 액션 버튼 목록 (기존과 동일)
  List<Widget> _buildActions() {
    return [
      IconButton(
        icon: const Icon(Icons.map),
        tooltip: '지도',
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const TimePostMapScreen()),
          );
        },
      ),
      IconButton(
        icon: const Icon(Icons.add),
        tooltip: '게시물 작성',
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreatePostScreen()),
          );
          if (created == true) _loadPosts();
        },
      ),
      IconButton(
        icon: const Icon(Icons.logout),
        tooltip: '로그아웃',
        onPressed: () async {
          await _authService.logout();
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // ✅ 3. AppBar의 title 부분에 3개의 토글 버튼 추가
        title: ToggleButtons(
          isSelected: _isSelected,
          onPressed: (int index) {
            setState(() {
              for (int i = 0; i < _isSelected.length; i++) {
                _isSelected[i] = i == index;
              }
              // ✅ 4. 선택된 타입 변경 로직 수정
              if (index == 0) {
                _currentPostType = null; // 전체
              } else if (index == 1) {
                _currentPostType = 'sale'; // 판매
              } else {
                _currentPostType = 'request'; // 구인
              }
            });
            _loadPosts();
          },
          borderRadius: BorderRadius.circular(8.0),
          selectedColor: Colors.blueAccent,
          color: Colors.white,
          fillColor: Colors.white.withOpacity(0.9),
          borderColor: Colors.white,
          selectedBorderColor: Colors.white,
          children: const <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('전체'),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('시간 판매'),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('구인'),
            ),
          ],
        ),
        actions: _buildActions(),
      ),
      // (body 부분은 기존과 동일)
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _posts == null || _posts!.isEmpty
              ? const Center(child: Text('게시글이 없습니다.'))
              : ListView.builder(
                itemCount: _posts!.length,
                itemBuilder: (context, index) {
                  final post = _posts![index];
                  final postObj = Post.fromJson(post);

                  Color getBadgeColor(String type) {
                    return type == 'sale' ? Colors.green : Colors.blue;
                  }

                  String getBadgeText(String type) {
                    return type == 'sale' ? '판매' : '구인';
                  }

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PostDetailScreen(post: postObj),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundImage:
                                postObj.author.profileImageUrl != null
                                    ? NetworkImage(
                                      postObj.author.profileImageUrl!,
                                    )
                                    : null,
                            child:
                                postObj.author.profileImageUrl == null
                                    ? const Icon(
                                      Icons.person,
                                      size: 28,
                                      color: Colors.grey,
                                    )
                                    : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  postObj.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        postObj.author.username,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 10.0),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: getBadgeColor(postObj.type),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        getBadgeText(postObj.type),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () async {
                                  final updated = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => EditPostScreen(
                                            postId: postObj.id,
                                            initialData: post,
                                          ),
                                    ),
                                  );
                                  if (updated == true) _loadPosts();
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder:
                                        (_) => AlertDialog(
                                          title: const Text('삭제 확인'),
                                          content: const Text('정말 삭제하시겠습니까?'),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    false,
                                                  ),
                                              child: const Text('취소'),
                                            ),
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    true,
                                                  ),
                                              child: const Text('삭제'),
                                            ),
                                          ],
                                        ),
                                  );
                                  if (confirmed == true) {
                                    final success = await _timePostService
                                        .deletePost(postObj.id);
                                    if (success) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(content: Text('삭제 완료')),
                                      );
                                      _loadPosts();
                                    } else {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(content: Text('삭제 실패')),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
