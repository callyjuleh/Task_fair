import 'package:flutter/material.dart';

// ─── Data Models ────────────────────────────────────────────────────────────

class Project {
  final String id;
  final String name;
  final Color color;
  final List<Task> tasks;
  final List<Member> members;

  const Project({
    required this.id,
    required this.name,
    required this.color,
    required this.tasks,
    required this.members,
  });

  double get progress {
    if (tasks.isEmpty) return 0;
    final done = tasks.where((t) => t.isDone).length;
    return done / tasks.length;
  }
}

class Task {
  final String id;
  final String title;
  bool isDone;
  final String assigneeInitials;
  final Color assigneeColor;

  Task({
    required this.id,
    required this.title,
    this.isDone = false,
    required this.assigneeInitials,
    required this.assigneeColor,
  });
}

class Member {
  final String name;
  final String initials;
  final Color color;

  const Member({
    required this.name,
    required this.initials,
    required this.color,
  });
}

// ─── Sample Data ─────────────────────────────────────────────────────────────

final List<Project> sampleProjects = [
  Project(
    id: '1',
    name: 'Mobile App Redesign',
    color: const Color(0xFF6C63FF),
    members: const [
      Member(name: 'Ana Reyes', initials: 'AR', color: Color(0xFF6C63FF)),
      Member(name: 'Ben Cruz', initials: 'BC', color: Color(0xFFFF6584)),
      Member(name: 'Carla Sy', initials: 'CS', color: Color(0xFF43D9AD)),
    ],
    tasks: [
      Task(
        id: 't1',
        title: 'Wireframes',
        isDone: true,
        assigneeInitials: 'AR',
        assigneeColor: Color(0xFF6C63FF),
      ),
      Task(
        id: 't2',
        title: 'UI Components',
        isDone: true,
        assigneeInitials: 'BC',
        assigneeColor: Color(0xFFFF6584),
      ),
      Task(
        id: 't3',
        title: 'User Testing',
        isDone: false,
        assigneeInitials: 'CS',
        assigneeColor: Color(0xFF43D9AD),
      ),
      Task(
        id: 't4',
        title: 'Final Review',
        isDone: false,
        assigneeInitials: 'AR',
        assigneeColor: Color(0xFF6C63FF),
      ),
    ],
  ),
  Project(
    id: '2',
    name: 'Backend API v2',
    color: const Color(0xFFFF6584),
    members: const [
      Member(name: 'Dan Lim', initials: 'DL', color: Color(0xFFFF6584)),
      Member(name: 'Eva Tan', initials: 'ET', color: Color(0xFFFFC75F)),
    ],
    tasks: [
      Task(
        id: 't5',
        title: 'Auth Module',
        isDone: true,
        assigneeInitials: 'DL',
        assigneeColor: Color(0xFFFF6584),
      ),
      Task(
        id: 't6',
        title: 'Database Schema',
        isDone: true,
        assigneeInitials: 'ET',
        assigneeColor: Color(0xFFFFC75F),
      ),
      Task(
        id: 't7',
        title: 'Endpoint Docs',
        isDone: true,
        assigneeInitials: 'DL',
        assigneeColor: Color(0xFFFF6584),
      ),
      Task(
        id: 't8',
        title: 'Load Testing',
        isDone: false,
        assigneeInitials: 'ET',
        assigneeColor: Color(0xFFFFC75F),
      ),
    ],
  ),
  Project(
    id: '3',
    name: 'Marketing Campaign',
    color: const Color(0xFF43D9AD),
    members: const [
      Member(name: 'Faye Go', initials: 'FG', color: Color(0xFF43D9AD)),
      Member(name: 'Gil Santos', initials: 'GS', color: Color(0xFF6C63FF)),
      Member(name: 'Hana Uy', initials: 'HU', color: Color(0xFFFF6584)),
    ],
    tasks: [
      Task(
        id: 't9',
        title: 'Content Calendar',
        isDone: true,
        assigneeInitials: 'FG',
        assigneeColor: Color(0xFF43D9AD),
      ),
      Task(
        id: 't10',
        title: 'Social Assets',
        isDone: false,
        assigneeInitials: 'GS',
        assigneeColor: Color(0xFF6C63FF),
      ),
      Task(
        id: 't11',
        title: 'Email Blast',
        isDone: false,
        assigneeInitials: 'HU',
        assigneeColor: Color(0xFFFF6584),
      ),
    ],
  ),
];

