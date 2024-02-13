import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:slotted/common/date_components.dart';
import 'package:slotted/common/event_class.dart';
// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';

class EventDetailsPage extends StatelessWidget {
  const EventDetailsPage({super.key, required this.user, required this.event});
  final User? user;
  final Event event;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.secondarySystemBackground,
        middle: Text(event.venueName),
      ),
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('Host'),
            Text(event.hostName),
            const SizedBox(height: 8),
            const Text('Rules'),
            Text(
              event.rules,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text('Date'),
            Text(
              '${_convertDateTimeToStringComponents(event.dateTime).dayFull}, ${_convertDateTimeToStringComponents(event.dateTime).monthFull} ${_convertDateTimeToStringComponents(event.dateTime).dayNum} at ${_convertDateTimeToStringComponents(event.dateTime).time}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              event.address,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  DateComponents _convertDateTimeToStringComponents(double dateTime) {
    final date = DateTime.fromMillisecondsSinceEpoch((dateTime * 1000).toInt());
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
