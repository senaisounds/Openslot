import 'package:flutter/cupertino.dart';


import 'package:shared_preferences/shared_preferences.dart';
import 'package:slotted/common/colors.dart' as app_colors;

class DevUISettingsPage extends StatefulWidget {
  const DevUISettingsPage({super.key});

  @override
  State<DevUISettingsPage> createState() => _DevUISettingsPageState();
}

class _DevUISettingsPageState extends State<DevUISettingsPage> {
  // Particle System Settings
  double _particleCount = 105.0; // Main + secondary + tertiary particles
  double _particleSpeed = 0.05;
  double _particleSize = 1.0;
  double _particleOpacity = 0.6;
  
  // Animation Durations (in seconds)
  double _mainAnimationDuration = 300.0;
  double _particleAnimationDuration = 250.0;
  double _streakAnimationDuration = 200.0;
  double _shapeAnimationDuration = 180.0;
  

  
  // Streak Settings
  double _streakCount = 14.0;
  double _streakLength = 55.0;
  double _streakOpacity = 0.8;
  double _streakSpeed = 0.05;
  
  // Shape Settings
  double _shapeCount = 20.0;
  double _shapeSize = 8.0;
  double _shapeSpeed = 0.07;
  double _shapeOpacity = 0.7;
  
  // Spotlight Settings
  double _spotlightCount = 6.0;
  double _spotlightSize = 0.35;
  double _spotlightSpeed = 0.05;
  double _spotlightOpacity = 0.7;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _particleCount = prefs.getDouble('dev_particle_count') ?? 105.0;
      _particleSpeed = prefs.getDouble('dev_particle_speed') ?? 0.05;
      _particleSize = prefs.getDouble('dev_particle_size') ?? 1.0;
      _particleOpacity = prefs.getDouble('dev_particle_opacity') ?? 0.6;
      
      _mainAnimationDuration = prefs.getDouble('dev_main_duration') ?? 300.0;
      _particleAnimationDuration = prefs.getDouble('dev_particle_duration') ?? 250.0;
      _streakAnimationDuration = prefs.getDouble('dev_streak_duration') ?? 200.0;
      _shapeAnimationDuration = prefs.getDouble('dev_shape_duration') ?? 180.0;
      
      _streakCount = prefs.getDouble('dev_streak_count') ?? 14.0;
      _streakLength = prefs.getDouble('dev_streak_length') ?? 55.0;
      _streakOpacity = prefs.getDouble('dev_streak_opacity') ?? 0.8;
      _streakSpeed = prefs.getDouble('dev_streak_speed') ?? 0.05;
      
      _shapeCount = prefs.getDouble('dev_shape_count') ?? 20.0;
      _shapeSize = prefs.getDouble('dev_shape_size') ?? 8.0;
      _shapeSpeed = prefs.getDouble('dev_shape_speed') ?? 0.07;
      _shapeOpacity = prefs.getDouble('dev_shape_opacity') ?? 0.7;
      
      _spotlightCount = prefs.getDouble('dev_spotlight_count') ?? 6.0;
      _spotlightSize = prefs.getDouble('dev_spotlight_size') ?? 0.35;
      _spotlightSpeed = prefs.getDouble('dev_spotlight_speed') ?? 0.05;
      _spotlightOpacity = prefs.getDouble('dev_spotlight_opacity') ?? 0.7;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('dev_particle_count', _particleCount);
    await prefs.setDouble('dev_particle_speed', _particleSpeed);
    await prefs.setDouble('dev_particle_size', _particleSize);
    await prefs.setDouble('dev_particle_opacity', _particleOpacity);
    
    await prefs.setDouble('dev_main_duration', _mainAnimationDuration);
    await prefs.setDouble('dev_particle_duration', _particleAnimationDuration);
    await prefs.setDouble('dev_streak_duration', _streakAnimationDuration);
    await prefs.setDouble('dev_shape_duration', _shapeAnimationDuration);
    
    await prefs.setDouble('dev_streak_count', _streakCount);
    await prefs.setDouble('dev_streak_length', _streakLength);
    await prefs.setDouble('dev_streak_opacity', _streakOpacity);
    await prefs.setDouble('dev_streak_speed', _streakSpeed);
    
    await prefs.setDouble('dev_shape_count', _shapeCount);
    await prefs.setDouble('dev_shape_size', _shapeSize);
    await prefs.setDouble('dev_shape_speed', _shapeSpeed);
    await prefs.setDouble('dev_shape_opacity', _shapeOpacity);
    
