import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:slotted/common/colors.dart';
import 'package:slotted/common/date_components.dart';
import 'package:slotted/common/event_class.dart';
// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';

class EventDetailsPage extends StatefulWidget {
  const EventDetailsPage({super.key, required this.user, required this.event});
  final User? user;
  final Event event;

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  void _reserveAction() {
    if (widget.user != null) {
      if (widget.event.attendees.contains(widget.user!.uid)) {
        // Unreserve
      } else if (widget.event.waitlist.contains(widget.user!.uid)) {
        // Unwaitlist
      } else if (widget.event.openSpots > 0) {
        // Reserve
      } else {
        // Waitlist
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      resizeToAvoidBottomInset: false,
      navigationBar: CupertinoNavigationBar(
        border: null,
        backgroundColor: CupertinoColors.systemBackground,
        middle: Text(widget.event.name, style: const TextStyle(
          color: CupertinoColors.label,
          fontWeight: FontWeight.w800,
        ),),
        trailing: widget.user != null
            ? Padding(
                padding: const EdgeInsets.fromLTRB(0, 6, 0, 6),
                child: CupertinoButton(
                  color: widget.event.attendees.contains(widget.user!.uid)
                      ? slottedOrange
                      : widget.event.waitlist.contains(widget.user!.uid)
                      ? slottedOrange
                      : CupertinoColors.secondarySystemBackground,
                  padding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
                  onPressed: () => _reserveAction,
                  borderRadius: BorderRadius.circular(50),
                  child: widget.event.attendees.contains(widget.user!.uid)
                      ? const Text(
                          'Reserved',
                          style: TextStyle(
                            color: CupertinoColors.systemBackground,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : widget.event.waitlist.contains(widget.user!.uid)
                          ? const Text(
                              'Waitlisted',
                              style: TextStyle(
                                color: CupertinoColors.systemBackground,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            )
                          : widget.event.openSpots > 0
                              ? const Text(
                                  'Reserve',
                                  style: TextStyle(
                                    color: slottedOrange,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                )
                              : const Text(
                                  'Waitlist',
                                  style: TextStyle(
                                    color: slottedOrange,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                ),
              )
            : null,
      ),
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Hosted by ${widget.event.hostName}'),
            const SizedBox(height: 8),
            const Text('Rules'),
            Text(
              widget.event.rules,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text('Date'),
            Text(
              '${_convertDateTimeToStringComponents(widget.event.date).dayFull}, ${_convertDateTimeToStringComponents(widget.event.date).monthFull} ${_convertDateTimeToStringComponents(widget.event.date).dayNum} at ${_convertDateTimeToStringComponents(widget.event.date).time}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.event.address,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  DateComponents _convertDateTimeToStringComponents(DateTime date) {
    final monthFull = DateFormat.LLLL().format(date).toString();
    final monthShort = DateFormat.LLL().format(date).toString();
    final dayFull = DateFormat.EEEE().format(date).toString();
    final dayShort = DateFormat.E().format(date).toString();
    final dayNum = DateFormat.d().format(date).toString();
    final time = DateFormat.jm().format(date).toString();

    return DateComponents(
      monthFull: monthFull,
      monthShort: monthShort,
      dayFull: dayFull,
      dayShort: dayShort,
      dayNum: dayNum,
      time: time,
    );
  }
}
