// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:location_picker_flutter_map/location_picker_flutter_map.dart';
import 'package:slotted/common/colors.dart';
import 'package:slotted/common/constants.dart';
import 'package:slotted/common/event_class.dart';
import 'package:slotted/common/slotted_user.dart';
import 'package:board_datetime_picker/board_datetime_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

import 'package:slotted/pages/location.dart';
import 'package:slotted/utils/logger.dart';
import 'package:slotted/common/design_system.dart';

import 'package:slotted/widgets/ds_section_header.dart';



class EditEventPage extends StatefulWidget {
  const EditEventPage({super.key, required this.user, this.event});

  final SlottedUser? user;

  final Event? event;

  @override
  EditEventPageState createState() => EditEventPageState();
}

class EditEventPageState extends State<EditEventPage> {
  late FocusNode eventNameNode;
  late FocusNode eventDateNode;
  late FocusNode eventSlotsNode;
  late FocusNode eventPriceNode;
  late FocusNode eventRulesNode;
  late FocusNode eventLocationNode;
  late FocusNode eventPasswordNode;
  late TextEditingController eventNameController;
  late TextEditingController eventDate;
  late TextEditingController eventSlots;
  late TextEditingController eventPrice;
  late TextEditingController eventRules;
  late TextEditingController eventLocation;
  late TextEditingController eventPassword;
  bool eventDateFocused = false;
  String selectedCategory = 'other';
  bool isPrivate = false;
  bool showPassword = false;
  bool isLoading = false;
  LatLong? eventLocationData;
  final textController = BoardDateTimeTextController();
  final dateFormatter = DateFormat('EEE, MMM d • h:mm a');
  String _selectedQuickFilter = '';
  
