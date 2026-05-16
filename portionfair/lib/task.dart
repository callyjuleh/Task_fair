import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'leader_rating_page.dart';
import 'login_page.dart'; // for kBaseUrl

// ─── Shared Palette (Single Source of Truth) ──────────────────────────────────
const kBg = Color(0xFFFFF8F0);
const kCard = Color(0xFFFFFFFF);
const kPrimary = Color(0xFFFF8C69);
const kSecondary = Color(0xFF7EC8E3);
const kAccent = Color(0xFFFFD166);
const kMint = Color(0xFF9EDEC8);
const kPurple = Color(0xFFB5A4E8);
const kTextDark = Color(0xFF3D2C2C);
const kTextMid = Color(0xFF7A6060);
const kTextLight = Color(0xFFB09898);
const kBorder = Color(0xFFEFE0D5);

const _avatarColors = [
  Color(0xFFFF8C69),
  Color(0xFF7EC8E3),
  Color(0xFFFFD166),
  Color(0xFF9EDEC8),
  Color(0xFFB5A4E8),
  Color(0xFFF9A8C9),
];

Color getAvatarColor(int i) => _avatarColors[i % _avatarColors.length];

const _suggestedTasks = [
  'Research & Data Gathering',
  'Writing & Documentation',
  'Presentation Slides',
  'Editing & Proofreading',
  'Coding / Programming',
  'Design & Visuals',
  'Testing & QA',
  'Project Management',
];

// ─── Shared Stepper Widget ────────────────────────────────────────────────────
Widget buildStepper({required int activeStep}) {
  const steps = [
    ('Setup', '🏫'),
    ('Rating', '⭐'),
    ('Computing', '⚡'),
    ('Results', '🎯'),
  ];
  return Container(
    margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: kCard,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: kBorder),
    ),
    child: Row(
      children: List.generate(steps.length, (i) {
        final isActive = i == activeStep;
        final isDone = i < activeStep;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: isActive
                            ? kPrimary
                            : isDone
                            ? kMint.withValues(alpha: 0.4)
                            : kBg,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isActive
                              ? kPrimary
                              : isDone
                              ? kMint
                              : kBorder,
                        ),
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(
                                Icons.check_rounded,
                                color: Color(0xFF2D9E7E),
                                size: 14,
                              )
                            : Text(
                                steps[i].$2,
                                style: const TextStyle(fontSize: 13),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      steps[i].$1,
                      style: TextStyle(
                        color: isActive
                            ? kPrimary
                            : isDone
                            ? kTextMid
                            : kTextLight,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (i < steps.length - 1)
                Container(width: 16, height: 1.5, color: kBorder),
            ],
          ),
        );
      }),
    ),
  );
}