// ─── HomePage ────────────────────────────────────────────────────────────────

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late List<Project> _projects;

  @override
  void initState() {
    super.initState();
    _projects = sampleProjects;
  }

  // Overall progress across ALL tasks
  double get _overallProgress {
    final allTasks = _projects.expand((p) => p.tasks).toList();
    if (allTasks.isEmpty) return 0;
    return allTasks.where((t) => t.isDone).length / allTasks.length;
  }

  int get _totalDone =>
      _projects.expand((p) => p.tasks).where((t) => t.isDone).length;
  int get _totalTasks => _projects.expand((p) => p.tasks).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0E17),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _buildGreeting(),
                    const SizedBox(height: 24),
                    _buildOverallProgress(),
                    const SizedBox(height: 28),
                    _buildMembersRow(),
                    const SizedBox(height: 28),
                    _buildSectionLabel('Projects & Tasks'),
                    const SizedBox(height: 14),
                    ..._projects.map((p) => _buildProjectCard(p)),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Top Bar ────────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF6C63FF).withOpacity(0.3),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.bolt, color: Color(0xFF6C63FF), size: 16),
                SizedBox(width: 4),
                Text(
                  'TaskFair',
                  style: TextStyle(
                    color: Color(0xFF6C63FF),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFF8A8A9A),
            ),
            onPressed: () {},
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF6C63FF),
            child: const Text(
              'ME',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Greeting ──────────────────────────────────────────────────────────────
  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good morning 👋',
          style: TextStyle(color: const Color(0xFF8A8A9A), fontSize: 14),
        ),
        const SizedBox(height: 4),
        const Text(
          'Here\'s your overview',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  // ── Overall Progress ──────────────────────────────────────────────────────
  Widget _buildOverallProgress() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF9B59B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Overall Progress',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Text(
                '$_totalDone/$_totalTasks tasks',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _overallProgress,
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${(_overallProgress * 100).toStringAsFixed(0)}% completed',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 28,
            ),
          ),
        ],
      ),
    );
  }

  // ── Members Row ───────────────────────────────────────────────────────────
  Widget _buildMembersRow() {
    final allMembers = _projects
        .expand((p) => p.members)
        .fold<Map<String, Member>>({}, (map, m) {
          map[m.name] = m;
          return map;
        })
        .values
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Members  •  ${allMembers.length}'),
        const SizedBox(height: 12),
        SizedBox(
          height: 70,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: allMembers.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final m = allMembers[i];
              return Column(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: m.color.withOpacity(0.2),
                    child: Text(
                      m.initials,
                      style: TextStyle(
                        color: m.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    m.initials,
                    style: const TextStyle(
                      color: Color(0xFF8A8A9A),
                      fontSize: 10,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Project Card ──────────────────────────────────────────────────────────
  Widget _buildProjectCard(Project project) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: project.color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: project.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  project.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              // Member stack
              SizedBox(
                width: project.members.length * 18.0 + 10,
                height: 28,
                child: Stack(
                  children: List.generate(project.members.length, (i) {
                    return Positioned(
                      left: i * 18.0,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: project.members[i].color,
                        child: Text(
                          project.members[i].initials[0],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Progress bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: project.progress,
                    minHeight: 7,
                    backgroundColor: Colors.white.withOpacity(0.07),
                    valueColor: AlwaysStoppedAnimation<Color>(project.color),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${(project.progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: project.color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Tasks
          ...project.tasks.map((task) => _buildTaskRow(task, project.color)),
        ],
      ),
    );
  }

  // ── Task Row ──────────────────────────────────────────────────────────────
  Widget _buildTaskRow(Task task, Color projectColor) {
    return GestureDetector(
      onTap: () => setState(() => task.isDone = !task.isDone),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: task.isDone ? projectColor : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: task.isDone ? projectColor : const Color(0xFF3A3A5C),
                  width: 1.5,
                ),
              ),
              child: task.isDone
                  ? const Icon(Icons.check, color: Colors.white, size: 13)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                task.title,
                style: TextStyle(
                  color: task.isDone
                      ? const Color(0xFF555570)
                      : const Color(0xFFCCCCDD),
                  decoration: task.isDone ? TextDecoration.lineThrough : null,
                  fontSize: 13,
                ),
              ),
            ),
            CircleAvatar(
              radius: 10,
              backgroundColor: task.assigneeColor.withOpacity(0.2),
              child: Text(
                task.assigneeInitials[0],
                style: TextStyle(
                  color: task.assigneeColor,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section Label ─────────────────────────────────────────────────────────
  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF8A8A9A),
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }

  // ── Bottom Nav ────────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    const items = [
      {'icon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.folder_outlined, 'label': 'Projects'},
      {'icon': Icons.add_circle, 'label': ''},
      {'icon': Icons.people_outline, 'label': 'Team'},
      {'icon': Icons.person_outline, 'label': 'Profile'},
    ];

    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        border: Border(top: BorderSide(color: Color(0xFF2A2A3E))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final isAdd = i == 2;
          final isSelected = _selectedIndex == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedIndex = i),
            child: isAdd
                ? Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF9B59B6)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 22),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        items[i]['icon'] as IconData,
                        color: isSelected
                            ? const Color(0xFF6C63FF)
                            : const Color(0xFF555570),
                        size: 22,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        items[i]['label'] as String,
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFF6C63FF)
                              : const Color(0xFF555570),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
          );
        }),
      ),
    );
  }
}
