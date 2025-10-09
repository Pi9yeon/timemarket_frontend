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

  List<Post> _posts = [];
  bool _loading = true;

  String? _currentPostType;
  List<bool> _isSelected = [true, false, false];

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

    final postsData = await _timePostService.fetchNearbyPosts(
      lat: _lat,
      lng: _lng,
      type: _currentPostType,
    );

    if (postsData != null) {
      final parsedPosts = postsData
              .map<Post>((postJson) => Post.fromJson(postJson))
              .toList();

      parsedPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        _posts = parsedPosts;
      });
    }

    setState(() {
      _loading = false;
    });
  }

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
        title: ToggleButtons(
          isSelected: _isSelected,
          onPressed: (int index) {
            setState(() {
              for (int i = 0; i < _isSelected.length; i++) {
                _isSelected[i] = i == index;
              }
              if (index == 0) {
                _currentPostType = null;
              } else if (index == 1) {
                _currentPostType = 'sale';
              } else {
                _currentPostType = 'request';
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
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _posts.isEmpty
              ? const Center(child: Text('게시글이 없습니다.'))
              : ListView.builder(
                itemCount: _posts.length,
                itemBuilder: (context, index) {
                  final postObj = _posts[index];

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

                                // ✅ 1. 가격 표시를 위한 Text 위젯 추가
                                const SizedBox(height: 8),
                                Text(
                                  '${postObj.price} TC', // TC는 Time Credit의 약자
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueAccent,
                                  ),
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
                                  final postJson = {
                                    'id': postObj.id,
                                    'title': postObj.title,
                                    'description': postObj.description,
                                    'latitude': postObj.latitude,
                                    'longitude': postObj.longitude,
                                    'type': postObj.type,
                                    'price': postObj.price,
                                    'created_at':
                                        postObj.createdAt.toIso8601String(),
                                    'user': {
                                      'id': postObj.author.id,
                                      'nickname': postObj.author.username,
                                      'email': postObj.author.email,
                                      'profile_image':
                                          postObj.author.profileImageUrl,
                                    },
                                  };
                                  final updated = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => EditPostScreen(
                                            postId: postObj.id,
                                            initialData: postJson,
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
