import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import '../components/navBar.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    return Scaffold(
      drawer: NavBar(),
      appBar: AppBar(
        title: Text('About'),
        centerTitle: true,
      ),
      body: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Text('About Page'),
      ),
    );
  }
}
