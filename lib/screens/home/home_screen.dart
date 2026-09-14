import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incoming_call_provider.dart';
import '../contacts/contacts_screen.dart';
import '../history/call_history_screen.dart'
    hide CallType, CallDirection, CallStatus;
import '../profile/user_profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  bool _signalingInitialized = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSignaling();
    });
  }

  Future<void> _initializeSignaling() async {
    if (_signalingInitialized) {
      return;
    }

    final currentUser = ref.read(authProvider).currentUser;

    if (currentUser == null) {
      debugPrint('SIGNALING: No logged-in user found.');
      return;
    }

    _signalingInitialized = true;

    try {
      debugPrint(
        'SIGNALING: Starting shared signaling for ${currentUser.id}',
      );

      final incomingCallListener = ref.read(incomingCallProvider);

      await incomingCallListener.start();

      if (!mounted) return;

      debugPrint(
        'SIGNALING: Shared signaling started successfully.',
      );
    } catch (e, stackTrace) {
      debugPrint('SIGNALING INITIALIZATION ERROR: $e');
      debugPrint('$stackTrace');

      _signalingInitialized = false;
    }
  }

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
            icon: Icon(
              Icons.home_outlined,
            ),
            selectedIcon: Icon(
              Icons.home_rounded,
              color: AppColors.primary,
            ),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.people_outline_rounded,
            ),
            selectedIcon: Icon(
              Icons.people_rounded,
              color: AppColors.primary,
            ),
            label: 'Contacts',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.call_outlined,
            ),
            selectedIcon: Icon(
              Icons.call_rounded,
              color: AppColors.primary,
            ),
            label: 'Calls',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.person_outline_rounded,
            ),
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

class _HomeTab extends ConsumerStatefulWidget {
  const _HomeTab();

  @override
  ConsumerState<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<_HomeTab> {
  List<Map<String, dynamic>> _recentCalls = [];

  bool _isLoadingCalls = true;
  bool _hasCallError = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecentCalls();
    });
  }

  Future<void> _loadRecentCalls() async {
    final currentUser = ref.read(authProvider).currentUser;

    if (currentUser == null) {
      return;
    }

    try {
      final response = await ApiService.getCallHistory(
        userId: currentUser.id,
      );

      if (!mounted) return;

      if (response['success'] == true) {
        final calls = response['calls'];

        if (calls is List) {
          setState(() {
            _recentCalls = calls
                .whereType<Map>()
                .map(
                  (call) => Map<String, dynamic>.from(call),
                )
                .take(4)
                .toList();

            _isLoadingCalls = false;
            _hasCallError = false;
          });
        } else {
          setState(() {
            _recentCalls = [];
            _isLoadingCalls = false;
          });
        }
      } else {
        setState(() {
          _recentCalls = [];
          _isLoadingCalls = false;
          _hasCallError = true;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('HOME CALL HISTORY ERROR: $e');
      debugPrint('$stackTrace');

      if (!mounted) return;

      setState(() {
        _recentCalls = [];
        _isLoadingCalls = false;
        _hasCallError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser =
        ref.watch(authProvider).currentUser;

    final userName = currentUser?.name ?? 'User';

    final userInitials =
        currentUser?.initials ?? 'U';

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadRecentCalls,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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

              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.call_rounded,
                      title: 'Audio Call',
                      subtitle: 'Voice only',
                      onTap: () {
                        _showContactSelectionMessage(
                          context,
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
                        _showContactSelectionMessage(
                          context,
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent calls',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedCallsTab(context);
                      });
                    },
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

              _buildRecentCalls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentCalls() {
    if (_isLoadingCalls) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    if (_hasCallError) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.border,
          ),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.secondaryText,
              size: 30,
            ),
            const SizedBox(height: 8),
            const Text(
              'Unable to load recent calls.',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _loadRecentCalls,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_recentCalls.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: 30,
          horizontal: 20,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.border,
          ),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.call_end_rounded,
              color: AppColors.secondaryText,
              size: 32,
            ),
            SizedBox(height: 10),
            Text(
              'No recent calls',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Your recent calls will appear here.',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _recentCalls.map((call) {
        return _RecentCallCard(
          call: call,
        );
      }).toList(),
    );
  }

  void _selectedCallsTab(BuildContext context) {
    // The Calls tab is already available in the
    // bottom navigation. This keeps the current
    // Home screen structure unchanged.
  }

  void _showContactSelectionMessage(
    BuildContext context,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Select a contact to start a call.',
        ),
      ),
    );
  }
}

class _RecentCallCard extends StatelessWidget {
  final Map<String, dynamic> call;

  const _RecentCallCard({
    required this.call,
  });

  @override
  Widget build(BuildContext context) {
    final callerId =
        call['callerId']?.toString() ?? '';

    final receiverId =
        call['receiverId']?.toString() ?? '';

    final callerName =
        call['callerName']?.toString() ?? 'Unknown';

    final receiverName =
        call['receiverName']?.toString() ?? 'Unknown';

    final callType =
        call['callType']?.toString() ?? 'audio';

    final status =
        call['status']?.toString() ?? 'completed';

    final currentUser =
        ProviderScope.containerOf(context)
            .read(authProvider)
            .currentUser;

    final currentUserId =
        currentUser?.id ?? '';

    final isOutgoing =
        callerId == currentUserId;

    final otherUserName =
        isOutgoing ? receiverName : callerName;

    final initials =
        _getInitials(otherUserName);

    final icon = callType == 'video'
        ? Icons.videocam_rounded
        : Icons.call_rounded;

    final statusIcon = isOutgoing
        ? Icons.call_made_rounded
        : Icons.call_received_rounded;

    final statusColor =
        status == 'declined' ||
                status == 'missed' ||
                status == 'failed'
            ? Colors.red
            : AppColors.online;

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
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color:
                  AppColors.primary.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
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
                Text(
                  otherUserName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(
                      statusIcon,
                      size: 13,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getCallStatus(status),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      '•',
                      style: TextStyle(
                        color:
                            AppColors.secondaryText,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      _getCallTime(call['createdAt']),
                      style: const TextStyle(
                        color:
                            AppColors.secondaryText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color:
                  AppColors.primary.withOpacity(0.10),
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  static String _getInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'U';
    }

    if (parts.length == 1) {
      return parts.first
          .substring(
            0,
            parts.first.length >= 2 ? 2 : 1,
          )
          .toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'
        .toUpperCase();
  }

  static String _getCallStatus(String status) {
    switch (status) {
      case 'completed':
        return 'Completed';

      case 'declined':
        return 'Declined';

      case 'missed':
        return 'Missed';

      case 'failed':
        return 'Failed';

      case 'connected':
        return 'Connected';

      case 'ringing':
        return 'Ringing';

      default:
        return 'Call';
    }
  }

  static String _getCallTime(dynamic value) {
    if (value == null) {
      return '';
    }

    try {
      final dateTime =
          DateTime.parse(value.toString()).toLocal();

      final now = DateTime.now();

      final difference =
          now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      }

      if (difference.inHours < 1) {
        return '${difference.inMinutes} min ago';
      }

      if (difference.inHours < 24 &&
          dateTime.day == now.day) {
        return '${difference.inHours} hr ago';
      }

      if (dateTime.day == now.day - 1 &&
          dateTime.month == now.month) {
        return 'Yesterday';
      }

      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (_) {
      return '';
    }
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
