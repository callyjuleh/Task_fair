import 'package:flutter/material.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
const _kBg = Color(0xFF0A0F0A);
const _kSurface = Color(0xFF111A11);
const _kCard = Color(0xFF162016);
const _kGreen = Color(0xFF22C55E);
const _kGreenDark = Color(0xFF16A34A);
const _kBorder = Color(0xFF1A3A1A);
const _kTextPrimary = Color(0xFFECFDF5);
const _kTextMuted = Color(0xFF6EE7B7);
const _kTextSecondary = Color(0xFF86EFAC);

const _kAvatarColors = [
  Color(0xFF5B4EE8),
  Color(0xFF2563EB),
  Color(0xFFDC2626),
  Color(0xFFD97706),
  Color(0xFF059669),
  Color(0xFF7C3AED),
  Color(0xFFDB2777),
];

Color _avatarColor(int index) => _kAvatarColors[index % _kAvatarColors.length];

// ─── Results Page ─────────────────────────────────────────────────────────────
class ResultsPage extends StatelessWidget {
  final String groupName;
  final List<String> members;
  final List<String> tasks;
  final List<List<double>> shapleyScores; // [member][task]

  const ResultsPage({
    super.key,
    required this.groupName,
    required this.members,
    required this.tasks,
    required this.shapleyScores,
  });

  /// For each task, find the member with the highest Shapley score
  List<int> get _assignments {
    return List.generate(tasks.length, (taskIdx) {
      int bestMember = 0;
      double bestScore = shapleyScores[0][taskIdx];
      for (int m = 1; m < members.length; m++) {
        if (shapleyScores[m][taskIdx] > bestScore) {
          bestScore = shapleyScores[m][taskIdx];
          bestMember = m;
        }
      }
      return bestMember;
    });
  }

