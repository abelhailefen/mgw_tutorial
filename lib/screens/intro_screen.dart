import 'package:flutter/material.dart';
import 'package:mgw_tutorial/screens/auth/login_screen.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'image': 'assets/images/exam_student.png',
      'title': 'Track Your Progress Like a Pro',
      'description':
          'Monitor your growth, assess your skills, and track your progress to stay ahead of the curve. Start practicing now and watch your results improve!',
    },
    {
      'image': 'assets/images/progress_chart.png',
      'title': 'Conquer Your Exams!',
      'description':
          'Get ready for success with Exit Exam Navigator! Prepare for Ethiopian exit exams using expert-curated materials and interactive tools that keep you on track.',
    },
    {
      'image': 'assets/images/explore_features.png', // Your customized image
      'title': 'Explore More Features',
      'description': 'Discover additional tools and resources to enhance your learning experience.',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  void _skip() {
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // Dark background
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  // Fullscreen Image
                  Image.asset(
                    _pages[index]['image'],
                    fit: BoxFit.cover,
                    width: size.width,
                    height: size.height,
                  ),
                  // Overlay for better text visibility
                  Container(
                    color: Colors.black.withOpacity(0.55),
                  ),
                  // Centered Column with Title, Description, Button
                  Positioned.fill(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Title
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            _pages[index]['title'],
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFFD700), // Yellow title
                              shadows: [
                                Shadow(
                                  blurRadius: 8,
                                  color: Colors.black87,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Description
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Text(
                            _pages[index]['description'],
                            style: const TextStyle(
                              fontSize: 17,
                              color: Color(0xFFEEEEEE), // Lighter text for dark bg
                              height: 1.5,
                              shadows: [
                                Shadow(
                                  blurRadius: 6,
                                  color: Colors.black45,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 100), // For button/bullets
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          // Skip Button
          Positioned(
            top: 40,
            right: 20,
            child: TextButton(
              onPressed: _skip,
              child: const Text(
                'SKIP',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFFFFD700), // Yellow SKIP text
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  shadows: [
                    Shadow(
                      blurRadius: 4,
                      color: Colors.black54,
                      offset: Offset(1, 2),
                    )
                  ],
                ),
              ),
            ),
          ),
          // Page indicator bullets
          Positioned(
            bottom: 90,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 7),
                  width: _currentPage == index ? 18 : 10,
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: _currentPage == index
                        ? const Color(0xFFFFD700)
                        : const Color(0x66FFD700),
                  ),
                );
              }),
            ),
          ),
          // Next / Get Started Button
          Positioned(
            bottom: 28,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: _nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                  shadowColor: Colors.black54,
                ),
                child: Text(
                  _currentPage == _pages.length - 1 ? 'GET STARTED' : 'NEXT',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}