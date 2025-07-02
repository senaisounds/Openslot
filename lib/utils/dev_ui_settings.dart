import 'package:shared_preferences/shared_preferences.dart';

class DevUISettings {
  static DevUISettings? _instance;
  static DevUISettings get instance => _instance ??= DevUISettings._();
  
  DevUISettings._();
  
  // Cache for settings
  Map<String, double> _cache = {};
  bool _loaded = false;
  
  Future<void> loadSettings() async {
    if (_loaded) return;
    
    final prefs = await SharedPreferences.getInstance();
    
    _cache = {
      // Particle System
      'particle_count': prefs.getDouble('dev_particle_count') ?? 105.0,
      'particle_speed': prefs.getDouble('dev_particle_speed') ?? 0.05,
      'particle_size': prefs.getDouble('dev_particle_size') ?? 1.0,
      'particle_opacity': prefs.getDouble('dev_particle_opacity') ?? 0.6,
      
      // Animation Durations
      'main_duration': prefs.getDouble('dev_main_duration') ?? 300.0,
      'particle_duration': prefs.getDouble('dev_particle_duration') ?? 250.0,
      'streak_duration': prefs.getDouble('dev_streak_duration') ?? 200.0,
      'shape_duration': prefs.getDouble('dev_shape_duration') ?? 180.0,
      
      // Streaks
      'streak_count': prefs.getDouble('dev_streak_count') ?? 14.0,
      'streak_length': prefs.getDouble('dev_streak_length') ?? 55.0,
      'streak_opacity': prefs.getDouble('dev_streak_opacity') ?? 0.8,
      'streak_speed': prefs.getDouble('dev_streak_speed') ?? 0.05,
      
      // Shapes
      'shape_count': prefs.getDouble('dev_shape_count') ?? 20.0,
      'shape_size': prefs.getDouble('dev_shape_size') ?? 8.0,
      'shape_speed': prefs.getDouble('dev_shape_speed') ?? 0.07,
      'shape_opacity': prefs.getDouble('dev_shape_opacity') ?? 0.7,
      
      // Spotlights
      'spotlight_count': prefs.getDouble('dev_spotlight_count') ?? 6.0,
      'spotlight_size': prefs.getDouble('dev_spotlight_size') ?? 0.35,
      'spotlight_speed': prefs.getDouble('dev_spotlight_speed') ?? 0.05,
      'spotlight_opacity': prefs.getDouble('dev_spotlight_opacity') ?? 0.7,
    };
    
    _loaded = true;
  }
  
  double get(String key, double defaultValue) {
    if (!_loaded) {
      return defaultValue;
    }
    return _cache[key] ?? defaultValue;
  }
  
  // Particle System Getters
  double get particleCount => get('particle_count', 105.0);
  double get particleSpeed => get('particle_speed', 0.05);
  double get particleSize => get('particle_size', 1.0);
  double get particleOpacity => get('particle_opacity', 0.6);
  
  // Animation Duration Getters
  double get mainDuration => get('main_duration', 300.0);
  double get particleDuration => get('particle_duration', 250.0);
  double get streakDuration => get('streak_duration', 200.0);
  double get shapeDuration => get('shape_duration', 180.0);
  
  // Streak Getters
  double get streakCount => get('streak_count', 14.0);
  double get streakLength => get('streak_length', 55.0);
  double get streakOpacity => get('streak_opacity', 0.8);
  double get streakSpeed => get('streak_speed', 0.05);
  
  // Shape Getters
  double get shapeCount => get('shape_count', 20.0);
  double get shapeSize => get('shape_size', 8.0);
  double get shapeSpeed => get('shape_speed', 0.07);
  double get shapeOpacity => get('shape_opacity', 0.7);
  
  // Spotlight Getters
  double get spotlightCount => get('spotlight_count', 6.0);
  double get spotlightSize => get('spotlight_size', 0.35);
  double get spotlightSpeed => get('spotlight_speed', 0.05);
  double get spotlightOpacity => get('spotlight_opacity', 0.7);
  
  void clearCache() {
    _cache.clear();
    _loaded = false;
  }
} 