  /// tasks assigned to each member
  List<List<int>> get _memberTaskMap {
    final assignments = _assignments;
    final map = List.generate(members.length, (_) => <int>[]);
    for (int t = 0; t < tasks.length; t++) {
      map[assignments[t]].add(t);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final assignments = _assignments;
    final memberTaskMap = _memberTaskMap;

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildNavBar(context),
            _buildStepper(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _kGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _kGreen.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: _kGreen,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Computation complete',
                            style: TextStyle(
                              color: _kGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Task Assignments',
                      style: TextStyle(
                        color: _kTextPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Each task assigned to the member with the highest Shapley score.',
                      style: TextStyle(
                        color: _kTextMuted,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Assignment cards grid
                    _buildAssignmentGrid(assignments),
                    const SizedBox(height: 24),

                    // Shapley Score Matrix
                    _buildScoreMatrix(assignments),
                    const SizedBox(height: 24),

                    // Member workload cards
                    _buildMemberCards(memberTaskMap),
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

  Widget _buildNavBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _kGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kGreen.withOpacity(0.3)),
            ),
            child: const Icon(
              Icons.grid_view_rounded,
              color: _kGreen,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'TaskFair',
            style: TextStyle(
              color: _kTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kBorder),
            ),
            child: const Text(
              'New Group',
              style: TextStyle(
                color: _kTextPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    const steps = [
      ('Setup', 'Group & tasks'),
      ('Rating', 'Skill levels'),
      ('Computing', 'Shapley calc'),
      ('Results', 'Assignments'),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: List.generate(steps.length, (i) {
          final isActive = i == 3;
          final isDone = i < 3;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isActive
                              ? _kGreen
                              : isDone
                              ? _kGreen.withOpacity(0.3)
                              : _kCard,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: (isActive || isDone) ? _kGreen : _kBorder,
                          ),
                        ),
                        child: Center(
                          child: isDone
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: _kGreen,
                                  size: 14,
                                )
                              : Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    color: isActive
                                        ? Colors.white
                                        : _kTextMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        steps[i].$1,
                        style: TextStyle(
                          color: (isActive || isDone)
                              ? _kTextPrimary
                              : _kTextMuted,
                          fontSize: 10,
                          fontWeight: (isActive || isDone)
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      Text(
                        steps[i].$2,
                        style: TextStyle(
                          color: _kTextMuted.withOpacity(0.5),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < steps.length - 1)
                  Container(width: 20, height: 1, color: _kBorder),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAssignmentGrid(List<int> assignments) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final cols = constraints.maxWidth > 560 ? 4 : 2;
        final itemWidth = (constraints.maxWidth - (cols - 1) * 12) / cols;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(tasks.length, (taskIdx) {
            final memberIdx = assignments[taskIdx];
            final score = shapleyScores[memberIdx][taskIdx];
            final color = _avatarColor(memberIdx);
            final taskName = tasks[taskIdx];
            final memberName = members[memberIdx];
            final taskIcon = _taskIcon(taskName);

            return SizedBox(
              width: itemWidth,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _kCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _kBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          taskIcon,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      taskName,
                      style: const TextStyle(
                        color: _kTextMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              memberName[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            memberName,
                            style: const TextStyle(
                              color: _kTextPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Score: ${score.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: _kTextMuted.withOpacity(0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildScoreMatrix(List<int> assignments) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'SHAPLEY SCORE MATRIX',
                style: TextStyle(
                  color: _kTextMuted.withOpacity(0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Text(
                '★ = assigned',
                style: TextStyle(
                  color: _kTextMuted.withOpacity(0.5),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              defaultColumnWidth: const IntrinsicColumnWidth(),
              children: [
                // Header row
                TableRow(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(right: 20, bottom: 10),
                      child: Text(
                        'Member',
                        style: TextStyle(
                          color: _kTextMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ...tasks.map(
                      (task) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 0,
                        ),
                        child: Column(
                          children: [
                            Text(
                              _taskIcon(task),
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              task,
                              style: TextStyle(
                                color: _kTextMuted.withOpacity(0.8),
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 14),
                      child: Text(
                        'Tasks',
                        style: TextStyle(
                          color: _kTextMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                // Member rows
                ...members.asMap().entries.map((memberEntry) {
                  final mi = memberEntry.key;
                  final memberName = memberEntry.value;
                  final color = _avatarColor(mi);
                  final assignedCount = assignments
                      .where((a) => a == mi)
                      .length;

                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 20, bottom: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  memberName[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              memberName,
                              style: const TextStyle(
                                color: _kTextPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...tasks.asMap().entries.map((taskEntry) {
                        final ti = taskEntry.key;
                        final score = shapleyScores[mi][ti];
                        final isAssigned = assignments[ti] == mi;
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 0,
                          ),
                          child: Center(
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isAssigned
                                    ? color.withOpacity(0.2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isAssigned
                                      ? color.withOpacity(0.5)
                                      : Colors.transparent,
                                ),
                              ),
                              child: Text(
                                '${score.toStringAsFixed(2)}${isAssigned ? ' ★' : ''}',
                                style: TextStyle(
                                  color: isAssigned ? color : _kTextSecondary,
                                  fontSize: 12,
                                  fontWeight: isAssigned
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      Padding(
                        padding: const EdgeInsets.only(left: 14, bottom: 10),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$assignedCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
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

  Widget _buildMemberCards(List<List<int>> memberTaskMap) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final wide = constraints.maxWidth > 560;
        final cols = wide ? 3 : 1;
        final cardWidth = (constraints.maxWidth - (cols - 1) * 14) / cols;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: members.asMap().entries.map((e) {
            final mi = e.key;
            final memberName = e.value;
            final color = _avatarColor(mi);
            final assignedTasks = memberTaskMap[mi];
            final workloadPct = tasks.isEmpty
                ? 0.0
                : assignedTasks.length / tasks.length;

            // Average score across assigned tasks
            double avgScore = 0;
            if (assignedTasks.isNotEmpty) {
              avgScore =
                  assignedTasks
                      .map((ti) => shapleyScores[mi][ti])
                      .reduce((a, b) => a + b) /
                  assignedTasks.length;
            }

            return SizedBox(
              width: wide ? cardWidth : double.infinity,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _kCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _kBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              memberName[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                memberName,
                                style: const TextStyle(
                                  color: _kTextPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${assignedTasks.length} task${assignedTasks.length == 1 ? '' : 's'} assigned',
                                style: TextStyle(
                                  color: _kTextMuted.withOpacity(0.6),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Workload bar
                    Row(
                      children: [
                        Text(
                          'Workload',
                          style: TextStyle(
                            color: _kTextMuted.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${(workloadPct * 100).round()}%',
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: workloadPct,
                        backgroundColor: color.withOpacity(0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Assigned tasks list
                    ...assignedTasks.map((ti) {
                      final taskScore = shapleyScores[mi][ti];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: _kSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _kBorder),
                        ),
                        child: Row(
                          children: [
                            Text(
                              _taskIcon(tasks[ti]),
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                tasks[ti],
                                style: const TextStyle(
                                  color: _kTextPrimary,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              taskScore.toStringAsFixed(2),
                              style: TextStyle(
                                color: color,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (assignedTasks.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(height: 0.5, color: _kBorder),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Avg score',
                            style: TextStyle(
                              color: _kTextMuted.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            avgScore.toStringAsFixed(2),
                            style: TextStyle(
                              color: color,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: _kBg,
        border: const Border(top: BorderSide(color: _kBorder)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              // Pop all the way back to the root
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
              decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _kBorder),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chevron_left_rounded,
                    color: _kTextPrimary,
                    size: 18,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'New Group',
                    style: TextStyle(
                      color: _kTextPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_kGreen, _kGreenDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _kGreen.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Done',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _taskIcon(String taskName) {
    final lower = taskName.toLowerCase();
    if (lower.contains('frontend') ||
        lower.contains('ui') ||
        lower.contains('design')) {
      return '🖥️';
    } else if (lower.contains('api') ||
        lower.contains('backend') ||
        lower.contains('server')) {
      return '🔌';
    } else if (lower.contains('test') || lower.contains('qa')) {
      return '🧪';
    } else if (lower.contains('doc') || lower.contains('write')) {
      return '📝';
    } else if (lower.contains('data') || lower.contains('analyt')) {
      return '📊';
    } else if (lower.contains('deploy') || lower.contains('devops')) {
      return '🚀';
    } else if (lower.contains('security') || lower.contains('auth')) {
      return '🔒';
    } else {
      return '📋';
    }
  }
}
