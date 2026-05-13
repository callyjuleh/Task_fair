import 'package:flutter/material.dart';
import 'rating_page.dart';

// ─── Green Theme Colors ───────────────────────────────────────────────────────
const _kBg = Color(0xFF0A0F0A);
const _kSurface = Color(0xFF111A11);
const _kCard = Color(0xFF162016);
const _kGreen = Color(0xFF22C55E);
const _kGreenDark = Color(0xFF16A34A);
const _kGreenLight = Color(0xFF4ADE80);
const _kBorder = Color(0xFF1A3A1A);
const _kTextPrimary = Color(0xFFECFDF5);
const _kTextMuted = Color(0xFF6EE7B7);
const _kTextSecondary = Color(0xFF86EFAC);

// ─── Member avatar colors ─────────────────────────────────────────────────────
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

// ─── Task Setup Page ──────────────────────────────────────────────────────────
class TaskSetupPage extends StatefulWidget {
  const TaskSetupPage({super.key});

  @override
  State<TaskSetupPage> createState() => _TaskSetupPageState();
}

class _TaskSetupPageState extends State<TaskSetupPage> {
  // ── State ──────────────────────────────────────────────────────────────────
  final _groupNameController = TextEditingController(text: 'Project Alpha');
  final _memberController = TextEditingController();
  final _taskController = TextEditingController();

  final List<String> _members = ['Alice', 'Bob', 'Carol'];
  final List<String> _tasks = [
    'Frontend Development',
    'API Design',
    'Testing',
    'Documentation',
  ];

  // ── Helpers ────────────────────────────────────────────────────────────────
  void _addMember() {
    final v = _memberController.text.trim();
    if (v.isEmpty || _members.contains(v)) return;
    setState(() => _members.add(v));
    _memberController.clear();
  }

  void _removeMember(int i) => setState(() => _members.removeAt(i));

  void _addTask() {
    final v = _taskController.text.trim();
    if (v.isEmpty || _tasks.contains(v)) return;
    setState(() => _tasks.add(v));
    _taskController.clear();
  }

  void _removeTask(int i) => setState(() => _tasks.removeAt(i));

