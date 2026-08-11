import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:slotted/common/colors.dart';
import 'package:slotted/common/styling.dart';
import 'package:slotted/common/event_class.dart';
import 'package:slotted/common/slotted_user.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:slotted/common/responsive_system.dart';
import 'package:slotted/pages/edit_event.dart';
import 'package:slotted/api/report_content_service.dart';
import 'dart:math' as math;

/// Enhanced Event Card with modern design principles
/// Features: Glassmorphism, improved typography, better visual hierarchy,
/// micro-interactions, accessibility enhancements, and reservation functionality
class EnhancedEventCard extends StatefulWidget {
  final Event event;
  final SlottedUser? currentUser;
  final VoidCallback? onTap;
  final VoidCallback? onShare;
  final VoidCallback? onSave;
  final Future<void> Function(Event event)? onReserve;
  final bool isCompact;
  final bool showGradientOverlay;
  final EdgeInsets? customMargin;
  
  const EnhancedEventCard({
    super.key,
    required this.event,
    this.currentUser,
    this.onTap,
    this.onShare,
    this.onSave,
    this.onReserve,
    this.isCompact = false,
    this.showGradientOverlay = true,
    this.customMargin,
  });

  @override
  State<EnhancedEventCard> createState() => _EnhancedEventCardState();
}

