import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:slotted/common/event_class.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:slotted/utils/logger.dart';

class SharingService {
  static final SharingService _instance = SharingService._internal();
  static SharingService get instance => _instance;

  SharingService._internal();
  
  // Main sharing method
  Future<bool> shareEvent(Event event, {ShareMethod method = ShareMethod.defaultMethod}) async {
    try {
      final shareText = _buildShareText(event);
      
      switch (method) {
        case ShareMethod.copyToClipboard:
          return await _copyToClipboard(shareText);
        case ShareMethod.sms:
          return await _shareViaSms(shareText);
        case ShareMethod.email:
          return await _shareViaEmail(event, shareText);
        case ShareMethod.twitter:
          return await _shareViaTwitter(shareText);
        case ShareMethod.instagram:
          return await _shareViaInstagram(shareText);
        case ShareMethod.facebook:
          return await _shareViaFacebook(shareText);
        case ShareMethod.defaultMethod:
          if (Platform.isIOS) {
            // On iOS, just copy to clipboard as system share sheet isn't easily accessible
            return await _copyToClipboard(shareText);
          } else {
            // For other platforms, try SMS as default
            final smsSuccess = await _shareViaSms(shareText);
            if (!smsSuccess) {
              return await _copyToClipboard(shareText);
            }
            return smsSuccess;
          }
      }
    } catch (e) {
      Logger.d('Error sharing event: $e', tag: 'Sharing_service');
      return false;
    }
  }
  
  // Format the event information for sharing
  String _buildShareText(Event event) {
    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(event.date);
    final formattedTime = DateFormat('h:mm a').format(event.date);
    
    final sb = StringBuffer();
    sb.writeln('Check out this event on Slotted!');
    sb.writeln('');
    sb.writeln('📅 ${event.name}');
    sb.writeln('📆 $formattedDate at $formattedTime');
    sb.writeln('📍 ${event.address}');
    
    if (event.description.isNotEmpty) {
      sb.writeln('');
      sb.writeln(event.description);
    }
    
    sb.writeln('');
    if (event.isFull) {
      sb.writeln('Note: This event is currently full, but you can join the waitlist.');
    } else {
      sb.writeln('There are ${event.openSlots} spots available!');
    }
    
    // Add app link (replace with actual dynamic link when available)
    sb.writeln('');
    sb.writeln('Download Slotted to reserve your spot!');
    sb.writeln('https://slotted.app/events/${event.id}');
    
    return sb.toString();
  }
  
  // Copy to clipboard
  Future<bool> _copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      return true;
    } catch (e) {
      Logger.d('Error copying to clipboard: $e', tag: 'Sharing_service');
      return false;
    }
  }
  
  // Share via SMS
  Future<bool> _shareViaSms(String text) async {
    final Uri smsUri = Uri(
      scheme: 'sms',
      queryParameters: {'body': text},
    );
    
    return _launchUrl(smsUri);
  }
  
  // Share via Email
  Future<bool> _shareViaEmail(Event event, String text) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      queryParameters: {
        'subject': 'Join me at ${event.name} on ${DateFormat('MMM d').format(event.date)}',
        'body': text,
      },
    );
    
    return _launchUrl(emailUri);
  }
  
  // Share via Twitter
  Future<bool> _shareViaTwitter(String text) async {
    // Twitter has character limit, so we need to truncate
    final truncatedText = text.length > 280 ? '${text.substring(0, 277)}...' : text;
    
    final Uri twitterUri = Uri.parse(
      'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(truncatedText)}',
    );
    
    return _launchUrl(twitterUri);
  }
  
  // Share via Instagram (limited support as Instagram doesn't have a direct sharing API)
  Future<bool> _shareViaInstagram(String text) async {
    // Instagram doesn't support direct sharing of text via URL scheme
    // This is a fallback that just opens Instagram app
    final Uri instagramUri = Uri.parse('instagram://');
    
    return _launchUrl(instagramUri);
  }
  
  // Share via Facebook
  Future<bool> _shareViaFacebook(String text) async {
    final Uri facebookUri = Uri.parse(
      'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent('https://slotted.app')}&quote=${Uri.encodeComponent(text)}',
    );
    
    return _launchUrl(facebookUri);
  }
  
  // Helper to launch URLs
  Future<bool> _launchUrl(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      Logger.d('Error launching URL: $e', tag: 'Sharing_service');
      return false;
    }
  }
}

// Share methods enum
enum ShareMethod {
  defaultMethod,
  copyToClipboard,
  sms,
  email,
  twitter,
  instagram,
  facebook,
} 