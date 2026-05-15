import 'package:flutter/material.dart';
import 'rating_page.dart';
import 'task.dart';

class LeaderRatingPage extends StatefulWidget {
  final String groupName;
  final String leaderName; // first member = leader
  final List<String> members;
  final List<String> tasks;
  final DateTime? deadline;

  const LeaderRatingPage({
    super.key,
    required this.groupName,
    required this.leaderName,
    required this.members,
    required this.tasks,
    required this.deadline,
  });

  @override
  State<LeaderRatingPage> createState() => _LeaderRatingPageState();
}

class _LeaderRatingPageState extends State<LeaderRatingPage> {
  // difficulty ratings per task (1–5, 0 = not yet rated)
  late List<int> _difficulties;

  @override
  void initState() {
    super.initState();
    _difficulties = List.filled(widget.tasks.length, 0);
  }

  int get _ratedCount => _difficulties.where((d) => d > 0).length;
  bool get _allRated => _difficulties.every((d) => d > 0);

  void _setDifficulty(int taskIndex, int value) {
    setState(() => _difficulties[taskIndex] = value);
  }

  void _proceed() {
    if (!_allRated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: kPrimary,
          content: Text(
            'Please rate the difficulty of all tasks first! 📋',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RatingPage(
          groupName: widget.groupName,
          members: widget.members,
          tasks: widget.tasks,
          deadline: widget.deadline,
          taskDifficulties: _difficulties,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildNavBar(),
            buildStepper(activeStep: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ──────────────────────────────────────
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: kAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: kAccent),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('👑', style: TextStyle(fontSize: 13)),
                              SizedBox(width: 6),
                              Text(
                                'LEADER STEP',
                                style: TextStyle(
                                  color: Color(0xFFB5750A),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Rate Task Difficulty 📋',
                      style: TextStyle(
                        color: kTextDark,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Hi ${widget.leaderName}! As the leader, rate how difficult each task is (1–5). Members will self-rate their skills after.',
                      style: const TextStyle(
                        color: kTextMid,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Leader info chip ─────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: kAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: kAccent.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: kAccent.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                widget.leaderName[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFFB5750A),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.leaderName,
                                style: const TextStyle(
                                  color: Color(0xFFB5750A),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Text(
                                'Group Leader',
                                style: TextStyle(
                                  color: Color(0xFFB5750A),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            '$_ratedCount / ${widget.tasks.length} rated',
                            style: const TextStyle(
                              color: Color(0xFFB5750A),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Task difficulty cards ────────────────────────
                    _buildDifficultyCard(),
                    const SizedBox(height: 16),
                    _buildDifficultyGuide(),
                    const SizedBox(height: 16),
                    _buildNextStepInfo(),
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

  Widget _buildDifficultyCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('📋', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text(
                'TASK DIFFICULTY',
                style: TextStyle(
                  color: kPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: kBorder),
          const SizedBox(height: 16),
          ...widget.tasks.asMap().entries.map((e) {
            final taskIndex = e.key;
            final taskName = e.value;
            final selected = _difficulties[taskIndex];

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: kBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected > 0
                      ? kPrimary.withValues(alpha: 0.4)
                      : kBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _numBadge(taskIndex + 1),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          taskName,
                          style: const TextStyle(
                            color: kTextDark,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (selected > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _difficultyColor(
                              selected,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _difficultyLabel(selected),
                            style: TextStyle(
                              color: _difficultyColor(selected),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(5, (i) {
                      final val = i + 1;
                      final isChosen = selected == val;
                      final color = _difficultyColor(val);
                      return GestureDetector(
                        onTap: () => _setDifficulty(taskIndex, val),
                        child: Column(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isChosen ? color : kCard,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isChosen ? color : kBorder,
                                  width: 1.5,
                                ),
                                boxShadow: isChosen
                                    ? [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Center(
                                child: Text(
                                  '$val',
                                  style: TextStyle(
                                    color: isChosen ? Colors.white : kTextMid,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _difficultyShort(val),
                              style: TextStyle(
                                color: isChosen ? color : kTextLight,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
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

  Widget _buildDifficultyGuide() {
    final guide = [
      (
        1,
        _difficultyColor(1),
        'Very Easy',
        'Anyone can do it with minimal effort',
      ),
      (2, _difficultyColor(2), 'Easy', 'Requires basic knowledge or skill'),
      (3, _difficultyColor(3), 'Moderate', 'Needs some experience or focus'),
      (4, _difficultyColor(4), 'Hard', 'Requires strong skills or expertise'),
      (
        5,
        _difficultyColor(5),
        'Very Hard',
        'Complex task needing deep expertise',
      ),
    ];

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
            'DIFFICULTY GUIDE',
            style: TextStyle(
              color: kTextLight,
              fontSize: 10,
              fontWeight: FontWeight.w800,
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
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: g.$2.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: g.$2.withValues(alpha: 0.4)),
                    ),
                    child: Center(
                      child: Text(
                        '${g.$1}',
                        style: TextStyle(
                          color: g.$2,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        g.$3,
                        style: TextStyle(
                          color: g.$2,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        g.$4,
                        style: const TextStyle(color: kTextLight, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextStepInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSecondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kSecondary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Text('⭐', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Next: Member Self-Rating',
                  style: TextStyle(
                    color: Color(0xFF1A7DA0),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'After this, all ${widget.members.length} members (including you) will rate their own skill per task.',
                  style: const TextStyle(
                    color: kTextMid,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
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
            onTap: _proceed,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: _allRated ? kPrimary : kPrimary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
                boxShadow: _allRated
                    ? [
                        BoxShadow(
                          color: kPrimary.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Done — Start Member Rating',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Text(
              'Go Back',
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

  Widget _numBadge(int n) => Container(
    width: 26,
    height: 26,
    decoration: BoxDecoration(
      color: kPrimary.withValues(alpha: 0.1),
      shape: BoxShape.circle,
      border: Border.all(color: kPrimary.withValues(alpha: 0.3)),
    ),
    child: Center(
      child: Text(
        '$n',
        style: const TextStyle(
          color: kPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );

  Color _difficultyColor(int val) {
    const colors = [
      Color(0xFF2D9E7E), // 1 - Very Easy
      Color(0xFF7EC8E3), // 2 - Easy
      Color(0xFFFFD166), // 3 - Moderate
      Color(0xFFFF8C69), // 4 - Hard
      Color(0xFFB5A4E8), // 5 - Very Hard
    ];
    return colors[(val - 1).clamp(0, 4)];
  }

  String _difficultyLabel(int val) {
    const labels = ['Very Easy', 'Easy', 'Moderate', 'Hard', 'Very Hard'];
    return labels[(val - 1).clamp(0, 4)];
  }

  String _difficultyShort(int val) {
    const labels = ['V.Easy', 'Easy', 'Med', 'Hard', 'V.Hard'];
    return labels[(val - 1).clamp(0, 4)];
  }
}
