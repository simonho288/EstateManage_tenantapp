import 'dart:developer' as developer;

import '../include.dart';
import '../components/navBar.dart';

class PendingPage extends StatelessWidget {
  const PendingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    return Scaffold(
      // drawer: NavBar(),
      appBar: AppBar(
        title: Text('Pending 等待中'),
        centerTitle: true,
      ),
      body: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Text(
            'Your application of access to the App is still pending for the estate manager to approve. Please be patient and come back later.\n\n手機程序使用申請仍在等待屋苑經理批核，請耐心等待並稍後再來',
            textAlign: TextAlign.center),
      ),
    );
  }
}