  void _startRating() {
    if (_members.isEmpty || _tasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _kCard,
          content: const Text(
            'Add at least one member and one task.',
            style: TextStyle(color: _kTextPrimary),
          ),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RatingPage(
          groupName: _groupNameController.text.trim(),
          members: List.from(_members),
          tasks: List.from(_tasks),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _memberController.dispose();
    _taskController.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
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
                      'Set Up Your Group',
                      style: TextStyle(
                        color: _kTextPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Name your group, add team members, and list the tasks you want to distribute.',
                      style: TextStyle(
                        color: _kTextMuted,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    LayoutBuilder(
                      builder: (ctx, constraints) {
                        final wide = constraints.maxWidth > 560;
                        if (wide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildLeftColumn()),
                              const SizedBox(width: 16),
                              Expanded(child: _buildRightColumn()),
                            ],
                          );
                        }
                        return Column(
                          children: [
                            _buildLeftColumn(),
                            const SizedBox(height: 16),
                            _buildRightColumn(),
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
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  // ── Nav Bar ────────────────────────────────────────────────────────────────
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
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
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
          ),
        ],
      ),
    );
  }

  // ── Stepper ────────────────────────────────────────────────────────────────
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
          final isActive = i == 0;
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
                          color: isActive ? _kGreen : _kCard,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isActive ? _kGreen : _kBorder,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: isActive ? Colors.white : _kTextMuted,
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
                          color: isActive ? _kTextPrimary : _kTextMuted,
                          fontSize: 10,
                          fontWeight: isActive
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

  // ── Left Column: Group name + Members + Tasks ──────────────────────────────
  Widget _buildLeftColumn() {
    return Column(
      children: [
        _buildGroupNameCard(),
        const SizedBox(height: 14),
        _buildMembersCard(),
        const SizedBox(height: 14),
        _buildTasksCard(),
      ],
    );
  }

  // ── Right Column: Summary + Tip ────────────────────────────────────────────
  Widget _buildRightColumn() {
    return Column(
      children: [
        _buildSummaryCard(),
        const SizedBox(height: 14),
        _buildTipCard(),
      ],
    );
  }

  // ── Group Name Card ────────────────────────────────────────────────────────
  Widget _buildGroupNameCard() {
    return _card(
      title: 'GROUP DETAILS',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Group Name',
            style: TextStyle(
              color: _kTextMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _groupNameController,
            style: const TextStyle(color: _kTextPrimary, fontSize: 14),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'e.g. Project Alpha',
              hintStyle: TextStyle(color: _kTextMuted.withOpacity(0.35)),
              filled: true,
              fillColor: _kSurface,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kGreen, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Members Card ───────────────────────────────────────────────────────────
  Widget _buildMembersCard() {
    return _card(
      title: 'TEAM MEMBERS',
      badge: '${_members.length}',
      child: Column(
        children: [
          ..._members.asMap().entries.map(
            (e) => _listItem(
              leading: _avatar(e.value, e.key),
              label: e.value,
              onDelete: () => _removeMember(e.key),
            ),
          ),
          const SizedBox(height: 8),
          _addRow(
            controller: _memberController,
            hint: 'Member name...',
            onAdd: _addMember,
          ),
        ],
      ),
    );
  }

  // ── Tasks Card ─────────────────────────────────────────────────────────────
  Widget _buildTasksCard() {
    return _card(
      title: 'TASKS TO DISTRIBUTE',
      badge: '${_tasks.length}',
      child: Column(
        children: [
          ..._tasks.asMap().entries.map(
            (e) => _listItem(
              leading: _numBadge(e.key + 1),
              label: e.value,
              onDelete: () => _removeTask(e.key),
            ),
          ),
          const SizedBox(height: 8),
          _addRow(
            controller: _taskController,
            hint: 'Task name...',
            onAdd: _addTask,
          ),
        ],
      ),
    );
  }

  // ── Summary Card ───────────────────────────────────────────────────────────
  Widget _buildSummaryCard() {
    return _card(
      title: 'SUMMARY',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Group',
            style: TextStyle(color: _kTextMuted, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            _groupNameController.text.trim().isEmpty
                ? 'Unnamed Group'
                : _groupNameController.text.trim(),
            style: const TextStyle(
              color: _kTextPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          _summaryDivider(),
          Text(
            'Members (${_members.length})',
            style: const TextStyle(color: _kTextMuted, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _members.asMap().entries.map((e) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _avatarColor(e.key).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _avatarColor(e.key).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: _avatarColor(e.key),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      e.value,
                      style: TextStyle(
                        color: _avatarColor(e.key),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          _summaryDivider(),
          Text(
            'Tasks (${_tasks.length})',
            style: const TextStyle(color: _kTextMuted, fontSize: 12),
          ),
          const SizedBox(height: 8),
          ..._tasks.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: _kTextMuted.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t,
                      style: const TextStyle(
                        color: _kTextSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _summaryDivider(),
          Row(
            children: [
              Expanded(
                child: _statBox(
                  value: '${_members.length * _tasks.length}',
                  label: 'Ratings needed',
                  color: const Color(0xFF3B6FD8),
                  bg: const Color(0xFF1A2A5E),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statBox(
                  value: '${_tasks.length}',
                  label: 'Assignments',
                  color: _kGreen,
                  bg: _kGreen.withOpacity(0.12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Tip Card ───────────────────────────────────────────────────────────────
  Widget _buildTipCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1A00),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3D3500)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tip',
                  style: TextStyle(
                    color: Color(0xFFFBBF24),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Have each member rate tasks independently before seeing others' ratings for the most accurate results.",
                  style: TextStyle(
                    color: Color(0xFFD97706),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Bar ─────────────────────────────────────────────────────────────
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
                    'Back',
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
            onTap: _startRating,
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
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Start Rating',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
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

  // ── Shared Widgets ─────────────────────────────────────────────────────────
  Widget _card({required String title, String? badge, required Widget child}) {
    return Container(
      width: double.infinity,
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
                title,
                style: TextStyle(
                  color: _kTextMuted.withOpacity(0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              if (badge != null) ...[
                const Spacer(),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _kSurface,
                    shape: BoxShape.circle,
                    border: Border.all(color: _kBorder),
                  ),
                  child: Center(
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: _kTextMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
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
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: _kTextPrimary, fontSize: 14),
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: Icon(
              Icons.close_rounded,
              size: 16,
              color: _kTextMuted.withOpacity(0.4),
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
  }) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            style: const TextStyle(color: _kTextPrimary, fontSize: 13),
            onSubmitted: (_) => onAdd(),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: _kTextMuted.withOpacity(0.35),
                fontSize: 13,
              ),
              filled: true,
              fillColor: _kSurface,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kGreen, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: _kGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kGreen.withOpacity(0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: _kGreen, size: 16),
                SizedBox(width: 4),
                Text(
                  'Add',
                  style: TextStyle(
                    color: _kGreen,
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

  Widget _avatar(String name, int index) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: _avatarColor(index),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          name[0].toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _numBadge(int n) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _kBorder),
      ),
      child: Center(
        child: Text(
          '$n',
          style: const TextStyle(color: _kTextMuted, fontSize: 11),
        ),
      ),
    );
  }

  Widget _statBox({
    required String value,
    required String label,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: color.withOpacity(0.7), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _summaryDivider() {
    return Container(
      height: 0.5,
      color: _kBorder,
      margin: const EdgeInsets.only(bottom: 12),
    );
  }
}
