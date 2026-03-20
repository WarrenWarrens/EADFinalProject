import 'package:flutter/material.dart';
import 'package:testing/screens/home/homeScreen.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common_widgets.dart';
import 'dart:async';

class SimScreen extends StatefulWidget {
  // final VoidCallback onBack;


  const SimScreen({super.key});

  @override
  State<SimScreen> createState() => _SimScreenState();
}

class _SimScreenState extends State<SimScreen> {
  bool _isRecording = false;
  String _simText = "";
  String _youText = '';

  void _changeText() {
    setState(() {
      _youText = "You: kaltxì";
      _isRecording = false;

      Timer(Duration(seconds: 1), () {
        setState(() {
          _simText = "Na'vi: smon nìprrte";
        });
      });

    });
  }


  // Avatar options — replace with your actual asset paths

  @override
  void initState() {
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
          title: Text('Conversation Simulation'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.textPrimary,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                const SizedBox(height: 20),

                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.voice_chat_rounded,
                      size: 60,
                      color: AppColors.primary,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                Text(
                  "Have A Conversation With A Na'vi",
                  textAlign: TextAlign.center,
                  style: Theme
                      .of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                Column(children: [Text(
                  "Na'vi: zola‘u nìprrte!",
                  style: const TextStyle(fontSize: 24),
                ),
                  Text(
                    "${_youText}",
                    style: const TextStyle(fontSize: 24),
                  ),
                  Text(
                    // Use the variable in the Text widget
                    "${_simText}",
                    style: const TextStyle(fontSize: 24),
                  ),
                ]),


                const Spacer(),

                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                    boxShadow: [
                      BoxShadow(
                        color: (AppColors.primary)
                            .withOpacity(0.35),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: IconButton(
                      icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                      color: Colors.white,
                      onPressed: (){
                        setState(() {
                          _isRecording = true; // Toggle state
                        });
                        Timer(Duration(seconds: 3), () {
                          // Code to be executed after 3 seconds
                          _changeText();
                        });

                      }
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => HomeScreen()),
                      );
                    },
                    child: const Text("Finish Conversation"),
                  ),
                ),

                const SizedBox(height: 12),
              ]
          ),


        )
    );
  }
}