import 'package:flutter/material.dart';

import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CallHistoryScreen extends ConsumerStatefulWidget {
  const CallHistoryScreen({super.key});

  @override
  ConsumerState<CallHistoryScreen> createState() =>
      _CallHistoryScreenState();
}

class _CallHistoryScreenState
    extends ConsumerState<CallHistoryScreen> {
  List<CallHistoryItem> _calls = [];

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCallHistory();
    });
  }

  // ============================================================
  // LOAD CALL HISTORY
  // ============================================================

  Future<void> _loadCallHistory() async {
    final currentUser =
        ref.read(authProvider).currentUser;

    if (currentUser == null) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = 'User not logged in.';
      });

      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result =
          await ApiService.getCallHistory(
        userId: currentUser.id,
      );

      if (!mounted) return;

      if (result['success'] != true) {
        setState(() {
          _isLoading = false;
          _error =
              result['message']?.toString() ??
              'Unable to load call history.';
        });

        return;
      }

      final calls = result['calls'];

      if (calls is! List) {
        setState(() {
          _calls = [];
          _isLoading = false;
        });

        return;
      }

      final List<CallHistoryItem> history = [];

      for (final item in calls) {
        if (item is! Map) {
          continue;
        }

        final call =
            Map<String, dynamic>.from(item);

        final String callerId =
            call['callerId']?.toString() ?? '';

        final String receiverId =
            call['receiverId']?.toString() ?? '';

        final bool isOutgoing =
            callerId == currentUser.id;

        final String name = isOutgoing
            ? call['receiverName']?.toString() ??
                'Unknown'
            : call['callerName']?.toString() ??
                'Unknown';

        final String type =
            call['callType']?.toString() ??
                'audio';

        final String status =
            call['status']?.toString() ??
                'failed';

        final String createdAt =
            call['createdAt']?.toString() ?? '';

        final int duration =
            _toInt(call['duration']);

        history.add(
          CallHistoryItem(
            name: name,
            initials: _getInitials(name),
            type: type == 'video'
                ? CallType.video
                : CallType.audio,
            direction: isOutgoing
                ? CallDirection.outgoing
                : CallDirection.incoming,
            status: _convertStatus(status),
            time: _formatDateTime(createdAt),
            duration: _formatDuration(duration),
          ),
        );
      }

      setState(() {
        _calls = history;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'CALL HISTORY LOAD ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error =
            'Unable to load call history.';
      });
    }
  }

  // ============================================================
  // CONVERT STATUS
  // ============================================================

  CallStatus _convertStatus(
    String status,
  ) {
    switch (status) {
      case 'declined':
        return CallStatus.declined;

      case 'missed':
        return CallStatus.missed;

      case 'completed':
      case 'connected':
        return CallStatus.completed;

      case 'failed':
      case 'ringing':
      default:
        return CallStatus.failed;
    }
  }

  // ============================================================
  // INITIALS
  // ============================================================

  String _getInitials(
    String name,
  ) {
    final trimmed = name.trim();

    if (trimmed.isEmpty) {
      return '?';
    }

    final parts = trimmed
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.length == 1) {
      return parts.first
          .substring(
            0,
            parts.first.length >= 2
                ? 2
                : 1,
          )
          .toUpperCase();
    }

    return (
      parts.first[0] +
      parts.last[0]
    ).toUpperCase();
  }

  // ============================================================
  // INTEGER CONVERSION
  // ============================================================

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  // ============================================================
  // FORMAT DURATION
  // ============================================================

  String _formatDuration(
    int seconds,
  ) {
    if (seconds <= 0) {
      return '—';
    }

    final hours = seconds ~/ 3600;
    final minutes =
        (seconds % 3600) ~/ 60;
    final remainingSeconds =
        seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${remainingSeconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // FORMAT DATE / TIME
  // ============================================================

  String _formatDateTime(
    String value,
  ) {
    final dateTime = DateTime.tryParse(value);

    if (dateTime == null) {
      return 'Unknown time';
    }

    final local = dateTime.toLocal();
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final callDay = DateTime(
      local.year,
      local.month,
      local.day,
    );

    final difference =
        today.difference(callDay).inDays;

    final hour =
        local.hour == 0
            ? 12
            : local.hour > 12
                ? local.hour - 12
                : local.hour;

    final minute =
        local.minute
            .toString()
            .padLeft(2, '0');

    final period =
        local.hour >= 12
            ? 'PM'
            : 'AM';

    final time =
        '$hour:$minute $period';

    if (difference == 0) {
      return 'Today, $time';
    }

    if (difference == 1) {
      return 'Yesterday, $time';
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[local.month - 1]} '
        '${local.day}, $time';
  }

  // ============================================================
  // BUILD
  // ============================================================

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
            onPressed: _loadCallHistory,
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.text,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.history_rounded,
                size: 50,
                color: AppColors.secondaryText,
              ),
              const SizedBox(height: 15),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: _loadCallHistory,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCallHistory,
      child: ListView(
        padding:
            const EdgeInsets.fromLTRB(
          20,
          8,
          20,
          25,
        ),
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

          if (_calls.isEmpty)
            _buildEmptyState()
          else
            ..._calls.map(
              (call) =>
                  _CallHistoryTile(
                call: call,
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummaryCard() {
    final total = _calls.length;

    final completed = _calls
        .where(
          (call) =>
              call.status ==
              CallStatus.completed,
        )
        .length;

    final missed = _calls
        .where(
          (call) =>
              call.status ==
                  CallStatus.missed ||
              call.status ==
                  CallStatus.declined,
        )
        .length;

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
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _SummaryItem(
            value: total.toString(),
            label: 'Total Calls',
          ),
          const _SummaryDivider(),
          _SummaryItem(
            value: completed.toString(),
            label: 'Completed',
          ),
          const _SummaryDivider(),
          _SummaryItem(
            value: missed.toString(),
            label: 'Missed',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 50,
      ),
      child: const Column(
        children: [
          Icon(
            Icons.call_rounded,
            size: 45,
            color: AppColors.secondaryText,
          ),
          SizedBox(height: 15),
          Text(
            'No calls yet',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Your recent calls will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.secondaryText,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SUMMARY ITEM
// ============================================================

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

// ============================================================
// SUMMARY DIVIDER
// ============================================================

class _SummaryDivider
    extends StatelessWidget {
  const _SummaryDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 35,
      width: 1,
      color: Colors.white24,
    );
  }
}

// ============================================================
// CALL HISTORY TILE
// ============================================================

class _CallHistoryTile
    extends StatelessWidget {
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

      case CallStatus.failed:
        return AppColors.danger;
    }
  }

  IconData get _statusIcon {
    if (call.status ==
        CallStatus.missed) {
      return Icons.call_received_rounded;
    }

    if (call.status ==
        CallStatus.declined) {
      return Icons.call_end_rounded;
    }

    if (call.status ==
        CallStatus.failed) {
      return Icons.call_end_rounded;
    }

    return call.direction ==
            CallDirection.incoming
        ? Icons.call_received_rounded
        : Icons.call_made_rounded;
  }

  String get _statusText {
    switch (call.status) {
      case CallStatus.completed:
        return call.direction ==
                CallDirection.incoming
            ? 'Incoming'
            : 'Outgoing';

      case CallStatus.missed:
        return 'Missed';

      case CallStatus.declined:
        return 'Declined';

      case CallStatus.failed:
        return 'Failed';
    }
  }

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
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: AppColors.primary
                  .withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                call.initials,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight:
                      FontWeight.w700,
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
                  call.name,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 5),

                Row(
                  children: [
                    Icon(
                      _statusIcon,
                      size: 13,
                      color:
                          _statusColor,
                    ),

                    const SizedBox(width: 4),

                    Text(
                      _statusText,
                      style: TextStyle(
                        color:
                            _statusColor,
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),

                    const SizedBox(width: 7),

                    Container(
                      height: 3,
                      width: 3,
                      decoration:
                          const BoxDecoration(
                        color: AppColors
                            .secondaryText,
                        shape:
                            BoxShape.circle,
                      ),
                    ),

                    const SizedBox(width: 7),

                    Icon(
                      call.type ==
                              CallType.video
                          ? Icons
                              .videocam_rounded
                          : Icons
                              .call_rounded,
                      size: 13,
                      color: AppColors
                          .secondaryText,
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                Text(
                  '${call.time}  •  ${call.duration}',
                  style:
                      const TextStyle(
                    color: AppColors
                        .secondaryText,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: () {},
            icon: Icon(
              call.type ==
                      CallType.video
                  ? Icons
                      .videocam_outlined
                  : Icons.call_outlined,
              color:
                  AppColors.primary,
              size: 21,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ENUMS
// ============================================================

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
  failed,
}

// ============================================================
// CALL HISTORY ITEM
// ============================================================

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