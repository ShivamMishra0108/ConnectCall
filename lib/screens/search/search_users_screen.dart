import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../calling/audio_call_screen.dart';
import '../calling/video_call_screen.dart';
import '../profile/user_profile_screen.dart';

class SearchUsersScreen extends StatefulWidget {
  const SearchUsersScreen({super.key});

  @override
  State<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  final List<SearchUser> _users = const [
    SearchUser(
      name: 'Sarah Johnson',
      email: 'sarah@example.com',
      initials: 'SJ',
      online: true,
    ),
    SearchUser(
      name: 'Michael Chen',
      email: 'michael@example.com',
      initials: 'MC',
      online: true,
    ),
    SearchUser(
      name: 'Emily Davis',
      email: 'emily@example.com',
      initials: 'ED',
      online: false,
    ),
    SearchUser(
      name: 'David Wilson',
      email: 'david@example.com',
      initials: 'DW',
      online: false,
    ),
    SearchUser(
      name: 'Olivia Brown',
      email: 'olivia@example.com',
      initials: 'OB',
      online: true,
    ),
  ];

  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SearchUser> get _results {
    if (_query.trim().isEmpty) {
      return _users;
    }

    return _users.where((user) {
      final query = _query.toLowerCase().trim();

      return user.name.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query);
    }).toList();
  }

  void _openProfile(SearchUser user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const UserProfileScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.text,
          ),
        ),
        title: const Text(
          'Search Users',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.border,
                ),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (value) {
                  setState(() {
                    _query = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search by name or email',
                  hintStyle: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.secondaryText,
                  ),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _query = '';
                            });
                          },
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.secondaryText,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: results.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_search_rounded,
                          size: 55,
                          color: AppColors.secondaryText,
                        ),
                        SizedBox(height: 14),
                        Text(
                          'No users found',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Try another name or email.',
                          style: TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                    ),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final user = results[index];

                      return _SearchUserTile(
                        user: user,
                        onProfile: () => _openProfile(user),
                        onAudio: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AudioCallScreen(
                                userName: user.name,
                              ),
                            ),
                          );
                        },
                        onVideo: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VideoCallScreen(
                                userName: user.name,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class SearchUser {
  final String name;
  final String email;
  final String initials;
  final bool online;

  const SearchUser({
    required this.name,
    required this.email,
    required this.initials,
    required this.online,
  });
}

class _SearchUserTile extends StatelessWidget {
  final SearchUser user;
  final VoidCallback onProfile;
  final VoidCallback onAudio;
  final VoidCallback onVideo;

  const _SearchUserTile({
    required this.user,
    required this.onProfile,
    required this.onAudio,
    required this.onVideo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onProfile,
            child: Stack(
              children: [
                Container(
                  height: 52,
                  width: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      user.initials,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (user.online)
                  Positioned(
                    right: 0,
                    bottom: 1,
                    child: Container(
                      height: 14,
                      width: 14,
                      decoration: BoxDecoration(
                        color: AppColors.online,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: onProfile,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: onAudio,
            icon: const Icon(
              Icons.call_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          IconButton(
            onPressed: onVideo,
            icon: const Icon(
              Icons.videocam_rounded,
              color: AppColors.primary,
              size: 21,
            ),
          ),
        ],
      ),
    );
  }
}