import 'package:flutter/material.dart';
import 'results_page.dart';
import 'task.dart';

class ComputingPage extends StatefulWidget {
  final String groupName;
  final List<String> members;
  final List<String> tasks;
  final List<List<int>> ratings;
  final DateTime? deadline;
  final List<int> taskDifficulties;

  const ComputingPage({
    super.key,
    required this.groupName,
    required this.members,
    required this.tasks,
    required this.ratings,
    required this.deadline,
    required this.taskDifficulties,
  });

  @override
  State<ComputingPage> createState() => _ComputingPageState();
}

class _ComputingPageState extends State<ComputingPage>
    with TickerProviderStateMixin {
  late AnimationController _circleController;
  late Animation<double> _circleAnim;

  final List<bool> _stepsDone = List.filled(7, false);
  bool _computationDone = false;
  late List<List<double>> _shapleyScores;

  static const _stepTitles = [
    'Load skill ratings',
    'Enumerate coalitions',
    'Compute marginal contributions',
    'Apply Shapley formula',
    'Build score matrix',
    'Determine optimal loads',
    'Finalize results',
  ];

  @override
  void initState() {
    super.initState();
    _shapleyScores = _computeShapley();
    _circleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _circleAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _circleController, curve: Curves.easeOut),
    );
    _runSteps();
  }

  Future<void> _runSteps() async {
    _circleController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    for (int i = 0; i < _stepTitles.length; i++) {
      await Future.delayed(Duration(milliseconds: 300 + i * 120));
      if (mounted) setState(() => _stepsDone[i] = true);
    }
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() => _computationDone = true);
  }

  // ─── Shapley value computation ─────────────────────────────────────────────
  List<List<double>> _computeShapley() {
    final n = widget.members.length;
    final t = widget.tasks.length;
    final shapley = List.generate(n, (_) => List<double>.filled(t, 0.0));

    for (int taskIdx = 0; taskIdx < t; taskIdx++) {
      final difficulty = widget.taskDifficulties[taskIdx].toDouble();
      final r = List.generate(
        n,
        (m) => widget.ratings[m][taskIdx].toDouble() * difficulty,
      );

      double v(List<int> subset) {
        if (subset.isEmpty) return 0.0;
        return subset.map((m) => r[m]).reduce((a, b) => a + b) / subset.length;
      }

      for (int i = 0; i < n; i++) {
        double phi = 0.0;
        final others = List.generate(n, (m) => m).where((m) => m != i).toList();
        final numSubsets = 1 << others.length;

        for (int mask = 0; mask < numSubsets; mask++) {
          final subset = <int>[];
          for (int bit = 0; bit < others.length; bit++) {
            if ((mask >> bit) & 1 == 1) subset.add(others[bit]);
          }
          final s = subset.length;
          final weight = _factorial(s) * _factorial(n - s - 1) / _factorial(n);
          phi += weight * (v([...subset, i]) - v(subset));
        }
        shapley[i][taskIdx] = double.parse(phi.toStringAsFixed(2));
      }
    }
    return shapley;
  }

  int _factorial(int n) => n <= 1 ? 1 : n * _factorial(n - 1);

  // ─── Fair multi-assignee assignment ───────────────────────────────────────
  //
  // Problem: if tasks < members, some members get no task.
  // Solution (2-step):
  //
  // Step 1 — Primary assignment:
  //   Sort tasks by score spread desc (most contested first).
  //   For each task, pick the highest-scoring member not yet assigned.
  //   If all members already assigned (tasks > members), pick least-loaded.
  //
  // Step 2 — Co-assign leftover members:
  //   Find members with no task yet (leftover).
  //   Sort leftover by overall score desc (best helpers first).
  //   For each leftover member, find the task with the lowest average
  //   Shapley score among current assignees (needs the most help),
  //   weighted by this member's fit: composite = avg - (member_fit × 0.3).
  //   Co-assign the leftover member to that task.
  //
  // Result: every member gets at least one task; hard/low-score tasks
  // get collaborative support.
  //
  List<List<int>> get _fairAssignments {
    final int numTasks = widget.tasks.length;
    final int numMembers = widget.members.length;

    // ── Step 1: greedy primary assignment ────────────────────────────────────
    final List<int> taskOrder = List.generate(numTasks, (i) => i);
    taskOrder.sort((a, b) {
      final sa = _shapleyScores.map((m) => m[a]).toList()
        ..sort((x, y) => y.compareTo(x));
      final sb = _shapleyScores.map((m) => m[b]).toList()
        ..sort((x, y) => y.compareTo(x));
      final spreadA = sa.length > 1 ? sa[0] - sa[1] : sa[0];
      final spreadB = sb.length > 1 ? sb[0] - sb[1] : sb[0];
      return spreadB.compareTo(spreadA);
    });

    final List<List<int>> assignments = List.generate(numTasks, (_) => <int>[]);
    final Set<int> assignedMembers = {};

    for (final t in taskOrder) {
      final candidates = List.generate(numMembers, (m) => m)
        ..sort((a, b) => _shapleyScores[b][t].compareTo(_shapleyScores[a][t]));

      int chosen = -1;
      for (final m in candidates) {
        if (!assignedMembers.contains(m)) {
          chosen = m;
          break;
        }
      }

      // Fallback: all members assigned (tasks > members) → pick least-loaded
      if (chosen == -1) {
        final loads = <int, int>{};
        for (final list in assignments) {
          for (final m in list) loads[m] = (loads[m] ?? 0) + 1;
        }
        chosen = candidates.reduce(
          (a, b) => (loads[a] ?? 0) <= (loads[b] ?? 0) ? a : b,
        );
      }

      assignments[t].add(chosen);
      assignedMembers.add(chosen);
    }

    // ── Step 2: co-assign leftover members to weakest tasks ──────────────────
    final List<int> unassigned = List.generate(
      numMembers,
      (m) => m,
    ).where((m) => !assignedMembers.contains(m)).toList();

    // Sort unassigned by overall average score desc (best helpers first)
    unassigned.sort((a, b) {
      final scoreA = _shapleyScores[a].reduce((x, y) => x + y) / numTasks;
      final scoreB = _shapleyScores[b].reduce((x, y) => x + y) / numTasks;
      return scoreB.compareTo(scoreA);
    });

    for (final m in unassigned) {
      // Find the task that needs the most help:
      // lowest avg assignee score + high fit for this member
      int weakestTask = 0;
      double lowestComposite = double.infinity;

      for (int t = 0; t < numTasks; t++) {
        final assignees = assignments[t];
        final avg = assignees.isEmpty
            ? 0.0
            : assignees
                      .map((a) => _shapleyScores[a][t])
                      .reduce((x, y) => x + y) /
                  assignees.length;

        final fit = _shapleyScores[m][t];
        final composite = avg - fit * 0.3;

        if (composite < lowestComposite) {
          lowestComposite = composite;
          weakestTask = t;
        }
      }

      assignments[weakestTask].add(m);
    }

    return assignments;
  }

  @override
  void dispose() {
    _circleController.dispose();
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
            buildStepper(activeStep: 2),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Computing Assignments ⚡',
                      style: TextStyle(
                        color: kTextDark,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Running the Shapley value algorithm across all member-task combinations.',
                      style: TextStyle(
                        color: kTextMid,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: kCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: kBorder),
                      ),
                      child: Column(
                        children: [
                          AnimatedBuilder(
                            animation: _circleAnim,
                            builder: (_, __) => SizedBox(
                              width: 90,
                              height: 90,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 90,
                                    height: 90,
                                    child: CircularProgressIndicator(
                                      value: _computationDone
                                          ? 1.0
                                          : _circleAnim.value * 0.95,
                                      strokeWidth: 6,
                                      backgroundColor: kPrimary.withValues(
                                        alpha: 0.15,
                                      ),
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                            kPrimary,
                                          ),
                                    ),
                                  ),
                                  Icon(
                                    _computationDone
                                        ? Icons.check_rounded
                                        : Icons.memory_rounded,
                                    color: kPrimary,
                                    size: 36,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _computationDone
                                ? 'Computation complete!'
                                : 'Computing…',
                            style: TextStyle(
                              color: _computationDone ? kPrimary : kTextDark,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: kCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: kBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ALGORITHM STEPS',
                            style: TextStyle(
                              color: kTextLight,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...List.generate(_stepTitles.length, (i) {
                            return AnimatedOpacity(
                              opacity: _stepsDone[i] ? 1.0 : 0.35,
                              duration: const Duration(milliseconds: 300),
                              child: _stepRow(
                                title: _stepTitles[i],
                                done: _stepsDone[i],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
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

  Widget _stepRow({required String title, required bool done}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: done ? kMint.withValues(alpha: 0.3) : kBg,
              shape: BoxShape.circle,
              border: Border.all(
                color: done ? const Color(0xFF2D9E7E) : kBorder,
              ),
            ),
            child: Icon(
              done ? Icons.check_rounded : Icons.circle_outlined,
              color: done ? const Color(0xFF2D9E7E) : kBorder,
              size: 14,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: kTextDark,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
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
            onTap: _computationDone
                ? () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ResultsPage(
                          groupName: widget.groupName,
                          members: widget.members,
                          tasks: widget.tasks,
                          shapleyScores: _shapleyScores,
                          deadline: widget.deadline,
                          taskDifficulties: widget.taskDifficulties,
                          assignments: _fairAssignments,
                        ),
                      ),
                    );
                  }
                : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: _computationDone
                    ? kPrimary
                    : kPrimary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
                boxShadow: _computationDone
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
                    'View Results',
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
              'Cancel Computation',
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
}
