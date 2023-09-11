import 'package:audiophyx/fft_test.dart';
import 'package:audiophyx/home.dart';
import 'package:audiophyx/noise_filter.dart';
import 'package:flutter/material.dart';
import 'package:audiophyx/sound_generator.dart';

Widget getDrawer(context){
  return Drawer(
    // Add a ListView to the drawer. This ensures the user can scroll
    // through the options in the drawer if there isn't enough vertical
    // space to fit everything.
    child: ListView(
      // Important: Remove any padding from the ListView.
      padding: EdgeInsets.zero,
      children: [
        const SizedBox(
          height: 95.0,
          child: DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blueAccent,
            ),
            child: Text('AudioPhyX'),
          ),
        ),
        ListTile(
          title: const Text('Home'),
          onTap: () {
            // Update the state of the app.
            Navigator.of(context)
              .pushAndRemoveUntil(MaterialPageRoute(builder: (context) => Home()),
              (route) => false);
          },
        ),
        ListTile(
          title: const Text('Tone Generator'),
          onTap: () {
            // Update the state of the app.
            Navigator.of(context)
              .pushAndRemoveUntil(MaterialPageRoute(builder: (context) => ToneGen()),
              (route) => false);
          },
        ),
        ListTile(
          title: const Text('Noise Filter'),
          onTap: () {
            // Update the state of the app.
            Navigator.of(context)
              .pushAndRemoveUntil(MaterialPageRoute(builder: (context) => NoiseFilter()),
              (route) => false);
          },
        ),
        ListTile(
          title: const Text('FFT Test'),
          onTap: () {
            // Update the state of the app.
            Navigator.of(context)
              .pushAndRemoveUntil(MaterialPageRoute(builder: (context) => FFT_Test()),
              (route) => false);
          },
        ),
      ],
    ),
  );
}