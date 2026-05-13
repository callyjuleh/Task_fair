import 'package:flutter/material.dart';
import 'computing_page.dart';

// ─── Green Theme Colors (shared) ─────────────────────────────────────────────
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

// ─── Rating Page ──────────────────────────────────────────────────────────────
class RatingPage extends StatefulWidget {
  final String groupName;
  final List<String> members;
  final List<String> tasks;

  const RatingPage({
    super.key,
    required this.groupName,
    required this.members,
    required this.tasks,
  });

  @override
  State<RatingPage> createState() => _RatingPageState();
}

class _RatingPageState extends State<RatingPage> {
  int _currentMemberIndex = 0;

  // ratings[memberIndex][taskIndex] = 1..5 (0 = not rated)
  late List<List<int>> _ratings;

  @override
  void initState() {
    super.initState();
    _ratings = List.generate(
      widget.members.length,
      (_) => List.filled(widget.tasks.length, 0),
    );
  }

  int get _ratedCount =>
      _ratings[_currentMemberIndex].where((r) => r > 0).length;

  bool get _allRated => _ratings[_currentMemberIndex].every((r) => r > 0);

  bool get _allMembersSubmitted =>
      _ratings.every((memberRatings) => memberRatings.every((r) => r > 0));

  void _setRating(int taskIndex, int value) {
    setState(() => _ratings[_currentMemberIndex][taskIndex] = value);
  }

