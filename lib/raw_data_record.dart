import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wav/raw_file.dart';
import 'package:wav/wav.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class RecordRaw extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<RecordRaw> {
  bool isPlaying = false;
  late ZoomPanBehavior _zoomPanBehavior;
  late List<FunctionData> _functionData;

  @override
  void initState() {
    _functionData = [];
    _zoomPanBehavior = ZoomPanBehavior(enablePinching: true);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Pain Suff'), // widget.title
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text(
                  'Attempt recording',
                ),
                FloatingActionButton(
                  onPressed: () {
                    setState(() {
                      isPlaying = !isPlaying;
                      doTheThing();
                    });
                  },
                  tooltip: isPlaying ? 'Stop Recording' : 'Start Recording',
                  child: Icon(isPlaying ? Icons.stop : Icons.mic_rounded),
                ),
                SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: SfCartesianChart(
                      title: ChartTitle(text: 'Clean Data'),
                      series: <ChartSeries>[
                        LineSeries<FunctionData, double>(
                            dataSource: _functionData,
                            xValueMapper: (FunctionData func, _) => func.time,
                            yValueMapper: (FunctionData func, _) =>
                                func.function)
                      ],
                      zoomPanBehavior: _zoomPanBehavior),
                ),
              ],
            ),
          ),
        ));
  }

  // functions can go here or below

  // function to get microphone access and attempt to start recording
  void doTheThing() async {
    await Permission.microphone.request();
    var status = await Permission
        .microphone.status; // determine if we have microphone access

    // if we don't have microphone access
    if (status.isDenied) {
      Fluttertoast.showToast(
        msg: "MICROPHONE ACCESS DENIED",
        toastLength: Toast.LENGTH_SHORT,
        textColor: Colors.black,
        fontSize: 16,
        backgroundColor: Colors.grey[200],
      );
    }
    // if we do have microphone access
    else {
      recording();
    }
  }

  // function to start and stop recording
  void recording() async {
    Record record = Record();
    final Directory tempDir = await getTemporaryDirectory();
    final String tempFile = "${tempDir.path}/test";
    AudioEncoder encoder = AudioEncoder.wav;
    if (kDebugMode) {
      print(tempFile);
    }

    // if microphone is recording, then stop
    if (await record.isRecording()) {
      record.stop();

      // CURRENT: might have successfully read data, now try to graph it
      final wav = await readRawAudioFile(tempFile, 1, WavFormat.pcm16bit);

      if (kDebugMode) {
        print(wav[0]);
      }

      // put wav data into data to be plotted
      List<double> timeData = [];
      for (int i = 0; i < wav[0].length; i++) {
        timeData.add(i.toDouble());
      }

      setState(() {
        for (var i = 0; i < timeData.length; i++) {
          _functionData.add(FunctionData(timeData[i], wav[0][i]));
        }
      });
    }
    // if microphone is not recording, then start
    else {
      record.start(
          path: tempFile,
          encoder:
              encoder // attempt to specify type of encoding to make it easier to read in data
          );
    }
  }
}

// this class is responsible for creating data that can be used in flutter charts
class FunctionData {
  FunctionData(this.time, this.function);
  final double time;
  final double function;
}
