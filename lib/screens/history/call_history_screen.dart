import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class CallHistoryScreen extends StatelessWidget {
  const CallHistoryScreen({super.key});

  static const List<CallHistoryItem> _calls = [
    CallHistoryItem(
      name: 'Sarah Johnson',
      initials: 'SJ',
      type: CallType.video,
      direction: CallDirection.outgoing,
      status: CallStatus.completed,
      time: 'Today, 10:42 AM',
      duration: '12:35',
    ),
    CallHistoryItem(
      name: 'Michael Chen',
      initials: 'MC',
      type: CallType.audio,
      direction: CallDirection.incoming,
      status: CallStatus.completed,
      time: 'Yesterday, 6:20 PM',
      duration: '08:12',
    ),
    CallHistoryItem(
      name: 'Emily Davis',
      initials: 'ED',
      type: CallType.video,
      direction: CallDirection.incoming,
      status: CallStatus.missed,
      time: 'Yesterday, 2:15 PM',
      duration: '—',
    ),
    CallHistoryItem(
      name: 'David Wilson',
      initials: 'DW',
      type: CallType.audio,
      direction: CallDirection.outgoing,
      status: CallStatus.completed,
      time: 'Sep 7, 4:32 PM',
      duration: '05:48',
    ),
    CallHistoryItem(
      name: 'Olivia Brown',
      initials: 'OB',
      type: CallType.video,
      direction: CallDirection.outgoing,
      status: CallStatus.declined,
      time: 'Sep 6, 11:08 AM',
      duration: '—',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Call History',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Call history filter opened'),
                ),
              );
            },
            icon: const Icon(
              Icons.tune_rounded,
              color: AppColors.text,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 25),
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 22),

          const Text(
            'Recent Calls',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 12),

          ..._calls.map(
            (call) => _CallHistoryTile(call: call),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _SummaryItem(
            value: '24',
            label: 'Total Calls',
          ),
          _SummaryDivider(),
          _SummaryItem(
            value: '18',
            label: 'Completed',
          ),
          _SummaryDivider(),
          _SummaryItem(
            value: '6',
            label: 'Missed',
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String value;
  final String label;

  const _SummaryItem({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 35,
      width: 1,
      color: Colors.white24,
    );
  }
}

class _CallHistoryTile extends StatelessWidget {
  final CallHistoryItem call;

  const _CallHistoryTile({
    required this.call,
  });

  Color get _statusColor {
    switch (call.status) {
      case CallStatus.completed:
        return AppColors.online;
      case CallStatus.missed:
        return AppColors.danger;
      case CallStatus.declined:
        return AppColors.warning;
    }
  }

  IconData get _statusIcon {
    if (call.status == CallStatus.missed) {
      return Icons.call_received_rounded;
    }

    if (call.status == CallStatus.declined) {
      return Icons.call_end_rounded;
    }

    return call.direction == CallDirection.incoming
        ? Icons.call_received_rounded
        : Icons.call_made_rounded;
  }

  String get _statusText {
    switch (call.status) {
      case CallStatus.completed:
        return call.direction == CallDirection.incoming
            ? 'Incoming'
            : 'Outgoing';
      case CallStatus.missed:
        return 'Missed';
      case CallStatus.declined:
        return 'Declined';
    }
  }

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
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                call.initials,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  call.name,
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
                      _statusIcon,
                      size: 13,
                      color: _statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _statusText,
                      style: TextStyle(
                        color: _statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Container(
                      height: 3,
                      width: 3,
                      decoration: const BoxDecoration(
                        color: AppColors.secondaryText,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Icon(
                      call.type == CallType.video
                          ? Icons.videocam_rounded
                          : Icons.call_rounded,
                      size: 13,
                      color: AppColors.secondaryText,
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                Text(
                  '${call.time}  •  ${call.duration}',
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: () {},
            icon: Icon(
              call.type == CallType.video
                  ? Icons.videocam_outlined
                  : Icons.call_outlined,
              color: AppColors.primary,
              size: 21,
            ),
          ),
        ],
      ),
    );
  }
}

enum CallType {
  audio,
  video,
}

enum CallDirection {
  incoming,
  outgoing,
}

enum CallStatus {
  completed,
  missed,
  declined,
}

class CallHistoryItem {
  final String name;
  final String initials;
  final CallType type;
  final CallDirection direction;
  final CallStatus status;
  final String time;
  final String duration;

  const CallHistoryItem({
    required this.name,
    required this.initials,
    required this.type,
    required this.direction,
    required this.status,
    required this.time,
    required this.duration,
  });
}