import 'dart:math';
import 'package:flutter/material.dart';
import 'results_page.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
const _kBg = Color(0xFF0A0F0A);
const _kSurface = Color(0xFF111A11);
const _kCard = Color(0xFF162016);
const _kGreen = Color(0xFF22C55E);
const _kGreenDark = Color(0xFF16A34A);
const _kBorder = Color(0xFF1A3A1A);
const _kTextPrimary = Color(0xFFECFDF5);
const _kTextMuted = Color(0xFF6EE7B7);

// ─── Computing Page ───────────────────────────────────────────────────────────
class ComputingPage extends StatefulWidget {
  final String groupName;
  final List<String> members;
  final List<String> tasks;
  final List<List<int>> ratings; // ratings[member][task]

  const ComputingPage({
    super.key,
    required this.groupName,
    required this.members,
    required this.tasks,
    required this.ratings,
  });

  @override
  State<ComputingPage> createState() => _ComputingPageState();
}

class _ComputingPageState extends State<ComputingPage>
    with TickerProviderStateMixin {
  late AnimationController _circleController;
  late AnimationController _stepsController;
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
    'Determine assignments',
    'Finalise results',
  ];
  static const _stepSubs = [
    'Reading ratings matrix from store',
    'All 2ⁿ subsets per task (excl. member i)',
    'v(S∪{i}) − v(S) for every subset S',
    'φᵢ = Σ [ v(S∪{i}) − v(S) ]',
    'Members × tasks grid of Shapley scores',
    'Each task → member with the highest score',
    'Saving assignments for display',
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

    _stepsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
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

  /// Shapley value computation
  List<List<double>> _computeShapley() {
    final n = widget.members.length;
    final t = widget.tasks.length;

    // Result: shapley[member][task]
    final shapley = List.generate(n, (_) => List<double>.filled(t, 0.0));

    for (int taskIdx = 0; taskIdx < t; taskIdx++) {
      // ratings for this task per member
      final r = List.generate(n, (m) => widget.ratings[m][taskIdx].toDouble());

      // Cooperative game: v(S) = average rating of members in S
      double v(List<int> subset) {
        if (subset.isEmpty) return 0.0;
        return subset.map((m) => r[m]).reduce((a, b) => a + b) / subset.length;
      }

      for (int i = 0; i < n; i++) {
        double phi = 0.0;
        // Enumerate all subsets NOT containing i
        final others = List.generate(n, (m) => m).where((m) => m != i).toList();
        final numSubsets = pow(2, others.length).toInt();

        for (int mask = 0; mask < numSubsets; mask++) {
          final subset = <int>[];
          for (int bit = 0; bit < others.length; bit++) {
            if ((mask >> bit) & 1 == 1) subset.add(others[bit]);
          }
          final s = subset.length;
          final sFactorial = _factorial(s);
          final nMinusSMinus1Factorial = _factorial(n - s - 1);
          final nFactorial = _factorial(n);

          final weight = sFactorial * nMinusSMinus1Factorial / nFactorial;
          phi += weight * (v([...subset, i]) - v(subset));
        }

        shapley[i][taskIdx] = double.parse(phi.toStringAsFixed(2));
      }
    }

    return shapley;
  }

  int _factorial(int n) {
    if (n <= 1) return 1;
    return n * _factorial(n - 1);
  }

  @override
  void dispose() {
    _circleController.dispose();
    _stepsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final memberCount = widget.members.length;
    final taskCount = widget.tasks.length;
    // Total evaluations: sum of all coalition evaluations per task
    final evaluations = taskCount * pow(2, memberCount).toInt();

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildNavBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Computing Assignments',
                      style: TextStyle(
                        color: _kTextPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Running the Shapley value algorithm across all member-task combinations.',
                      style: TextStyle(
                        color: _kTextMuted,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Progress circle card
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: _kCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _kBorder),
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
                                      strokeWidth: 5,
                                      backgroundColor: _kGreen.withOpacity(
                                        0.15,
                                      ),
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                            _kGreen,
                                          ),
                                    ),
                                  ),
                                  Icon(
                                    _computationDone
                                        ? Icons.check_rounded
                                        : Icons.memory_rounded,
                                    color: _kGreen,
                                    size: 32,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              _computationDone
                                  ? 'Computation complete!'
                                  : 'Computing…',
                              key: ValueKey(_computationDone),
                              style: TextStyle(
                                color: _computationDone
                                    ? _kTextPrimary
                                    : _kTextMuted,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _computationDone
                                ? 'All assignments are ready.'
                                : 'Please wait…',
                            style: TextStyle(
                              color: _kTextMuted.withOpacity(0.6),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(height: 0.5, color: _kBorder),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _statBox('$memberCount', 'Members'),
                              Container(width: 1, height: 40, color: _kBorder),
                              _statBox('$taskCount', 'Tasks'),
                              Container(width: 1, height: 40, color: _kBorder),
                              _statBox('$evaluations', 'Evaluations'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Steps card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _kCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _kBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ALGORITHM STEPS',
                            style: TextStyle(
                              color: _kTextMuted.withOpacity(0.7),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
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
                                sub: _stepSubs[i],
                                done: _stepsDone[i],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Formula card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1A0D),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF1A3A1A)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SHAPLEY FORMULA',
                            style: TextStyle(
                              color: _kTextMuted.withOpacity(0.7),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'φᵢ = (1/n!) × Σ [ v(S∪{i}) − v(S) ]',
                            style: TextStyle(
                              color: _kGreen,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Averaged over all possible member orderings.',
                            style: TextStyle(
                              color: _kTextMuted.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
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
      bottomNavigationBar: _buildBottomBar(context),
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

  Widget _stepRow({
    required String title,
    required String sub,
    required bool done,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: done ? _kGreen.withOpacity(0.15) : _kSurface,
              shape: BoxShape.circle,
              border: Border.all(color: done ? _kGreen : _kBorder),
            ),
            child: Center(
              child: Icon(
                done ? Icons.check_rounded : Icons.circle_outlined,
                color: done ? _kGreen : _kBorder,
                size: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _kTextPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  sub,
                  style: TextStyle(
                    color: _kTextMuted.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (done)
            Text(
              'Done',
              style: TextStyle(
                color: _kGreen,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _statBox(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: _kTextPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: _kTextMuted.withOpacity(0.7), fontSize: 12),
        ),
      ],
    );
  }

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
            onTap: _computationDone
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ResultsPage(
                          groupName: widget.groupName,
                          members: widget.members,
                          tasks: widget.tasks,
                          shapleyScores: _shapleyScores,
                        ),
                      ),
                    );
                  }
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _computationDone
                      ? [_kGreen, _kGreenDark]
                      : [
                          _kGreen.withOpacity(0.3),
                          _kGreenDark.withOpacity(0.3),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: _computationDone
                    ? [
                        BoxShadow(
                          color: _kGreen.withOpacity(0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View Results',
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
}
