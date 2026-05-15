import 'package:flutter/material.dart';
import 'results_page.dart';
import 'task.dart'; 

class ComputingPage extends StatefulWidget {
  final String groupName;
  final List<String> members;
  final List<String> tasks;
  final List<List<int>> ratings;
  final DateTime deadline;

  const ComputingPage({
    super.key,
    required this.groupName,
    required this.members,
    required this.tasks,
    required this.ratings,
    required this.deadline,
  });

  @override
  State<ComputingPage> createState() => _ComputingPageState();
}

class _ComputingPageState extends State<ComputingPage> with TickerProviderStateMixin {
  late AnimationController _circleController;
  late Animation<double> _circleAnim;

  final List<bool> _stepsDone = List.filled(7, false);
  bool _computationDone = false;
  late List<List<double>> _shapleyScores;

  static const _stepTitles = [
    'Load skill ratings', 'Enumerate coalitions', 'Compute marginal contributions',
    'Apply Shapley formula', 'Build score matrix', 'Determine optimal loads', 'Finalize results',
  ];

  @override
  void initState() {
    super.initState();
    _shapleyScores = _computeShapley();
    _circleController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _circleAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _circleController, curve: Curves.easeOut));
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

  List<List<double>> _computeShapley() {
    final n = widget.members.length;
    final t = widget.tasks.length;
    final shapley = List.generate(n, (_) => List<double>.filled(t, 0.0));

    for (int taskIdx = 0; taskIdx < t; taskIdx++) {
      final r = List.generate(n, (m) => widget.ratings[m][taskIdx].toDouble());
      double v(List<int> subset) {
        if (subset.isEmpty) return 0.0;
        return subset.map((m) => r[m]).reduce((a, b) => a + b) / subset.length;
      }

      for (int i = 0; i < n; i++) {
        double phi = 0.0;
        final others = List.generate(n, (m) => m).where((m) => m != i).toList();
        final numSubsets = 1 << others.length; // Bitwise shift replaces dart:math pow

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
                    const Text('Computing Assignments ⚡', style: TextStyle(color: kTextDark, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.6)),
                    const SizedBox(height: 6),
                    const Text('Running the Shapley value algorithm across all member-task combinations.', style: TextStyle(color: kTextMid, fontSize: 13, height: 1.5)),
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: kBorder)),
                      child: Column(
                        children: [
                          AnimatedBuilder(
                            animation: _circleAnim,
                            builder: (_, __) => SizedBox(
                              width: 90, height: 90,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 90, height: 90,
                                    child: CircularProgressIndicator(
                                      value: _computationDone ? 1.0 : _circleAnim.value * 0.95,
                                      strokeWidth: 6,
                                      backgroundColor: kPrimary.withValues(alpha: 0.15),
                                      valueColor: const AlwaysStoppedAnimation<Color>(kPrimary),
                                    ),
                                  ),
                                  Icon(_computationDone ? Icons.check_rounded : Icons.memory_rounded, color: kPrimary, size: 36),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(_computationDone ? 'Computation complete!' : 'Computing…', style: TextStyle(color: _computationDone ? kPrimary : kTextDark, fontSize: 18, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: kBorder)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ALGORITHM STEPS', style: TextStyle(color: kTextLight, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                          const SizedBox(height: 16),
                          ...List.generate(_stepTitles.length, (i) {
                            return AnimatedOpacity(
                              opacity: _stepsDone[i] ? 1.0 : 0.35,
                              duration: const Duration(milliseconds: 300),
                              child: _stepRow(title: _stepTitles[i], done: _stepsDone[i]),
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
          Text('TaskFair', style: TextStyle(color: kPrimary, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
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
            width: 24, height: 24,
            decoration: BoxDecoration(color: done ? kMint.withValues(alpha: 0.3) : kBg, shape: BoxShape.circle, border: Border.all(color: done ? const Color(0xFF2D9E7E) : kBorder)),
            child: Icon(done ? Icons.check_rounded : Icons.circle_outlined, color: done ? const Color(0xFF2D9E7E) : kBorder, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(color: kTextDark, fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(color: kBg, border: Border(top: BorderSide(color: kBorder))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _computationDone ? () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ResultsPage(
                groupName: widget.groupName, members: widget.members, tasks: widget.tasks, shapleyScores: _shapleyScores, deadline: widget.deadline,
              )));
            } : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: _computationDone ? kPrimary : kPrimary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
                boxShadow: _computationDone ? [BoxShadow(color: kPrimary.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 4))] : [],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('View Results', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Text('Cancel Computation', style: TextStyle(color: kTextMid, fontWeight: FontWeight.w700, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}