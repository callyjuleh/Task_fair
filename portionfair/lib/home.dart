import 'package:flutter/material.dart';
import 'package:portionfair/login_page.dart';
import 'package:portionfair/main.dart';
import 'package:portionfair/task.dart';
import 'dashboard.dart';
import 'task.dart';

// ─── Green Theme Colors ───────────────────────────────────────────────────────
const kBg = Color(0xFF0A0F0A);
const kSurface = Color(0xFF111A11);
const kCard = Color(0xFF162016);
const kGreen = Color(0xFF22C55E);
const kGreenLight = Color(0xFF4ADE80);
const kGreenDark = Color(0xFF16A34A);
const kTextPrimary = Color(0xFFECFDF5);
const kTextSecondary = Color(0xFF86EFAC);
const kBorder = Color(0xFF1A3A1A);

// ─── Home Page (Landing/Hero Screen) ─────────────────────────────────────────
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildNavBar(context),
              _buildHeroSection(context),
              _buildStepsSection(),
              _buildFeatureCardsSection(),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
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
              color: kGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kGreen.withOpacity(0.3)),
            ),
            child: const Icon(Icons.grid_view_rounded, color: kGreen, size: 18),
          ),
          const SizedBox(width: 10),
          const Text(
            'TaskFair',
            style: TextStyle(
              color: kTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _goToDashboard(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [kGreen, kGreenDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: kGreen.withOpacity(0.35),
                    blurRadius: 16,
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

  // ── Hero Section ──────────────────────────────────────────────────────────
  Widget _buildHeroSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: kGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kGreen.withOpacity(0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, color: kGreenLight, size: 13),
                SizedBox(width: 6),
                Text(
                  'Powered by Shapley Value Theory',
                  style: TextStyle(
                    color: kGreenLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.0,
                height: 1.15,
              ),
              children: [
                TextSpan(
                  text: 'Tasks distributed.\n',
                  style: TextStyle(color: kTextPrimary),
                ),
                TextSpan(
                  text: 'Fairly.',
                  style: TextStyle(color: kGreen),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'TaskFair uses cooperative game theory to assign\nwork to the most capable person — based on\nself-reported skill ratings from every team member.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF6EE7B7),
              fontSize: 14,
              height: 1.65,
            ),
          ),
          const SizedBox(height: 36),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Primary CTA → Dashboard
              GestureDetector(
                onTap: () => _goToDashboard(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [kGreen, kGreenDark],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: kGreen.withOpacity(0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Create a Group',
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
              const SizedBox(width: 12),
              // Secondary — no-op scroll hint
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: kBorder, width: 1.5),
                ),
                child: const Text(
                  'How it works',
                  style: TextStyle(
                    color: kTextPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 4-Step Flow Section ───────────────────────────────────────────────────
  Widget _buildStepsSection() {
    final steps = [
      _StepData(
        number: '01',
        icon: Icons.group_add_rounded,
        label: 'Group Setup',
        description: 'Add members & define tasks to distribute',
      ),
      _StepData(
        number: '02',
        icon: Icons.star_rounded,
        label: 'Skill Rating',
        description: 'Each member rates their ability 1–5 per task',
      ),
      _StepData(
        number: '03',
        icon: Icons.bolt_rounded,
        label: 'Shapley Computation',
        description: 'Game-theory algorithm calculates fair scores',
      ),
      _StepData(
        number: '04',
        icon: Icons.check_circle_rounded,
        label: 'Task Assignment',
        description: 'Highest Shapley score earns each task',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: kBorder),
        ),
        child: Column(
          children: [
            Text(
              '4-STEP FLOW',
              style: TextStyle(
                color: kGreen.withOpacity(0.7),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(steps.length, (i) {
                return Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildStepItem(steps[i])),
                      if (i < steps.length - 1)
                        Padding(
                          padding: const EdgeInsets.only(top: 22),
                          child: Container(
                            width: 16,
                            height: 1,
                            color: kGreen.withOpacity(0.25),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem(_StepData step) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: kGreen.withOpacity(0.12),
            shape: BoxShape.circle,
            border: Border.all(color: kGreen.withOpacity(0.25)),
          ),
          child: Icon(step.icon, color: kGreenLight, size: 22),
        ),
        const SizedBox(height: 10),
        Text(
          step.number,
          style: const TextStyle(
            color: kGreen,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          step.label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: kTextPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          step.description,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: kTextSecondary.withOpacity(0.65),
            fontSize: 10.5,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // ── Feature Cards Section ─────────────────────────────────────────────────
  Widget _buildFeatureCardsSection() {
    final features = [
      _FeatureData(
        icon: Icons.verified_rounded,
        title: 'Provably Fair',
        description:
            'Shapley values are the only allocation satisfying efficiency, symmetry, and fairness axioms from cooperative game theory.',
      ),
      _FeatureData(
        icon: Icons.people_alt_rounded,
        title: 'Everyone Rates',
        description:
            'Every team member self-rates their skill. No manager assigns — the math decides based on collective input.',
      ),
      _FeatureData(
        icon: Icons.arrow_forward_rounded,
        title: 'Instant Output',
        description:
            'Once ratings are collected the algorithm runs in milliseconds and presents a clear assignment table.',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        children: features
            .map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _buildFeatureCard(f),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildFeatureCard(_FeatureData feature) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: kGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kGreen.withOpacity(0.2)),
            ),
            child: Icon(feature.icon, color: kGreenLight, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  feature.description,
                  style: TextStyle(
                    color: kTextSecondary.withOpacity(0.7),
                    fontSize: 13,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Navigation ────────────────────────────────────────────────────────────
  void _goToDashboard(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const TaskSetupPage()),
    );
  }
}

// ─── Data Helpers ─────────────────────────────────────────────────────────────
class _StepData {
  final String number;
  final IconData icon;
  final String label;
  final String description;
  const _StepData({
    required this.number,
    required this.icon,
    required this.label,
    required this.description,
  });
}

class _FeatureData {
  final IconData icon;
  final String title;
  final String description;
  const _FeatureData({
    required this.icon,
    required this.title,
    required this.description,
  });
}
