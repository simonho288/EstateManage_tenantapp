import 'dart:developer' as developer;
import 'package:flutter/material.dart';

import '../globals.dart' as Globals;

class RawBackground extends StatelessWidget {
  final String title;
  final Widget child;
  const RawBackground({Key? key, required this.title, required this.child})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // developer.log(StackTrace.current.toString().split('\n')[0]);
    Size size = MediaQuery.of(context).size;

    return Container(
      width: size.width,
      height: size.height,
      child: Stack(
        children: <Widget>[
          Container(
            height: 130,
            width: size.width,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover),
                Container(
                  width: size.width,
                  height: size.height,
                  color: Globals.primaryColor,
                ),
              ],
            ),
          ),
          // Back button
          Positioned(
            top: 30,
            left: 10,
            child: GestureDetector(
              onTap: () async {
                developer.log(StackTrace.current.toString().split('\n')[0]);
                Navigator.of(context).pop();
              },
              child: Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: Icon(Icons.arrow_back),
              ),
            ),
          ),
          // Centered header text
          Positioned(
            top: 30,
            left: 0,
            width: size.width,
            child: Center(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          // The circular colored background
          Positioned(
            top: 85,
            child: Container(
              width: size.width,
              height: size.height,
              decoration: BoxDecoration(
                color: Globals.primaryLighterColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(50),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 10),
                    // Widgets to show time slots and its layout
                    SingleChildScrollView(
                      child: SizedBox(
                        height: size.height - 95, // 85 + 10
                        child: child,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  } // build()
} // RawBackground
