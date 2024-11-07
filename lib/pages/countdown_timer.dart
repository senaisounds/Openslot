import 'dart:async';
import 'package:flutter/material.dart';

class CountdownTimer extends StatefulWidget {
  const CountdownTimer({super.key});

  @override
  _CountdownTimerState createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  Duration duration = const Duration(seconds: 60); // Set duration of the timer
  Timer? timer;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    timer =
        Timer.periodic(const Duration(microseconds: 1), (_) => setCountdown());
  }

  void setCountdown() {
    const reduceMicroSecondsBy = 10;
    setState(() {
      final seconds = duration.inMicroseconds - reduceMicroSecondsBy;
      if (seconds < 0) {
        timer?.cancel();
      } else {
        duration = Duration(microseconds: seconds);
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 200,
          height: 200,
          child: CircularProgressIndicator(
            value: (60000 - duration.inMilliseconds) / 60000,
            strokeWidth: 6,
            backgroundColor: Colors.grey,
            valueColor: const AlwaysStoppedAnimation(Colors.orange),
          ),
        ),
        Text(
          '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ],
    );
  }
}
