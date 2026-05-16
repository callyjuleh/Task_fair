import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'task.dart';
import 'login_page.dart'; // for kBaseUrl
import 'dashboard_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _projects = [];
  bool _loadingProjects = true;

  @override
  void initState() {
    super.initState();
    _fetchProjects();
  }

  Future<void> _fetchProjects() async {
    setState(() => _loadingProjects = true);
    try {
      final res = await http.get(Uri.parse('$kBaseUrl/projects'));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        setState(() => _projects = List<Map<String, dynamic>>.from(data));
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingProjects = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNavBar(context),
              _buildHero(context),
              _buildMyProjectsSection(context),
              _buildStepsSection(),
              _buildFeatureCards(),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          const Text(
            'TaskFair',
            style: TextStyle(
              color: kPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TaskSetupPage()),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: kPrimary,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: kPrimary.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Text(
                'Get Started',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: kPrimary,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -10,
            right: -10,
            child: _blob(80, kAccent.withValues(alpha: 0.3)),
          ),
          Positioned(
            bottom: -15,
            left: 40,
            child: _blob(60, kSecondary.withValues(alpha: 0.25)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('✨', style: TextStyle(fontSize: 12)),
                    SizedBox(width: 6),
                    Text(
                      'Powered by Shapley Value Theory',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Tasks distributed.\nFairly. 🎉',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'TaskFair uses cooperative game theory to assign group work to the most capable member — based on honest skill self-ratings.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TaskSetupPage()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Create a Group',
                            style: TextStyle(
                              color: kPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: kPrimary,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMyProjectsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionLabel('MY PROJECTS'),
              const Spacer(),
              GestureDetector(
                onTap: _fetchProjects,
                child: const Icon(
                  Icons.refresh_rounded,
                  color: kTextLight,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_loadingProjects)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(
                  color: kPrimary,
                  strokeWidth: 2.5,
                ),
              ),
            )
          else if (_projects.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kBorder),
              ),
              child: const Column(
                children: [
                  Text('📂', style: TextStyle(fontSize: 32)),
                  SizedBox(height: 8),
                  Text(
                    'No projects yet',
                    style: TextStyle(
                      color: kTextDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tap "Get Started" to create your first group!',
                    style: TextStyle(color: kTextLight, fontSize: 12),
                  ),
                ],
              ),
            )
          else
            ...(_projects.map(
              (project) => _buildProjectCard(context, project),
            )),
        ],
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, Map<String, dynamic> project) {
    final status = project['status'] ?? 'setup';
    final name = project['project_name'] ?? 'Unnamed Project';
    final createdAt = project['created_at'] != null
        ? formatDate(DateTime.parse(project['created_at']))
        : '';

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'computed':
      case 'done':
        statusColor = const Color(0xFF2D9E7E);
        statusLabel = '✅ Done';
        break;
      case 'rating':
        statusColor = kAccent;
        statusLabel = '⭐ Rating';
        break;
      default:
        statusColor = kSecondary;
        statusLabel = '🏫 Setup';
    }

    return GestureDetector(
      onTap: () async {
        final deleted = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => ProjectDetailSheet(project: project),
        );
        if (deleted == true) _fetchProjects();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: kPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('📋', style: TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: kTextDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    createdAt,
                    style: const TextStyle(color: kTextLight, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepsSection() {
    final steps = [
      _StepData('01', '👥', 'Group Setup', 'Name your group & add members'),
      _StepData(
        '02',
        '⭐',
        'Rate Skills',
        'Each member rates their ability 1–5 per task',
      ),
      _StepData(
        '03',
        '⚡',
        'Compute',
        'Shapley algorithm calculates fair scores',
      ),
      _StepData('04', '🎯', 'Get Results', 'Best-fit member earns each task'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('HOW IT WORKS'),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: kBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                steps.length,
                (i) => Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _stepItem(steps[i])),
                      if (i < steps.length - 1)
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Container(
                            width: 16,
                            height: 1.5,
                            color: kBorder,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepItem(_StepData s) {
    return Column(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: kBg,
            shape: BoxShape.circle,
            border: Border.all(color: kBorder, width: 1.5),
          ),
          child: Center(
            child: Text(s.emoji, style: const TextStyle(fontSize: 20)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          s.number,
          style: const TextStyle(
            color: kPrimary,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          s.label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: kTextDark,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          s.desc,
          textAlign: TextAlign.center,
          style: const TextStyle(color: kTextLight, fontSize: 9.5, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildFeatureCards() {
    final features = [
      _FeatureData(
        '🎓',
        'For Students',
        kMint,
        const Color(0xFF2D9E7E),
        'Perfect for group projects, research papers, presentations, or any team activity.',
      ),
      _FeatureData(
        '⚖️',
        'Provably Fair',
        kPurple,
        const Color(0xFF6B4FCF),
        'Shapley values satisfy efficiency, symmetry & fairness — no manager bias.',
      ),
      _FeatureData(
        '🚀',
        'Instant Results',
        kAccent,
        const Color(0xFFB5750A),
        'Once all ratings are collected, the algorithm runs instantly.',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('WHY TASKFAIR'),
          const SizedBox(height: 14),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _featureCard(f),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureCard(_FeatureData f) {
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
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: f.bg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(f.emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  f.title,
                  style: TextStyle(
                    color: f.color,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  f.desc,
                  style: const TextStyle(
                    color: kTextMid,
                    fontSize: 13,
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

  Widget _sectionLabel(String label) => Text(
    label,
    style: const TextStyle(
      color: kTextLight,
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 2.0,
    ),
  );
  Widget _blob(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _StepData {
  final String number, emoji, label, desc;
  const _StepData(this.number, this.emoji, this.label, this.desc);
}

class _FeatureData {
  final String emoji, title, desc;
  final Color bg, color;
  const _FeatureData(this.emoji, this.title, this.bg, this.color, this.desc);
}

// ─── Project Detail Bottom Sheet ─────────────────────────────────────────────
class ProjectDetailSheet extends StatefulWidget {
  final Map<String, dynamic> project;
  const ProjectDetailSheet({super.key, required this.project});

  @override
  State<ProjectDetailSheet> createState() => _ProjectDetailSheetState();
}

class _ProjectDetailSheetState extends State<ProjectDetailSheet> {
  Map<String, dynamic>? _summary;
  bool _loading = true;
  bool _deleting = false;
  bool _editing = false;
  late TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
      text: widget.project['project_name'] ?? '',
    );
    _fetchSummary();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchSummary() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(
        Uri.parse('$kBaseUrl/projects/${widget.project['id']}/summary'),
      );
      if (res.statusCode == 200) {
        setState(() => _summary = jsonDecode(res.body));
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveName() async {
    final newName = _nameCtrl.text.trim();
    if (newName.isEmpty) return;
    try {
      final res = await http.put(
        Uri.parse('$kBaseUrl/projects/${widget.project['id']}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'project_name': newName}),
      );
      if (res.statusCode == 200) {
        widget.project['project_name'] = newName;
        setState(() => _editing = false);
        _snack('Project renamed! ✅');
      } else {
        _snack('Could not rename. Try again.');
      }
    } catch (_) {
      _snack('Cannot reach server.');
    }
  }

  Future<void> _deleteProject() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete project?',
          style: TextStyle(color: kTextDark, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'This will permanently delete "${widget.project['project_name']}" along with all members, tasks, and ratings.',
          style: const TextStyle(color: kTextMid, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: kTextMid)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      final res = await http.delete(
        Uri.parse('$kBaseUrl/projects/${widget.project['id']}'),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        Navigator.pop(context, true);
      } else {
        _snack('Failed to delete. Try again.');
        setState(() => _deleting = false);
      }
    } catch (_) {
      _snack('Cannot reach server.');
      if (mounted) setState(() => _deleting = false);
    }
  }

  void _goToDashboard() {
    if (_summary == null) return;
    final members = (_summary!['members'] as List)
        .map((m) => m['name'] as String)
        .toList();
    final tasks = (_summary!['tasks'] as List)
        .map((t) => t['task_name'] as String)
        .toList();
    // Build assignments: index of assigned member per task
    final assignments = (_summary!['tasks'] as List).map((t) {
      final assignedName = t['assigned_to_name'] as String?;
      if (assignedName == null) return 0;
      final idx = members.indexOf(assignedName);
      return idx < 0 ? 0 : idx;
    }).toList();

    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DashboardPage(
          groupName: widget.project['project_name'] ?? '',
          members: members,
          tasks: tasks,
          assignments: assignments,
          deadline: null,
          taskDifficulties: List.filled(tasks.length, 1),
        ),
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: kPrimary,
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final status = project['status'] ?? 'setup';
    final createdAt = project['created_at'] != null
        ? formatDate(DateTime.parse(project['created_at']))
        : '—';

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'computed':
      case 'done':
        statusColor = const Color(0xFF2D9E7E);
        statusLabel = '✅ Completed';
        break;
      case 'rating':
        statusColor = kAccent;
        statusLabel = '⭐ Rating in progress';
        break;
      default:
        statusColor = kSecondary;
        statusLabel = '🏫 Setup';
    }

    final isComputed = status == 'computed' || status == 'done';

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: kBorder,
                borderRadius: BorderRadius.circular(4),
              ),
            ),

            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _editing
                        ? TextField(
                            controller: _nameCtrl,
                            autofocus: true,
                            style: const TextStyle(
                              color: kTextDark,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Project name',
                              hintStyle: const TextStyle(color: kTextLight),
                              filled: true,
                              fillColor: kBg,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: kBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: kPrimary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          )
                        : Text(
                            project['project_name'] ?? 'Unnamed Project',
                            style: const TextStyle(
                              color: kTextDark,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                  ),
                  const SizedBox(width: 10),
                  if (_editing) ...[
                    _iconBtn(
                      icon: Icons.check_rounded,
                      color: kPrimary,
                      bg: kPrimary.withValues(alpha: 0.1),
                      onTap: _saveName,
                    ),
                    const SizedBox(width: 8),
                    _iconBtn(
                      icon: Icons.close_rounded,
                      color: kTextMid,
                      bg: kBg,
                      onTap: () => setState(() => _editing = false),
                    ),
                  ] else ...[
                    _iconBtn(
                      icon: Icons.edit_rounded,
                      color: kTextMid,
                      bg: kBg,
                      onTap: () => setState(() => _editing = true),
                    ),
                  ],
                ],
              ),
            ),

            // Status + date
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Created $createdAt',
                    style: const TextStyle(color: kTextLight, fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),
            const Divider(color: kBorder, height: 24),

            // ── Body ────────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: kPrimary,
                        strokeWidth: 2.5,
                      ),
                    )
                  : _summary == null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('😕', style: TextStyle(fontSize: 36)),
                          const SizedBox(height: 8),
                          const Text(
                            'Could not load project details.',
                            style: TextStyle(color: kTextMid),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: _fetchSummary,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: kPrimary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Retry',
                                style: TextStyle(
                                  color: kPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      children: [
                        // Stats
                        Row(
                          children: [
                            _statBox(
                              '${(_summary!['members'] as List).length}',
                              'Members',
                              kSecondary,
                              const Color(0xFF1A7DA0),
                            ),
                            const SizedBox(width: 10),
                            _statBox(
                              '${(_summary!['tasks'] as List).length}',
                              'Tasks',
                              kMint,
                              const Color(0xFF2D9E7E),
                            ),
                            const SizedBox(width: 10),
                            _statBox(
                              '${(_summary!['members'] as List).where((m) => m['has_submitted'] == 1).length}',
                              'Rated',
                              kPurple,
                              const Color(0xFF6B4FCF),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Members
                        _sectionLabel('👥  MEMBERS'),
                        const SizedBox(height: 10),
                        ...(_summary!['members'] as List).asMap().entries.map((
                          e,
                        ) {
                          final m = e.value as Map;
                          final color = getAvatarColor(e.key);
                          final isLeader = e.key == 0;
                          final hasRated = (m['has_submitted'] ?? 0) == 1;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: kBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: kBorder),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: color,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      (m['name'] as String)[0].toUpperCase(),
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    isLeader
                                        ? '${m['name']}  👑'
                                        : m['name'] as String,
                                    style: const TextStyle(
                                      color: kTextDark,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: hasRated
                                        ? kMint.withValues(alpha: 0.2)
                                        : kBorder.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    hasRated ? '✅ Rated' : '⏳ Pending',
                                    style: TextStyle(
                                      color: hasRated
                                          ? const Color(0xFF2D9E7E)
                                          : kTextLight,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: 24),

                        // Tasks
                        _sectionLabel('📋  TASKS'),
                        const SizedBox(height: 10),
                        ...(_summary!['tasks'] as List).asMap().entries.map((
                          e,
                        ) {
                          final t = e.value as Map;
                          final assignedTo = t['assigned_to_name'] as String?;
                          final assigneeIdx = assignedTo != null
                              ? (_summary!['members'] as List).indexWhere(
                                  (m) => m['name'] == assignedTo,
                                )
                              : -1;
                          final assigneeColor = assigneeIdx >= 0
                              ? getAvatarColor(assigneeIdx)
                              : kTextLight;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: kBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: kBorder),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: kPrimary.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: kPrimary.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${e.key + 1}',
                                      style: const TextStyle(
                                        color: kPrimary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    t['task_name'] as String? ?? '—',
                                    style: const TextStyle(
                                      color: kTextDark,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (assignedTo != null) ...[
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: assigneeColor.withValues(
                                        alpha: 0.2,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        assignedTo[0].toUpperCase(),
                                        style: TextStyle(
                                          color: assigneeColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    assignedTo,
                                    style: TextStyle(
                                      color: assigneeColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ] else
                                  const Text(
                                    'Unassigned',
                                    style: TextStyle(
                                      color: kTextLight,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: 28),

                        // Go to Dashboard button (only if computed)
                        if (isComputed)
                          GestureDetector(
                            onTap: _goToDashboard,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
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
                                  Icon(
                                    Icons.space_dashboard_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Open Group Dashboard',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Delete button — always visible at bottom
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _deleting ? null : _deleteProject,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.red.withValues(alpha: 0.2),
                              ),
                            ),
                            child: _deleting
                                ? const Center(
                                    child: SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        color: Colors.redAccent,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.delete_outline_rounded,
                                        color: Colors.redAccent,
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Delete Project',
                                        style: TextStyle(
                                          color: Colors.redAccent,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn({
    IconData? icon,
    required Color color,
    required Color bg,
    VoidCallback? onTap,
    bool loading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
        ),
        child: Center(
          child: loading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: color,
                    strokeWidth: 2,
                  ),
                )
              : Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  Widget _statBox(String value, String label, Color bg, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bg.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: textColor,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: kTextMid,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(
    label,
    style: const TextStyle(
      color: kTextLight,
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.2,
    ),
  );
}
