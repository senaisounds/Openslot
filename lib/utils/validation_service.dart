import 'package:html_unescape/html_unescape.dart';
import 'package:slotted/common/event_class.dart' as event_class;
import 'package:slotted/common/slotted_user.dart';

/// A service that provides input validation and sanitization
class ValidationService {
  // Singleton pattern
  ValidationService._privateConstructor();
  static final ValidationService instance = ValidationService._privateConstructor();
  
  final HtmlUnescape _htmlUnescape = HtmlUnescape();
  
  // Regular expressions for validation
  static final RegExp _emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
  static final RegExp _scriptTagRegex = RegExp(r'<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>', caseSensitive: false);
  static final RegExp _htmlTagsRegex = RegExp(r'<[^>]*>', multiLine: true);
  static final RegExp _urlRegex = RegExp(r'(https?:\/\/[^\s]+)', caseSensitive: false);
  
  // Objectionable content patterns
  static final List<RegExp> _profanityPatterns = [
    RegExp(r'\b(fuck|shit|bitch|asshole|dick|pussy|cunt|whore|slut)\b', caseSensitive: false),
    RegExp(r'\b(nigga|nigger|faggot|dyke|retard)\b', caseSensitive: false),
    RegExp(r'\b(rape|kill|murder|suicide|bomb|terrorist)\b', caseSensitive: false),
  ];
  
  static final List<RegExp> _hateSpeechPatterns = [
    RegExp(r'\b(all\s+)?(white|black|asian|hispanic|jewish|muslim|gay|lesbian|trans)\s+(people|person|man|woman|boy|girl)\s+(should|must|need|deserve)\s+(to\s+)?(die|burn|suffer|leave)\b', caseSensitive: false),
    RegExp(r'\b(hitler|nazi|kkk|supremacist|racist|sexist|homophobic)\b', caseSensitive: false),
  ];
  
  static final List<RegExp> _inappropriatePatterns = [
    RegExp(r'\b(sex|nude|naked|porn|pornography|adult|escort|prostitute)\b', caseSensitive: false),
    RegExp(r'\b(drugs|cocaine|heroin|meth|weed|marijuana|alcohol|drunk)\b', caseSensitive: false),
    RegExp(r'\b(violence|fight|attack|weapon|gun|knife|bomb)\b', caseSensitive: false),
  ];
  
  static final List<String> _spamPatterns = [
    'buy now', 'click here', 'free money', 'make money fast',
    'work from home', 'earn cash', 'get rich quick', 'lottery winner',
    'viagra', 'cialis', 'weight loss', 'diet pills',
  ];
  
  /// Check if text contains objectionable content
  bool containsObjectionableContent(String text) {
    if (text.isEmpty) return false;
    
    final lowerText = text.toLowerCase();
    
    // Check for profanity
    for (final pattern in _profanityPatterns) {
      if (pattern.hasMatch(lowerText)) {
        return true;
      }
    }
    
    // Check for hate speech
    for (final pattern in _hateSpeechPatterns) {
      if (pattern.hasMatch(lowerText)) {
        return true;
      }
    }
    
    // Check for inappropriate content
    for (final pattern in _inappropriatePatterns) {
      if (pattern.hasMatch(lowerText)) {
        return true;
      }
    }
    
    // Check for spam patterns
    for (final spam in _spamPatterns) {
      if (lowerText.contains(spam)) {
        return true;
      }
    }
    
    return false;
  }
  
  /// Get the specific reason for objectionable content
  String? getObjectionableContentReason(String text) {
    if (text.isEmpty) return null;
    
    final lowerText = text.toLowerCase();
    
    // Check for profanity
    for (final pattern in _profanityPatterns) {
      if (pattern.hasMatch(lowerText)) {
        return 'Content contains inappropriate language';
      }
    }
    
    // Check for hate speech
    for (final pattern in _hateSpeechPatterns) {
      if (pattern.hasMatch(lowerText)) {
        return 'Content contains hate speech or discriminatory language';
      }
    }
    
    // Check for inappropriate content
    for (final pattern in _inappropriatePatterns) {
      if (pattern.hasMatch(lowerText)) {
        return 'Content contains inappropriate or adult content';
      }
    }
    
    // Check for spam patterns
    for (final spam in _spamPatterns) {
      if (lowerText.contains(spam)) {
        return 'Content appears to be spam or promotional';
      }
    }
    
    return null;
  }
  
  /// Validates an email address
  bool validateEmail(String email) {
    return _emailRegex.hasMatch(email);
  }
  
