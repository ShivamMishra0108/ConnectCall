import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/user_model.dart';

class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({
    super.key,
    this.size = 55,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        Icons.call_rounded,
        color: Colors.white,
        size: size * .48,
      ),
    );
  }
}

class ProfileAvatar extends StatelessWidget {
  final UserModel user;
  final double radius;
  final bool showOnline;

  const ProfileAvatar({
    super.key,
    required this.user,
    this.radius = 25,
    this.showOnline = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor:
              AppColors.primary.withOpacity(.12),
          child: Text(
            user.initials,
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: radius * .6,
            ),
          ),
        ),

        if (showOnline && user.online)
          Positioned(
            right: 0,
            bottom: 1,
            child: Container(
              width: radius * .5,
              height: radius * .5,
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
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: icon == null
            ? const SizedBox.shrink()
            : Icon(icon),

        label: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),

        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class CallActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const CallActionButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(.1),
      shape: const CircleBorder(),

      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,

        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            color: color,
            size: 21,
          ),
        ),
      ),
    );
  }
}

class UserTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onAudio;
  final VoidCallback? onVideo;
  final VoidCallback? onTap;

  const UserTile({
    super.key,
    required this.user,
    this.onAudio,
    this.onVideo,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,

      contentPadding:
          const EdgeInsets.symmetric(vertical: 5),

      leading: ProfileAvatar(user: user),

      title: Text(
        user.name,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
        ),
      ),

      subtitle: Text(
        user.online ? 'Online' : 'Offline',
        style: TextStyle(
          color: user.online
              ? AppColors.online
              : AppColors.secondaryText,
          fontSize: 13,
        ),
      ),

      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onAudio != null)
            CallActionButton(
              icon: Icons.call_rounded,
              onTap: onAudio!,
            ),

          const SizedBox(width: 8),

          if (onVideo != null)
            CallActionButton(
              icon: Icons.videocam_rounded,
              onTap: onVideo!,
            ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionTitle({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,

      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),

        if (action != null)
          TextButton(
            onPressed: onAction,
            child: Text(action!),
          ),
      ],
    );
  }
}