    await prefs.setDouble('dev_spotlight_count', _spotlightCount);
    await prefs.setDouble('dev_spotlight_size', _spotlightSize);
    await prefs.setDouble('dev_spotlight_speed', _spotlightSpeed);
    await prefs.setDouble('dev_spotlight_opacity', _spotlightOpacity);
  }

  Future<void> _resetToDefaults() async {
    setState(() {
      _particleCount = 105.0;
      _particleSpeed = 0.05;
      _particleSize = 1.0;
      _particleOpacity = 0.6;
      
      _mainAnimationDuration = 300.0;
      _particleAnimationDuration = 250.0;
      _streakAnimationDuration = 200.0;
      _shapeAnimationDuration = 180.0;
      
      _streakCount = 14.0;
      _streakLength = 55.0;
      _streakOpacity = 0.8;
      _streakSpeed = 0.05;
      
      _shapeCount = 20.0;
      _shapeSize = 8.0;
      _shapeSpeed = 0.07;
      _shapeOpacity = 0.7;
      
      _spotlightCount = 6.0;
      _spotlightSize = 0.35;
      _spotlightSpeed = 0.05;
      _spotlightOpacity = 0.7;
    });
    await _saveSettings();
  }

  Widget _buildSlider({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    String? unit,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: app_colors.AppColors.backgroundLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: app_colors.AppColors.accent.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${value.toStringAsFixed(value < 1 ? 3 : value < 10 ? 1 : 0)}${unit ?? ''}',
                style: const TextStyle(
                  color: app_colors.AppColors.accent,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: CupertinoColors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          CupertinoSlider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: app_colors.AppColors.accent,
            thumbColor: app_colors.AppColors.accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              color: app_colors.AppColors.accent,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: app_colors.AppColors.backgroundDark,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: app_colors.AppColors.backgroundDark.withValues(alpha: 0.8),
        border: null,
        middle: const Text(
          'Developer UI Settings',
          style: TextStyle(
            color: CupertinoColors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(
            CupertinoIcons.back,
            color: CupertinoColors.white,
          ),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _saveSettings,
          child: const Text(
            'Save',
            style: TextStyle(
              color: app_colors.AppColors.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // Warning Banner
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemYellow.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: CupertinoColors.systemYellow.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.exclamationmark_triangle,
                      color: CupertinoColors.systemYellow,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Developer Settings',
                            style: TextStyle(
                              color: CupertinoColors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'These settings are for development only. Delete this page when done.',
                            style: TextStyle(
                              color: CupertinoColors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Particle System Settings
              _buildSection('Particle System', [
                _buildSlider(
                  title: 'Particle Count',
                  subtitle: 'Total number of particles in the background',
                  value: _particleCount,
                  min: 0,
                  max: 200,
                  divisions: 200,
                  onChanged: (value) => setState(() => _particleCount = value),
                ),
                _buildSlider(
                  title: 'Particle Speed',
                  subtitle: 'Speed multiplier for particle movement',
                  value: _particleSpeed,
                  min: 0.001,
                  max: 0.5,
                  divisions: 499,
                  onChanged: (value) => setState(() => _particleSpeed = value),
                ),
                _buildSlider(
                  title: 'Particle Size',
                  subtitle: 'Size multiplier for particles',
                  value: _particleSize,
                  min: 0.1,
                  max: 3.0,
                  divisions: 29,
                  onChanged: (value) => setState(() => _particleSize = value),
                ),
                _buildSlider(
                  title: 'Particle Opacity',
                  subtitle: 'Opacity of particles (0 = invisible, 1 = fully visible)',
                  value: _particleOpacity,
                  min: 0.0,
                  max: 1.0,
                  divisions: 100,
                  onChanged: (value) => setState(() => _particleOpacity = value),
                ),
              ]),
              
              // Animation Durations
              _buildSection('Animation Durations', [
                _buildSlider(
                  title: 'Main Animation Duration',
                  subtitle: 'Duration for main background animation cycle',
                  value: _mainAnimationDuration,
                  min: 10,
                  max: 600,
                  divisions: 590,
                  onChanged: (value) => setState(() => _mainAnimationDuration = value),
                  unit: 's',
                ),
                _buildSlider(
                  title: 'Particle Animation Duration',
                  subtitle: 'Duration for particle animation cycle',
                  value: _particleAnimationDuration,
                  min: 10,
                  max: 500,
                  divisions: 490,
                  onChanged: (value) => setState(() => _particleAnimationDuration = value),
                  unit: 's',
                ),
                _buildSlider(
                  title: 'Streak Animation Duration',
                  subtitle: 'Duration for streak animation cycle',
                  value: _streakAnimationDuration,
                  min: 10,
                  max: 400,
                  divisions: 390,
                  onChanged: (value) => setState(() => _streakAnimationDuration = value),
                  unit: 's',
                ),
                _buildSlider(
                  title: 'Shape Animation Duration',
                  subtitle: 'Duration for shape animation cycle',
                  value: _shapeAnimationDuration,
                  min: 10,
                  max: 300,
                  divisions: 290,
                  onChanged: (value) => setState(() => _shapeAnimationDuration = value),
                  unit: 's',
                ),
              ]),
              
              // Streak Settings
              _buildSection('Streak Effects', [
                _buildSlider(
                  title: 'Streak Count',
                  subtitle: 'Number of animated streaks',
                  value: _streakCount,
                  min: 0,
                  max: 30,
                  divisions: 30,
                  onChanged: (value) => setState(() => _streakCount = value),
                ),
                _buildSlider(
                  title: 'Streak Length',
                  subtitle: 'Average length of streaks',
                  value: _streakLength,
                  min: 10,
                  max: 150,
                  divisions: 140,
                  onChanged: (value) => setState(() => _streakLength = value),
                  unit: 'px',
                ),
                _buildSlider(
                  title: 'Streak Speed',
                  subtitle: 'Speed of streak animations',
                  value: _streakSpeed,
                  min: 0.001,
                  max: 0.3,
                  divisions: 299,
                  onChanged: (value) => setState(() => _streakSpeed = value),
                ),
                _buildSlider(
                  title: 'Streak Opacity',
                  subtitle: 'Opacity of streak effects',
                  value: _streakOpacity,
                  min: 0.0,
                  max: 1.0,
                  divisions: 100,
                  onChanged: (value) => setState(() => _streakOpacity = value),
                ),
              ]),
              
              // Shape Settings
              _buildSection('Floating Shapes', [
                _buildSlider(
                  title: 'Shape Count',
                  subtitle: 'Number of floating shapes',
                  value: _shapeCount,
                  min: 0,
                  max: 40,
                  divisions: 40,
                  onChanged: (value) => setState(() => _shapeCount = value),
                ),
                _buildSlider(
                  title: 'Shape Size',
                  subtitle: 'Average size of shapes',
                  value: _shapeSize,
                  min: 2,
                  max: 20,
                  divisions: 18,
                  onChanged: (value) => setState(() => _shapeSize = value),
                  unit: 'px',
                ),
                _buildSlider(
                  title: 'Shape Speed',
                  subtitle: 'Speed of shape movements',
                  value: _shapeSpeed,
                  min: 0.001,
                  max: 0.5,
                  divisions: 499,
                  onChanged: (value) => setState(() => _shapeSpeed = value),
                ),
                _buildSlider(
                  title: 'Shape Opacity',
                  subtitle: 'Opacity of floating shapes',
                  value: _shapeOpacity,
                  min: 0.0,
                  max: 1.0,
                  divisions: 100,
                  onChanged: (value) => setState(() => _shapeOpacity = value),
                ),
              ]),
              
              // Spotlight Settings
              _buildSection('Spotlight Effects', [
                _buildSlider(
                  title: 'Spotlight Count',
                  subtitle: 'Number of background spotlights',
                  value: _spotlightCount,
                  min: 0,
                  max: 12,
                  divisions: 12,
                  onChanged: (value) => setState(() => _spotlightCount = value),
                ),
                _buildSlider(
                  title: 'Spotlight Size',
                  subtitle: 'Size of spotlight effects (relative to screen)',
                  value: _spotlightSize,
                  min: 0.1,
                  max: 0.8,
                  divisions: 70,
                  onChanged: (value) => setState(() => _spotlightSize = value),
                ),
                _buildSlider(
                  title: 'Spotlight Speed',
                  subtitle: 'Speed of spotlight movements',
                  value: _spotlightSpeed,
                  min: 0.001,
                  max: 0.2,
                  divisions: 199,
                  onChanged: (value) => setState(() => _spotlightSpeed = value),
                ),
                _buildSlider(
                  title: 'Spotlight Opacity',
                  subtitle: 'Opacity of spotlight effects',
                  value: _spotlightOpacity,
                  min: 0.0,
                  max: 1.0,
                  divisions: 100,
                  onChanged: (value) => setState(() => _spotlightOpacity = value),
                ),
              ]),
              
              // Action Buttons
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        color: app_colors.AppColors.accent,
                        onPressed: () async {
                          await _saveSettings();
                          if (mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        child: const Text(
                          'Save & Apply Settings',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        color: CupertinoColors.systemGrey,
                        onPressed: _resetToDefaults,
                        child: const Text(
                          'Reset to Defaults',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Note: Changes will take effect after restarting the app or navigating to a different page.',
                      style: TextStyle(
                        color: CupertinoColors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 