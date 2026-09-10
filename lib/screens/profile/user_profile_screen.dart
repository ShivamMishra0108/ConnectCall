import 'package:connect_call/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../calling/audio_call_screen.dart';
import '../calling/video_call_screen.dart';

class UserProfileScreen extends ConsumerWidget {
  final String userName;

  const UserProfileScreen({
    super.key,
    this.userName = '',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider).currentUser;

    final name = currentUser?.name ?? userName;
    final initials = currentUser?.initials ?? 'U';
    final email = currentUser?.email ?? '';
    final phone = currentUser?.phoneNumber ?? '';
    final isOnline = currentUser?.online ?? false;

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
          'Profile',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 15),

            // Avatar
            Stack(
              children: [
                Container(
                  height: 112,
                  width: 112,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (isOnline)
                  Positioned(
                    right: 7,
                    bottom: 8,
                    child: Container(
                      height: 23,
                      width: 23,
                      decoration: BoxDecoration(
                        color: AppColors.online,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.background,
                          width: 4,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 18),

            Text(
              name,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 23,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              isOnline ? 'Online' : 'Offline',
              style: TextStyle(
                color: isOnline
                    ? AppColors.online
                    : AppColors.secondaryText,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 28),

            // Call buttons
            Row(
              children: [
                Expanded(
                  child: _ProfileCallButton(
                    icon: Icons.call_rounded,
                    title: 'Audio',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AudioCallScreen(
                            userName: name,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ProfileCallButton(
                    icon: Icons.videocam_rounded,
                    title: 'Video',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VideoCallScreen(
                            userName: name,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Email
            _ProfileInfoCard(
              icon: Icons.email_outlined,
              title: 'Email',
              value: email.isEmpty ? 'Not available' : email,
            ),

            const SizedBox(height: 10),

            // Mobile
            _ProfileInfoCard(
              icon: Icons.phone_outlined,
              title: 'Mobile',
              value: phone.isEmpty ? 'Not available' : '+91 $phone',
            ),

            const SizedBox(height: 10),

            // Status
            _ProfileInfoCard(
              icon: Icons.person_outline_rounded,
              title: 'Status',
              value: isOnline
                  ? 'Available for calls'
                  : 'Offline',
            ),

            const SizedBox(height: 10),

            // About
            _ProfileInfoCard(
              icon: Icons.info_outline_rounded,
              title: 'About',
              value: 'Available on ConnectCall',
            ),

            const SizedBox(height: 25),

            // Logout
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await ref
                      .read(authProvider.notifier)
                      .logout();

                  if (!context.mounted) return;

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                    (_) => false,
                  );
                },
                icon: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.danger,
                ),
                label: const Text(
                  'Logout',
                  style: TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: AppColors.danger,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _ProfileCallButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ProfileCallButton({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(
          icon,
          size: 19,
        ),
        label: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _ProfileInfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}