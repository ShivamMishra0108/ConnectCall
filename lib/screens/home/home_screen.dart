import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../contacts/contacts_screen.dart';
import '../history/call_history_screen.dart';
import '../calling/audio_call_screen.dart';
import '../calling/video_call_screen.dart';
import '../profile/user_profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider).currentUser;

    final pages = [
      const _HomeTab(),
      const ContactsScreen(),
      const CallHistoryScreen(),
      UserProfileScreen(
        userName: currentUser?.name ?? 'User',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: AppColors.surface,
        elevation: 0,
        height: 70,
        indicatorColor:
            AppColors.primary.withOpacity(0.12),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(
              Icons.home_rounded,
              color: AppColors.primary,
            ),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(
              Icons.people_rounded,
              color: AppColors.primary,
            ),
            label: 'Contacts',
          ),
          NavigationDestination(
            icon: Icon(Icons.call_outlined),
            selectedIcon: Icon(
              Icons.call_rounded,
              color: AppColors.primary,
            ),
            label: 'Calls',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(
              Icons.person_rounded,
              color: AppColors.primary,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider).currentUser;

    final userName = currentUser?.name ?? 'User';
    final userInitials = currentUser?.initials ?? 'U';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          20,
          20,
          20,
          24,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primary
                        .withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      userInitials,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Good evening 👋',
                        style: TextStyle(
                          color:
                              AppColors.secondaryText,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        userName,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                IconButton(
                  onPressed: () {},
                  style: IconButton.styleFrom(
                    backgroundColor:
                        AppColors.surface,
                  ),
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 26),

            // Search
            Container(
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius:
                    BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.border,
                ),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Search people...',
                  hintStyle: TextStyle(
                    color:
                        AppColors.secondaryText,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color:
                        AppColors.secondaryText,
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(
                    vertical: 15,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'Quick call',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 14),

            // Quick actions
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.call_rounded,
                    title: 'Audio Call',
                    subtitle: 'Voice only',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const AudioCallScreen(
                            userName:
                                'Sarah Johnson',
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.videocam_rounded,
                    title: 'Video Call',
                    subtitle: 'Voice & video',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const VideoCallScreen(
                            userName:
                                'Sarah Johnson',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Recent contacts heading
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent contacts',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'See all',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            const _ContactCard(
              initials: 'SJ',
              name: 'Sarah Johnson',
              status: 'Online',
              isOnline: true,
            ),

            const _ContactCard(
              initials: 'MC',
              name: 'Michael Chen',
              status: 'Online',
              isOnline: true,
            ),

            const _ContactCard(
              initials: 'ED',
              name: 'Emily Davis',
              status: 'Last seen 10 min ago',
              isOnline: false,
            ),

            const _ContactCard(
              initials: 'DW',
              name: 'David Wilson',
              status: 'Last seen 1 hour ago',
              isOnline: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary
                      .withOpacity(0.10),
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final String initials;
  final String name;
  final String status;
  final bool isOnline;

  const _ContactCard({
    required this.initials,
    required this.name,
    required this.status,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:
          const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary
                      .withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (isOnline)
                Positioned(
                  right: 1,
                  bottom: 1,
                  child: Container(
                    height: 13,
                    width: 13,
                    decoration:
                        BoxDecoration(
                      color: AppColors.online,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            AppColors.surface,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: TextStyle(
                    color: isOnline
                        ? AppColors.online
                        : AppColors
                            .secondaryText,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AudioCallScreen(
                    userName: name,
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.call_rounded,
              size: 20,
              color: AppColors.primary,
            ),
          ),

          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      VideoCallScreen(
                    userName: name,
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.videocam_rounded,
              size: 21,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}