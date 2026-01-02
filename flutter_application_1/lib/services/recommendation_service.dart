import '../models/course_model.dart';
import 'firestore_service.dart';

// =============================================================================
// RECOMMENDATION SERVICE - Category-Based Course Recommendations
// =============================================================================
// This service recommends courses based on:
// 1. Category matching - courses in the same category
// 2. Tag overlap - courses with similar tags
// 3. Popularity - higher rated courses ranked first
// =============================================================================

class RecommendationService {
  final FirestoreService _firestoreService = FirestoreService();

  /// Get personalized recommendations for a user
  /// Returns featured/popular courses from the catalog
  Future<List<CourseModel>> getRecommendations(String userId) async {
    try {
      // Get all courses and return featured ones
      final allCourses = await _firestoreService.getAllCourses();

      // Sort by rating and enrollment count for "recommended" courses
      final sorted = List<CourseModel>.from(allCourses);
      sorted.sort((a, b) {
        // First by rating, then by enrolled count
        final ratingCompare = b.rating.compareTo(a.rating);
        if (ratingCompare != 0) return ratingCompare;
        return b.enrolledCount.compareTo(a.enrolledCount);
      });

      // Return top 5 popular courses
      return sorted.take(5).toList();
    } catch (e) {
      print('Error generating recommendations: $e');
      return [];
    }
  }

  /// Get related courses based on category and tags
  /// This is the main recommendation algorithm
  Future<List<CourseModel>> getRelatedCourses(CourseModel currentCourse) async {
    try {
      final allCourses = await _firestoreService.getAllCourses();
      return _getCategoryBasedRelatedCourses(currentCourse, allCourses);
    } catch (e) {
      print('Error finding related courses: $e');
      return [];
    }
  }

  /// Category-based related courses algorithm
  ///
  /// How it works:
  /// 1. Filter courses by same category (excluding current course)
  /// 2. Calculate tag overlap score for each course
  /// 3. Sort by tag overlap + rating
  /// 4. Return top 5 results
  List<CourseModel> _getCategoryBasedRelatedCourses(
    CourseModel currentCourse,
    List<CourseModel> allCourses,
  ) {
    // Filter by same category, exclude current course
    final sameCategoryCourses = allCourses.where((c) {
      return c.courseId != currentCourse.courseId &&
          _normalizeCategory(c.category) ==
              _normalizeCategory(currentCourse.category);
    }).toList();

    // If not enough in same category, include all courses
    List<CourseModel> candidates = sameCategoryCourses;
    if (candidates.length < 5) {
      candidates = allCourses
          .where((c) => c.courseId != currentCourse.courseId)
          .toList();
    }

    // Score and sort by tag overlap + rating
    final scored = <Map<String, dynamic>>[];
    for (var course in candidates) {
      final tagOverlap = _calculateTagOverlap(currentCourse.tags, course.tags);
      final categoryMatch =
          _normalizeCategory(course.category) ==
              _normalizeCategory(currentCourse.category)
          ? 2.0
          : 0.0;
      final score = tagOverlap + categoryMatch + (course.rating / 5.0);

      scored.add({'course': course, 'score': score});
    }

    // Sort by score (highest first)
    scored.sort(
      (a, b) => (b['score'] as double).compareTo(a['score'] as double),
    );

    // Return top 5
    return scored.take(5).map((e) => e['course'] as CourseModel).toList();
  }

  /// Calculate tag overlap between two courses
  double _calculateTagOverlap(List<String> tags1, List<String> tags2) {
    final set1 = tags1.map((t) => t.toLowerCase()).toSet();
    final set2 = tags2.map((t) => t.toLowerCase()).toSet();
    return set1.intersection(set2).length.toDouble();
  }

  /// Normalize category names to handle variations
  String _normalizeCategory(String category) {
    final lower = category.toLowerCase();

    if (lower.contains('programming') ||
        lower.contains('web') ||
        lower.contains('development') ||
        lower.contains('frontend') ||
        lower.contains('backend')) {
      return 'development';
    }
    if (lower.contains('mobile') ||
        lower.contains('flutter') ||
        lower.contains('android') ||
        lower.contains('ios')) {
      return 'mobile';
    }
    if (lower.contains('blockchain') ||
        lower.contains('web3') ||
        lower.contains('crypto') ||
        lower.contains('defi')) {
      return 'blockchain';
    }
    if (lower.contains('data') ||
        lower.contains('machine') ||
        lower.contains('ai') ||
        lower.contains('learning')) {
      return 'data_science';
    }
    if (lower.contains('design') ||
        lower.contains('ui') ||
        lower.contains('ux') ||
        lower.contains('figma')) {
      return 'design';
    }
    if (lower.contains('security') ||
        lower.contains('cyber') ||
        lower.contains('hacking')) {
      return 'security';
    }
    if (lower.contains('devops') ||
        lower.contains('cloud') ||
        lower.contains('aws') ||
        lower.contains('docker')) {
      return 'devops';
    }
    if (lower.contains('business') ||
        lower.contains('marketing') ||
        lower.contains('product')) {
      return 'business';
    }

    return lower;
  }

  /// Cleanup method (kept for API compatibility)
  void close() {
    // No resources to clean up in simple implementation
  }
}
