import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:slotted/common/colors.dart';

const placeholderImage =
    'https://upload.wikimedia.org/wikipedia/commons/c/cd/Portrait_Placeholder_Square.png';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LivePage(),
    );
  }
}

class LivePage extends StatefulWidget {
  _LivePageState createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> {
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
    return Scaffold(
      appBar: AppBar(
        leading: CupertinoButton(
          child: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          CupertinoButton(
            child: const Text("5m Time Limit"),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 240,
                    height: 240,
                    child: CircularProgressIndicator(
                      value: (60000 - duration.inMilliseconds) / 60000,
                      strokeWidth: 6,
                      backgroundColor: Colors.grey,
                      valueColor: const AlwaysStoppedAnimation(Colors.orange),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          // "0:00",
                          '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 24),
                        ),
                        const Text(
                          'Performing Now',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 24),
                        ),
                      ],
                    ),
                  ),
                  // Text(
                  //   '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
                  //   style: const TextStyle(
                  //     fontWeight: FontWeight.bold,
                  //     fontSize: 20,
                  //   ),
                  // ),
                ],
              ),
            ),
            // Padding(
            //   padding: EdgeInsets.symmetric(horizontal: 16.0),
            //   child: Text("Performing Now"),
            // ),
            // if (event.rules.isNotEmpty) ...[
            const SizedBox(height: 28),
            const Text(
              'Event Title',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            const Text(
              'Rules',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              height: 96,
              width: MediaQuery.of(context).size.width * 0.8,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children:
                      'These are a test set of rules\nSomething something blah bring your best jokes you loser\nLet\'s go'
                          .split('\n')
                          .map((rule) => Text(
                                rule,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.w600),
                              ))
                          .toList(),
                ),
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            // ],
            // if (event.rules.isEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: 10, // replace with your dynamic size
                itemBuilder: (context, index) {
                  return ListTile(
                    onTap: () => {},
                    leading: const CircleAvatar(
                      backgroundImage: NetworkImage(
                        placeholderImage,
                      ),
                    ),
                    title: Text(
                      "Participant ${index + 1}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    // subtitle: Text("W W W W"),
                    // trailing: ElevatedButton(
                    //   onPressed: () {
                    //     // Handle start
                    //   },
                    //   child: Text("Start"),
                    // ),
                  );
                },
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: 84,
              padding: const EdgeInsets.fromLTRB(8, 24, 8, 0),
              child: CupertinoButton(
                borderRadius: BorderRadius.circular(20),
                onPressed: () {
                  // Handle start event
                },
                color: slottedOrange,
                child: const Text(
                  "Start Event",
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 21,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
