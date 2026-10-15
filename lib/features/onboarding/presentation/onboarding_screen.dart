import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'DukaanPilot AI',
      'subtitle': 'Your smart assistant for everyday shop management.',
      'icon': Icons.storefront_rounded,
      'color': const Color(0xFF4F46E5),
    },
    {
      'title': 'Zero Spreadsheets',
      'subtitle': 'Track stock effortlessly without complicated spreadsheets.',
      'icon': Icons.inventory_2_rounded,
      'color': const Color(0xFF0D9488),
    },
    {
      'title': 'Voice-First Management',
      'subtitle': 'Speak your sales and stock updates in natural language.',
      'icon': Icons.mic_rounded,
      'color': const Color(0xFF6366F1),
    },
    {
      'title': 'Instant Bill Scanning',
      'subtitle': 'Scan supplier invoices directly using your camera.',
      'icon': Icons.document_scanner_rounded,
      'color': const Color(0xFFEA580C),
    },
    {
      'title': 'Daily Business Insights',
      'subtitle': 'Get clear daily summaries, udhaar tracking, and low-stock alerts.',
      'icon': Icons.insights_rounded,
      'color': const Color(0xFF2563EB),
    },
  ];

  void _onNext() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() async {
    await ref.read(authNotifierProvider.notifier).completeOnboarding();
    if (mounted) {
      context.go('/business-setup');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_currentPage < _slides.length - 1)
            TextButton(
              onPressed: _finishOnboarding,
              child: Text(
                'Skip',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            color: (slide['color'] as Color).withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              slide['icon'] as IconData,
                              size: 64,
                              color: slide['color'] as Color,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          slide['title'] as String,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          slide['subtitle'] as String,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.65),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Pagination Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (index) {
                final isSelected = _currentPage == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isSelected ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 36),

            // Bottom Action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: ElevatedButton(
                onPressed: _onNext,
                child: Text(
                  _currentPage == _slides.length - 1 ? 'Get Started' : 'Next',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
