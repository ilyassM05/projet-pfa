import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/course_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/course_model.dart';
import '../../services/recommendation_service.dart';
import '../../widgets/course_card.dart';
import '../auth/login_screen.dart';
import '../courses/courses_screen.dart';
import '../courses/course_detail_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<CourseModel> _recommendedCourses = [];
  bool _loadingRecommendations = true;
  final RecommendationService _recommendationService = RecommendationService();

  @override
  void initState() {
    super.initState();
    // Load courses on initialization
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final courseProvider = Provider.of<CourseProvider>(
        context,
        listen: false,
      );
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Initialize regular data
      await courseProvider.initialize();

      // Load recommendations (category-based)
      if (authProvider.currentUser != null) {
        final recs = await _recommendationService.getRecommendations(
          authProvider.currentUser!.userId,
        );
        if (mounted) {
          setState(() => _recommendedCourses = recs);
        }
      }
      if (mounted) setState(() => _loadingRecommendations = false);
    });
  }

  @override
  void dispose() {
    _recommendationService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context);
    final featuredCourses = courseProvider.featuredCourses;
    final recentCourses = courseProvider.recentCourses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('E-Learning DApp'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            tooltip: 'Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await courseProvider.initialize();
          // specific refresh for recs
          final authProvider = Provider.of<AuthProvider>(
            context,
            listen: false,
          );
          if (authProvider.currentUser != null) {
            final recs = await _recommendationService.getRecommendations(
              authProvider.currentUser!.userId,
            );
            if (mounted) setState(() => _recommendedCourses = recs);
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.spacingL),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome Back!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Continue your learning journey',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CoursesScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primaryColor,
                      ),
                      child: const Text('Browse All Courses'),
                    ),
                  ],
                ),
              ),

              // Error Message
              if (courseProvider.errorMessage != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(AppTheme.spacingL),
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.1),
                    border: Border.all(color: AppTheme.errorColor),
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppTheme.errorColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        courseProvider.errorMessage!,
                        style: const TextStyle(color: AppTheme.errorColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => courseProvider.initialize(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),

              // Recommended For You (AI)
              if (_recommendedCourses.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.spacingL,
                        AppTheme.spacingL,
                        AppTheme.spacingL,
                        0,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            color: AppTheme.accentColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Recommended for You',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: AppTheme.accentColor,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    SizedBox(
                      height: 320,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingL,
                        ),
                        itemCount: _recommendedCourses.length,
                        itemBuilder: (context, index) {
                          final course = _recommendedCourses[index];
                          return Container(
                            width: 260,
                            margin: const EdgeInsets.only(
                              right: AppTheme.spacingM,
                            ),
                            child: CourseCard(
                              course: course,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        CourseDetailScreen(course: course),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

              // Featured Courses
              if (featuredCourses.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingL,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Featured Courses',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CoursesScreen(),
                                ),
                              );
                            },
                            child: const Text('See All'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    SizedBox(
                      height: 320,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingL,
                        ),
                        itemCount: featuredCourses.length,
                        itemBuilder: (context, index) {
                          final course = featuredCourses[index];
                          return Container(
                            width: 260,
                            margin: const EdgeInsets.only(
                              right: AppTheme.spacingM,
                            ),
                            child: CourseCard(
                              course: course,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        CourseDetailScreen(course: course),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                )
              else if (courseProvider.isLoading)
                const Padding(
                  padding: EdgeInsets.all(AppTheme.spacingL),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.school_outlined,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 8),
                        const Text('No courses found'),
                        if (courseProvider.allCourses.isEmpty)
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProfileScreen(),
                              ),
                            ),
                            child: const Text('Go to Profile to Seed Data'),
                          ),
                      ],
                    ),
                  ),
                ),

              // Recent Courses
              if (recentCourses.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Courses',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CoursesScreen(),
                                ),
                              );
                            },
                            child: const Text('See All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      ...recentCourses.map(
                        (course) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppTheme.spacingM,
                          ),
                          child: CourseCard(
                            course: course,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      CourseDetailScreen(course: course),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: AppTheme.spacingL),
            ],
          ),
        ),
      ),
    );
  }
}
