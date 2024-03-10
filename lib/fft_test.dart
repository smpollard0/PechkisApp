import 'dart:async';
import 'dart:typed_data';

import 'package:audiophyx/components/drawer.dart';
import 'package:fftea/fftea.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mic_stream/mic_stream.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:scidart/numdart.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

enum SampleItem { itemOne, itemTwo, itemThree }

void main() {
  runApp(const FFT_Test());
}

class FFT_Test extends StatelessWidget {
  const FFT_Test({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'FFT Test',
      home: MyHomePage(title: 'Denoising Data with FFT'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int sampleRate = 22050;
  int currentPageIndex = 0;
  SampleItem? selectedMenu;

  Timer? timer;
  Stopwatch stopwatch = Stopwatch();

  Stream? stream;
  late StreamSubscription listener;

  List<Uint8List> micData = [];

  bool buttonPressed = false;

  late List<FunctionData> _realData;
  late List<FunctionData> _specData;
  late List<FunctionData> _fftFunc;
  late ZoomPanBehavior _zoomPanBehavior;

  void _changeRecordingState() async {
    if (await Permission.microphone.request().isGranted) {
      (buttonPressed) ? buttonPressed = false : buttonPressed = true;

      if (kDebugMode) {
        print(buttonPressed);
      }

      //   setState(() {});

      //   // need to add formal null checking for anything dealing with a future or stream
      //   if (isRecording){
      //     record();
      //   }
      //   else{
      //     // build data set from micdata to graph
      //     int size = micData.length;
      //     double time = size / sampleRate;
      //     // List<double> timeData = linspace(0.0, time, num: size);

      //     // for (var i = 0; i < timeData.length; i++){
      //     //   _realData.add(FunctionData(timeData[i], micData[i]));
      //     // }

      //     // generateFFT(_realData);

      //     if (kDebugMode) {
      //       print("Test");
      //     }

      //     setState(() {});

      //   }
      // }
      // else {
      //   throw Exception('Microphone permission not granted');
    }
  }

  List<List<FunctionData>> generateFFT(List<FunctionData> noisyFunc) {
    int size = micData.length;
    double time = size / sampleRate;
    List<double> timeData = linspace(0.0, time, num: size);
    List<double> fftFunc = [];

    List<List<FunctionData>> result = [];

    // build fftFunc list for fft object
    for (var i = 0; i < noisyFunc.length; i++) {
      fftFunc.add(noisyFunc[i].function);
    }

    // create fft object from fftFunc
    final fft = FFT(fftFunc.length);
    final tempData = fft.realFft(fftFunc);
    final amplitudes = tempData.magnitudes();
    Array freq = createArrayRange(stop: size);

    // go through the amplitudes and zero out the ones that are lower than a certain threshold
    for (var i = 0; i < tempData.length; i++) {
      if (amplitudes[i] < 0 || i == 0) {
        tempData[i] = Float64x2(0, 0);
        amplitudes[i] = 0;
      }
    }

    final iFFT = fft.realInverseFft(tempData);

    for (var i = 0; i < amplitudes.length; i++) {
      _specData.add(FunctionData(freq[i], amplitudes[i]));
      _fftFunc.add(FunctionData(timeData[i], iFFT.elementAt(i)));
    }

    result.add(_specData);
    result.add(_fftFunc);

    return result;
  }

  @override
  void initState() {
    _realData = [];
    _specData = [];
    _fftFunc = [];
    _zoomPanBehavior = ZoomPanBehavior(
      enablePinching: true,
      enablePanning: true,
    );
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(icon: Icon(Icons.raw_on), label: 'Raw Data'),
          NavigationDestination(
            icon: Icon(Icons.poll),
            label: 'PSD',
          ),
          NavigationDestination(icon: Icon(Icons.broken_image), label: 'iFFT'),
        ],
      ),
      drawer: getDrawer(context),
      body: <Widget>[
        SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: SfCartesianChart(
                      title: ChartTitle(text: 'Raw Microphone Data'),
                      series: <ChartSeries>[
                        LineSeries<FunctionData, double>(
                            dataSource: _realData,
                            xValueMapper: (FunctionData func, _) => func.time,
                            yValueMapper: (FunctionData func, _) =>
                                func.function)
                      ],
                      zoomPanBehavior: _zoomPanBehavior),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: PopupMenuButton<SampleItem>(
                    initialValue: selectedMenu,
                    onSelected: (SampleItem item) {
                      setState(() {
                        selectedMenu = item;
                        if (item == SampleItem.itemOne) {
                          if (kDebugMode) {
                            print("Item one chosen");
                          }
                        } else if (item == SampleItem.itemTwo) {
                          if (kDebugMode) {
                            print("Item two chosen");
                          }
                        } else if (item == SampleItem.itemThree) {
                          if (kDebugMode) {
                            print("Item three chosen");
                          }
                        }
                      });
                    },
                    icon: const Icon(Icons.settings),
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<SampleItem>>[
                      const PopupMenuItem<SampleItem>(
                        value: SampleItem.itemOne,
                        child: Text('Item 1'),
                      ),
                      const PopupMenuItem<SampleItem>(
                        value: SampleItem.itemTwo,
                        child: Text('Item 2'),
                      ),
                      const PopupMenuItem<SampleItem>(
                        value: SampleItem.itemThree,
                        child: Text('Item 3'),
                      ),
                    ],
                  ),
                ),
                FloatingActionButton(
                  onPressed: () async {
                    if (buttonPressed) {
                      buttonPressed = false;
                      stopwatch.stop();
                      stopwatch.reset();
                      listener.cancel();
                      timer!.cancel();
                    } else {
                      buttonPressed = true;
                      stopwatch.start();

                      /* recording logic goes here */
                      stream = await MicStream.microphone(
                          audioSource: AudioSource.DEFAULT,
                          sampleRate: sampleRate,
                          channelConfig: ChannelConfig.CHANNEL_IN_MONO);

                      // CURRENT ISSUE: MICROPHONE DATA IS INITALLY NULL AND IT GIVES ERRORS ON FIRST BUTTON PRESS

                      List<double> floatList = [];

                      listener = stream!.listen((samples) {
                        if (stopwatch.elapsedMilliseconds < 1000) {
                          micData.add(samples);
                          for (var i = 0; i < micData.length; i++) {
                            for (var j = 0; j < micData[i].length; j++) {
                              floatList.add(micData[i][j].toDouble());
                            }
                          }
                        }
                      });

                      timer = Timer.periodic(const Duration(milliseconds: 5000),
                          (_) async {
                        if (kDebugMode) {
                          print(stopwatch.elapsedMilliseconds);
                        }
                        stopwatch.reset();
                      });

                      micData = [];

                      for (var i = 0; i < floatList.length; i++) {
                        if (kDebugMode) {
                          print(floatList[i]);
                        }
                      }

                      int size = micData.length;
                      List<double> timeData = linspace(
                          0.0, floatList.length.toDouble() / 1000,
                          num: size); // the upperbound here is wrong

                      if (kDebugMode) {
                        print(floatList.length);
                      }

                      // for (var i = 0; i < micData.length; i++){
                      //   _realData.add(FunctionData(timeData[i], floatList[i]));
                      //   if (kDebugMode){
                      //     print(_realData[i]);
                      //   }
                      // }
                    }
                    setState(() {});
                  },
                  child: (buttonPressed)
                      ? const Icon(Icons.stop)
                      : const Icon(Icons.mic),
                ),
              ],
            ),
          ),
        ),
        SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: SfCartesianChart(
                      title: ChartTitle(text: 'Power Spectrum Distribution'),
                      series: <ChartSeries>[
                        LineSeries<FunctionData, double>(
                            dataSource: _specData,
                            xValueMapper: (FunctionData func, _) => func.time,
                            yValueMapper: (FunctionData func, _) =>
                                func.function)
                      ],
                      zoomPanBehavior: _zoomPanBehavior),
                ),
                Align(
                    alignment: Alignment.bottomRight,
                    child: IconButton(
                        onPressed: () {
                          if (kDebugMode) {
                            print("Pressed Settings Button");
                          }
                        },
                        icon: const Icon(Icons.settings))),
              ],
            ),
          ),
        ),
        SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: SfCartesianChart(
                      title: ChartTitle(text: 'Inverse Fourier Transform'),
                      series: <ChartSeries>[
                        LineSeries<FunctionData, double>(
                            dataSource: _fftFunc,
                            xValueMapper: (FunctionData func, _) => func.time,
                            yValueMapper: (FunctionData func, _) =>
                                func.function)
                      ],
                      zoomPanBehavior: _zoomPanBehavior),
                ),
                Align(
                    alignment: Alignment.bottomRight,
                    child: IconButton(
                        onPressed: () {
                          if (kDebugMode) {
                            print("Pressed Settings Button");
                          }
                        },
                        icon: const Icon(Icons.settings))),
              ],
            ),
          ),
        ),
      ][currentPageIndex],
    );
  }
}

class FunctionData {
  FunctionData(this.time, this.function);
  final double time;
  final double function;
}