  // Add date-time picker state variables
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  int _selectedDay = DateTime.now().day;
  int _selectedHour = DateTime.now().hour;
  int _selectedMinute = (DateTime.now().minute ~/ 15) * 15;
  bool _isAM = DateTime.now().hour < 12;

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  String _uploadStatus = '';
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupEventData();
  }

  @override
  void didUpdateWidget(EditEventPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.event != oldWidget.event) {
      _setupEventData();
    }
  }

  void _initializeControllers() {
    eventNameNode = FocusNode();
    eventDateNode = FocusNode();
    eventSlotsNode = FocusNode();
    eventPriceNode = FocusNode();
    eventRulesNode = FocusNode();
    eventLocationNode = FocusNode();
    eventPasswordNode = FocusNode();
    
    eventNameController = TextEditingController();
    eventDate = TextEditingController();
    eventSlots = TextEditingController();
    eventPrice = TextEditingController();
    eventRules = TextEditingController();
    eventLocation = TextEditingController();
    eventPassword = TextEditingController();

    // Add price formatting listener
    eventPriceNode.addListener(() {
      if (!eventPriceNode.hasFocus) {
        _formatPrice();
      }
    });
  }

  void _formatPrice() {
    eventPrice.text =
        double.tryParse(eventPrice.text)?.toStringAsFixed(2) ?? '0.00';
    // Make sure it is rounded to the closest multiple of 0.05
    double price = double.parse(eventPrice.text);
    if (price < 0.50 && price != 0) {
      price = 0.50;
    } else {
      double remainder = price % 0.05;
      if (remainder != 0) {
        if (remainder < 0.026) {
          price -= remainder;
        } else {
          price += 0.05 - remainder;
        }
      }
    }
    eventPrice.text = price.toStringAsFixed(2);
  }

  void _setupEventData() {
    if (widget.event != null) {
      eventNameController.text = widget.event!.name;
      eventDate.text = dateFormatter.format(
          widget.event!.date.isAfter(DateTime.now())
              ? widget.event!.date
              : DateTime.now());
      eventSlots.text = widget.event!.slots.toString();
      eventPrice.text = widget.event!.price.toStringAsFixed(2);
      eventRules.text = widget.event!.rules;
      eventLocation.text = widget.event!.address;
      selectedCategory = widget.event!.category;
      isPrivate = widget.event!.isPrivate;
      eventPassword.text = widget.event!.password ?? '';
    } else {
      // Set empty values for new event
      eventNameController.text = '';
      eventDate.text = dateFormatter.format(DateTime.now().add(const Duration(days: 1)));
      eventSlots.text = '';
      eventPrice.text = '0.00';
      eventRules.text = '';
      eventLocation.text = '';
      selectedCategory = 'other';
      isPrivate = false;
      eventPassword.text = '';
    }
  }

  @override
  void dispose() {
    eventNameController.dispose();
    eventDate.dispose();
    eventSlots.dispose();
    eventPrice.dispose();
    eventRules.dispose();
    eventLocation.dispose();
    eventPassword.dispose();
    eventNameNode.dispose();
    eventDateNode.dispose();
    eventSlotsNode.dispose();
    eventPriceNode.dispose();
    eventRulesNode.dispose();
    eventLocationNode.dispose();
    eventPasswordNode.dispose();
    super.dispose();
  }

  KeyboardActionsConfig _buildConfig(BuildContext context) {
    return KeyboardActionsConfig(
      keyboardActionsPlatform: KeyboardActionsPlatform.ALL,
      keyboardBarColor: AppColors.backgroundDark.withValues(alpha: 0.9),
      nextFocus: false,
      actions: [
        KeyboardActionsItem(focusNode: eventNameNode, toolbarButtons: [
          (node) {
            return CupertinoButton(
              padding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
              onPressed: () => node.unfocus(),
              child: const Text(
                'Done',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }
        ]),
        KeyboardActionsItem(focusNode: eventSlotsNode, toolbarButtons: [
          (node) {
            return CupertinoButton(
              padding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
              onPressed: () => node.unfocus(),
              child: const Text(
                'Done',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }
        ]),
        KeyboardActionsItem(focusNode: eventPriceNode, toolbarButtons: [
          (node) {
            return CupertinoButton(
              padding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
              onPressed: () => node.unfocus(),
              child: const Text(
                'Done',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }
        ]),
        KeyboardActionsItem(focusNode: eventRulesNode, toolbarButtons: [
          (node) {
            return CupertinoButton(
              padding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
              onPressed: () => node.unfocus(),
              child: const Text(
                'Done',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }
        ]),
      ],
    );
  }

  // Helper to check if form is valid for saving
  bool get canSave {
    return eventNameController.text.isNotEmpty &&
        eventDate.text.isNotEmpty &&
        eventSlots.text.isNotEmpty &&
        eventPrice.text.isNotEmpty &&
        eventLocation.text.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    bool newEvent = widget.event == null;
    final now = DateTime.now();
    textController.setText('Event Date');
    
    return CupertinoPageScaffold(
      backgroundColor: DesignSystem.backgroundDark,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: DesignSystem.backgroundDark.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: DesignSystem.primaryOrange.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DesignSystem.primaryOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              CupertinoIcons.back,
              color: DesignSystem.primaryOrange,
              size: 20,
            ),
          ),
        ),
        middle: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${newEvent ? '✨ Create' : '🎨 Edit'} Event',
              style: DesignSystem.h3.copyWith(
                color: DesignSystem.primaryOrange,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (isLoading) ...[
              const SizedBox(height: 4),
              Container(
                width: 100,
                height: 2,
                decoration: BoxDecoration(
                  color: DesignSystem.primaryOrange.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(1),
                ),
                child: const LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(DesignSystem.primaryOrange),
                ),
              ),
            ],
          ],
        ),
        trailing: canSave ? Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: DesignSystem.primaryOrange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            CupertinoIcons.checkmark_alt,
            color: DesignSystem.primaryOrange,
            size: 16,
          ),
        ) : null,
      ),
      child: SafeArea(
      child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                DesignSystem.primaryOrange.withValues(alpha: 0.05),
                DesignSystem.primaryOrange.withValues(alpha: 0.05),
                ],
              ),
            ),
          child: KeyboardActions(
            config: _buildConfig(context),
            disableScroll: true,
            isDialog: false,
            overscroll: 0,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                DesignSystem.spacingM,
                DesignSystem.spacingL,
                DesignSystem.spacingM,
                DesignSystem.spacingXL,
                    ),
                    child: Column(
                children: <Widget>[
                  // Primary Event Information Group
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event Name Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const DSSectionHeader(
                            title: 'Event Name',
                            icon: CupertinoIcons.textformat,
                            showBorder: false,
                            padding: EdgeInsets.zero,
                          ),
                          LayoutHelpers.sectionSpacing,
                          _buildTextField(
                            key: const Key('name_field'),
                        controller: eventNameController,
                        focusNode: eventNameNode,
                            placeholder: 'Give your event a catchy name',
                        textCapitalization: TextCapitalization.characters,
                        onChanged: (value) {
                          setState(() {
                            eventNameController.text = value.toUpperCase();
                          });
                        },
                          ),
                        ],
                      ),

                      LayoutHelpers.mediumSpacing,

                      // Category Selection
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const DSSectionHeader(
                            title: 'Event Category',
                            icon: CupertinoIcons.tag,
                            showBorder: false,
                            padding: EdgeInsets.zero,
                          ),
                          LayoutHelpers.sectionSpacing,
                          Container(
                            height: 100,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildEnhancedCategoryBubble('Comedy', '🤣', 'comedy'),
                                  LayoutHelpers.horizontalSpacingM,
                                  _buildEnhancedCategoryBubble('DJ', '🎧', 'dj'),
                                  LayoutHelpers.horizontalSpacingM,
                                  _buildEnhancedCategoryBubble('Poetry', '✍️', 'poetry'),
                                  LayoutHelpers.horizontalSpacingM,
                                  _buildEnhancedCategoryBubble('Music', '🎼', 'music'),
                                  LayoutHelpers.horizontalSpacingM,
                                  _buildEnhancedCategoryBubble('Other', '🎭', 'other'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  LayoutHelpers.largeSpacing,

                  // Event Details Group
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const DSSectionHeader(
                        title: 'Event Details',
                        icon: CupertinoIcons.calendar,
                        showBorder: false,
                        padding: EdgeInsets.zero,
                      ),
                      LayoutHelpers.sectionSpacing,
                      
                      // Date and Time
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'When is your event?',
                            style: DesignSystem.caption.copyWith(
                              color: DesignSystem.primaryOrange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          LayoutHelpers.smallSpacing,
                          _buildTextField(
                            key: const Key('date_field'),
                        controller: eventDate,
                        focusNode: eventDateNode,
                            placeholder: 'Select date and time',
                        readOnly: true,
                        onTap: () => _showDatePicker(context, now),
                          ),
                        ],
                      ),

                      LayoutHelpers.mediumSpacing,

                      // Capacity and Pricing
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Available Slots',
                                  style: DesignSystem.caption.copyWith(
                                    color: DesignSystem.primaryOrange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                LayoutHelpers.smallSpacing,
                                _buildTextField(
                                  key: const Key('slots_field'),
                              controller: eventSlots,
                              focusNode: eventSlotsNode,
                                  placeholder: 'Number of slots',
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                ),
                              ],
                            ),
                          ),
                          LayoutHelpers.horizontalSpacingM,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Price per Slot',
                                  style: DesignSystem.caption.copyWith(
                                    color: DesignSystem.primaryOrange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                LayoutHelpers.smallSpacing,
                                _buildTextField(
                                  key: const Key('price_field'),
                              controller: eventPrice,
                              focusNode: eventPriceNode,
                                  placeholder: 'Set price',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  LayoutHelpers.largeSpacing,

                  // Location Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const DSSectionHeader(
                        title: 'Location',
                        icon: CupertinoIcons.location,
                        showBorder: false,
                        padding: EdgeInsets.zero,
                      ),
                      LayoutHelpers.sectionSpacing,
                      _buildTextField(
                        key: const Key('location_field'),
                    controller: eventLocation,
                    focusNode: eventLocationNode,
                        placeholder: 'Select event location',
                    readOnly: true,
                    onTap: () => _selectLocation(context, eventLocation, eventLocationData),
                      ),
                    ],
                  ),

                  LayoutHelpers.largeSpacing,

                  // Additional Information Group
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Rules Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const DSSectionHeader(
                            title: 'Event Rules',
                            icon: CupertinoIcons.doc_text,
                            showBorder: false,
                            padding: EdgeInsets.zero,
                          ),
                          LayoutHelpers.sectionSpacing,
                          _buildTextField(
                            key: const Key('rules_field'),
                        controller: eventRules,
                        focusNode: eventRulesNode,
                            placeholder: 'Add your event rules (Optional)',
                        maxLines: null,
                        minLines: 3,
                          ),
                        ],
                      ),

                      LayoutHelpers.mediumSpacing,

                      // Private Event Toggle
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: DesignSystem.borderLight.withValues(alpha: 0.3),
                            width: 0.5,
                          ),
                        ),
                        child: CupertinoButton(
                          key: const Key('private_event_toggle'),
                          padding: const EdgeInsets.all(16),
                          onPressed: () {
                            setState(() {
                              isPrivate = !isPrivate;
                            });
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Private Event',
                                style: TextStyle(
                                  color: DesignSystem.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Icon(
                                isPrivate ? CupertinoIcons.lock_fill : CupertinoIcons.lock_open_fill,
                                color: isPrivate ? DesignSystem.primaryOrange : DesignSystem.textTertiary,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (isPrivate) ...[
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: DesignSystem.borderLight.withValues(alpha: 0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                                child: Text(
                                  'Event Password',
                                  style: TextStyle(
                                    color: DesignSystem.primaryOrange,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              _buildTextField(
                                key: const Key('password_field'),
                            controller: eventPassword,
                            focusNode: eventPasswordNode,
                                placeholder: 'Set event password',
                            obscureText: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),

                  LayoutHelpers.largeSpacing,

                  // Image Upload Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const DSSectionHeader(
                        title: 'Event Image',
                        icon: CupertinoIcons.photo,
                        showBorder: false,
                        padding: EdgeInsets.zero,
                      ),
                      LayoutHelpers.sectionSpacing,
                      _buildImageUploadSection(),
                    ],
                  ),

                  LayoutHelpers.largeSpacing,

                  // Form Validation Status
                  _buildFormValidationStatus(),

                  LayoutHelpers.largeSpacing,

                  // Action Buttons
                  _buildActionButtons(newEvent),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Enhanced text field with modern styling and better UX
  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String placeholder,
    bool readOnly = false,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Function(String)? onChanged,
    Function()? onTap,
    int? maxLines = 1,
    int? minLines,
    bool obscureText = false,
    Key? key,
  }) {
    final bool isDateField = key == const Key('date_field');
    final bool isNameField = key == const Key('name_field');
    final bool hasFocus = focusNode.hasFocus;
    final bool hasContent = controller.text.isNotEmpty;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 12),
      decoration: BoxDecoration(
        color: hasFocus 
            ? DesignSystem.primaryOrange.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasFocus 
              ? DesignSystem.primaryOrange.withValues(alpha: 0.6)
              : DesignSystem.borderLight.withValues(alpha: 0.3),
          width: hasFocus ? 1.5 : 0.5,
        ),
      ),
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          CupertinoTextField(
            key: key,
        enabled: !isLoading,
        controller: controller,
        focusNode: focusNode,
            padding: EdgeInsets.fromLTRB(
              12,
              isNameField && hasContent ? 16 : 12,
              12,
              12,
            ),
        readOnly: readOnly,
            obscureText: obscureText && !showPassword,
        textCapitalization: textCapitalization,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onTap: () {
              HapticFeedback.selectionClick();
                        setState(() {
            if (onTap != null) {
              onTap();
            } else {
              FocusScope.of(context).requestFocus(focusNode);
            }
          });
        },
            onChanged: (value) {
              setState(() {
                if (onChanged != null) {
                  onChanged(value);
                }
              });
            },
        maxLines: maxLines,
        minLines: minLines,
        decoration: null,
        style: TextStyle(
              color: DesignSystem.textPrimary,
              fontSize: isDateField ? 14 : (isNameField ? 14 : 13),
              fontWeight: isDateField || isNameField ? FontWeight.w600 : FontWeight.w500,
              letterSpacing: isDateField ? -0.3 : (isNameField ? 0.5 : 0),
            ),
            placeholder: isNameField && hasContent ? '' : placeholder,
        placeholderStyle: const TextStyle(
              color: DesignSystem.textTertiary,
          fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
            suffix: _buildTextFieldSuffix(isDateField, obscureText, controller),
          ),
          // Floating label for name field
          if (isNameField && hasContent) 
            Positioned(
              left: 12,
              top: 4,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: hasContent ? 1.0 : 0.0,
                child: Text(
                  'Event Name',
                  style: TextStyle(
                    color: DesignSystem.primaryOrange.withValues(alpha: 0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Helper method to build text field suffix icons
  Widget? _buildTextFieldSuffix(bool isDateField, bool obscureText, TextEditingController controller) {
    if (isDateField) {
      return Padding(
        padding: const EdgeInsets.only(right: 16),
              child: Icon(
                CupertinoIcons.calendar,
          color: DesignSystem.primaryOrange.withValues(alpha: 0.7),
                size: 20,
              ),
      );
    }
    
    if (obscureText && controller.text.isNotEmpty) {
      return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: CupertinoButton(
                key: const Key('password_visibility_toggle'),
                padding: EdgeInsets.zero,
                onPressed: () {
            HapticFeedback.selectionClick();
                  setState(() {
                    showPassword = !showPassword;
                  });
                },
                child: Icon(
                  showPassword ? CupertinoIcons.eye_slash_fill : CupertinoIcons.eye_fill,
                  color: AppColors.backgroundLight.withValues(alpha: 0.5),
                  size: 20,
                ),
              ),
      );
    }
    
    return null;
  }

  // Enhanced image upload section with better UX
  Widget _buildImageUploadSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DesignSystem.borderLight.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          if (_imageFile != null) ...[
            // Image preview
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: FileImage(_imageFile!),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.5),
                        ],
                      ),
                    ),
                  ),
                  // Change button
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: DesignSystem.primaryOrange,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        onPressed: _pickEventImage,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.camera,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Change',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Upload prompt
            Container(
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: DesignSystem.primaryOrange.withValues(alpha: 0.3),
                  width: 2,
                  style: BorderStyle.solid,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    DesignSystem.primaryOrange.withValues(alpha: 0.05),
                    DesignSystem.primaryOrange.withValues(alpha: 0.02),
                  ],
                ),
              ),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _pickEventImage,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: DesignSystem.primaryOrange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Icon(
                        CupertinoIcons.camera_fill,
                        color: DesignSystem.primaryOrange,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Add Event Photo',
                      style: DesignSystem.body1.copyWith(
                        color: DesignSystem.primaryOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Make your event stand out!',
                      style: DesignSystem.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (_uploadStatus.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _uploadStatus.contains('successful') 
                    ? Colors.green.withValues(alpha: 0.1)
                    : _uploadStatus.contains('failed')
                        ? Colors.red.withValues(alpha: 0.1)
                        : DesignSystem.primaryOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isUploading) ...[
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CupertinoActivityIndicator(
                        color: DesignSystem.primaryOrange,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      _uploadStatus,
                      style: DesignSystem.caption.copyWith(
                        color: _uploadStatus.contains('successful') 
                            ? Colors.green
                            : _uploadStatus.contains('failed')
                                ? Colors.red
                                : DesignSystem.primaryOrange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Form validation status indicator
  Widget _buildFormValidationStatus() {
    final List<String> missingFields = [];
    
    if (eventNameController.text.isEmpty) missingFields.add('Event Name');
    if (eventDate.text.isEmpty) missingFields.add('Date & Time');
    if (eventSlots.text.isEmpty) missingFields.add('Available Slots');
    if (eventPrice.text.isEmpty) missingFields.add('Price');
    if (eventLocation.text.isEmpty) missingFields.add('Location');
    
    if (missingFields.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.withValues(alpha: 0.1),
              Colors.green.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.green.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              CupertinoIcons.checkmark_circle_fill,
              color: Colors.green,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'All required fields completed! Ready to publish.',
                style: DesignSystem.body2.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.withValues(alpha: 0.1),
            Colors.orange.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.info_circle_fill,
                color: Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Complete these fields to publish:',
                style: DesignSystem.body2.copyWith(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: missingFields.map((field) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                field,
                style: DesignSystem.caption.copyWith(
                  color: Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  // Enhanced action buttons with better styling and animations
  Widget _buildActionButtons(bool newEvent) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            DesignSystem.backgroundDark.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
      children: [
        if (!newEvent) ...[
            Expanded(
              child: AnimatedScale(
                duration: const Duration(milliseconds: 200),
                scale: isLoading ? 0.95 : 1.0,
            child: Container(
                  height: 56,
              decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        CupertinoColors.destructiveRed.withValues(alpha: 0.15),
                        CupertinoColors.destructiveRed.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: CupertinoColors.destructiveRed.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: isLoading ? null : () {
                      HapticFeedback.lightImpact();
                      _showDeleteConfirmation();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          CupertinoIcons.trash,
                          color: CupertinoColors.destructiveRed,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                'Delete',
                          style: DesignSystem.body1.copyWith(
                  color: CupertinoColors.destructiveRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            flex: newEvent ? 1 : 2,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 200),
              scale: isLoading ? 0.98 : 1.0,
              child: Container(
                height: 56,
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                    colors: canSave && !isLoading ? [
                      DesignSystem.primaryOrange,
                      DesignSystem.primaryOrange.withValues(alpha: 0.8),
                    ] : [
                      Colors.grey.withValues(alpha: 0.3),
                      Colors.grey.withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                boxShadow: canSave && !isLoading ? [
                  BoxShadow(
                      color: DesignSystem.primaryOrange.withValues(alpha: 0.3),
                      blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ] : null,
              ),
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: canSave && !isLoading ? () async {
                    HapticFeedback.mediumImpact();
                    setState(() {
                      isLoading = true;
                    });
                    
                    // Add a slight delay for visual feedback
                    await Future.delayed(const Duration(milliseconds: 300));
                    
                    await _saveEvent(newEvent);
                  } : null,
              child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading) ...[
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CupertinoActivityIndicator(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          newEvent ? 'Publishing...' : 'Updating...',
                          style: DesignSystem.body1.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ] else ...[
                        Icon(
                          newEvent ? CupertinoIcons.sparkles : CupertinoIcons.checkmark_alt_circle,
                          color: Colors.white,
                          size: 20,
                        ),
                    const SizedBox(width: 8),
                  Text(
                          newEvent ? 'Publish Event ✨' : 'Update Event 🎉',
                          style: DesignSystem.body1.copyWith(
                            color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                      ],
                ],
                  ),
              ),
            ),
          ),
        ),
      ],
      ),
    );
  }

  // Add helper method for date picker
  void _showDatePicker(BuildContext context, DateTime now) async {
    try {
      // Reset the quick filter selection when opening the picker
      _selectedQuickFilter = '';
      
      // Always ensure we're in current year or later
      final currentYear = now.year;
      final effectiveYear = currentYear;
      
      // If no date is selected, initialize with a future time
      if (eventDate.text.isEmpty) {
        // Start with tomorrow at the next 15-minute interval
        final tomorrow = now.add(const Duration(days: 1));
        final startDate = DateTime(
          effectiveYear,
          tomorrow.month,
          tomorrow.day,
          tomorrow.hour,
          15 - tomorrow.minute % 15,
        );
        eventDate.text = dateFormatter.format(startDate);
      }

      // Initialize selected values from the current date text or default to tomorrow
      DateTime currentDate;
      try {
        currentDate = eventDate.text.isNotEmpty 
          ? dateFormatter.parse(eventDate.text)
          : now.add(const Duration(days: 1));
      } catch (e) {
        // Show a friendly error message if date parsing fails
        await showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Oops! 🤔'),
            content: const Text(
              "Looks like there's something funky with the date format! Let's pick a new date and time together. 📅✨",
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Got it!'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
        
        // Use tomorrow as fallback
        currentDate = now.add(const Duration(days: 1));
      }
      
      _selectedYear = max(currentDate.year, DateTime.now().year);
      _selectedMonth = currentDate.month;
      _selectedDay = currentDate.day;
      _selectedHour = currentDate.hour;
      _selectedMinute = (currentDate.minute ~/ 15) * 15;
      _isAM = currentDate.hour < 12;

      Logger.d('DEBUG: Initial date picker values:', tag: 'Edit_event');
      Logger.d('Year: $_selectedYear', tag: 'Edit_event');
      Logger.d('Month: $_selectedMonth', tag: 'Edit_event');
      Logger.d('Day: $_selectedDay', tag: 'Edit_event');
      Logger.d('Hour: $_selectedHour', tag: 'Edit_event');
      Logger.d('Minute: $_selectedMinute', tag: 'Edit_event');
      Logger.d('Is AM: $_isAM', tag: 'Edit_event');

      // Store the context size before the async operation
      final contextSize = MediaQuery.of(context).size;
      
      final result = await showCupertinoDialog<DateTime>(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return Center(
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                // Create scroll controllers for the pickers
                final monthController = FixedExtentScrollController(initialItem: _selectedMonth - 1);
                final dayController = FixedExtentScrollController(initialItem: _selectedDay - 1);
                final yearController = FixedExtentScrollController(initialItem: _selectedYear - DateTime.now().year);
                final hourController = FixedExtentScrollController(initialItem: _selectedHour % 12);
                final minuteController = FixedExtentScrollController(initialItem: _selectedMinute ~/ 15);
                final amPmController = FixedExtentScrollController(initialItem: _isAM ? 0 : 1);
                
                // Create a function to build quick select buttons with the dialog's setState
                Widget buildQuickSelectButtonInDialog(String title, DateTime date) {
                  final bool isSelected = _selectedQuickFilter == title;
                  
                  return AnimatedScale(
                    duration: const Duration(milliseconds: 200),
                    scale: isSelected ? 1.05 : 1.0,
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        // Use the dialog's setState to update the UI
                        setDialogState(() {
                          _selectedQuickFilter = title;
                          _selectedYear = date.year;
                          _selectedMonth = date.month;
                          _selectedDay = date.day;
                          _selectedHour = date.hour;
                          _selectedMinute = (date.minute ~/ 15) * 15;
                          _isAM = date.hour < 12;
                          
                          // Update the scroll controllers to reflect the new values
                          monthController.jumpToItem(_selectedMonth - 1);
                          dayController.jumpToItem(_selectedDay - 1);
                          yearController.jumpToItem(_selectedYear - DateTime.now().year);
                          hourController.jumpToItem(_selectedHour % 12);
                          minuteController.jumpToItem(_selectedMinute ~/ 15);
                          amPmController.jumpToItem(_isAM ? 0 : 1);
                        });
                        
                        // Also update the parent widget's state
                        setState(() {
                          eventDate.text = dateFormatter.format(date);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isSelected
                                ? [AppColors.primary, AppColors.secondary]
                                : [AppColors.primary.withValues(alpha: 0.2), AppColors.secondary.withValues(alpha: 0.2)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppColors.accent : AppColors.primary.withValues(alpha: 0.3),
                            width: isSelected ? 2.0 : 1.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                  BoxShadow(
                                    color: AppColors.secondary.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) ...[
                              const Icon(
                                CupertinoIcons.checkmark_circle_fill,
                                color: AppColors.accent,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              title,
                              style: TextStyle(
                                color: isSelected ? AppColors.backgroundLight : AppColors.accent,
                                fontSize: isSelected ? 16 : 15,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  width: double.infinity,
                  height: contextSize.height * 0.7,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundDark,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary.withValues(alpha: 0.2),
                              AppColors.secondary.withValues(alpha: 0.2),
                            ],
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Cancel button - fixed width
                                      SizedBox(
                                        width: constraints.maxWidth * 0.25,
                                        child: CupertinoButton(
                                          padding: EdgeInsets.zero,
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                CupertinoIcons.xmark,
                                                color: AppColors.accent,
                                                size: 14,
                                              ),
                                              SizedBox(width: 2),
                                              Text(
                                                'Cancel',
                                                style: TextStyle(
                                                  color: AppColors.accent,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Title - flexible center
                                      const Expanded(
                                        child: Text(
                                          'Select Date & Time',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: AppColors.backgroundLight,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      // Done button - fixed width
                                      SizedBox(
                                        width: constraints.maxWidth * 0.25,
                                        child: CupertinoButton(
                                          padding: EdgeInsets.zero,
                                          onPressed: () {
                                            final selectedDate = DateTime(
                                              _selectedYear,
                                              _selectedMonth,
                                              _selectedDay,
                                              _selectedHour,
                                              _selectedMinute,
                                            );
                                            Navigator.of(context).pop(selectedDate);
                                          },
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              Text(
                                                'Done',
                                                style: TextStyle(
                                                  color: AppColors.accent,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(width: 2),
                                              Icon(
                                                CupertinoIcons.check_mark,
                                                color: AppColors.accent,
                                                size: 14,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  buildQuickSelectButtonInDialog(
                                    'Today',
                                    now,
                                  ),
                                  const SizedBox(width: 8),
                                  buildQuickSelectButtonInDialog(
                                    'Tomorrow',
                                    now.add(const Duration(days: 1)),
                                  ),
                                  const SizedBox(width: 8),
                                  buildQuickSelectButtonInDialog(
                                    'Next Week',
                                    now.add(const Duration(days: 7)),
                                  ),
                                  const SizedBox(width: 8),
                                  buildQuickSelectButtonInDialog(
                                    'Next Month',
                                    now.add(const Duration(days: 30)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primary.withValues(alpha: 0.05),
                                AppColors.secondary.withValues(alpha: 0.05),
                              ],
                            ),
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(24),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Date Selection (Left Side)
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppColors.primary.withValues(alpha: 0.1),
                                        AppColors.secondary.withValues(alpha: 0.1),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppColors.primary.withValues(alpha: 0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 12),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              CupertinoIcons.calendar,
                                              color: AppColors.accent,
                                              size: 18,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Date',
                                              style: TextStyle(
                                                color: AppColors.accent,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        height: 1,
                                        color: AppColors.primary.withValues(alpha: 0.2),
                                      ),
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: CupertinoPicker(
                                                backgroundColor: Colors.transparent,
                                                itemExtent: 40,
                                                scrollController: monthController,
                                                onSelectedItemChanged: (index) {
                                                  setDialogState(() {
                                                    _selectedMonth = index + 1;
                                                  });
                                                },
                                                children: List<Widget>.generate(12, (index) {
                                                  return Center(
                                                    child: Text(
                                                      DateFormat('MMM').format(DateTime(2024, index + 1)),
                                                      style: const TextStyle(
                                                        color: AppColors.backgroundLight,
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  );
                                                }),
                                              ),
                                            ),
                                            Container(
                                              width: 1,
                                              color: AppColors.primary.withValues(alpha: 0.2),
                                            ),
                                            Expanded(
                                              child: CupertinoPicker(
                                                backgroundColor: Colors.transparent,
                                                itemExtent: 40,
                                                scrollController: dayController,
                                                onSelectedItemChanged: (index) {
                                                  setDialogState(() {
                                                    _selectedDay = index + 1;
                                                  });
                                                },
                                                children: List<Widget>.generate(31, (index) {
                                                  return Center(
                                                    child: Text(
                                                      '${index + 1}',
                                                      style: const TextStyle(
                                                        color: AppColors.backgroundLight,
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  );
                                                }),
                                              ),
                                            ),
                                            Container(
                                              width: 1,
                                              color: AppColors.primary.withValues(alpha: 0.2),
                                            ),
                                            Expanded(
                                              child: CupertinoPicker(
                                                backgroundColor: Colors.transparent,
                                                itemExtent: 40,
                                                scrollController: yearController,
                                                onSelectedItemChanged: (index) {
                                                  setDialogState(() {
                                                    _selectedYear = DateTime.now().year + index;
                                                  });
                                                },
                                                children: List<Widget>.generate(5, (index) {
                                                  final year = DateTime.now().year + index;
                                                  return Center(
                                                    child: Text(
                                                      '$year',
                                                      style: const TextStyle(
                                                        color: AppColors.backgroundLight,
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  );
                                                }),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Time Selection (Right Side)
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppColors.secondary.withValues(alpha: 0.1),
                                        AppColors.primary.withValues(alpha: 0.1),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppColors.secondary.withValues(alpha: 0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 12),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              CupertinoIcons.time,
                                              color: AppColors.accent,
                                              size: 18,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Time',
                                              style: TextStyle(
                                                color: AppColors.accent,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        height: 1,
                                        color: AppColors.secondary.withValues(alpha: 0.2),
                                      ),
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 2,
                                              child: CupertinoPicker(
                                                backgroundColor: Colors.transparent,
                                                itemExtent: 40,
                                                scrollController: hourController,
                                                onSelectedItemChanged: (index) {
                                                  setDialogState(() {
                                                    _selectedHour = index == 0 ? 12 : index;
                                                    if (!_isAM) _selectedHour += 12;
                                                  });
                                                },
                                                children: List<Widget>.generate(12, (index) {
                                                  return Center(
                                                    child: Text(
                                                      (index == 0 ? 12 : index).toString().padLeft(2, '0'),
                                                      style: const TextStyle(
                                                        color: AppColors.backgroundLight,
                                                        fontSize: 20,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  );
                                                }),
                                              ),
                                            ),
                                            Container(
                                              width: 1,
                                              color: AppColors.secondary.withValues(alpha: 0.2),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: CupertinoPicker(
                                                backgroundColor: Colors.transparent,
                                                itemExtent: 40,
                                                scrollController: minuteController,
                                                onSelectedItemChanged: (index) {
                                                  setDialogState(() {
                                                    _selectedMinute = index * 15;
                                                  });
                                                },
                                                children: List<Widget>.generate(4, (index) {
                                                  return Center(
                                                    child: Text(
                                                      (index * 15).toString().padLeft(2, '0'),
                                                      style: const TextStyle(
                                                        color: AppColors.backgroundLight,
                                                        fontSize: 20,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  );
                                                }),
                                              ),
                                            ),
                                            Container(
                                              width: 1,
                                              color: AppColors.secondary.withValues(alpha: 0.2),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: CupertinoPicker(
                                                backgroundColor: Colors.transparent,
                                                itemExtent: 40,
                                                scrollController: amPmController,
                                                onSelectedItemChanged: (index) {
                                                  setDialogState(() {
                                                    _isAM = index == 0;
                                                    _selectedHour = _isAM ? _selectedHour % 12 : (_selectedHour % 12) + 12;
                                                  });
                                                },
                                                children: const [
                                                  Center(
                                                    child: Text(
                                                      'AM',
                                                      style: TextStyle(
                                                        color: AppColors.backgroundLight,
                                                        fontSize: 20,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  Center(
                                                    child: Text(
                                                      'PM',
                                                      style: TextStyle(
                                                        color: AppColors.backgroundLight,
                                                        fontSize: 20,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      );

      if (result != null) {
        setState(() {
          eventDate.text = dateFormatter.format(result);
        });
      }
    } catch (e) {
      Logger.d('Error selecting date: $e', tag: 'Edit_event');
    }
  }

  // Add helper method for saving event
  Future<void> _saveEvent(bool newEvent) async {
    setState(() {
      isLoading = true;
    });

    try {
      // Upload image first if available
      String? imageUrl;
      if (_imageFile != null) {
        imageUrl = await _uploadEventImage();
        
        // If image upload failed and user wants to proceed anyway
        if (imageUrl == null) {
          final bool continueWithoutImage = await showCupertinoDialog<bool>(
            context: context,
            builder: (_) => CupertinoAlertDialog(
              title: const Text('Image Upload Failed'),
              content: const Text('Do you want to continue creating the event without an image?'),
              actions: [
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                CupertinoDialogAction(
                  child: const Text('Continue'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            ),
          ) ?? false;
          
          if (!continueWithoutImage) {
            setState(() {
              isLoading = false;
            });
            return;
          }
        }
      }
      
      Event event = widget.event ?? Event.empty();
      event.name = eventNameController.text;
      
      // Set the image URL if it was uploaded successfully
      if (imageUrl != null) {
        event.coverUrl = imageUrl;
      }
      
      try {
        // Parse the date with debug logging
        Logger.d('DEBUG: Date text from field: ${eventDate.text}', tag: 'Edit_event');
        final parsedDate = dateFormatter.parse(eventDate.text);
        Logger.d('DEBUG: Parsed date: $parsedDate', tag: 'Edit_event');
        
        // Get current time for comparison
        final now = DateTime.now();
        Logger.d('DEBUG: Current time: $now', tag: 'Edit_event');
        
        // Ensure the date is not in the past (handle any year dynamically)
        DateTime eventDateTime = parsedDate;
        
        // If the parsed date is in the past, suggest current year
        if (parsedDate.isBefore(now)) {
          // Try to create the event in the current year or next year if month has passed
          final currentYear = now.year;
          final nextYear = now.year + 1;
          
          DateTime adjustedDate = DateTime(
            currentYear,
            parsedDate.month,
            parsedDate.day,
            parsedDate.hour,
            parsedDate.minute,
          );
          
          // If still in the past, try next year
          if (adjustedDate.isBefore(now)) {
            adjustedDate = DateTime(
              nextYear,
              parsedDate.month,
              parsedDate.day,
              parsedDate.hour,
              parsedDate.minute,
            );
          }
          
          eventDateTime = adjustedDate;
        }
        
        // If the event is in the past, show a friendly error
        if (eventDateTime.isBefore(now)) {
          throw Exception('⏰ Oops! Time travel not available yet! Please pick a future date and time for your event. 🚀');
        }
        
        Logger.d('DEBUG: Final validated date: $eventDateTime', tag: 'Edit_event');
        event.date = eventDateTime;
      } catch (e) {
        if (e.toString().contains('FormatException')) {
          throw Exception('📅 Hmm, that date looks a bit wonky! Let\'s try selecting it again using the date picker. ✨');
        }
        rethrow;
      }

      event.slots = int.tryParse(eventSlots.text) ?? 3;
      event.price = double.tryParse(eventPrice.text) ?? 0;
      event.rules = eventRules.text;
      event.category = selectedCategory;
      event.isPrivate = isPrivate;
      event.password = isPrivate ? eventPassword.text : null;

      event.id = event.id.isEmpty
          ? FirebaseFirestore.instance.collection('events').doc().id
          : event.id;

      event.host = widget.user!.id;
      event.hostName = widget.user!.username;

      final finalLatData = eventLocationData ?? const LatLong(0, 0);
      event.location = latlong2.LatLng(finalLatData.latitude, finalLatData.longitude);
      event.address = eventLocation.text;

      Logger.d('DEBUG: Final event date before saving: ${event.date}', tag: 'Edit_event');

      await FirebaseFirestore.instance
          .collection('events')
          .doc(event.id)
          .set(event.toDocument(), SetOptions(merge: true));

      // Show success animation and dialog
      if (mounted) {
        // First show the success animation
        await _showSuccessAnimation();
        
        // Then show the dialog asking if they want to view the event
        final viewEvent = await _showViewEventDialog(event);
        
        if (viewEvent) {
          // Navigate to event details page
          Navigator.of(context).pop({"viewEvent": true, "eventId": event.id});
        } else {
          // Just go back to previous screen
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      Logger.d('Error saving event: $e', tag: 'Edit_event');
      await showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: Text(e.toString()),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Show a success animation when event is created
  Future<void> _showSuccessAnimation() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // Automatically dismiss after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });
        
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 15,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Confetti animation
                SizedBox(
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Animated stars/confetti
                      ...List.generate(12, (index) {
                        return TweenAnimationBuilder(
                          tween: Tween<double>(begin: 0, end: 1),
                          duration: Duration(milliseconds: 1200 + (index * 100)),
                          builder: (context, double value, child) {
                            // Calculate opacity with clamping to ensure it's between 0.0 and 1.0
                            final double opacity = value > 0.5 
                                ? (1.0 - (value - 0.5) * 2).clamp(0.0, 1.0) 
                                : (value * 2).clamp(0.0, 1.0);
                            
                            return Positioned(
                              top: 60 - (value * 50) + (index % 3) * 10,
                              left: 60 + cos(index * 0.5) * (50 * value),
                              child: Opacity(
                                opacity: opacity,
                                child: Transform.rotate(
                                  angle: value * 2 * 3.14,
                                  child: Icon(
                                    index % 2 == 0 
                                      ? CupertinoIcons.star_fill 
                                      : CupertinoIcons.sparkles,
                                    color: [
                                      AppColors.highlight,
                                      AppColors.primary,
                                      AppColors.secondary,
                                      AppColors.accent,
                                    ][index % 4],
                                    size: 20 + (index % 3) * 5,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }),
                      
                      // Center success icon with pulsing animation
                      TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0.8, end: 1.2),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeInOut,
                        builder: (context, double value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                CupertinoIcons.checkmark_circle_fill,
                                color: Colors.green,
                                size: 60,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Animated text
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.elasticOut,
                  builder: (context, double value, child) {
                    return Transform.scale(
                      scale: value,
                      child: const Text(
                        "Woohoo! Event Created!",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 10),
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutBack,
                  builder: (context, double value, child) {
                    return Opacity(
                      opacity: value.clamp(0.0, 1.0),
                      child: const Text(
                        "Get ready for an amazing time! 🎉",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Show dialog asking if user wants to view the event
  Future<bool> _showViewEventDialog(Event event) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        CupertinoIcons.eye_fill,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Check out your event?",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  "Would you like to see how '${event.name}' looks to your attendees?",
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Not Now button
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "Not Now",
                          style: TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    // View Event button
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: kPrimaryGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              CupertinoIcons.eye,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "View Event",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    
    return result ?? false;
  }



  // Enhanced category bubble with better animations and visual feedback
  Widget _buildEnhancedCategoryBubble(String title, String emoji, String categoryValue) {
    final bool isSelected = selectedCategory == categoryValue;
    
    // Get corresponding color based on category
    Color categoryColor;
    switch (categoryValue) {
      case 'comedy':
        categoryColor = const Color(0xFFFF6B6B);  // Coral Pink
        break;
      case 'dj':
        categoryColor = const Color(0xFF4ECDC4);  // Turquoise
        break;
      case 'poetry':
        categoryColor = const Color(0xFFFFBE0B);  // Sunny Yellow
        break;
      case 'music':
        categoryColor = const Color(0xFF7209B7);  // Vibrant Purple
        break;
      default:
        categoryColor = DesignSystem.primaryOrange;
    }

    return AnimatedScale(
      duration: const Duration(milliseconds: 200),
      scale: isSelected ? 1.05 : 1.0,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            selectedCategory = categoryValue;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: isSelected
                ? categoryColor.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected 
                  ? categoryColor.withValues(alpha: 0.8)
                  : categoryColor.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: isSelected ? 22 : 20,
                ),
                child: Text(emoji),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: isSelected 
                      ? categoryColor
                      : DesignSystem.textSecondary,
                  fontSize: isSelected ? 11 : 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Event'),
        content: const Text(
          'Are you sure you want to delete this event? This action cannot be undone.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        isLoading = true;
      });

      try {
        // Delete from Firestore
        await FirebaseFirestore.instance
            .collection('events')
            .doc(widget.event!.id)
            .delete();

        if (mounted) {
          Navigator.of(context).pop(); // Return to previous screen
        }
      } catch (e) {
        if (mounted) {
          await showCupertinoDialog(
            context: context,
            builder: (_) => CupertinoAlertDialog(
              title: const Text('Error'),
              content: Text(
                'An error occurred while deleting the event. Please try again.\n${e.toString()}',
              ),
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
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _selectLocation(BuildContext context,
      TextEditingController controller, LatLong? eventLocation) async {
    if (!mounted) return;
    
    try {
      // Instead of awaiting the result and expecting a return value,
      // navigate to the location page and let it call our callback
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Theme(
            data: ThemeData.from(
              colorScheme: ColorScheme.dark(
                  primary: AppColors.slottedOrange,
                  surface: CupertinoColors.label.withValues(alpha: 1.0)),
            ),
            child: LocationPage(
                onPicked: (Map<String, dynamic> picked) {
                  // Process the picked location
                  if (picked.containsKey('address') && picked.containsKey('latlng')) {
                    final address = picked['address'] as String?;
                    final latlng = picked['latlng'];
                    
                    if (address != null && address.isNotEmpty) {
                      if (latlng != null) {
                        try {
                          final latitude = latlng.latitude as double;
                          final longitude = latlng.longitude as double;
                          
                          setState(() {
                            controller.text = address;
                            eventLocationData = LatLong(latitude, longitude);
                          });
                        } catch (e) {
                          _showLocationError('Invalid coordinates format: latitude and longitude must be numbers', controller: controller);
                        }
                      } else {
                        // Web mode - no coordinates
                        setState(() {
                          controller.text = address;
                          eventLocationData = null;
                        });
                      }
                    } else {
                      _showLocationError('No address found for selected location', controller: controller);
                    }
                  } else {
                    _showLocationError('Invalid location data received', controller: controller);
                  }
                  
                  // Pop the location page after handling the selection
                  Navigator.of(context).pop();
                },
                eventLocation: eventLocation,
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showLocationError('Unable to select location: ${e.toString()}', controller: controller);
    }
  }
  
  // Helper method to show location errors
  Future<void> _showLocationError(String errorMessage, {TextEditingController? controller}) async {
    if (!mounted) return;
    
    // Parse the error message to make it more user-friendly
    String displayMessage = 'Unable to select location';
    
    if (errorMessage.contains('permission')) {
      displayMessage = 'Location permission denied. Please enable location services to continue.';
    } else if (errorMessage.contains('network')) {
      displayMessage = 'Network error. Please check your internet connection.';
    } else if (errorMessage.contains('Invalid location')) {
      displayMessage = 'Invalid location selected. Please try again.';
    } else if (errorMessage.contains('No address')) {
      displayMessage = 'Could not find address for selected location. Please try a different location.';
    } else if (errorMessage.contains('Invalid coordinates')) {
      displayMessage = 'Invalid coordinates received. Please try a different location.';
    }
    
    await showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Location Error'),
        content: Text(displayMessage),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
    
    // Reset location data if error occurs
    setState(() {
      if (controller != null) {
        controller.text = '';
      }
      eventLocationData = null;
    });
    
    Logger.d('Error selecting location: $errorMessage', tag: 'Edit_event');
  }

  // Add image picker function with optimized settings for slower connections
  Future<void> _pickEventImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85, // Balanced quality and file size
      );
      
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        
        // Automatically upload after picking
        if (_imageFile != null) {
          _uploadStatus = 'Image selected';
        }
      }
    } catch (e) {
      Logger.e('Error picking image: $e', tag: 'Edit_event');
      _showErrorDialog('Could not select image: ${e.toString()}');
    }
  }

  // Improved image upload function with retry capability
  Future<String?> _uploadEventImage() async {
    if (_imageFile == null) return null;
    
    setState(() {
      _isUploading = true;
      _uploadStatus = 'Preparing upload...';
    });
    
    const int maxRetries = 3;
    int currentRetry = 0;
    
    while (currentRetry < maxRetries) {
      try {
        // Get file details
        final String fileName = path.basename(_imageFile!.path);
        final String uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
        
        // Create reference to upload location
        final Reference storageRef = FirebaseStorage.instance
            .ref()
            .child('event_images')
            .child(uniqueFileName);
            
        // Update status
        setState(() {
          _uploadStatus = 'Uploading image... (${currentRetry > 0 ? "Retry $currentRetry/" : ""}$maxRetries)';
        });
        
        // Create upload task
        final UploadTask uploadTask = storageRef.putFile(
          _imageFile!,
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'eventId': widget.event?.id ?? 'new_event',
              'userId': widget.user?.id ?? '',
              'uploadTime': DateTime.now().toIso8601String(),
            },
          ),
        );
        
        // Handle upload progress
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          double progress = snapshot.bytesTransferred / snapshot.totalBytes;
          setState(() {
            _uploadStatus = 'Uploading: ${(progress * 100).toStringAsFixed(1)}%';
          });
        });
        
        // Wait for upload to complete
        final TaskSnapshot taskSnapshot = await uploadTask.timeout(
          const Duration(minutes: 2),
          onTimeout: () {
            // This will trigger the catch block with a timeout error
            throw TimeoutException('Upload timed out after 2 minutes');
          },
        );
        
        // Get download URL
        final String downloadUrl = await taskSnapshot.ref.getDownloadURL();
        
        setState(() {
          _isUploading = false;
          _uploadStatus = 'Upload successful!';
        });
        
        return downloadUrl;
      } catch (e) {
        currentRetry++;
        
        // Log the error
        Logger.e('Error uploading image (attempt $currentRetry): $e', tag: 'Edit_event');
        
        if (currentRetry >= maxRetries) {
          setState(() {
            _isUploading = false;
            _uploadStatus = 'Upload failed after $maxRetries attempts';
          });
          
          // Show error to user
          _showErrorDialog('Could not upload image after several attempts. Please check your connection and try again.');
          return null;
        }
        
        // Wait before retrying with exponential backoff
        setState(() {
          _uploadStatus = 'Connection issue. Retrying in ${currentRetry * 2} seconds...';
        });
        
        // Wait with exponential backoff
        await Future.delayed(Duration(seconds: currentRetry * 2));
      }
    }
    
    return null;
  }
  
  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
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

/// A widget that applies a pulsing animation to its child
class PulsingWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;

  const PulsingWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.minScale = 0.9,
    this.maxScale = 1.1,
  });

  @override
  State<PulsingWidget> createState() => _PulsingWidgetState();
}

class _PulsingWidgetState extends State<PulsingWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