  /// Validates user data
  Map<String, String?> validateUser(SlottedUser user) {
    final errors = <String, String?>{};
    
    // Username validation
    if (user.username.isEmpty) {
      errors['username'] = 'Username is required';
    } else if (user.username.length < 3) {
      errors['username'] = 'Username must be at least 3 characters';
    } else if (user.username.length > 30) {
      errors['username'] = 'Username must not exceed 30 characters';
    }
    
    // Email validation
    if (user.email != null && user.email!.isNotEmpty && !_emailRegex.hasMatch(user.email!)) {
      errors['email'] = 'Please enter a valid email address';
    }
    
    // Bio validation - length check, script detection, and objectionable content
    if (user.bio.length > 500) {
      errors['bio'] = 'Bio must not exceed 500 characters';
    } else if (_scriptTagRegex.hasMatch(user.bio)) {
      errors['bio'] = 'Bio contains disallowed content';
    } else if (containsObjectionableContent(user.bio)) {
      errors['bio'] = getObjectionableContentReason(user.bio) ?? 'Bio contains inappropriate content';
    }
    
    // Social media validation
    if (user.instagram.isNotEmpty && user.instagram.contains(' ')) {
      errors['instagram'] = 'Instagram username should not contain spaces';
    }
    
    if (user.twitter.isNotEmpty && user.twitter.contains(' ')) {
      errors['twitter'] = 'Twitter username should not contain spaces';
    }
    
    return errors;
  }
  
  /// Validates event data
  Map<String, String?> validateEvent(event_class.Event event) {
    final errors = <String, String?>{};
    
    // Name validation
    if (event.name.isEmpty) {
      errors['name'] = 'Event name is required';
    } else if (event.name.length < 3) {
      errors['name'] = 'Event name must be at least 3 characters';
    } else if (event.name.length > 100) {
      errors['name'] = 'Event name must not exceed 100 characters';
    }
    
    // Description validation
    if (event.description.isEmpty) {
      errors['description'] = 'Event description is required';
    } else if (event.description.length < 10) {
      errors['description'] = 'Description must be at least 10 characters';
    } else if (event.description.length > 2000) {
      errors['description'] = 'Description must not exceed 2000 characters';
    } else if (_scriptTagRegex.hasMatch(event.description)) {
      errors['description'] = 'Description contains disallowed content';
    } else if (containsObjectionableContent(event.description)) {
      errors['description'] = getObjectionableContentReason(event.description) ?? 'Description contains inappropriate content';
    }
    
    // Address validation
    if (event.address.isEmpty) {
      errors['address'] = 'Event address is required';
    }
    
    // Category validation
    if (event.category.isEmpty) {
      errors['category'] = 'Event category is required';
    }
    
    // Date validation
    final now = DateTime.now();
    // Allow events to be created in the past for testing, but add a lower limit
    final lowerLimit = DateTime(2020, 1, 1);
    final upperLimit = now.add(const Duration(days: 365)); // One year from now
    
    if (event.date.isBefore(lowerLimit)) {
      errors['date'] = 'Event date cannot be before 2020';
    } else if (event.date.isAfter(upperLimit)) {
      errors['date'] = 'Event date cannot be more than one year in the future';
    }
    
    // Rules validation
    if (event.rules.length > 1000) {
      errors['rules'] = 'Rules must not exceed 1000 characters';
    } else if (_scriptTagRegex.hasMatch(event.rules)) {
      errors['rules'] = 'Rules contain disallowed content';
    } else if (containsObjectionableContent(event.rules)) {
      errors['rules'] = getObjectionableContentReason(event.rules) ?? 'Rules contain inappropriate content';
    }
    
    // Capacity validation
    if (event.capacity < 1) {
      errors['capacity'] = 'Capacity must be at least 1';
    } else if (event.capacity > 10000) {
      errors['capacity'] = 'Capacity cannot exceed 10,000';
    }
    
    return errors;
  }
  
  /// Sanitizes text input to prevent XSS attacks
  String sanitizeText(String text) {
    // Decode HTML entities first (e.g. &lt; to <)
    String sanitized = _htmlUnescape.convert(text);
    
    // Remove <script> tags and their content
    sanitized = sanitized.replaceAll(_scriptTagRegex, '');
    
    // Remove all other HTML tags but keep their content
    sanitized = sanitized.replaceAll(_htmlTagsRegex, '');
    
    // Trim whitespace
    sanitized = sanitized.trim();
    
    return sanitized;
  }
  
  /// Sanitizes a URL to ensure it's safe to use
  String? sanitizeUrl(String? url) {
    if (url == null || url.isEmpty) {
      return null;
    }
    
    // Check if the URL is valid
    if (!_urlRegex.hasMatch(url)) {
      return null;
    }
    
    // Ensure the URL uses http or https protocol
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    
    return url;
  }
  
  /// Sanitizes user data
  SlottedUser sanitizeUser(SlottedUser user) {
    user.username = sanitizeText(user.username);
    user.bio = sanitizeText(user.bio);
    user.instagram = sanitizeText(user.instagram).replaceAll('@', '');
    user.twitter = sanitizeText(user.twitter).replaceAll('@', '');
    
    return user;
  }
  
  /// Sanitizes event data
  event_class.Event sanitizeEvent(event_class.Event event) {
    event.name = sanitizeText(event.name);
    event.description = sanitizeText(event.description);
    event.address = sanitizeText(event.address);
    event.category = sanitizeText(event.category);
    event.rules = sanitizeText(event.rules);
    event.hostName = sanitizeText(event.hostName);
    
    return event;
  }
} 