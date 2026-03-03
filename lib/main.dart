import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'features/upload/upload_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.nachiket.nplayer.music.channel',
    androidNotificationChannelName: 'N Player',
    androidNotificationOngoing: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'N Player',
      theme: ThemeData.light(),
      home: const UploadScreen(),
    );
  }
}
