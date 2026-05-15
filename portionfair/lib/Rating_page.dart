import 'package:flutter/material.dart';
import 'computing_page.dart';
import 'task.dart'; 

class RatingPage extends StatefulWidget {
  final String groupName;
  final List<String> members;
  final List<String> tasks;
  final DateTime deadline;

  const RatingPage({
    super.key,
    required this.groupName,
    required this.members,
    required this.tasks,
    required this.deadline,
  });

  @override
  State<RatingPage> createState() => _RatingPageState();
}

class _RatingPageState extends State<RatingPage> {
  int _currentMemberIndex = 0;
  late List<List<int>> _ratings;

  @override
  void initState() {
    super.initState();
    _ratings = List.generate(widget.members.length, (_) => List.filled(widget.tasks.length, 0));
  }

  int get _ratedCount => _ratings[_currentMemberIndex].where((r) => r > 0).length;
  bool get _allRated => _ratings[_currentMemberIndex].every((r) => r > 0);
  bool get _allMembersSubmitted => _ratings.every((m) => m.every((r) => r > 0));

  void _setRating(int taskIndex, int value) {
    setState(() => _ratings[_currentMemberIndex][taskIndex] = value);
  }

  void _submitAndNext() {
    if (!_allRated) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: kPrimary,
        content: Text('Please rate all tasks before submitting.', style: TextStyle(color: Colors.white)),
      ));
      return;
    }

    if (_currentMemberIndex < widget.members.length - 1) {
      setState(() => _currentMemberIndex++);
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ComputingPage(
        groupName: widget.groupName,
        members: widget.members,
        tasks: widget.tasks,
        ratings: _ratings,
        deadline: widget.deadline,
      )));
    }
  }

  @override
  Widget build(BuildContext context) {
    final member = widget.members[_currentMemberIndex];
    final isLast = _currentMemberIndex == widget.members.length - 1;

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
                    const Text('Skill Rating', style: TextStyle(color: kTextDark, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.6)),
                    const SizedBox(height: 6),
                    const Text('Each member rates their skill level (1–5) for every task independently.', style: TextStyle(color: kTextMid, fontSize: 13, height: 1.5)),
                    const SizedBox(height: 20),
                    _buildMemberTabs(),
                    const SizedBox(height: 20),
                    _buildRatingCard(member),
                    const SizedBox(height: 14),
                    _buildProgressCard(),
                    const SizedBox(height: 14),
                    _buildGuideCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(isLast),
    );
  }

  Widget _buildNavBar() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Text('TaskFair', style: TextStyle(color: kPrimary, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        ],
      ),
    );
  }

  Widget _buildMemberTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: widget.members.asMap().entries.map((e) {
          final isSelected = e.key == _currentMemberIndex;
          final color = getAvatarColor(e.key);
          return GestureDetector(
            onTap: () => setState(() => _currentMemberIndex = e.key),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? color : kCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isSelected ? color : kBorder, width: isSelected ? 2 : 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(color: isSelected ? Colors.white.withValues(alpha: 0.25) : color.withValues(alpha: 0.2), shape: BoxShape.circle),
                    child: Center(child: Text(e.value[0].toUpperCase(), style: TextStyle(color: isSelected ? Colors.white : color, fontSize: 11, fontWeight: FontWeight.w800))),
                  ),
                  const SizedBox(width: 8),
                  Text(e.value, style: TextStyle(color: isSelected ? Colors.white : kTextDark, fontWeight: FontWeight.w600, fontSize: 14)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRatingCard(String member) {
    final memberColor = getAvatarColor(_currentMemberIndex);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: kBorder), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 32, height: 32, decoration: BoxDecoration(color: memberColor, shape: BoxShape.circle), child: Center(child: Text(member[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)))),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(text: TextSpan(style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700), children: [const TextSpan(text: 'Rating as ', style: TextStyle(color: kTextMid)), TextSpan(text: member, style: TextStyle(color: memberColor))])),
                  Text('$_ratedCount of ${widget.tasks.length} tasks rated', style: const TextStyle(color: kTextLight, fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: kBorder),
          const SizedBox(height: 16),
          ...widget.tasks.asMap().entries.map((e) {
            final taskIndex = e.key;
            final taskName = e.value;
            final selected = _ratings[_currentMemberIndex][taskIndex];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: selected > 0 ? kPrimary.withValues(alpha: 0.4) : kBorder)),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(taskName, style: const TextStyle(color: kTextDark, fontSize: 14, fontWeight: FontWeight.w600)),
                        Text(selected > 0 ? _ratingLabel(selected) : 'Not rated', style: TextStyle(color: selected > 0 ? kPrimary : kTextLight, fontSize: 11)),
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
                          width: 32, height: 32,
                          decoration: BoxDecoration(color: isChosen ? kPrimary : kCard, shape: BoxShape.circle, border: Border.all(color: isChosen ? kPrimary : kBorder, width: 1.5)),
                          child: Center(child: Text('$val', style: TextStyle(color: isChosen ? Colors.white : kTextMid, fontSize: 12, fontWeight: FontWeight.w700))),
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
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: kBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SUBMISSION PROGRESS', style: TextStyle(color: kTextLight, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
          const SizedBox(height: 14),
          ...widget.members.asMap().entries.map((e) {
            final memberIndex = e.key;
            final memberName = e.value;
            final rated = _ratings[memberIndex].where((r) => r > 0).length;
            final total = widget.tasks.length;
            final isDone = rated == total;
            final isActive = memberIndex == _currentMemberIndex;
            final color = getAvatarColor(memberIndex);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(width: 28, height: 28, decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle, border: Border.all(color: color)), child: Center(child: Text(memberName[0].toUpperCase(), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)))),
                  const SizedBox(width: 10),
                  Expanded(child: Text(memberName, style: const TextStyle(color: kTextDark, fontSize: 13, fontWeight: FontWeight.w600))),
                  if (isActive) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: kPrimary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)), child: const Text('Active', style: TextStyle(color: kPrimary, fontSize: 10, fontWeight: FontWeight.w700))) else if (isDone) const Icon(Icons.check_circle_rounded, color: Color(0xFF2D9E7E), size: 18),
                  const SizedBox(width: 8),
                  Text('$rated/$total', style: const TextStyle(color: kTextMid, fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGuideCard() {
    const guide = [
      (1, Color(0xFF2D9E7E), 'Beginner'),
      (2, Color(0xFF7EC8E3), 'Elementary'),
      (3, Color(0xFFFFD166), 'Intermediate'),
      (4, Color(0xFFFF8C69), 'Advanced'),
      (5, Color(0xFFB5A4E8), 'Expert'),
    ];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: kBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('RATING GUIDE', style: TextStyle(color: kTextLight, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
          const SizedBox(height: 14),
          ...guide.map((g) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(width: 24, height: 24, decoration: BoxDecoration(color: g.$2.withValues(alpha: 0.15), shape: BoxShape.circle, border: Border.all(color: g.$2.withValues(alpha: 0.3))), child: Center(child: Text('${g.$1}', style: TextStyle(color: g.$2, fontSize: 11, fontWeight: FontWeight.w800)))),
                const SizedBox(width: 10),
                Text(g.$3, style: TextStyle(color: g.$2, fontSize: 13, fontWeight: FontWeight.w700)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isLast) {
    final nextLabel = isLast ? 'Submit & Compute' : 'Next → ${widget.members[_currentMemberIndex + 1]}';
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(color: kBg, border: Border(top: BorderSide(color: kBorder))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _submitAndNext,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: _allRated ? kPrimary : kPrimary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
                boxShadow: _allRated ? [BoxShadow(color: kPrimary.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 4))] : [],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(nextLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Text('Go Back', style: TextStyle(color: kTextMid, fontWeight: FontWeight.w700, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  String _ratingLabel(int rating) {
    const labels = ['', 'Beginner', 'Elementary', 'Intermediate', 'Advanced', 'Expert'];
    return labels[rating.clamp(0, 5)];
  }
}