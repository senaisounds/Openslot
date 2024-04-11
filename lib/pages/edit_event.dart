// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:latlong2/latlong.dart';
import 'package:location_picker_flutter_map/location_picker_flutter_map.dart';
import 'package:slotted/common/colors.dart';
import 'package:slotted/common/event_class.dart';
import 'package:slotted/common/slotted_user.dart';
import 'package:board_datetime_picker/board_datetime_picker.dart';

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
  bool eventDateFocused = false;
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
        builder: (context) => Theme(
          data: ThemeData.from(
            colorScheme: ColorScheme.dark(
                primary: slottedOrange,
                background: CupertinoColors.label.withOpacity(1.0)),
          ),
          child: LocationPage(onPicked: (pickedData) {
            Navigator.of(context).pop(pickedData);
          }),
        ),
      ),
    );

    final picked = location as PickedData?;
    if (picked != null) {
      setState(() {
        controller.text = picked.address;
        eventLocationData = picked;
      });
    }
  }

  PickedData? eventLocationData;

  final textController = BoardDateTimeTextController();

  @override
  void initState() {
    super.initState();
    // Add a listener to the focus node
    eventPriceNode.addListener(() {
      if (!eventPriceNode.hasFocus) {
        eventPrice.text =
            double.tryParse(eventPrice.text)?.toStringAsFixed(2) ?? '0.00';
        // Make sure it is rounded to the closest multiple of 0.50
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
    });

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
    }
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
                setState(() {
                  node.unfocus();
                });
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
        KeyboardActionsItem(focusNode: eventSlotsNode, toolbarButtons: [
          (node) {
            return CupertinoButton(
              padding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
              onPressed: () {
                setState(() {
                  node.unfocus();
                });
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
                setState(() {
                  node.unfocus();
                });
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
                setState(() {
                  node.unfocus();
                });
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
      ],
    );
  }

  bool isLoading = false;

  DateFormat dateFormatter = DateFormat('EEEE  -  MMMM d, yyyy  -  h:mm a');

  @override
  Widget build(BuildContext context) {
    Event event = widget.event ?? Event();
    bool newEvent = widget.event == null;
    final now = DateTime.now();
    textController.setText('Event Date');
    return KeyboardActions(
      config: _buildConfig(context),
      disableScroll: true,
      child: Theme(
        data: ThemeData.from(
          colorScheme: const ColorScheme.dark(primary: slottedOrange),
        ),
        child: Scaffold(
          backgroundColor: CupertinoColors.label,
          appBar: CupertinoNavigationBar(
            backgroundColor: Colors.black,
            middle: Text(
              '${newEvent ? 'Create' : 'Edit'} Event',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: slottedOrange),
            ),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: <Widget>[
                  CupertinoTextField(
                    enabled: !isLoading,
                    padding: const EdgeInsets.all(16),
                    controller: eventNameController,
                    focusNode: eventNameNode,
                    onTap: () => setState(() {
                      FocusScope.of(context).unfocus();
                      FocusScope.of(context).requestFocus(eventNameNode);
                    }),
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (value) {
                      setState(() {
                        eventNameController.text = value.toUpperCase();
                      });
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
                    enabled: !isLoading,
                    padding: const EdgeInsets.all(16),
                    controller: eventDate,
                    focusNode: eventNameNode,
                    onTap: () async {
                      setState(() {
                        FocusScope.of(context).unfocus();
                        FocusScope.of(context).requestFocus(eventDateNode);
                      });

                      if (eventDate.text.isEmpty) {
                        eventDate.text = dateFormatter.format(now.add(
                          Duration(
                            minutes: 15 - now.minute % 15,
                          ),
                        ));
                      }

                      final result = await showBoardDateTimePicker(
                        context: context,
                        pickerType: DateTimePickerType.datetime,
                        initialDate: eventDate.text.isEmpty
                            ? null
                            : dateFormatter.parse(eventDate.text).isAfter(now)
                                ? dateFormatter.parse(eventDate.text)
                                : now,
                        // Minimum date is the next quarter hour
                        minimumDate: now.add(
                          Duration(
                            minutes: 15 - now.minute % 15,
                          ),
                        ),
                        maximumDate: now.add(
                          const Duration(days: 365),
                        ),
                        onChanged: (date) {
                          setState(() {
                            eventDate.text = dateFormatter.format(date);
                          });
                        },
                        options: BoardDateTimeOptions(
                          languages: const BoardPickerLanguages.en(),
                          boardTitle: 'Event Date',
                          pickerSubTitles: const BoardDateTimeItemTitles(
                            hour: 'Hour',
                            minute: 'Minute',
                            day: 'Day',
                            month: 'Month',
                            year: 'Year',
                          ),
                          pickerFormat: PickerFormat.mdy,
                          backgroundColor: const Color.fromARGB(255, 24, 24, 24)
                              .withOpacity(1.0),
                          activeColor: slottedOrange,
                          activeTextColor: CupertinoColors.label,
                          foregroundColor:
                              CupertinoColors.secondaryLabel.withOpacity(1.0),
                          customOptions:
                              BoardPickerCustomOptions.every15minutes(),
                          textColor: slottedOrange,
                        ),
                      );

                      if (result != null) {
                        setState(() {
                          eventDate.text = dateFormatter.format(result);
                        });
                      }
                    },
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    readOnly: true,
                    keyboardType: TextInputType.none,
                    onChanged: (value) {
                      final date = dateFormatter.parse(value);
                      setState(() {
                        eventDate.text = dateFormatter.format(date);
                      });
                    },
                    decoration: BoxDecoration(
                      border: Border.all(
                        color:
                            eventDateNode.hasFocus || eventDate.text.isNotEmpty
                                ? slottedOrange
                                : CupertinoColors.systemGrey,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    placeholder: 'Event Date',
                    placeholderStyle: const TextStyle(
                      color: CupertinoColors.systemGrey,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CupertinoTextField(
                    enabled: !isLoading,
                    padding: const EdgeInsets.all(16),
                    controller: eventSlots,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    keyboardType: TextInputType.number,
                    focusNode: eventSlotsNode,
                    onTap: () => setState(() {
                      FocusScope.of(context).unfocus();
                      FocusScope.of(context).requestFocus(eventSlotsNode);
                    }),
                    onChanged: (value) {
                      // Make sure if value == 0, then it just appears as a single 0, also make sure the number is not negative if so set 0
                      setState(() {
                        if (value == '0') {
                          eventSlots.text = '0';
                        } else if (value.startsWith('0')) {
                          eventSlots.text = value.substring(1);
                        } else if (value.startsWith('-')) {
                          eventSlots.text = '0';
                        }
                      });
                    },
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: eventSlotsNode.hasFocus ||
                                eventSlots.text.isNotEmpty
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
                    enabled: !isLoading,
                    padding: const EdgeInsets.all(16),
                    controller: eventPrice,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'))
                    ],
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    focusNode: eventPriceNode,
                    onTap: () => setState(() {
                      FocusScope.of(context).unfocus();
                      FocusScope.of(context).requestFocus(eventPriceNode);
                    }),
                    onChanged: (value) {
                      // Make sure if value == 0, then it just appears as a single 0, also make sure the number is not negative if so set 0
                      if (value.startsWith('0') &&
                          !value.startsWith('0.') &&
                          value.length > 1) {
                        eventPrice.text = value.substring(1);
                      } else if (value.startsWith('-') ||
                          (value.characters.where((p0) => p0 == '0').length ==
                                  value.length &&
                              value.isNotEmpty)) {
                        eventPrice.text = '0';
                      } else if (value.startsWith('.')) {
                        eventPrice.text = '0$value';
                      }
                    },
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: eventPriceNode.hasFocus ||
                                eventPrice.text.isNotEmpty
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
                    enabled: !isLoading,
                    padding: const EdgeInsets.all(16),
                    controller: eventRules,
                    focusNode: eventRulesNode,
                    onTap: () => setState(() {}),
                    onChanged: (_) => setState(() {
                      FocusScope.of(context).unfocus();
                      FocusScope.of(context).requestFocus(eventRulesNode);
                    }),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: eventRulesNode.hasFocus ||
                                eventRules.text.isNotEmpty
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
                    enabled: !isLoading,
                    padding: const EdgeInsets.all(16),
                    controller: eventLocation,
                    focusNode: eventLocationNode,
                    expands: true,
                    maxLines: null,
                    minLines: null,
                    readOnly:
                        true, // Make the field read-only since we are using a picker
                    onTap: () {
                      setState(() {
                        FocusScope.of(context).unfocus();
                      });
                      _selectLocation(context, eventLocation);
                    },
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: eventLocation.text.isNotEmpty
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
                            eventLocation.text.isEmpty
                        ? null
                        : () async {
                            setState(() {
                              isLoading = true;
                            });

                            event.name = eventNameController.text;
                            event.date = dateFormatter.parse(eventDate.text);
                            event.slots = int.tryParse(eventSlots.text) ?? 3;
                            event.price = double.tryParse(eventPrice.text) ?? 0;
                            event.rules = eventRules.text;

                            event.id = event.id.isEmpty
                                ? FirebaseFirestore.instance
                                    .collection('events')
                                    .doc()
                                    .id
                                : event.id;

                            event.host = widget.user!.id;
                            event.hostName = widget.user!.username;

                            final finalLatData = eventLocationData?.latLong ??
                                const LatLong(0, 0);
                            event.location = LatLng(
                                finalLatData.latitude, finalLatData.longitude);
                            event.address = eventLocation.text;

                            try {
                              await FirebaseFirestore.instance
                                  .collection('events')
                                  .doc(event.id)
                                  .set(
                                    Event.toDocument(event),
                                    SetOptions(merge: true),
                                  );
                              Navigator.of(context).pop();
                            } catch (e) {
                              await showDialog(
                                  context: context,
                                  builder: (_) {
                                    return CupertinoAlertDialog(
                                      title: const Text('Error'),
                                      content: Text(
                                          'An error occurred while saving the event. Please try again.\n${e.toString()}'),
                                      actions: <Widget>[
                                        CupertinoDialogAction(
                                          child: const Text('OK'),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    );
                                  });
                            } finally {
                              setState(() {
                                isLoading = false;
                              });
                            }
                          },
                    child: isLoading
                        ? const CupertinoActivityIndicator(
                            radius: 16,
                            color: Colors.white,
                          )
                        : Text(
                            'Save Event',
                            style: TextStyle(
                              color: eventNameController.text.isEmpty ||
                                      eventDate.text.isEmpty ||
                                      eventSlots.text.isEmpty ||
                                      eventPrice.text.isEmpty ||
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
      ),
    );
  }
}
