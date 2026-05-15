import 'package:flutter/material.dart';
import 'task.dart';
import 'dashboard_page.dart';

class ResultsPage extends StatelessWidget {
  final String groupName;
  final List<String> members;
  final List<String> tasks;
  final List<List<double>> shapleyScores;
  final DateTime? deadline;
  final List<int> taskDifficulties;
  final List<List<int>> assignments; // multi-assignee per task

  const ResultsPage({
    super.key,
    required this.groupName,
    required this.members,
    required this.tasks,
    required this.shapleyScores,
    required this.deadline,
    required this.taskDifficulties,
    required this.assignments,
  });

  // ─── Per-member task count ─────────────────────────────────────────────────
  Map<int, int> get _memberTaskCounts {
    final counts = <int, int>{};
    for (final assignees in assignments) {
      for (final m in assignees) {
        counts[m] = (counts[m] ?? 0) + 1;
      }
    }
    return counts;
  }

  // Primary assignee per task (first in list) — for DashboardPage
  List<int> get _primaryAssignments =>
      assignments.map((a) => a.isNotEmpty ? a.first : 0).toList();

  @override
  Widget build(BuildContext context) {
    final taskCounts = _memberTaskCounts;

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildNavBar(),
            buildStepper(activeStep: 3),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: kMint.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF2D9E7E),
                            size: 14,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Computation complete',
                            style: TextStyle(
                              color: Color(0xFF2D9E7E),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Fair Assignments 🎯',
                      style: TextStyle(
                        color: kTextDark,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tasks distributed using Shapley values. When members outnumber tasks, the weakest task gets a co-assignee.',
                      style: TextStyle(
                        color: kTextMid,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildAssignmentGrid(),
                    const SizedBox(height: 24),
                    _buildMemberSummary(taskCounts),
                    const SizedBox(height: 24),
                    _buildScoreMatrix(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildNavBar() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Text(
            'TaskFair',
            style: TextStyle(
              color: kPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentGrid() {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final cols = constraints.maxWidth > 560 ? 4 : 2;
        final itemWidth = (constraints.maxWidth - (cols - 1) * 12) / cols;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(tasks.length, (taskIdx) {
            final assignees = assignments[taskIdx];
            final difficulty = taskDifficulties[taskIdx];
            final isCollaborative = assignees.length > 1;

            return SizedBox(
              width: itemWidth,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isCollaborative
                        ? kAccent.withValues(alpha: 0.6)
                        : kBorder,
                    width: isCollaborative ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _difficultyColor(
                              difficulty,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _difficultyLabel(difficulty),
                            style: TextStyle(
                              color: _difficultyColor(difficulty),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (isCollaborative) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: kAccent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '👥 Collab',
                              style: TextStyle(
                                color: Color(0xFFB07800),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tasks[taskIdx],
                      style: const TextStyle(
                        color: kTextDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    ...assignees.map((memberIdx) {
                      final color = getAvatarColor(memberIdx);
                      final score = shapleyScores[memberIdx][taskIdx];
                      final isPrimary = assignees.first == memberIdx;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                                border: isPrimary
                                    ? Border.all(color: color, width: 1.5)
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  members[memberIdx][0].toUpperCase(),
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                isPrimary
                                    ? members[memberIdx]
                                    : '${members[memberIdx]} (support)',
                                style: TextStyle(
                                  color: kTextMid,
                                  fontSize: 11,
                                  fontWeight: isPrimary
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              score.toStringAsFixed(2),
                              style: const TextStyle(
                                color: kTextLight,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildMemberSummary(Map<int, int> taskCounts) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MEMBER WORKLOAD',
            style: TextStyle(
              color: kTextLight,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          ...members.asMap().entries.map((e) {
            final mi = e.key;
            final color = getAvatarColor(mi);
            final count = taskCounts[mi] ?? 0;
            final isLeader = mi == 0;

            final myTasks = tasks
                .asMap()
                .entries
                .where((t) => assignments[t.key].contains(mi))
                .map((t) => t.value)
                .toList();

            // Check which tasks are primary vs support
            final primaryTasks = tasks
                .asMap()
                .entries
                .where(
                  (t) =>
                      assignments[t.key].isNotEmpty &&
                      assignments[t.key].first == mi,
                )
                .map((t) => t.value)
                .toList();

            final supportTasks = tasks
                .asMap()
                .entries
                .where(
                  (t) =>
                      assignments[t.key].contains(mi) &&
                      assignments[t.key].first != mi,
                )
                .map((t) => t.value)
                .toList();

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: color, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            e.value[0].toUpperCase(),
                            style: TextStyle(
                              color: color,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isLeader ? '${e.value} 👑' : e.value,
                          style: const TextStyle(
                            color: kTextDark,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count task${count != 1 ? 's' : ''}',
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (myTasks.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    if (primaryTasks.isNotEmpty) ...[
                      const Text(
                        'Primary',
                        style: TextStyle(
                          color: kTextLight,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: primaryTasks
                            .map(
                              (t) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: color.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  t,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    if (supportTasks.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Support',
                        style: TextStyle(
                          color: kTextLight,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: supportTasks
                            .map(
                              (t) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: kCard,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: kBorder),
                                ),
                                child: Text(
                                  t,
                                  style: const TextStyle(
                                    color: kTextMid,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ] else ...[
                    const SizedBox(height: 8),
                    const Text(
                      'No tasks assigned',
                      style: TextStyle(color: kTextLight, fontSize: 11),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildScoreMatrix() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SHAPLEY SCORE MATRIX',
            style: TextStyle(
              color: kTextLight,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Highlighted = assigned. Bold border = primary assignee.',
            style: TextStyle(color: kTextLight, fontSize: 11),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              defaultColumnWidth: const IntrinsicColumnWidth(),
              children: [
                TableRow(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(right: 20, bottom: 10),
                      child: Text(
                        'Member',
                        style: TextStyle(
                          color: kTextLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    ...tasks.asMap().entries.map(
                      (t) => Padding(
                        padding: const EdgeInsets.only(
                          left: 8,
                          right: 8,
                          bottom: 10,
                        ),
                        child: Column(
                          children: [
                            Text(
                              t.value.split(' ').first,
                              style: const TextStyle(
                                color: kTextLight,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _difficultyColor(
                                  taskDifficulties[t.key],
                                ).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'D${taskDifficulties[t.key]}',
                                style: TextStyle(
                                  color: _difficultyColor(
                                    taskDifficulties[t.key],
                                  ),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                ...members.asMap().entries.map((mEntry) {
                  final mi = mEntry.key;
                  final color = getAvatarColor(mi);
                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 20, bottom: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  mEntry.value[0].toUpperCase(),
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              mEntry.value,
                              style: const TextStyle(
                                color: kTextDark,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...tasks.asMap().entries.map((tEntry) {
                        final ti = tEntry.key;
                        final isAssigned = assignments[ti].contains(mi);
                        final isPrimary =
                            assignments[ti].isNotEmpty &&
                            assignments[ti].first == mi;
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isAssigned
                                    ? color.withValues(alpha: 0.15)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: isAssigned
                                    ? Border.all(
                                        color: color.withValues(
                                          alpha: isPrimary ? 0.6 : 0.3,
                                        ),
                                        width: isPrimary ? 1.5 : 1,
                                      )
                                    : null,
                              ),
                              child: Text(
                                shapleyScores[mi][ti].toStringAsFixed(2),
                                style: TextStyle(
                                  color: isAssigned ? color : kTextMid,
                                  fontSize: 12,
                                  fontWeight: isAssigned
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: kBg,
        border: Border(top: BorderSide(color: kBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => DashboardPage(
                    groupName: groupName,
                    members: members,
                    tasks: tasks,
                    assignments: _primaryAssignments,
                    deadline: deadline,
                    taskDifficulties: taskDifficulties,
                  ),
                ),
              );
            },
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
                    'Go to Group Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.space_dashboard_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text(
              'Back to Home',
              style: TextStyle(
                color: kTextMid,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Difficulty helpers ──────────────────────────────────────────────────────
  Color _difficultyColor(int val) {
    const colors = [
      Color(0xFF2D9E7E),
      Color(0xFF7EC8E3),
      Color(0xFFFFD166),
      Color(0xFFFF8C69),
      Color(0xFFB5A4E8),
    ];
    return colors[(val - 1).clamp(0, 4)];
  }

  String _difficultyLabel(int val) {
    const labels = ['Very Easy', 'Easy', 'Moderate', 'Hard', 'Very Hard'];
    return labels[(val - 1).clamp(0, 4)];
  }
}
