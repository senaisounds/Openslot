// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:location_picker_flutter_map/location_picker_flutter_map.dart';
import 'package:slotted/common/colors.dart';
import 'package:slotted/common/event_class.dart';
import 'package:slotted/common/slotted_user.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';
import 'package:slotted/pages/location.dart';

class EditEventPage extends StatefulWidget {
  const EditEventPage({super.key, required this.user, this.event});

  final SlottedUser? user;

  final Event? event;

  @override
  EditEventPageState createState() => EditEventPageState();
}

class EditEventPageState extends State<EditEventPage> {
  FocusNode eventNameNode = FocusNode();
  FocusNode eventDateNode = FocusNode();
  FocusNode eventSlotsNode = FocusNode();
  FocusNode eventPriceNode = FocusNode();
  FocusNode eventRulesNode = FocusNode();
  FocusNode eventLocationNode = FocusNode();
  TextEditingController eventNameController = TextEditingController();
  TextEditingController eventDate = TextEditingController();
  TextEditingController eventSlots = TextEditingController();
  TextEditingController eventPrice = TextEditingController();
  TextEditingController eventRules = TextEditingController();
  TextEditingController eventLocation = TextEditingController();

  Future<void> _selectLocation(
      BuildContext context, TextEditingController controller) async {
    final location = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LocationPage(onPicked: (pickedData) {
          Navigator.of(context).pop(pickedData);
        }),
      ),
    );

    final picked = location as PickedData?;
    if (picked != null) {
      setState(() {
        controller.text = picked.address;
      });
    }
  }

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    final now = DateTime.now();
    DateTime? dateTime = await showOmniDateTimePicker(
      context: context,
      initialDate: eventDate.text.isEmpty
          ? now
          : DateFormat('MMMM d, yyyy – h:mm a').parse(eventDate.text),
      firstDate: now,
      lastDate: now.add(
        const Duration(days: 365),
      ),
      is24HourMode: false,
      isShowSeconds: false,
      minutesInterval: 5,
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      constraints: const BoxConstraints(
        maxWidth: 350,
        maxHeight: 650,
      ),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1.drive(
            Tween(
              begin: 0,
              end: 1,
            ),
          ),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 200),
      barrierDismissible: false,
    );

    if (dateTime != null) {
      setState(() {
        // Format the picked DateTime object and set it to the controller's text
        controller.text = DateFormat('MMMM d, yyyy – h:mm a').format(dateTime);
      });
    }

    // final DateTime? pickedDateTime = await showModalBottomSheet<DateTime>(
    //   context: context,
    //   builder: (BuildContext builder) {
    //     DateTime tempPickedDate = DateTime.now();
    //     return SizedBox(
    //       height: MediaQuery.of(context).copyWith().size.height / 3,
    //       child: CupertinoDatePicker(
    //         initialDateTime: tempPickedDate,
    //         mode: CupertinoDatePickerMode
    //             .dateAndTime, // Allow both date and time picking
    //         onDateTimeChanged: (DateTime newDate) {
    //           tempPickedDate = newDate;
    //         },
    //         minimumDate: tempPickedDate,
    //         maximumDate: DateTime.now().add(const Duration(days: 365)),
    //         use24hFormat: false, // Set to true if you want 24-hour format
    //       ),
    //     );
    //   },
    // );

    // if (pickedDateTime != null) {
    //   setState(() {
    //     // Format the picked DateTime object and set it to the controller's text
    //     controller.text =
    //         DateFormat('MMMM d, yyyy – h:mm a').format(pickedDateTime);
    //   });
    // }
    // final DateTime? picked = await showDatePicker(
    //   barrierDismissible: false,
    //   context: context,
    //   initialDate: DateTime.now(),
    //   firstDate: DateTime.now(),
    //   lastDate: DateTime.now().add(const Duration(days: 365)),
    // );
    // if (picked != null) {
    //   setState(() {
    //     controller.text =
    //         DateFormat('MMMM d yyyy').format(DateTime.parse(picked.toString()));
    //   });
    // }
    // if (picked != null && picked != birthday) {
    //   setState(() {
    //     birthday = picked;
    //     controller.text = DateFormat('MMMM d yyyy').format(picked);
    //   });
    // }
  }

  @override
  void initState() {
    super.initState();
    // Add a listener to the focus node
    eventPriceNode.addListener(() {
      if (!eventPriceNode.hasFocus) {
        eventPrice.text = double.parse(eventPrice.text).toStringAsFixed(2);
        // Make sure it is rounded to the closest multiple of 0.50
        double price = double.parse(eventPrice.text);
        if (price < 0.26 && price > 0) {
          price = 0.50;
        } else {
          double remainder = price % 0.50;
          if (remainder != 0) {
            if (remainder < 0.25) {
              price -= remainder;
            } else {
              price += 0.50 - remainder;
            }
          }
        }
        eventPrice.text = price.toStringAsFixed(2);
      }
    });
  }

  @override
  void dispose() {
    // Dispose the focus node when the state object is removed from the tree
    eventPriceNode.dispose();
    super.dispose();
  }

  KeyboardActionsConfig _buildConfig(BuildContext context) {
    return KeyboardActionsConfig(
      keyboardActionsPlatform: KeyboardActionsPlatform.ALL,
      keyboardBarColor: CupertinoColors.secondaryLabel.withOpacity(1),
      nextFocus: false,
      actions: [
        KeyboardActionsItem(focusNode: eventNameNode, toolbarButtons: [
          (node) {
            return CupertinoButton(
              padding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
              onPressed: () {
                node.unfocus();
                setState(() {});
              },
              child: const Text(
                'Done',
                style: TextStyle(
                  color: slottedOrange,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }
        ]),
        // KeyboardActionsItem(focusNode: eventDateNode, toolbarButtons: [
        //   (node) {
        //     return CupertinoButton(
        //       padding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
        //       onPressed: () {
        //         node.unfocus();
        //         setState(() {});
        //       },
        //       child: const Text(
        //         'Done',
        //         style: TextStyle(
        //           color: slottedOrange,
        //           fontSize: 18,
        //           fontWeight: FontWeight.bold,
        //         ),
        //       ),
        //     );
        //   }
        // ]),
        KeyboardActionsItem(focusNode: eventSlotsNode, toolbarButtons: [
          (node) {
            return CupertinoButton(
              padding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
              onPressed: () {
                node.unfocus();
                setState(() {});
              },
              child: const Text(
                'Done',
                style: TextStyle(
                  color: slottedOrange,
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
              onPressed: () {
                node.unfocus();
                setState(() {});
              },
              child: const Text(
                'Done',
                style: TextStyle(
                  color: slottedOrange,
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
              onPressed: () {
                node.unfocus();
                setState(() {});
              },
              child: const Text(
                'Done',
                style: TextStyle(
                  color: slottedOrange,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }
        ]),
        //   KeyboardActionsItem(focusNode: eventLocationNode, toolbarButtons: [
        //     (node) {
        //       return CupertinoButton(
        //         padding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
        //         onPressed: () {
        //           node.unfocus();
        //           setState(() {});
        //         },
        //         child: const Text(
        //           'Done',
        //           style: TextStyle(
        //             color: slottedOrange,
        //             fontSize: 18,
        //             fontWeight: FontWeight.bold,
        //           ),
        //         ),
        //       );
        //     }
        //   ]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Event event = widget.event ?? Event();
    bool newEvent = widget.event == null;
    return KeyboardActions(
      config: _buildConfig(context),
      disableScroll: true,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: CupertinoNavigationBar(
          middle: Text(
            '${newEvent ? 'Create' : 'Edit'} Event',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: <Widget>[
                CupertinoTextField(
                  padding: const EdgeInsets.all(16),
                  controller: eventNameController,
                  focusNode: eventNameNode,
                  onTap: () => setState(() {}),
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (value) {
                    eventNameController.text = value.toUpperCase();
                  },
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: eventNameNode.hasFocus ||
                              eventNameController.text.isNotEmpty
                          ? slottedOrange
                          : CupertinoColors.systemGrey,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  placeholder: 'Event Name',
                  placeholderStyle: const TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                CupertinoTextField(
                  padding: const EdgeInsets.all(16),
                  controller: eventDate, // Use the controller
                  // focusNode: eventDateNode,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: eventDateNode.hasFocus || eventDate.text.isNotEmpty
                          ? slottedOrange
                          : CupertinoColors.systemGrey,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  placeholder: 'Date',
                  placeholderStyle: const TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  readOnly:
                      true, // Make the field read-only since we are using a picker
                  onTap: () {
                    setState(() {});
                    _selectDate(context, eventDate);
                  },
                ),
                const SizedBox(height: 16),
                CupertinoTextField(
                  padding: const EdgeInsets.all(16),
                  controller: eventSlots,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  keyboardType: TextInputType.number,
                  focusNode: eventSlotsNode,
                  onTap: () => setState(() {}),
                  onChanged: (value) {
                    // Make sure if value == 0, then it just appears as a single 0, also make sure the number is not negative if so set 0
                    if (value == '0') {
                      eventSlots.text = '0';
                    } else if (value.startsWith('0')) {
                      eventSlots.text = value.substring(1);
                    } else if (value.startsWith('-')) {
                      eventSlots.text = '0';
                    }
                  },
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          eventSlotsNode.hasFocus || eventSlots.text.isNotEmpty
                              ? slottedOrange
                              : CupertinoColors.systemGrey,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  placeholder: 'Slots',
                  placeholderStyle: const TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                CupertinoTextField(
                  padding: const EdgeInsets.all(16),
                  controller: eventPrice,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
                  ],
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  focusNode: eventPriceNode,
                  onTap: () => setState(() {}),
                  onChanged: (value) {
                    // Make sure if value == 0, then it just appears as a single 0, also make sure the number is not negative if so set 0
                    if (value == '0') {
                      eventPrice.text = '0';
                    } else if (value.startsWith('0') && value('.')) {
                      eventPrice.text = value.substring(1);
                    }
                  },
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          eventPriceNode.hasFocus || eventPrice.text.isNotEmpty
                              ? slottedOrange
                              : CupertinoColors.systemGrey,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  placeholder: 'Price',
                  placeholderStyle: const TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                CupertinoTextField(
                  padding: const EdgeInsets.all(16),
                  controller: eventRules,
                  focusNode: eventRulesNode,
                  onTap: () => setState(() {}),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          eventRulesNode.hasFocus || eventRules.text.isNotEmpty
                              ? slottedOrange
                              : CupertinoColors.systemGrey,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  expands: true,
                  maxLines: null,
                  minLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  placeholder: 'Rules (Optional)',
                  placeholderStyle: const TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                CupertinoTextField(
                  padding: const EdgeInsets.all(16),
                  controller: eventLocation,
                  focusNode: eventLocationNode,
                  expands: true,
                  maxLines: null,
                  minLines: null,
                  readOnly:
                      true, // Make the field read-only since we are using a picker
                  onTap: () {
                    setState(() {});
                    _selectLocation(context, eventLocation);
                  },
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: eventLocationNode.hasFocus ||
                              eventLocation.text.isNotEmpty
                          ? slottedOrange
                          : CupertinoColors.systemGrey,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  placeholder: 'Location',
                  placeholderStyle: const TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                CupertinoButton(
                  color: slottedOrange,
                  borderRadius: BorderRadius.circular(16),
                  onPressed: eventNameController.text.isEmpty ||
                          eventDate.text.isEmpty ||
                          eventSlots.text.isEmpty ||
                          eventPrice.text.isEmpty ||
                          eventRules.text.isEmpty ||
                          eventLocation.text.isEmpty
                      ? null
                      : () {
                          event.name = eventNameController.text;
                          // event.date = DateTime.parse(eventDate.text);
                          event.date = DateFormat('MMMM d, yyyy – h:mm a')
                              .parse(eventDate.text);
                          event.slots = int.tryParse(eventSlots.text) ?? 3;
                          event.price = double.tryParse(eventPrice.text) ?? 0;
                          event.rules = eventRules.text;
                          print(event.toString());
                          // event.location = eventLocation.text;
                          // if (newEvent) {
                          //   FirebaseFirestore.instance
                          //       .collection('events')
                          //       .add(event.toMap());
                          // } else {
                          //   FirebaseFirestore.instance
                          //       .collection('events')
                          //       .doc(event.id)
                          //       .update(event.toMap());
                          // }
                          // Navigator.of(context).pop();
                        },
                  child: Text(
                    'Save Event',
                    style: TextStyle(
                      color: eventNameController.text.isEmpty ||
                              eventDate.text.isEmpty ||
                              eventSlots.text.isEmpty ||
                              eventPrice.text.isEmpty ||
                              eventRules.text.isEmpty ||
                              eventLocation.text.isEmpty
                          ? Colors.grey
                          : Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(
                  width: double.infinity,
                  height: 64,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
