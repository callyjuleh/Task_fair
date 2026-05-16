import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'results_page.dart';
import 'task.dart';
import 'login_page.dart'; // for kBaseUrl

class ComputingPage extends StatefulWidget {
  final String groupName;
  final List<String> members;
  final List<String> tasks;
  final List<List<int>> ratings;
  final DateTime? deadline;
  final List<int> taskDifficulties;
  // ─── NEW: DB identifiers ─────────────────────────────────────────────────────
  final String projectId;
  final List<String> memberIds;
  final List<String> taskIds;
  final bool leaderAlreadySaved; // leader ratings saved in LeaderRatingPage

  const ComputingPage({
    super.key,
    required this.groupName,
    required this.members,
    required this.tasks,
    required this.ratings,
    required this.deadline,
    required this.taskDifficulties,
    required this.projectId,
    required this.memberIds,
    required this.taskIds,
    this.leaderAlreadySaved = false,
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
  bool _dbSaveFailed = false;
  late List<List<double>> _shapleyScores;

  static const _stepTitles = [
    'Save ratings to database',
    'Enumerate coalitions',
    'Compute marginal contributions',
    'Apply Shapley formula',
    'Build score matrix',
    'Determine optimal loads',
    'Finalize & save results',
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
    _saveAndRun();
  }

  // ─── Save all ratings to DB then run step animation ───────────────────────
  Future<void> _saveAndRun() async {
    _circleController.forward();
    await Future.delayed(const Duration(milliseconds: 300));

    // Step 1: save each member's ratings via POST /ratings
    // (skip leader index 0 if their ratings were already saved in LeaderRatingPage)
    try {
      for (int mi = 0; mi < widget.members.length; mi++) {
        if (mi == 0 && widget.leaderAlreadySaved) continue;

        // Build ratings map: { taskId: skillRating }
        final Map<String, int> ratingsMap = {};
        for (int ti = 0; ti < widget.tasks.length; ti++) {
          ratingsMap[widget.taskIds[ti]] = widget.ratings[mi][ti];
        }

        final res = await http.post(
          Uri.parse('$kBaseUrl/ratings'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'member_id': widget.memberIds[mi],
            'ratings': ratingsMap,
          }),
        );

        if (res.statusCode != 200) {
          setState(() => _dbSaveFailed = true);
        }
      }

      if (mounted) setState(() => _stepsDone[0] = true);
      await Future.delayed(const Duration(milliseconds: 350));

      // Steps 2–6: animate local computation steps
      for (int i = 1; i <= 5; i++) {
        await Future.delayed(Duration(milliseconds: 300 + i * 120));
        if (mounted) setState(() => _stepsDone[i] = true);
      }

      // Step 7: call /compute-shapley on server to persist results table
      await http.post(
        Uri.parse('$kBaseUrl/compute-shapley'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'project_id': widget.projectId}),
      );

      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) setState(() => _stepsDone[6] = true);
    } catch (_) {
      // Network error — still mark steps done so user can see results locally
      for (int i = 0; i < 7; i++) {
        if (mounted) setState(() => _stepsDone[i] = true);
      }
      if (mounted) setState(() => _dbSaveFailed = true);
    }

    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() => _computationDone = true);
  }

  // ─── Local Shapley computation (for instant UI display) ───────────────────
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

  // ─── Fair assignments using Shapley scores ────────────────────────────────
  // Rules:
  //  1. Every task gets exactly one primary assignee (highest Shapley score).
  //  2. If tasks > members, members can receive multiple tasks — assigned to
  //     whoever has the highest score for that task (load-balanced as tiebreak).
  //  3. Every member receives at least one task when tasks >= members.
  List<List<int>> get _fairAssignments {
    final int numTasks = widget.tasks.length;
    final int numMembers = widget.members.length;

    // Each task gets one assignee list (primary + any co-assignees)
    final List<List<int>> assignments = List.generate(numTasks, (_) => <int>[]);

    // Track load (number of tasks assigned per member)
    final List<int> load = List.filled(numMembers, 0);

    // Sort tasks by "contention" — highest spread between best and second-best
    // means that task has a clear best candidate; assign it first.
    final List<int> taskOrder = List.generate(numTasks, (i) => i);
    taskOrder.sort((a, b) {
      final scoresA = List.generate(numMembers, (m) => _shapleyScores[m][a])
        ..sort((x, y) => y.compareTo(x));
      final scoresB = List.generate(numMembers, (m) => _shapleyScores[m][b])
        ..sort((x, y) => y.compareTo(x));
      final spreadA = scoresA.length > 1 ? scoresA[0] - scoresA[1] : scoresA[0];
      final spreadB = scoresB.length > 1 ? scoresB[0] - scoresB[1] : scoresB[0];
      return spreadB.compareTo(spreadA);
    });

    // First pass: assign each task to the best available member (prefer least loaded)
    final Set<int> assignedOnce = {};
    for (final t in taskOrder) {
      // Rank members by Shapley score for this task, break ties by load (prefer lighter)
      final candidates = List.generate(numMembers, (m) => m)
        ..sort((a, b) {
          final scoreDiff = _shapleyScores[b][t].compareTo(
            _shapleyScores[a][t],
          );
          if (scoreDiff != 0) return scoreDiff;
          return load[a].compareTo(load[b]); // lighter load wins tie
        });

      // Prefer members not yet assigned any task to ensure everyone gets at least one
      int chosen = candidates.firstWhere(
        (m) => !assignedOnce.contains(m),
        orElse: () => candidates.first, // all assigned: pick highest scorer
      );

      assignments[t].add(chosen);
      assignedOnce.add(chosen);
      load[chosen]++;
    }

    // Second pass: if any member was never assigned (tasks < members scenario),
    // assign them to the task where they add the most value relative to current assignee
    final List<int> unassigned = List.generate(
      numMembers,
      (m) => m,
    ).where((m) => !assignedOnce.contains(m)).toList();

    for (final m in unassigned) {
      // Find the task where this member's score is closest to (or exceeds) the
      // current assignee's score — best collaborative fit
      int bestTask = 0;
      double bestFit = double.negativeInfinity;

      for (int t = 0; t < numTasks; t++) {
        final currentAssigneeScore = assignments[t].isNotEmpty
            ? _shapleyScores[assignments[t].first][t]
            : 0.0;
        // Prefer tasks where the member is strong AND the current assignee is weak
        final fit = _shapleyScores[m][t] - currentAssigneeScore * 0.5;
        if (fit > bestFit) {
          bestFit = fit;
          bestTask = t;
        }
      }

      assignments[bestTask].add(m);
      load[m]++;
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
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: kCard,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: kBorder),
                      ),
                      child: Column(
                        children: [
                          AnimatedBuilder(
                            animation: _circleAnim,
                            builder: (_, __) => SizedBox(
                              width: 100,
                              height: 100,
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
                          if (_dbSaveFailed) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.red.withValues(alpha: 0.3),
                                ),
                              ),
                              child: const Text(
                                '⚠️ Could not reach server — results shown locally but not saved to database.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
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
                          projectId: '',
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
