import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'rating_page.dart';
import 'task.dart';
import 'login_page.dart'; // for kBaseUrl

class LeaderRatingPage extends StatefulWidget {
  final String groupName;
  final String leaderName;
  final List<String> members;
  final List<String> tasks;
  final DateTime? deadline;
  // ─── NEW: DB identifiers passed from TaskSetupPage ───────────────
  final String projectId;
  final List<String> memberIds;
  final List<String> taskIds;

  const LeaderRatingPage({
    super.key,
    required this.groupName,
    required this.leaderName,
    required this.members,
    required this.tasks,
    required this.deadline,
    required this.projectId,
    required this.memberIds,
    required this.taskIds,
  });

  @override
  State<LeaderRatingPage> createState() => _LeaderRatingPageState();
}

class _LeaderRatingPageState extends State<LeaderRatingPage> {
  late List<int> _difficulties;
  late List<int> _skillRatings; // leader's own skill per task
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _difficulties = List.filled(widget.tasks.length, 0);
    _skillRatings = List.filled(widget.tasks.length, 0);
  }

  int get _ratedCount => _difficulties.where((d) => d > 0).length;
  int get _skillRatedCount => _skillRatings.where((r) => r > 0).length;
  bool get _allRated =>
      _difficulties.every((d) => d > 0) && _skillRatings.every((r) => r > 0);

  void _setDifficulty(int taskIndex, int value) {
    setState(() => _difficulties[taskIndex] = value);
  }

  void _setSkillRating(int taskIndex, int value) {
    setState(() => _skillRatings[taskIndex] = value);
  }

  // ─── UPDATED: saves difficulty + leader skill ratings to DB before proceeding ──
  Future<void> _proceed() async {
    if (!_allRated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: kPrimary,
          content: Text(
            'Please rate task difficulty AND your skill level for all tasks! 📋',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // 1. Save difficulty for each task via PUT /tasks/:id
      for (int i = 0; i < widget.taskIds.length; i++) {
        final res = await http.put(
          Uri.parse('$kBaseUrl/tasks/${widget.taskIds[i]}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'difficulty': _difficulties[i]}),
        );
        if (res.statusCode != 200) {
          _showSnack('Failed to save task difficulty. Try again.');
          return;
        }
      }

      // 2. Save leader's skill ratings to DB via POST /ratings
      final Map<String, int> ratingsMap = {};
      for (int i = 0; i < widget.taskIds.length; i++) {
        ratingsMap[widget.taskIds[i]] = _skillRatings[i];
      }
      final rRes = await http.post(
        Uri.parse('$kBaseUrl/ratings'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'member_id': widget.memberIds[0], // leader is always index 0
          'ratings': ratingsMap,
        }),
      );
      if (rRes.statusCode != 200) {
        _showSnack('Failed to save your skill ratings. Try again.');
        return;
      }
    } catch (e) {
      _showSnack('Cannot reach server. Check your connection.');
      return;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }

    if (!mounted) return;

    // Pre-fill leader's skill ratings so RatingPage starts from member index 1
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RatingPage(
          groupName: widget.groupName,
          members: widget.members,
          tasks: widget.tasks,
          deadline: widget.deadline,
          taskDifficulties: _difficulties,
          leaderSkillRatings: List.from(_skillRatings),
          // ─── Pass IDs through ───────────────────────────────────
          projectId: widget.projectId,
          memberIds: widget.memberIds,
          taskIds: widget.taskIds,
        ),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: kPrimary,
        content: Text(msg, style: const TextStyle(color: Colors.white)),
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Difficulty: $_ratedCount/${widget.tasks.length}',
                                style: const TextStyle(
                                  color: Color(0xFFB5750A),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Skills: $_skillRatedCount/${widget.tasks.length}',
                                style: const TextStyle(
                                  color: Color(0xFFB5750A),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildDifficultyCard(),
                    const SizedBox(height: 16),
                    _buildDifficultyGuide(),
                    const SizedBox(height: 16),
                    _buildSkillRatingCard(),
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TASKS',
            style: TextStyle(
              color: kTextLight,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          ...widget.tasks.asMap().entries.map((e) {
            final i = e.key;
            final task = e.value;
            final selected = _difficulties[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _numBadge(i + 1),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          task,
                          style: const TextStyle(
                            color: kTextDark,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
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
                            _difficultyShort(selected),
                            style: TextStyle(
                              color: _difficultyColor(selected),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: List.generate(5, (star) {
                      final val = star + 1;
                      final isSelected = selected == val;
                      final color = _difficultyColor(val);
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => _setDifficulty(i, val),
                          child: Container(
                            margin: EdgeInsets.only(right: star < 4 ? 6 : 0),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color.withValues(alpha: 0.2)
                                  : kBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? color : kBorder,
                                width: isSelected ? 1.8 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '$val',
                                style: TextStyle(
                                  color: isSelected ? color : kTextLight,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  if (selected > 0) ...[
                    const SizedBox(height: 6),
                    Text(
                      _difficultyLabel(selected),
                      style: TextStyle(
                        color: _difficultyColor(selected),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildSkillRatingCard() {
    const skillColors = [
      Color(0xFF2D9E7E),
      Color(0xFF7EC8E3),
      Color(0xFFFFD166),
      Color(0xFFFF8C69),
      Color(0xFFB5A4E8),
    ];
    const skillLabels = [
      'Beginner',
      'Elementary',
      'Intermediate',
      'Advanced',
      'Expert',
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kAccent.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('👑', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              const Text(
                'YOUR SKILL SELF-RATING',
                style: TextStyle(
                  color: Color(0xFFB5750A),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Text(
                '$_skillRatedCount/${widget.tasks.length} rated',
                style: const TextStyle(
                  color: Color(0xFFB5750A),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Rate your own skill level (1–5) for each task.',
            style: TextStyle(color: kTextMid, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 16),
          ...widget.tasks.asMap().entries.map((e) {
            final i = e.key;
            final task = e.value;
            final selected = _skillRatings[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _numBadge(i + 1),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          task,
                          style: const TextStyle(
                            color: kTextDark,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
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
                            color: skillColors[selected - 1].withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            skillLabels[selected - 1],
                            style: TextStyle(
                              color: skillColors[selected - 1],
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: List.generate(5, (star) {
                      final val = star + 1;
                      final isSelected = selected == val;
                      final color = skillColors[star];
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => _setSkillRating(i, val),
                          child: Container(
                            margin: EdgeInsets.only(right: star < 4 ? 6 : 0),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color.withValues(alpha: 0.2)
                                  : kBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? color : kBorder,
                                width: isSelected ? 1.8 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '$val',
                                style: TextStyle(
                                  color: isSelected ? color : kTextLight,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
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
                  'After this, the remaining ${widget.members.length - 1} member(s) will rate their own skill per task.',
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
            onTap: (_isSaving || !_allRated) ? null : _proceed,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: _allRated && !_isSaving
                    ? kPrimary
                    : kPrimary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
                boxShadow: (_allRated && !_isSaving)
                    ? [
                        BoxShadow(
                          color: kPrimary.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: _isSaving
                  ? const Center(
                      child: SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      ),
                    )
                  : const Row(
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

  String _difficultyShort(int val) {
    const labels = ['V.Easy', 'Easy', 'Med', 'Hard', 'V.Hard'];
    return labels[(val - 1).clamp(0, 4)];
  }
}
