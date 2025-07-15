import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Award types
enum AwardType {
  performance,
  attendance,
  social,
  special
}

// Award rarity levels
enum AwardRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary
}

// Award class to define award structure
class Award {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final AwardType type;
  final AwardRarity rarity;
  final List<Color> colors;
  final DateTime? earnedDate;
  
  Award({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.type,
    required this.rarity,
    required this.colors,
    this.earnedDate,
  });
  
  // Create Award from map data
  factory Award.fromMap(Map<String, dynamic> map) {
    return Award(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      icon: _getIconFromString(map['icon'] as String),
      type: AwardType.values.firstWhere(
        (e) => e.toString() == 'AwardType.${map['type']}',
        orElse: () => AwardType.special,
      ),
      rarity: AwardRarity.values.firstWhere(
        (e) => e.toString() == 'AwardRarity.${map['rarity']}',
        orElse: () => AwardRarity.common,
      ),
      colors: _getColorsFromList(map['colors'] as List<dynamic>),
      earnedDate: map['earnedDate'] != null 
          ? DateTime.parse(map['earnedDate'] as String) 
          : null,
    );
  }
  
  // Convert Award to map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': _getStringFromIcon(icon),
      'type': type.toString().split('.').last,
      'rarity': rarity.toString().split('.').last,
      'colors': colors.map((color) => color.toARGB32()).toList(),
      'earnedDate': earnedDate?.toIso8601String(),
    };
  }
  
  // Static map of predefined Cupertino icons by codepoint
  static final Map<int, IconData> _cupertinoIconMap = {
    // Add frequently used icons here
    CupertinoIcons.mic_fill.codePoint: CupertinoIcons.mic_fill,
    CupertinoIcons.headphones.codePoint: CupertinoIcons.headphones,
    CupertinoIcons.star_fill.codePoint: CupertinoIcons.star_fill,
    CupertinoIcons.map_fill.codePoint: CupertinoIcons.map_fill,
    CupertinoIcons.calendar_badge_plus.codePoint: CupertinoIcons.calendar_badge_plus,
    CupertinoIcons.at.codePoint: CupertinoIcons.at,
    CupertinoIcons.hand_thumbsup_fill.codePoint: CupertinoIcons.hand_thumbsup_fill,
    CupertinoIcons.person_2_fill.codePoint: CupertinoIcons.person_2_fill,
    CupertinoIcons.sparkles.codePoint: CupertinoIcons.sparkles,
    CupertinoIcons.person_fill.codePoint: CupertinoIcons.person_fill,
    CupertinoIcons.person.codePoint: CupertinoIcons.person,
  };
  
  // Static map of predefined Material icons by codepoint
  static final Map<int, IconData> _materialIconMap = {
    // Add frequently used icons here
    Icons.emoji_emotions.codePoint: Icons.emoji_emotions,
    Icons.headset.codePoint: Icons.headset,
    Icons.auto_stories.codePoint: Icons.auto_stories,
    Icons.music_note.codePoint: Icons.music_note,
    Icons.event.codePoint: Icons.event,
  };
  
  // Helper to convert icon to string
  static String _getStringFromIcon(IconData icon) {
    if (icon.fontFamily == CupertinoIcons.iconFont) {
      return 'cupertino:${icon.codePoint}';
    }
    return 'material:${icon.codePoint}';
  }
  
  // Helper to convert string to icon using predefined icons
  static IconData _getIconFromString(String iconString) {
    final parts = iconString.split(':');
    final codePoint = int.parse(parts[1]);
    
    if (parts[0] == 'cupertino') {
      // Look up in the cupertino icon map, or fall back to a default
      return _cupertinoIconMap[codePoint] ?? CupertinoIcons.question;
    }
    
    // Look up in the material icon map, or fall back to a default
    return _materialIconMap[codePoint] ?? Icons.help;
  }
  
  // Helper to convert color list to Color objects
  static List<Color> _getColorsFromList(List<dynamic> colorValues) {
    return colorValues.map((value) => Color(value as int)).toList();
  }
}

// Predefined awards
class AwardsHelper {
  // Performance awards
  static Award firstPerformance = Award(
    id: 'first_performance',
    name: 'First Timer',
    description: 'Completed your first performance',
    icon: CupertinoIcons.mic_fill,
    type: AwardType.performance,
    rarity: AwardRarity.common,
    colors: [const Color(0xFFFFD700), const Color(0xFFFFA500)],
  );
  
  static Award tenPerformances = Award(
    id: 'ten_performances',
    name: 'Regular Performer',
    description: 'Completed 10 performances',
    icon: CupertinoIcons.headphones,
    type: AwardType.performance,
    rarity: AwardRarity.uncommon,
    colors: [const Color(0xFF4ECDC4), const Color(0xFF6EE7E0)],
  );
  