String formatDate(DateTime date) {
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
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

// ─── Task Setup Page ──────────────────────────────────────────────────────────
class TaskSetupPage extends StatefulWidget {
  const TaskSetupPage({super.key});
  @override
  State<TaskSetupPage> createState() => _TaskSetupPageState();
}

class _TaskSetupPageState extends State<TaskSetupPage> {
  final _groupCtrl = TextEditingController();
  final _memberCtrl = TextEditingController();
  final _taskCtrl = TextEditingController();

  final List<String> _members = [];
  final List<String> _tasks = [];

  DateTime? _deadline;
  bool _isLoading = false; // ← NEW: loading state for API calls

  void _addMember() {
    final v = _memberCtrl.text.trim();
    if (v.isEmpty || _members.contains(v)) return;
    setState(() => _members.add(v));
    _memberCtrl.clear();
  }

  void _removeMember(int i) => setState(() => _members.removeAt(i));

  void _addTask([String? preset]) {
    final v = preset ?? _taskCtrl.text.trim();
    if (v.isEmpty) {
      _snack('Type a task name first! 📋');
      return;
    }
    if (_tasks.contains(v)) {
      _snack('"$v" is already in the list!');
      return;
    }
    // Dismiss keyboard before updating list
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _tasks.add(v));
    _taskCtrl.clear();
  }

  void _removeTask(int i) => setState(() => _tasks.removeAt(i));

  Future<void> _selectDeadline() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kPrimary,
              onPrimary: Colors.white,
              onSurface: kTextDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  // ─── UPDATED: _startRating now saves to DB first ──────────────────────────
  Future<void> _startRating() async {
    if (_groupCtrl.text.trim().isEmpty) {
      _snack('Please enter a group name! 🏷️');
      return;
    }
    if (_members.length < 2) {
      _snack('Add at least 2 members! 👥');
      return;
    }
    if (_tasks.isEmpty) {
      _snack('Add at least one task! 📋');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Create project in DB
      final projRes = await http.post(
        Uri.parse('$kBaseUrl/projects'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'project_name': _groupCtrl.text.trim()}),
      );
      if (projRes.statusCode != 201) {
        _snack('Failed to create project. Try again.');
        return;
      }
      final String projectId = jsonDecode(projRes.body)['project_id'];

      // 2. Add each member to DB, collect their IDs
      final List<String> memberIds = [];
      for (final name in _members) {
        final mRes = await http.post(
          Uri.parse('$kBaseUrl/projects/$projectId/members'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'name': name}),
        );
        if (mRes.statusCode != 201) {
          final errMsg = jsonDecode(mRes.body)['message'] ?? 'unknown error';
          _snack('Failed to add member "$name": $errMsg');
          return;
        }
        memberIds.add(jsonDecode(mRes.body)['member_id']);
      }

      // 3. Add each task to DB, collect their IDs
      final List<String> taskIds = [];
      for (final taskName in _tasks) {
        final tRes = await http.post(
          Uri.parse('$kBaseUrl/projects/$projectId/tasks'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'task_name': taskName}),
        );
        if (tRes.statusCode != 201) {
          final errMsg = jsonDecode(tRes.body)['message'] ?? 'unknown error';
          _snack('Failed to add task "$taskName": $errMsg');
          return;
        }
        taskIds.add(jsonDecode(tRes.body)['task_id']);
      }

      if (!mounted) return;

      // Navigate with DB IDs now attached
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LeaderRatingPage(
            groupName: _groupCtrl.text.trim(),
            leaderName: _members.first,
            members: List.from(_members),
            tasks: List.from(_tasks),
            deadline: _deadline,
            projectId: projectId,
            memberIds: memberIds,
            taskIds: taskIds,
          ),
        ),
      );
    } catch (e) {
      _snack('Cannot reach server. Check your connection. 😕');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: kPrimary,
        content: Text(msg, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  @override
  void dispose() {
    _groupCtrl.dispose();
    _memberCtrl.dispose();
    _taskCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildNavBar(),
            buildStepper(activeStep: 0),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Set Up Your Group 🏫',
                      style: TextStyle(
                        color: kTextDark,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Name your group, set a deadline, add members, and list the tasks to distribute.',
                      style: TextStyle(
                        color: kTextMid,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildGroupNameCard(),
                    const SizedBox(height: 16),
                    _buildDeadlineCard(),
                    const SizedBox(height: 16),
                    _buildMembersCard(),
                    const SizedBox(height: 16),
                    _buildTasksCard(),
                    const SizedBox(height: 16),
                    _buildSummaryCard(),
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

  Widget _buildGroupNameCard() {
    return _card(
      emoji: '🏷️',
      title: 'GROUP NAME',
      color: kPrimary,
      child: TextField(
        controller: _groupCtrl,
        style: const TextStyle(
          color: kTextDark,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        onChanged: (_) => setState(() {}),
        decoration: _inputDeco('e.g. STEM Group 3'),
      ),
    );
  }

  Widget _buildDeadlineCard() {
    return _card(
      emoji: '📅',
      title: 'PROJECT DEADLINE',
      color: kPurple,
      child: GestureDetector(
        onTap: _selectDeadline,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: kBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBorder),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                color: kPurple,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _deadline != null
                      ? formatDate(_deadline!)
                      : 'Tap to set deadline',
                  style: TextStyle(
                    color: _deadline != null ? kTextDark : kTextLight,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                _deadline != null ? 'Change' : 'Set',
                style: const TextStyle(
                  color: kPurple,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMembersCard() {
    return _card(
      emoji: '👥',
      title: 'TEAM MEMBERS',
      color: kSecondary,
      badge: '${_members.length}',
      child: Column(
        children: [
          if (_members.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: kBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kBorder),
                ),
                child: const Text(
                  'No members yet — add one below 👇',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kTextLight, fontSize: 13),
                ),
              ),
            ),
          ..._members.asMap().entries.map((e) {
            final isLeader = e.key == 0;
            return _listItem(
              leading: _avatarBubble(e.value, e.key),
              label: isLeader ? '${e.value}  👑 Leader' : e.value,
              onDelete: () => _removeMember(e.key),
            );
          }),
          const SizedBox(height: 8),
          _addRow(
            controller: _memberCtrl,
            hint: 'Add member name...',
            onAdd: _addMember,
            color: kSecondary,
          ),
          if (_members.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'First member added = Leader 👑',
                style: TextStyle(
                  color: kTextLight.withValues(alpha: 0.8),
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTasksCard() {
    return _card(
      emoji: '📋',
      title: 'TASKS TO DISTRIBUTE',
      color: kMint,
      badge: '${_tasks.length}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: kBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kBorder),
                ),
                child: const Text(
                  'No tasks yet — add one below 👇',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kTextLight, fontSize: 13),
                ),
              ),
            ),
          ..._tasks.asMap().entries.map(
            (e) => _listItem(
              leading: _numBadge(e.key + 1),
              label: e.value,
              onDelete: () => _removeTask(e.key),
            ),
          ),
          const SizedBox(height: 8),
          _addRow(
            controller: _taskCtrl,
            hint: 'Add custom task...',
            onAdd: () => _addTask(),
            color: kMint,
          ),
          const SizedBox(height: 14),
          const Text(
            'Quick add:',
            style: TextStyle(
              color: kTextLight,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestedTasks
                .where((t) => !_tasks.contains(t))
                .take(6)
                .map(
                  (t) => GestureDetector(
                    onTap: () => _addTask(t),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: kMint.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: kMint),
                      ),
                      child: Text(
                        t,
                        style: const TextStyle(
                          color: Color(0xFF2D9E7E),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kPrimary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          _statPill('${_members.length}', 'Members', kSecondary),
          const SizedBox(width: 12),
          _statPill('${_tasks.length}', 'Tasks', kMint),
          const SizedBox(width: 12),
          _statPill(
            '${_members.length * _tasks.length}',
            'Ratings needed',
            kPurple,
          ),
        ],
      ),
    );
  }

  Widget _statPill(String val, String label, Color color) {
    Color textColor = color == kSecondary
        ? const Color(0xFF1A7DA0)
        : color == kMint
        ? const Color(0xFF2D9E7E)
        : const Color(0xFF6B4FCF);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              val,
              style: TextStyle(
                color: textColor,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kTextMid,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
            onTap: _isLoading ? null : _startRating,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: _isLoading ? kPrimary.withValues(alpha: 0.6) : kPrimary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: kPrimary.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _isLoading
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
                          'Start Rating',
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
              'Cancel / Go Back',
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

  Widget _card({
    required String emoji,
    required String title,
    required Color color,
    String? badge,
    required Widget child,
  }) {
    Color labelColor = color == kPrimary
        ? kPrimary
        : color == kSecondary
        ? const Color(0xFF1A7DA0)
        : color == kMint
        ? const Color(0xFF2D9E7E)
        : const Color(0xFF6B4FCF);
    return Container(
      width: double.infinity,
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
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: labelColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              if (badge != null) ...[
                const Spacer(),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      badge,
                      style: TextStyle(
                        color: labelColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _listItem({
    required Widget leading,
    required String label,
    required VoidCallback onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: kTextDark, fontSize: 14),
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 14,
                color: Colors.redAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addRow({
    required TextEditingController controller,
    required String hint,
    required VoidCallback onAdd,
    required Color color,
  }) {
    final isGreen = color == kMint;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            style: const TextStyle(color: kTextDark, fontSize: 13),
            onSubmitted: (_) => onAdd(),
            decoration: _inputDeco(hint),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_rounded,
                  color: isGreen ? const Color(0xFF2D9E7E) : kPrimary,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Add',
                  style: TextStyle(
                    color: isGreen ? const Color(0xFF2D9E7E) : kPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _avatarBubble(String name, int idx) {
    final c = getAvatarColor(idx);
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: c, width: 1.5),
      ),
      child: Center(
        child: Text(
          name[0].toUpperCase(),
          style: TextStyle(color: c, fontSize: 13, fontWeight: FontWeight.w800),
        ),
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

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: kTextLight, fontSize: 13),
    filled: true,
    fillColor: kBg,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kPrimary, width: 1.5),
    ),
  );
}
