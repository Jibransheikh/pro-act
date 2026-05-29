import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class ProgressService {
  static SupabaseClient get _supabase => SupabaseService.client;

  static Future<Map<String, dynamic>> getTodayProgress() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return _defaultProgress();

    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // Get or create today's progress row
    final existing = await _supabase
        .from('daily_progress')
        .select()
        .eq('user_id', userId)
        .eq('date', dateStr);

    if (existing.isEmpty) {
      // Get user targets from profile
      final profile = await _supabase
          .from('profiles')
          .select('water_target, steps_target, pages_target, weight_kg, age, gender')
          .eq('id', userId)
          .single();

      final waterTarget = profile['water_target'] as int? ?? 2500;
      final stepsTarget = profile['steps_target'] as int? ?? 8000;
      final pagesTarget = profile['pages_target'] as int? ?? 20;

      final newRow = await _supabase.from('daily_progress').insert({
        'user_id': userId,
        'date': dateStr,
        'water_ml': 0,
        'steps': 0,
        'pages_read': 0,
        'water_target': waterTarget,
        'steps_target': stepsTarget,
        'pages_target': pagesTarget,
      }).select().single();

      return Map<String, dynamic>.from(newRow);
    }

    return Map<String, dynamic>.from(existing.first);
  }

  static Future<void> logWater(int ml) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    final progress = await getTodayProgress();
    final current = progress['water_ml'] as int? ?? 0;

    await _supabase
        .from('daily_progress')
        .update({'water_ml': current + ml})
        .eq('id', progress['id']);
  }

  static Future<void> updateSteps(int steps) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    final progress = await getTodayProgress();

    await _supabase
        .from('daily_progress')
        .update({'steps': steps})
        .eq('id', progress['id']);
  }

  static Future<void> logPages(int pages) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    final progress = await getTodayProgress();
    final current = progress['pages_read'] as int? ?? 0;

    await _supabase
        .from('daily_progress')
        .update({'pages_read': current + pages})
        .eq('id', progress['id']);
  }

  static Future<Map<String, int>> getStreaks() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return {'water': 0, 'steps': 0, 'reading': 0};

    final rows = await _supabase
        .from('daily_progress')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false)
        .limit(90);

    int waterStreak = 0;
    int stepsStreak = 0;
    int readingStreak = 0;

    for (final row in rows) {
      final waterDone =
          (row['water_ml'] as int? ?? 0) >= (row['water_target'] as int? ?? 2500);
      if (waterDone) {
        waterStreak++;
      } else {
        break;
      }
    }

    for (final row in rows) {
      final stepsDone =
          (row['steps'] as int? ?? 0) >= (row['steps_target'] as int? ?? 8000);
      if (stepsDone) {
        stepsStreak++;
      } else {
        break;
      }
    }

    for (final row in rows) {
      final readingDone =
          (row['pages_read'] as int? ?? 0) >= (row['pages_target'] as int? ?? 20);
      if (readingDone) {
        readingStreak++;
      } else {
        break;
      }
    }

    return {
      'water': waterStreak,
      'steps': stepsStreak,
      'reading': readingStreak,
    };
  }

  static Map<String, dynamic> _defaultProgress() {
    return {
      'water_ml': 0,
      'steps': 0,
      'pages_read': 0,
      'water_target': 2500,
      'steps_target': 8000,
      'pages_target': 20,
    };
  }

  static String streakMessage(String type, int streak) {
    if (streak == 0) return 'Start your streak today.';
    if (streak == 1) return 'Day one. The hardest step is starting.';
    if (streak == 3) return '3 days straight. A pattern is forming.';
    if (streak == 7) return 'One week. You\'re building something real.';
    if (streak == 14) return 'Two weeks. Most people quit by now.';
    if (streak == 21) return '21 days. Science says this is a habit now.';
    if (streak == 30) return '30 days. You\'re not the same person who started.';
    if (streak == 60) return '60 days. This is just who you are now.';
    if (streak == 90) return '90 days. You\'ve earned the right to call this a lifestyle.';

    if (streak < 7) return '$streak days. Keep showing up.';
    if (streak < 14) return '$streak days. The momentum is real.';
    if (streak < 30) return '$streak days. Don\'t break the chain.';
    if (streak < 60) return '$streak days. You\'re in rare company.';
    return '$streak days. Unstoppable.';
  }

  static int recommendWaterTarget(double weightKg) {
    return (weightKg * 35).round();
  }

  static int recommendStepsTarget(int age, String gender) {
    if (age < 18) return 10000;
    if (age > 60) return 6000;
    return gender.toLowerCase() == 'male' ? 9000 : 8000;
  }

  static int recommendPagesTarget(int age) {
    if (age < 18) return 15;
    if (age > 50) return 10;
    return 20;
  }
}