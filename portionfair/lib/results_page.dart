import 'package:flutter/material.dart';
import 'task.dart'; // Palette & buildStepper
import 'dashboard_page.dart';

class ResultsPage extends StatelessWidget {
  final String groupName;
  final List<String> members;
  final List<String> tasks;
  final List<List<double>> shapleyScores;
  final DateTime deadline;

  const ResultsPage({
    super.key,
    required this.groupName,
    required this.members,
    required this.tasks,
    required this.shapleyScores,
    required this.deadline,
  });

  /// Load-Balanced Greedy Assignment
  List<int> get _assignments {
    final int numTasks = tasks.length;
    final int numMembers = members.length;
    
    final List<int> assignments = List.filled(numTasks, -1);
    final List<int> memberLoads = List.filled(numMembers, 0);
    
    final int maxLoad = (numTasks / numMembers).ceil();

    List<int> taskOrder = List.generate(numTasks, (i) => i);
    taskOrder.sort((a, b) {
      double maxA = shapleyScores.map((m) => m[a]).reduce((x, y) => x > y ? x : y);
      double maxB = shapleyScores.map((m) => m[b]).reduce((x, y) => x > y ? x : y);
      return maxB.compareTo(maxA);
    });

    for (int t in taskOrder) {
      int bestMember = -1;
      double bestScore = -double.infinity;

      for (int m = 0; m < numMembers; m++) {
        if (memberLoads[m] < maxLoad) {
          if (shapleyScores[m][t] > bestScore) {
            bestScore = shapleyScores[m][t];
            bestMember = m;
          }
        }
      }
      if (bestMember == -1) bestMember = 0; 
      
      assignments[t] = bestMember;
      memberLoads[bestMember]++;
    }
    
    return assignments;
  }

  @override
  Widget build(BuildContext context) {
    final assignments = _assignments;

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildNavBar(),
            buildStepper(activeStep: 3),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: kMint.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(20)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, color: Color(0xFF2D9E7E), size: 14),
                          SizedBox(width: 6),
                          Text('Computation complete', style: TextStyle(color: Color(0xFF2D9E7E), fontSize: 12, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Fair Assignments 🎯', style: TextStyle(color: kTextDark, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.8)),
                    const SizedBox(height: 6),
                    const Text('Tasks are load-balanced. No one gets overloaded, but experts still get the tasks they are best at.', style: TextStyle(color: kTextMid, fontSize: 13, height: 1.5)),
                    const SizedBox(height: 24),
                    _buildAssignmentGrid(assignments),
                    const SizedBox(height: 24),
                    _buildScoreMatrix(assignments),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context, assignments),
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

  Widget _buildAssignmentGrid(List<int> assignments) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final cols = constraints.maxWidth > 560 ? 4 : 2;
      final itemWidth = (constraints.maxWidth - (cols - 1) * 12) / cols;
      return Wrap(
        spacing: 12, runSpacing: 12,
        children: List.generate(tasks.length, (taskIdx) {
          final memberIdx = assignments[taskIdx];
          final color = getAvatarColor(memberIdx);
          return SizedBox(
            width: itemWidth,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tasks[taskIdx], style: const TextStyle(color: kTextDark, fontSize: 13, fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(width: 20, height: 20, decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle), child: Center(child: Text(members[memberIdx][0].toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)))),
                      const SizedBox(width: 6),
                      Expanded(child: Text(members[memberIdx], style: const TextStyle(color: kTextMid, fontSize: 12, fontWeight: FontWeight.w600))),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      );
    });
  }

  Widget _buildScoreMatrix(List<int> assignments) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: kBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SHAPLEY SCORE MATRIX', style: TextStyle(color: kTextLight, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              defaultColumnWidth: const IntrinsicColumnWidth(),
              children: [
                TableRow(
                  children: [
                    const Padding(padding: EdgeInsets.only(right: 20, bottom: 10), child: Text('Member', style: TextStyle(color: kTextLight, fontSize: 12, fontWeight: FontWeight.w700))),
                    ...tasks.map((task) => Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text(task.split(' ').first, style: const TextStyle(color: kTextLight, fontSize: 10)))),
                  ],
                ),
                ...members.asMap().entries.map((mEntry) {
                  final mi = mEntry.key;
                  final color = getAvatarColor(mi);
                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 20, bottom: 10),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(width: 20, height: 20, decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle), child: Center(child: Text(mEntry.value[0].toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)))),
                          const SizedBox(width: 8),
                          Text(mEntry.value, style: const TextStyle(color: kTextDark, fontSize: 13, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                      ...tasks.asMap().entries.map((tEntry) {
                        final ti = tEntry.key;
                        final isAssigned = assignments[ti] == mi;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(color: isAssigned ? color.withValues(alpha: 0.15) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                              child: Text(shapleyScores[mi][ti].toStringAsFixed(1), style: TextStyle(color: isAssigned ? color : kTextMid, fontSize: 12, fontWeight: isAssigned ? FontWeight.w800 : FontWeight.w500)),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, List<int> assignments) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(color: kBg, border: Border(top: BorderSide(color: kBorder))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => DashboardPage(
                groupName: groupName, members: members, tasks: tasks, assignments: assignments, deadline: deadline,
              )));
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: kPrimary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: kPrimary.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 4))],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Go to Group Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                  SizedBox(width: 8),
                  Icon(Icons.space_dashboard_rounded, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text('Back to Home', style: TextStyle(color: kTextMid, fontWeight: FontWeight.w700, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}