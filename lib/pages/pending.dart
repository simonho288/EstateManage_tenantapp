import 'dart:developer' as developer;
import 'package:flutter/material.dart';

class PendingPage extends StatelessWidget {
  const PendingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    return Scaffold(
      // drawer: NavBar(),
      appBar: AppBar(
        title: Text('Account Is Pending'),
        centerTitle: true,
      ),
      body: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          'Your application of access to the App is still pending. Please check your email inbox and click the confirmation link.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
