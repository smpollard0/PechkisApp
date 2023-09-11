import 'dart:async';
import 'dart:typed_data';

import 'package:audiophyx/components/drawer.dart';
import 'package:fftea/fftea.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:scidart/numdart.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

void main() {
  runApp(const NoiseFilter());
}

class NoiseFilter extends StatelessWidget {
  const NoiseFilter({super.key});

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
  int sampleRate = 5000;

  late List<FunctionData> _specData;
  late List<FunctionData> _fftFunc;
  late List<FunctionData> _realData;

  late ZoomPanBehavior _zoomPanBehavior;
  
  bool isRecording = false;
  final FlutterSoundRecorder _mRecorder = FlutterSoundRecorder();
  StreamSubscription? listener;
  List<double> micData = [];
    
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      drawer: getDrawer(context),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                height: 300,
                width: double.infinity,
                child: SfCartesianChart(
                  title: ChartTitle(text: 'Real Microphone Data'),
                  series: <ChartSeries>[
                    LineSeries<FunctionData, double>(
                      dataSource: _realData,
                      xValueMapper: (FunctionData func, _) => func.time,
                      yValueMapper: (FunctionData func, _) => func.function
                    )
                  ],
                  zoomPanBehavior: _zoomPanBehavior
                ),
              ),
              FloatingActionButton(
                onPressed: _changeRecordingState,
                child: const Icon(Icons.mic),
              ),
              
              SizedBox(
                height: 300,
                width: double.infinity,
                child: SfCartesianChart(
                  title: ChartTitle(text: 'Power Spectrum Distribution'),
                  series: <ChartSeries>[
                    LineSeries<FunctionData, double>(
                      dataSource: _specData,
                      xValueMapper: (FunctionData func, _) => func.time,
                      yValueMapper: (FunctionData func, _) => func.function
                    )
                  ],
                  zoomPanBehavior: _zoomPanBehavior
                ),
              ),
              SizedBox(
                height: 300,
                width: double.infinity,
                child: SfCartesianChart(
                  title: ChartTitle(text: 'De-Noised Data'),
                  series: <ChartSeries>[
                    LineSeries<FunctionData, double>(
                      dataSource: _fftFunc,
                      xValueMapper: (FunctionData func, _) => func.time,
                      yValueMapper: (FunctionData func, _) => func.function
                    )
                  ],
                  zoomPanBehavior: _zoomPanBehavior
                ),
              ),
              
            ],
          ),
        ),
      )
      
    );
  }

  // perform fast fourier transform to display power spectrum distribution and filtered signal
  List<List<FunctionData>> generateFFT(List<FunctionData> noisyFunc) {
    int size = micData.length;
    double time = size / sampleRate;
    List<double> timeData = linspace(0.0, time, num: size);
    List<double> fftFunc = [];

    List<List<FunctionData>> result = [];

    // build fftFunc list for fft object
    for (var i = 0; i < noisyFunc.length; i++){
      fftFunc.add(noisyFunc[i].function);
    }

    // create fft object from fftFunc
    final fft = FFT(fftFunc.length);
    final tempData = fft.realFft(fftFunc);
    final amplitudes = tempData.magnitudes();
    Array freq = createArrayRange(stop: size);

    // go through the amplitudes and zero out the ones that are lower than a certain threshold
    for (var i = 0; i < tempData.length; i++){
      if (amplitudes[i] < 0 || i == 0){ 
        tempData[i] = Float64x2(0, 0);
        amplitudes[i] = 0;
      }
    }

    final iFFT = fft.realInverseFft(tempData);

    for (var i = 0; i < amplitudes.length; i++){
      _specData.add(FunctionData(freq[i], amplitudes[i]));
      _fftFunc.add(FunctionData(timeData[i], iFFT.elementAt(i)));
    }
    
    result.add(_specData);
    result.add(_fftFunc);

    return result;
  }

  Future<void> record() async {
    micData = [];
    var recordingDataController = StreamController<Food>();
    listener =
        recordingDataController.stream.listen((buffer) {
      if (buffer is FoodData) {
        for (var i = 0; i < buffer.data!.length; i++){
          micData.add(buffer.data![i].toDouble());
        }
      }
    });
    await _mRecorder.startRecorder(
      toStream: recordingDataController.sink,
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: sampleRate,
    );
    setState(() {});
  }

  // class method to change the recording state and start or stop recording
  void _changeRecordingState() async {
    if (await Permission.microphone.request().isGranted) {
      (isRecording) ? isRecording = false : isRecording = true;
      _mRecorder.openRecorder();

      setState(() {});
      
      // need to add formal null checking lfor anything dealing with a 
      if (isRecording){
        record();
      }
      else{
        // Cancel the subscription
        await _mRecorder.stopRecorder();
        if (listener != null) {
          await listener!.cancel();
          listener = null;
        }
        // build data set from micdata to graph
        int size = micData.length;
        double time = size / sampleRate;
        List<double> timeData = linspace(0.0, time, num: size);
        for (var i = 0; i < timeData.length; i++){
          _realData.add(FunctionData(timeData[i], micData[i]));
        }

        generateFFT(_realData);
        setState(() {});
        
      }
    }
    else {
      RecordingPermissionException('Microphone permission not granted');
    }
  }
}

class FunctionData {
  FunctionData(this.time, this.function);
  final double time;
  final double function;
}