class _EnhancedEventCardState extends State<EnhancedEventCard> 
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  bool _isHovered = false;
  bool _isReserving = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: AppStyling.animationShort,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: AppStyling.animationCurveEmphasized,
    ));
    
    _elevationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: AppStyling.animationCurveDecelerate,
    ));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _onHoverStart() {
    if (!_isHovered) {
      setState(() => _isHovered = true);
      _hoverController.forward();
    }
  }

  void _onHoverEnd() {
    if (_isHovered) {
      setState(() => _isHovered = false);
      _hoverController.reverse();
    }
  }

  /// Check if current user has reserved this event
  bool get _isReserved {
    if (widget.currentUser == null) return false;
    return widget.event.attendees.contains(widget.currentUser!.id);
  }

  /// Check if current user is on waitlist
  bool get _isWaitlisted {
    if (widget.currentUser == null) return false;
    return widget.event.waitlist.contains(widget.currentUser!.id);
  }

  /// Get reservation button text
  String get _reservationButtonText {
    if (widget.event.isExternalListing) return 'Open listing';
    if (_isReserved) return 'Reserved';
    if (_isWaitlisted) return 'Waitlist';
    if (widget.event.openSlots > 0) {
      return widget.event.price > 0 ? 'Reserve - \$${widget.event.price.toStringAsFixed(2)}' : 'Reserve';
    }
    return 'Join Waitlist';
  }

  /// Get reservation button icon
  IconData get _reservationButtonIcon {
    if (widget.event.isExternalListing) return CupertinoIcons.compass;
    if (_isReserved) return CupertinoIcons.checkmark_circle_fill;
    if (_isWaitlisted) return CupertinoIcons.clock_fill;
    if (widget.event.openSlots > 0) return CupertinoIcons.plus_circle_fill;
    return CupertinoIcons.person_2_fill;
  }

  Future<void> _openExternalListing() async {
    final rawUrl = widget.event.externalUrl?.trim() ?? '';
    if (rawUrl.isEmpty) return;
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Handle reservation action
  Future<void> _handleReservation() async {
    if (_isReserving) return;

    if (widget.event.isExternalListing) {
      setState(() => _isReserving = true);
      try {
        HapticFeedback.lightImpact();
        await _openExternalListing();
      } catch (e) {
        if (mounted) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Unable to open listing'),
              content: Text(e.toString()),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isReserving = false);
      }
      return;
    }

    if (widget.onReserve == null) return;
    
    setState(() => _isReserving = true);
    
    try {
      // Add haptic feedback for better UX
      HapticFeedback.lightImpact();
      
      // Call the reserve action
      await widget.onReserve!(widget.event);
      
      // Show success feedback using a dialog instead of SnackBar
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Success'),
            content: Text(_isReserved ? 'Successfully reserved!' : 'Reservation cancelled!'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Enhanced error handling
      debugPrint('Reservation error: $e');
      
      if (mounted) {
        // Show error dialog with retry option
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Reservation Failed'),
            content: Text('Could not process reservation: ${e.toString()}'),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              CupertinoDialogAction(
                child: const Text('Retry'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _handleReservation(); // Retry the reservation
                },
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isReserving = false);
      }
    }
  }

  /// Open map with event location
  Future<void> _openMap() async {
    if (widget.event.address.isEmpty) return;
    
    try {
      final query = Uri.encodeComponent(widget.event.address);
      final url = Uri.parse('https://maps.google.com/maps?q=$query');
      
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        _showMapError();
      }
    } catch (e) {
      debugPrint('Error launching maps: $e');
      if (mounted) {
        _showMapError();
      }
    }
  }

  /// Show error dialog when map fails to open
  void _showMapError() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: const Text('Could not open maps. Please try again.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;
    
    final cardHeight = widget.isCompact 
        ? layout.cardHeight * 0.8 
        : layout.cardHeight;
    
    final defaultMargin = EdgeInsets.symmetric(
      horizontal: ResponsiveSystem.getSpacing(context).m,
      vertical: ResponsiveSystem.getSpacing(context).s,
    );

    return AnimatedBuilder(
      animation: _hoverController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: widget.customMargin ?? defaultMargin,
            height: cardHeight,
            child: _buildCard(context),
          ),
        );
      },
    );
  }

  Widget _buildCard(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHoverStart(),
      onExit: (_) => _onHoverEnd(),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: _buildCardDecoration(),
          child: ClipRRect(
            borderRadius: AppStyling.borderRadiusLarge,
            child: Stack(
              children: [
                _buildBackgroundImage(),
                if (widget.showGradientOverlay) _buildGradientOverlay(),
                _buildContent(),
                _buildActionButtons(),
                _buildCategoryChip(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildCardDecoration() {
    const baseShadow = AppStyling.shadowMedium;
    const elevatedShadow = AppStyling.shadowLarge;
    
    final currentShadow = [
      ...baseShadow,
      ...elevatedShadow.map((shadow) => shadow.copyWith(
        color: shadow.color.withValues(
          alpha: (shadow.color.a / 255.0) * _elevationAnimation.value,
        ),
      )),
    ];

    return BoxDecoration(
      borderRadius: AppStyling.borderRadiusLarge,
      boxShadow: currentShadow,
      border: Border.all(
        color: AppColors.divider.withValues(alpha: 0.1),
        width: 1,
      ),
    );
  }

  Widget _buildBackgroundImage() {
    // Only show cached image if we have a valid URL
    if (widget.event.coverUrl.isEmpty) {
      return _buildImagePlaceholder();
    }
    
    return Positioned.fill(
      child: CachedNetworkImage(
        imageUrl: widget.event.coverUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildImagePlaceholder(),
        errorWidget: (context, url, error) => _buildImagePlaceholder(),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    final categoryColor = AppColors.getCategoryColor(widget.event.category);
    
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.getCategoryGradient(
          widget.event.category,
          opacity: 0.3,
        ),
      ),
      child: Center(
        child: Icon(
          AppColors.getCategoryIcon(widget.event.category),
          size: 48,
          color: categoryColor.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.3, 0.7, 1.0],
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.1),
              Colors.black.withValues(alpha: 0.6),
              Colors.black.withValues(alpha: 0.8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final horizontalPadding = widget.isCompact ? 16.0 : 20.0;
    final bottomPadding = widget.isCompact ? 16.0 : 20.0;
    
    return Positioned(
      left: horizontalPadding,
      right: horizontalPadding,
      bottom: bottomPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTitle(),
          const SizedBox(height: 8),
          _buildSubtitle(),
          const SizedBox(height: 12),
          _buildEventDetails(),
          if (!_isCurrentUserHost &&
              (widget.event.isExternalListing ||
                  (widget.onReserve != null && widget.currentUser != null))) ...[
            const SizedBox(height: 12),
            _buildReservationButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      widget.event.name.isNotEmpty ? widget.event.name : 'NO EVENT NAME',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        shadows: [
          Shadow(
            offset: Offset(0, 2),
            blurRadius: 4,
            color: Colors.black,
          ),
          Shadow(
            offset: Offset(0, 0),
            blurRadius: 8,
            color: Colors.black,
          ),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSubtitle() {
    if (widget.event.description.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Text(
      widget.event.description,
      style: AppStyling.bodySmall.copyWith(
        color: AppColors.textSecondary,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildEventDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildDateTimeInfo(),
            const Spacer(),
            _buildAttendeeInfo(),
          ],
        ),
        if (widget.event.address.isNotEmpty) ...[
          AppStyling.getSpacing(height: AppStyling.spacingSmall),
          _buildLocationInfo(),
        ],
        if (widget.event.hostName.isNotEmpty) ...[
          AppStyling.getSpacing(height: AppStyling.spacingSmall),
          _buildHostInfo(),
        ],
      ],
    );
  }

  Widget _buildDateTimeInfo() {
    final eventDate = widget.event.date;
    final dateText = DateFormat('MMM dd • h:mm a').format(eventDate);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          CupertinoIcons.calendar,
          size: 16,
          color: AppColors.textSecondary,
        ),
        AppStyling.getSpacing(width: AppStyling.spacingXSmall),
        Text(
          dateText,
          style: AppStyling.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationInfo() {
    return GestureDetector(
      onTap: () => _openMap(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            CupertinoIcons.location,
            size: 16,
            color: AppColors.textSecondary,
          ),
          AppStyling.getSpacing(width: AppStyling.spacingXSmall),
          Expanded(
            child: Text(
              widget.event.address,
              style: AppStyling.labelMedium.copyWith(
                color: AppColors.textSecondary,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          AppStyling.getSpacing(width: AppStyling.spacingXSmall),
          Icon(
            CupertinoIcons.map,
            size: 14,
            color: AppColors.textSecondary.withValues(alpha: 0.7),
          ),
        ],
      ),
    );
  }

  Widget _buildHostInfo() {
    final hostLabel = widget.event.isExternalListing
        ? 'At ${widget.event.hostName}'
        : 'Hosted by ${widget.event.hostName}';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          widget.event.isExternalListing
              ? CupertinoIcons.building_2_fill
              : CupertinoIcons.person_circle,
          size: 16,
          color: AppColors.textSecondary,
        ),
        AppStyling.getSpacing(width: AppStyling.spacingXSmall),
        Expanded(
          child: Text(
            hostLabel,
            style: AppStyling.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildAttendeeInfo() {
    final attendeeCount = widget.event.attendees.length;
    if (attendeeCount == 0) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildAttendeeAvatars(),
        AppStyling.getSpacing(width: AppStyling.spacingXSmall),
        Text(
          '+$attendeeCount',
          style: AppStyling.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAttendeeAvatars() {
    final attendees = widget.event.attendees;
    final displayCount = math.min(3, attendees.length);
    
    if (displayCount == 0) return const SizedBox.shrink();

    final avatarSize = widget.isCompact ? 20.0 : 24.0;
    final stackOffset = widget.isCompact ? 10.0 : 12.0;

    return SizedBox(
      width: displayCount * (avatarSize - stackOffset) + stackOffset,
      height: avatarSize,
      child: Stack(
        children: List.generate(displayCount, (index) {
          return Positioned(
            left: index * stackOffset,
            child: Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF1E1E1E),
                  width: widget.isCompact ? 1.5 : 2,
                ),
                gradient: AppColors.getCategoryGradient(
                  widget.event.category,
                  opacity: 0.8,
                ),
              ),
              child: _buildAvatarPlaceholder(),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF2A2A2A),
      ),
      child: const Icon(
        CupertinoIcons.person_fill,
        size: 12,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildReservationButton() {
    final bool isDisabled = _isReserving || widget.currentUser == null;
    final Color buttonColor = _isReserved 
        ? AppColors.getCategoryColor(widget.event.category)
        : (_isWaitlisted ? AppColors.neutral700 : AppColors.primaryDark);
    
    final buttonPadding = widget.isCompact 
        ? const EdgeInsets.symmetric(horizontal: AppStyling.spacingMedium, vertical: AppStyling.spacingSmall)
        : const EdgeInsets.symmetric(horizontal: AppStyling.spacingMedium, vertical: AppStyling.spacingSmall);
    
    final iconSize = widget.isCompact ? 16.0 : 18.0;
    final textStyle = widget.isCompact ? AppStyling.labelMedium : AppStyling.labelMedium;
    
    return SizedBox(
      width: double.infinity,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: CupertinoButton(
          padding: buttonPadding,
          color: isDisabled ? AppColors.neutral600 : buttonColor,
          disabledColor: AppColors.neutral600,
          onPressed: isDisabled ? null : () {
            // Add immediate visual feedback
            HapticFeedback.lightImpact();
            _handleReservation();
          },
          child: _isReserving
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: iconSize,
                      height: iconSize,
                      child: const CupertinoActivityIndicator(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    AppStyling.getSpacing(width: AppStyling.spacingSmall),
                    Text(
                      'Processing...',
                      style: textStyle.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _reservationButtonIcon,
                      size: iconSize,
                      color: AppColors.textPrimary,
                    ),
                    AppStyling.getSpacing(width: AppStyling.spacingSmall),
                    Text(
                      _reservationButtonText,
                      style: textStyle.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final topPadding = widget.isCompact ? AppStyling.spacingMedium : AppStyling.spacingMedium;
    final rightPadding = widget.isCompact ? AppStyling.spacingMedium : AppStyling.spacingMedium;
    
    return Positioned(
      top: topPadding,
      right: rightPadding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Host-only edit button (leftmost)
          if (_isCurrentUserHost) ...[
            _buildActionButton(
              icon: CupertinoIcons.pencil,
              onTap: _navigateToEditEvent,
            ),
            AppStyling.getSpacing(width: AppStyling.spacingSmall),
          ],
          if (widget.onShare != null) _buildActionButton(
            icon: CupertinoIcons.share,
            onTap: widget.onShare!,
          ),
          if (widget.onSave != null) ...[
            AppStyling.getSpacing(width: AppStyling.spacingSmall),
            _buildSaveButton(),
          ],
          // Report button for App Store compliance
          AppStyling.getSpacing(width: AppStyling.spacingSmall),
          _buildActionButton(
            icon: CupertinoIcons.flag,
            onTap: () => _showReportDialog(),
          ),
          AppStyling.getSpacing(width: AppStyling.spacingSmall),
          _buildActionButton(
            icon: CupertinoIcons.location_fill,
            onTap: _openMap,
          ),
        ],
      ),
    );
  }

  /// Check if the current event is saved by the user
  bool get _isEventSaved {
    if (widget.currentUser == null) return false;
    return widget.currentUser!.savedEvents.contains(widget.event.id);
  }

  /// Check if the current user is the host of this event
  bool get _isCurrentUserHost {
    if (widget.currentUser == null) return false;
    return widget.event.host == widget.currentUser!.id;
  }

  /// Navigate to edit event page (host only)
  void _navigateToEditEvent() async {
    if (!_isCurrentUserHost) {
      debugPrint('Non-host user attempted to edit event');
      return;
    }

    try {
      if (mounted) {
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => EditEventPage(
              user: widget.currentUser,
              event: widget.event,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error navigating to edit event: $e');
      
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: const Text('Failed to open event editor. Please try again.'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    }
  }

  /// Show report dialog
  void _showReportDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Report Event'),
        content: const Text('Are you sure you want to report this event? This action cannot be undone.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            child: const Text('Report'),
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              _reportEvent(); // Call the actual reporting function
            },
          ),
        ],
      ),
    );
  }

  /// Report the event to the backend
  Future<void> _reportEvent() async {
    if (widget.currentUser == null) {
      debugPrint('User not logged in, cannot report event.');
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: const Text('You must be logged in to report events.'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
      return;
    }

    try {
             final success = await ReportContentService.reportContent(
         contentType: 'event',
         contentId: widget.event.id,
         reportType: 'Inappropriate Content',
         reporterId: widget.currentUser!.id,
       );
      if (success && mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Report Sent'),
            content: const Text('Your report has been submitted. Thank you for helping keep our community safe.'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      } else {
        debugPrint('Failed to report event: $success');
        if (mounted) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Report Failed'),
              content: const Text('Failed to submit your report. Please try again.'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error reporting event: $e');
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Report Failed'),
            content: Text('Could not submit your report: ${e.toString()}'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    }
  }

  /// Build the save button with different visual states for saved/unsaved
  Widget _buildSaveButton() {
    const buttonSize = 32.0;
    const iconSize = 16.0;
    
    return StatefulBuilder(
      builder: (context, setLocalState) {
        final isSaved = _isEventSaved;  // Check saved state on each rebuild
        
        return GestureDetector(

          onTap: () {
            HapticFeedback.selectionClick(); // Additional haptic feedback on release
            widget.onSave!();
            // Force a rebuild of the parent widget to update saved state
            setState(() {});
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              color: isSaved 
                  ? Colors.white.withValues(alpha: 0.9)  // Clean white when saved
                  : Colors.white.withValues(alpha: 0.2),  // Default white
              borderRadius: AppStyling.borderRadiusCircular,
              border: Border.all(
                color: isSaved
                    ? Colors.grey.withValues(alpha: 0.4)  // Subtle gray border when saved
                    : Colors.white.withValues(alpha: 0.1),  // Default border
                width: isSaved ? 2 : 1  // Thicker border when saved
              ),
              boxShadow: isSaved
                  ? [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                        spreadRadius: 0,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: Transform.scale(
              scale: 1.0,
              child: Icon(
                isSaved ? CupertinoIcons.heart_fill : CupertinoIcons.heart,  // Filled heart when saved
                size: iconSize,
                color: isSaved
                    ? Colors.grey.shade600  // Subtle gray heart when saved
                    : AppColors.textPrimary,  // Default color
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    const buttonSize = 32.0;
    const iconSize = 16.0;
    
    return StatefulBuilder(
      builder: (context, setState) {
        
        return GestureDetector(

          onTap: () {
            HapticFeedback.selectionClick(); // Additional haptic feedback on release
            onTap();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: AppStyling.borderRadiusCircular,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1), 
                width: 1
              ),
              boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
            ),
            child: Transform.scale(
              scale: 1.0,
              child: Icon(
                icon,
                size: iconSize,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryChip() {
    const topPadding = AppStyling.spacingLarge;
    const leftPadding = AppStyling.spacingLarge;
    const iconSize = 12.0;
    
    return Positioned(
      top: topPadding,
      left: leftPadding,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppStyling.spacingSmall,
          vertical: AppStyling.spacingXSmall,
        ),
        decoration: BoxDecoration(
          color: AppColors.getCategoryColor(widget.event.category)
              .withValues(alpha: 0.9),
          borderRadius: AppStyling.borderRadiusCircular,
          boxShadow: AppStyling.shadowSubtle,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppColors.getCategoryIcon(widget.event.category),
              size: iconSize,
              color: Colors.white,
            ),
            AppStyling.getSpacing(width: AppStyling.spacingXSmall),
            Text(
              widget.event.category.toUpperCase(),
              style: AppStyling.overline.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Enhanced skeleton loading card that matches the new design
class EnhancedSkeletonEventCard extends StatefulWidget {
  final bool isCompact;
  final EdgeInsets? customMargin;
  final bool animate;
  
  const EnhancedSkeletonEventCard({
    super.key,
    this.isCompact = false,
    this.customMargin,
    this.animate = true,
  });
  
  @override
  State<EnhancedSkeletonEventCard> createState() => _EnhancedSkeletonEventCardState();
}

class _EnhancedSkeletonEventCardState extends State<EnhancedSkeletonEventCard> 
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  
  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: AppStyling.animationExtended,
    );
    
    if (widget.animate) {
      _shimmerController.repeat(reverse: true);
    }
  }
  
  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final cardHeight = widget.isCompact ? 200.0 : 
                     (screenSize.width < AppStyling.mobileBreakpoint ? 260.0 : 300.0);
    
    const defaultMargin = EdgeInsets.symmetric(
      horizontal: AppStyling.spacingLarge,
      vertical: AppStyling.spacingMedium,
    );
    
    return Container(
      margin: widget.customMargin ?? defaultMargin,
      height: cardHeight,
      decoration: AppStyling.getCardDecoration(),
      child: ClipRRect(
        borderRadius: AppStyling.borderRadiusLarge,
        child: Stack(
          children: [
            _buildShimmerBackground(),
            _buildShimmerContent(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildShimmerBackground() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF424242).withValues(alpha: 0.3),
                  const Color(0xFF616161).withValues(alpha: 0.1 + _shimmerController.value * 0.3),
                  const Color(0xFF424242).withValues(alpha: 0.3),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildShimmerContent() {
    return Positioned(
      left: AppStyling.spacingLarge,
      right: AppStyling.spacingLarge,
      bottom: AppStyling.spacingLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildShimmerBox(
            width: double.infinity,
            height: widget.isCompact ? 16 : 20,
          ),
          AppStyling.getSpacing(height: AppStyling.spacingXSmall),
          _buildShimmerBox(
            width: MediaQuery.of(context).size.width * 0.6,
            height: 12,
          ),
          AppStyling.getSpacing(height: AppStyling.spacingMedium),
          Row(
            children: [
              _buildShimmerBox(width: 100, height: 12),
              const Spacer(),
              _buildShimmerBox(width: 60, height: 12),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildShimmerBox({required double width, required double height}) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFF757575).withValues(
              alpha: 0.3 + _shimmerController.value * 0.3,
            ),
            borderRadius: AppStyling.borderRadiusSmall,
          ),
        );
      },
    );
  }
} 