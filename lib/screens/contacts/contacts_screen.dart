import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../calling/audio_call_screen.dart';
import '../calling/video_call_screen.dart';
import '../profile/user_profile_screen.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() =>
      _ContactsScreenState();
}

class _ContactsScreenState
    extends ConsumerState<ContactsScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  String _searchQuery = '';
  List<UserModel> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final storage = ref.read(storageServiceProvider);

    final users = await storage.getUsers();
    final currentUser = ref.read(authProvider).currentUser;

    if (!mounted) return;

    setState(() {
      _users = users.where((user) {
        return user.id != currentUser?.id;
      }).toList();

      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UserModel> get _filteredContacts {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return _users;
    }

    return _users.where((user) {
      return user.name.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          user.phoneNumber.contains(query);
    }).toList();
  }

  void _openProfile(UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(
          userName: user.name,
        ),
      ),
    );
  }

  void _openAudioCall(UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AudioCallScreen(
          userName: user.name,
        ),
      ),
    );
  }

  void _openVideoCall(UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoCallScreen(
          userName: user.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contacts = _filteredContacts;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                20,
                20,
                0,
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Contacts',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 27,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: AppColors.border,
                      ),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {},
                      icon: const Icon(
                        Icons.person_add_alt_1_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Search
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ),
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
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search contacts...',
                    hintStyle: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.secondaryText,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();

                              setState(() {
                                _searchQuery = '';
                              });
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              color:
                                  AppColors.secondaryText,
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(
                      vertical: 15,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 22),

            // Contact count
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: Row(
                children: [
                  Text(
                    '${contacts.length} contacts',
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Contacts
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : contacts.isEmpty
                      ? _EmptyContacts(
                          searchQuery: _searchQuery,
                        )
                      : ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(
                            20,
                            4,
                            20,
                            20,
                          ),
                          itemCount: contacts.length,
                          itemBuilder: (context, index) {
                            final user = contacts[index];

                            return _ContactTile(
                              user: user,
                              onProfileTap: () =>
                                  _openProfile(user),
                              onAudioTap: () =>
                                  _openAudioCall(user),
                              onVideoTap: () =>
                                  _openVideoCall(user),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback onProfileTap;
  final VoidCallback onAudioTap;
  final VoidCallback onVideoTap;

  const _ContactTile({
    required this.user,
    required this.onProfileTap,
    required this.onAudioTap,
    required this.onVideoTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = user.online
        ? 'Online'
        : 'Offline';

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
          // Avatar
          GestureDetector(
            onTap: onProfileTap,
            child: Stack(
              children: [
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color:
                        AppColors.primary.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      user.initials,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (user.online)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: 14,
                      width: 14,
                      decoration: BoxDecoration(
                        color: AppColors.online,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.surface,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Name + status
          Expanded(
            child: GestureDetector(
              onTap: onProfileTap,
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    status,
                    style: TextStyle(
                      color: user.online
                          ? AppColors.online
                          : AppColors.secondaryText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Audio
          _CallIconButton(
            icon: Icons.call_rounded,
            onTap: onAudioTap,
          ),

          const SizedBox(width: 5),

          // Video
          _CallIconButton(
            icon: Icons.videocam_rounded,
            onTap: onVideoTap,
          ),
        ],
      ),
    );
  }
}

class _CallIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CallIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary.withOpacity(0.10),
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: SizedBox(
          height: 38,
          width: 38,
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _EmptyContacts extends StatelessWidget {
  final String searchQuery;

  const _EmptyContacts({
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              height: 70,
              width: 70,
              decoration: BoxDecoration(
                color:
                    AppColors.primary.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_search_rounded,
                size: 32,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No contacts found',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              searchQuery.isEmpty
                  ? 'Create another account to see contacts here.'
                  : 'Try searching for a different name.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