  void _submitAndNext() {
    if (!_allRated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _kCard,
          content: Text(
            'Please rate all ${widget.tasks.length} tasks before submitting.',
            style: const TextStyle(color: _kTextPrimary),
          ),
        ),
      );
      return;
    }

    if (_currentMemberIndex < widget.members.length - 1) {
      setState(() => _currentMemberIndex++);
    } else {
      // All members done — go to computing
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ComputingPage(
            groupName: widget.groupName,
            members: widget.members,
            tasks: widget.tasks,
            ratings: _ratings,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final member = widget.members[_currentMemberIndex];
    final isLast = _currentMemberIndex == widget.members.length - 1;

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
                    const Text(
                      'Skill Rating',
                      style: TextStyle(
                        color: _kTextPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Each member rates their skill level (1–5) for every task independently.',
                      style: TextStyle(
                        color: _kTextMuted,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Member tabs
                    _buildMemberTabs(),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (ctx, constraints) {
                        final wide = constraints.maxWidth > 560;
                        if (wide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: _buildRatingCard(member),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  children: [
                                    _buildProgressCard(),
                                    const SizedBox(height: 14),
                                    _buildGuideCard(),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }
                        return Column(
                          children: [
                            _buildRatingCard(member),
                            const SizedBox(height: 14),
                            _buildProgressCard(),
                            const SizedBox(height: 14),
                            _buildGuideCard(),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context, isLast),
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
          final isActive = i == 1;
          final isDone = i == 0;
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

  Widget _buildMemberTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: widget.members.asMap().entries.map((e) {
          final isSelected = e.key == _currentMemberIndex;
          final color = _avatarColor(e.key);
          return GestureDetector(
            onTap: () => setState(() => _currentMemberIndex = e.key),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? color : _kSurface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected ? color : _kBorder,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withOpacity(0.25)
                          : color,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        e.value[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    e.value,
                    style: TextStyle(
                      color: isSelected ? Colors.white : _kTextPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRatingCard(String member) {
    final memberColor = _avatarColor(_currentMemberIndex);
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
          // Header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: memberColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    member[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      children: [
                        const TextSpan(
                          text: 'Rating as ',
                          style: TextStyle(color: _kTextMuted),
                        ),
                        TextSpan(
                          text: member,
                          style: TextStyle(color: memberColor),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$_ratedCount of ${widget.tasks.length} tasks rated',
                    style: TextStyle(
                      color: _kTextMuted.withOpacity(0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(height: 0.5, color: _kBorder),
          const SizedBox(height: 16),
          // Task rows
          ...widget.tasks.asMap().entries.map((e) {
            final taskIndex = e.key;
            final taskName = e.value;
            final selected = _ratings[_currentMemberIndex][taskIndex];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected > 0 ? _kGreen.withOpacity(0.4) : _kBorder,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          taskName,
                          style: const TextStyle(
                            color: _kTextPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          selected > 0 ? _ratingLabel(selected) : 'Not rated',
                          style: TextStyle(
                            color: selected > 0
                                ? _kGreen
                                : _kTextMuted.withOpacity(0.5),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Row(
                    children: List.generate(5, (i) {
                      final val = i + 1;
                      final isChosen = selected == val;
                      return GestureDetector(
                        onTap: () => _setRating(taskIndex, val),
                        child: Container(
                          margin: const EdgeInsets.only(left: 6),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isChosen ? _kGreen : _kCard,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isChosen ? _kGreen : _kBorder,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '$val',
                              style: TextStyle(
                                color: isChosen ? Colors.white : _kTextMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
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
          Text(
            'SUBMISSION PROGRESS',
            style: TextStyle(
              color: _kTextMuted.withOpacity(0.7),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          ...widget.members.asMap().entries.map((e) {
            final memberIndex = e.key;
            final memberName = e.value;
            final rated = _ratings[memberIndex].where((r) => r > 0).length;
            final total = widget.tasks.length;
            final isDone = rated == total;
            final isActive = memberIndex == _currentMemberIndex;
            final color = _avatarColor(memberIndex);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        memberName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      memberName,
                      style: const TextStyle(
                        color: _kTextPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _kGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _kGreen.withOpacity(0.3)),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          color: _kGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else if (isDone)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: _kGreen,
                      size: 18,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    '$rated/$total',
                    style: const TextStyle(
                      color: _kTextMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Container(height: 0.5, color: _kBorder),
          const SizedBox(height: 10),
          Text(
            _allMembersSubmitted
                ? 'All members have submitted!'
                : 'Computation starts after all ${widget.members.length} members submit.',
            style: TextStyle(
              color: _allMembersSubmitted
                  ? _kGreen
                  : _kTextMuted.withOpacity(0.6),
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideCard() {
    const guide = [
      (1, Color(0xFF22C55E), 'Beginner'),
      (2, Color(0xFF84CC16), 'Elementary'),
      (3, Color(0xFFF59E0B), 'Intermediate'),
      (4, Color(0xFF3B82F6), 'Advanced'),
      (5, Color(0xFF8B5CF6), 'Expert'),
    ];
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
          Text(
            'RATING GUIDE',
            style: TextStyle(
              color: _kTextMuted.withOpacity(0.7),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          ...guide.map(
            (g) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: g.$2.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: g.$2.withOpacity(0.3)),
                    ),
                    child: Center(
                      child: Text(
                        '${g.$1}',
                        style: TextStyle(
                          color: g.$2,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    g.$3,
                    style: TextStyle(
                      color: g.$2,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
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

  Widget _buildBottomBar(BuildContext context, bool isLast) {
    final nextLabel = isLast
        ? 'Submit & Compute'
        : 'Submit & Next → ${widget.members[_currentMemberIndex + 1]}';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: _kBg,
        border: const Border(top: BorderSide(color: _kBorder)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
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
                    'Back to Setup',
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
            onTap: _submitAndNext,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _allRated
                      ? [_kGreen, _kGreenDark]
                      : [
                          _kGreen.withOpacity(0.4),
                          _kGreenDark.withOpacity(0.4),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: _allRated
                    ? [
                        BoxShadow(
                          color: _kGreen.withOpacity(0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    nextLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
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

  String _ratingLabel(int rating) {
    const labels = [
      '',
      'Beginner',
      'Elementary',
      'Intermediate',
      'Advanced',
      'Expert',
    ];
    return labels[rating.clamp(0, 5)];
  }
}
