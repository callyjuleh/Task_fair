import 'dart:math';
import 'package:flutter/material.dart';
import 'task.dart'; // Imports shared palette, avatar colors, and formatDate

class DashboardPage extends StatefulWidget {
  final String groupName;
  final List<String> members;
  final List<String> tasks;
  final List<int> assignments;
  final DateTime? deadline;
  final List<int> taskDifficulties;

  const DashboardPage({
    super.key,
    required this.groupName,
    required this.members,
    required this.tasks,
    required this.assignments,
    required this.deadline,
    required this.taskDifficulties,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _viewingAsIndex = 0;
  late Map<int, double> _taskProgress;
  List<String> _activityLog = [];

  @override
  void initState() {
    super.initState();
    _taskProgress = {for (int i = 0; i < widget.tasks.length; i++) i: 0.0};
    _activityLog = [
      'Group "${widget.groupName}" was successfully created and tasks assigned.',
    ];
  }

  double get _overallProgress {
    if (widget.tasks.isEmpty) return 0.0;
    double total = 0.0;
    _taskProgress.forEach((_, progress) => total += progress);
    return total / widget.tasks.length;
  }

  void _showUploadDialog(int taskIndex, String taskName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _UploadSimulationSheet(
        taskName: taskName,
        onUploadComplete: () {
          setState(() {
            double current = _taskProgress[taskIndex]!;
            double bump = (20 + Random().nextInt(31)) / 100.0;
            double newProgress = (current + bump).clamp(0.0, 1.0);

            _taskProgress[taskIndex] = newProgress;

            String memberName = widget.members[_viewingAsIndex];
            _activityLog.insert(
              0,
              '$memberName updated "$taskName" to ${(newProgress * 100).toInt()}% complete.',
            );

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: newProgress == 1.0
                    ? const Color(0xFF2D9E7E)
                    : kPrimary,
                content: Text(
                  newProgress == 1.0
                      ? 'Task Complete! 100% analyzed. 🎉'
                      : 'File analyzed! Task is now ${(newProgress * 100).toInt()}% complete. 📈',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentMember = widget.members[_viewingAsIndex];
    final myTasks = widget.tasks
        .asMap()
        .entries
        .where((e) => widget.assignments[e.key] == _viewingAsIndex)
        .toList();
    final otherTasks = widget.tasks
        .asMap()
        .entries
        .where((e) => widget.assignments[e.key] != _viewingAsIndex)
        .toList();

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildNavBar(),
            _buildViewingAsTabs(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, $currentMember! 👋',
                      style: const TextStyle(
                        color: kTextDark,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Upload your work regularly to keep the progress bar moving.',
                      style: TextStyle(color: kTextMid, fontSize: 13),
                    ),
                    const SizedBox(height: 24),

                    _buildDeadlineAndProgressCard(),
                    const SizedBox(height: 32),

                    const Text(
                      'MY ASSIGNMENTS',
                      style: TextStyle(
                        color: kTextLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (myTasks.isEmpty)
                      const Text(
                        'You have no assigned tasks at the moment.',
                        style: TextStyle(color: kTextMid),
                      )
                    else
                      ...myTasks.map((e) => _buildMyTaskCard(e.key, e.value)),

                    const SizedBox(height: 32),
                    const Text(
                      'TEAM PROGRESS',
                      style: TextStyle(
                        color: kTextLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (otherTasks.isEmpty)
                      const Text(
                        'No other tasks in this group.',
                        style: TextStyle(color: kTextMid),
                      )
                    else
                      ...otherTasks.map(
                        (e) => _buildOtherTaskCard(e.key, e.value),
                      ),

                    const SizedBox(height: 32),
                    const Text(
                      'RECENT ACTIVITY',
                      style: TextStyle(
                        color: kTextLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildActivityLog(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildDeadlineAndProgressCard() {
    int pct = (_overallProgress * 100).toInt();
    int daysLeft = widget.deadline != null
        ? widget.deadline!.difference(DateTime.now()).inDays.clamp(0, 99999)
        : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimary, kPrimary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timer_outlined, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.deadline != null
                      ? 'Due: ${formatDate(widget.deadline!)}'
                      : 'No deadline set',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.deadline != null ? '$daysLeft days left' : '—',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Project Completion',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '$pct%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _overallProgress,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavBar() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          Text(
            'Dashboard',
            style: TextStyle(
              color: kTextDark,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewingAsTabs() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        color: kCard,
        border: Border(bottom: BorderSide(color: kBorder)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            const Text(
              'Viewing as:  ',
              style: TextStyle(
                color: kTextLight,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            ...widget.members.asMap().entries.map((e) {
              final isSelected = e.key == _viewingAsIndex;
              final color = getAvatarColor(e.key);
              return GestureDetector(
                onTap: () => setState(() => _viewingAsIndex = e.key),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? color : kBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? color : kBorder),
                  ),
                  child: Text(
                    e.value,
                    style: TextStyle(
                      color: isSelected ? Colors.white : kTextMid,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMyTaskCard(int taskIndex, String taskName) {
    final progress = _taskProgress[taskIndex]!;
    final pct = (progress * 100).toInt();
    final isComplete = progress == 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isComplete ? const Color(0xFF2D9E7E) : kBorder,
          width: isComplete ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  taskName,
                  style: const TextStyle(
                    color: kTextDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isComplete
                      ? kMint.withValues(alpha: 0.15)
                      : kPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isComplete ? 'Done' : 'In Progress',
                  style: TextStyle(
                    color: isComplete ? const Color(0xFF2D9E7E) : kPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: kBorder,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isComplete ? const Color(0xFF2D9E7E) : kPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$pct%',
                style: TextStyle(
                  color: isComplete ? const Color(0xFF2D9E7E) : kTextDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: isComplete
                ? null
                : () => _showUploadDialog(taskIndex, taskName),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isComplete ? kBg : kSecondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isComplete
                      ? kBorder
                      : kSecondary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isComplete
                        ? Icons.check_circle_rounded
                        : Icons.cloud_upload_rounded,
                    color: isComplete ? kTextLight : const Color(0xFF1A7DA0),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isComplete
                        ? 'Task Fully Completed'
                        : 'Upload Work for Analysis',
                    style: TextStyle(
                      color: isComplete ? kTextLight : const Color(0xFF1A7DA0),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherTaskCard(int taskIndex, String taskName) {
    final memberAssigned = widget.members[widget.assignments[taskIndex]];
    final color = getAvatarColor(widget.assignments[taskIndex]);
    final progress = _taskProgress[taskIndex]!;
    final pct = (progress * 100).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    memberAssigned[0].toUpperCase(),
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
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
                      taskName,
                      style: const TextStyle(
                        color: kTextDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Assigned to $memberAssigned',
                      style: const TextStyle(color: kTextMid, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Text(
                '$pct%',
                style: TextStyle(
                  color: progress == 1.0 ? const Color(0xFF2D9E7E) : kTextDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: kBorder,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress == 1.0 ? const Color(0xFF2D9E7E) : color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityLog() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _activityLog
            .map(
              (log) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.bolt_rounded, color: kAccent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        log,
                        style: const TextStyle(
                          color: kTextDark,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: kCard,
        border: Border(top: BorderSide(color: kBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: kPrimary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: kPrimary.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Return to Home',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadSimulationSheet extends StatefulWidget {
  final String taskName;
  final VoidCallback onUploadComplete;

  const _UploadSimulationSheet({
    required this.taskName,
    required this.onUploadComplete,
  });

  @override
  State<_UploadSimulationSheet> createState() => _UploadSimulationSheetState();
}

class _UploadSimulationSheetState extends State<_UploadSimulationSheet> {
  bool _isAnalyzing = false;

  void _simulateUpload() async {
    setState(() => _isAnalyzing = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      Navigator.pop(context);
      widget.onUploadComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: kBorder,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Upload Work',
              style: TextStyle(
                color: kTextDark,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.taskName,
              style: const TextStyle(
                color: kTextMid,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (_isAnalyzing) ...[
              const CircularProgressIndicator(color: kSecondary),
              const SizedBox(height: 20),
              const Text(
                'Analyzing file and updating progress...',
                style: TextStyle(
                  color: kTextMid,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
            ] else ...[
              GestureDetector(
                onTap: _simulateUpload,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: kBg,
                    border: Border.all(
                      color: kSecondary.withValues(alpha: 0.5),
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.folder_open_rounded,
                        color: kSecondary,
                        size: 48,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Tap to select file',
                        style: TextStyle(
                          color: kTextDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'PDF, DOCX, or Images',
                        style: TextStyle(color: kTextLight, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}