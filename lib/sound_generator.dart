import 'dart:ui';

import 'package:audiophyx/components/drawer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinbox/flutter_spinbox.dart';
import 'package:sound_generator/sound_generator.dart';
import 'package:sound_generator/waveTypes.dart';

class ToneGen extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class MyPainter extends CustomPainter {
  //         <-- CustomPainter class
  final List<int> oneCycleData;

  MyPainter(this.oneCycleData);

  @override
  void paint(Canvas canvas, Size size) {
    var i = 0;
    List<Offset> maxPoints = [];

    final t = size.width / (oneCycleData.length - 1);
    for (var _i = 0, _len = oneCycleData.length; _i < _len; _i++) {
      maxPoints.add(Offset(
          t * i,
          size.height / 2 -
              oneCycleData[_i].toDouble() / 32767.0 * size.height / 2));
      i++;
    }

    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    canvas.drawPoints(PointMode.polygon, maxPoints, paint);
  }

  @override
  bool shouldRepaint(MyPainter old) {
    if (oneCycleData != old.oneCycleData) {
      return true;
    }
    return false;
  }
}

class _MyAppState extends State<ToneGen> {
  bool isPlaying = false;
  double frequency = 20;
  TextEditingController startingFrequency = TextEditingController();
  TextEditingController endingFrequency = TextEditingController();
  double balance = 0;
  double volume = 1;
  waveTypes waveType = waveTypes.SINUSOIDAL;
  List<String> sampleRates = <String>["44.1 kHz", "96 kHz"];  
  String selectedVal = "44.1 kHz";
  int sampleRate = 44100;
  List<int>? oneCycleData;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
            appBar: AppBar(
              title: const Text('Tone Generator'),
            ),
            drawer: getDrawer(context),
            body: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 20,
                ),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text("A Cycle's Snapshot With Real Data"),
                      const SizedBox(height: 2),
                      Container(
                          height: 100,
                          width: double.infinity,
                          color: Colors.white54,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 0,
                          ),
                          child: oneCycleData != null
                              ? CustomPaint(
                                  painter: MyPainter(oneCycleData!),
                                )
                              : Container()),
                      const SizedBox(height: 2),
                      //Text("A Cycle Data Length is ${(sampleRate / frequency).round()} on sample rate $sampleRate"),
                      const SizedBox(height: 5),
                      const Divider(
                        color: Colors.red,
                      ),
                      const SizedBox(height: 5),
                      CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.lightBlueAccent,
                          child: IconButton(
                              icon: Icon(
                                  isPlaying ? Icons.stop : Icons.play_arrow),
                              onPressed: () {
                                isPlaying
                                    ? SoundGenerator.stop()
                                    : SoundGenerator.play();
                              })),
                      const SizedBox(height: 5),
                      const Divider(
                        color: Colors.red,
                      ),
                      const SizedBox(height: 5),
                      const Text("Wave Form"),
                      Center(
                          child: DropdownButton<waveTypes>(
                              value: this.waveType,
                              onChanged: (waveTypes? newValue) {
                                setState(() {
                                  this.waveType = newValue!;
                                  SoundGenerator.setWaveType(this.waveType);
                                });
                              },
                              items:
                                  waveTypes.values.map((waveTypes classType) {
                                return DropdownMenuItem<waveTypes>(
                                    value: classType,
                                    child: Text(
                                        classType.toString().split('.').last));
                              }).toList())),
                      const SizedBox(height: 5),
                      const Divider(
                        color: Colors.red,
                      ),
                      const SizedBox(height: 5),
                      const Text("Sample Rate"),
                      Center(
                          child: DropdownButton(
                            value: selectedVal,
                            onChanged: (String? value) {
                              setState(() {
                                switch (value){
                                  case "44.1 kHz":
                                    sampleRate = 44100;
                                  case "96 kHz":
                                    sampleRate = 96000;
                                }
                                selectedVal = value!;
                              });
                            },
                            items: sampleRates.map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value));
                            }).toList(),
                          )),
                      const SizedBox(height: 5),
                      const Text("Frequency"),
                      const SizedBox(height: 5),
                      const Text("ERROR: DO NOT SET FREQUENCY TO NULL OR ZERO"),
                      SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                Expanded(
                                  flex: 2,
                                  child: SpinBox(
                                    acceleration: 1,
                                    min: 20,
                                    max: 20000,
                                    value: frequency,
                                    direction: Axis.horizontal,
                                    onChanged: (value) {
                                        setState(() {
                                          if (value.isNaN || value.isInfinite){
                                            frequency = 20;
                                            if (kDebugMode) {
                                              print(frequency);
                                            }
                                          }else{
                                            frequency = value;
                                          }
                                          SoundGenerator.setFrequency(frequency);
                                          if (kDebugMode) {
                                            print(frequency);
                                          }                                            
                                        });              
                                    },
                                  ),
                                ),
                              ])),
                              const SizedBox(height: 1),
                              const Divider(
                                color: Colors.red,
                              ),
                              const Text("Frequency Sweep"),
                              const SizedBox(height: 5),
                              SizedBox(
                                width: 200,
                                child: Column(
                                  children: [
                                    TextField(
                                      controller: startingFrequency,
                                      decoration: InputDecoration(
                                        labelText: 'Starting Frequency',
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                    SizedBox(height: 5),
                                    TextField(
                                      controller: endingFrequency,
                                      decoration: InputDecoration(
                                        labelText: 'Ending Frequency',
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                  ],
                                ),
                              ),   
                    ])))); 
  }

  @override
  void dispose() {
    super.dispose();
    SoundGenerator.release();
  }

  @override
  void initState() {
    super.initState();
    isPlaying = false;

    SoundGenerator.init(sampleRate);

    SoundGenerator.onIsPlayingChanged.listen((value) {
      setState(() {
        isPlaying = value;
      });
    });

    SoundGenerator.onOneCycleDataHandler.listen((value) {
      setState(() {
        oneCycleData = value;
      });
    });

    SoundGenerator.setAutoUpdateOneCycleSample(true);
    //Force update for one time
    SoundGenerator.refreshOneCycleData();
  }
}