  static Award fiftyPerformances = Award(
    id: 'fifty_performances',
    name: 'Stage Veteran',
    description: 'Completed 50 performances',
    icon: CupertinoIcons.star_fill,
    type: AwardType.performance,
    rarity: AwardRarity.rare,
    colors: [const Color(0xFF6C4AB0), const Color(0xFF8D72E1)],
  );
  
  static Award fiftyOpenMics = Award(
    id: 'fifty_open_mics',
    name: 'Open Mic Master',
    description: 'Performed at 50 open mic events',
    icon: CupertinoIcons.mic_fill,
    type: AwardType.performance,
    rarity: AwardRarity.rare,
    colors: [const Color(0xFFFF6B6B), const Color(0xFFFF8E8E)],
  );
  
  // Attendance awards
  static Award fiveEvents = Award(
    id: 'five_events',
    name: 'Event Explorer',
    description: 'Attended 5 different events',
    icon: CupertinoIcons.map_fill,
    type: AwardType.attendance,
    rarity: AwardRarity.common,
    colors: [const Color(0xFF9ADCFF), const Color(0xFF72EFDD)],
  );
  
  static Award twentyEvents = Award(
    id: 'twenty_events',
    name: 'Scene Regular',
    description: 'Attended 20 different events',
    icon: CupertinoIcons.calendar_badge_plus,
    type: AwardType.attendance,
    rarity: AwardRarity.uncommon,
    colors: [const Color(0xFFFF6B6B), const Color(0xFFFF8E8E)],
  );
  
  // Social awards
  static Award connectedSocial = Award(
    id: 'connected_social',
    name: 'Social Butterfly',
    description: 'Connected your social media accounts',
    icon: CupertinoIcons.at,
    type: AwardType.social,
    rarity: AwardRarity.common,
    colors: [const Color(0xFF00B4D8), const Color(0xFF90E0EF)],
  );
  
  static Award popularPerformer = Award(
    id: 'popular_performer',
    name: 'Popular Performer',
    description: 'Received 50+ likes on your performances',
    icon: CupertinoIcons.hand_thumbsup_fill,
    type: AwardType.social,
    rarity: AwardRarity.rare,
    colors: [const Color(0xFFFF9E00), const Color(0xFFFFCA3A)],
  );
  
  // Special awards
  static Award eventHost = Award(
    id: 'event_host',
    name: 'Event Host',
    description: 'Successfully hosted your own event',
    icon: CupertinoIcons.person_2_fill,
    type: AwardType.special,
    rarity: AwardRarity.epic,
    colors: [const Color(0xFF8338EC), const Color(0xFFC77DFF)],
  );
  
  static Award featuredArtist = Award(
    id: 'featured_artist',
    name: 'Featured Artist',
    description: 'Selected as a featured artist on Slotted',
    icon: CupertinoIcons.sparkles,
    type: AwardType.special,
    rarity: AwardRarity.legendary,
    colors: [const Color(0xFFFF006E), const Color(0xFFFF5E78)],
  );
  
  // Get all predefined awards
  static List<Award> getAllAwards() {
    return [
      firstPerformance,
      tenPerformances,
      fiftyPerformances,
      fiftyOpenMics,
      fiveEvents,
      twentyEvents,
      connectedSocial,
      popularPerformer,
      eventHost,
      featuredArtist,
    ];
  }
  
  // Get award by ID
  static Award? getAwardById(String id) {
    try {
      return getAllAwards().firstWhere((award) => award.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // Get background color for rarity
  static Color getRarityColor(AwardRarity rarity) {
    switch (rarity) {
      case AwardRarity.common:
        return const Color(0xFF9ADCFF).withAlpha(204);
      case AwardRarity.uncommon:
        return const Color(0xFF4ECDC4).withAlpha(204);
      case AwardRarity.rare:
        return const Color(0xFF6C4AB0).withAlpha(204);
      case AwardRarity.epic:
        return const Color(0xFF8338EC).withAlpha(204);
      case AwardRarity.legendary:
        return const Color(0xFFFF006E).withAlpha(204);
    }
  }
  
  // Get border color for rarity
  static Color getRarityBorderColor(AwardRarity rarity) {
    switch (rarity) {
      case AwardRarity.common:
        return const Color(0xFF9ADCFF).withAlpha(204);
      case AwardRarity.uncommon:
        return const Color(0xFF4ECDC4).withAlpha(204);
      case AwardRarity.rare:
        return const Color(0xFF6C4AB0).withAlpha(204);
      case AwardRarity.epic:
        return const Color(0xFF8338EC).withAlpha(204);
      case AwardRarity.legendary:
        return const Color(0xFFFF006E).withAlpha(204);
    }
  }
  
  // Get text representation of rarity
  static String getRarityText(AwardRarity rarity) {
    switch (rarity) {
      case AwardRarity.common:
        return 'Common';
      case AwardRarity.uncommon:
        return 'Uncommon';
      case AwardRarity.rare:
        return 'Rare';
      case AwardRarity.epic:
        return 'Epic';
      case AwardRarity.legendary:
        return 'Legendary';
    }
  }
} 