import 'dart:developer' as developer;

import '../include.dart';
import '../components/navBar.dart';

class SuspendedPage extends StatelessWidget {
  const SuspendedPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    return Scaffold(
      // drawer: NavBar(),
      appBar: AppBar(
        title: Text('Account Is Suspended'),
        centerTitle: true,
      ),
      body: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          'Your account is suspended for some reason. Please contact the estate manage',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
