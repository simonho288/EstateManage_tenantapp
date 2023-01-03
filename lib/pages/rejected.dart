import 'dart:developer' as developer;
import 'dart:convert' as convert;
import 'package:easy_localization/easy_localization.dart';

import '../include.dart';
import '../globals.dart' as Globals;
import '../utils.dart' as Utils;
import '../ajax.dart' as Ajax;

class RejectedPage extends StatelessWidget {
  const RejectedPage({Key? key}) : super(key: key);

  Future<void> _onBtnUpdate(context) async {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    Ajax.ApiResponse resp = await Ajax.getTenantStatus(
      tenantId: Globals.curUserJson!['id'],
    );

    String newStatus = resp.data[0]['status'];
    if (newStatus == 'approved') {
      // Save the new status to SharedPreferences
      Globals.curUserJson?['status'] = newStatus;
      await prefs.setString(
          'userJson', convert.jsonEncode(Globals.curUserJson));

      await Utils.showAlertDialog(
        context,
        'congratulation'.tr(),
        'requestApproved'.tr(),
      );

      Navigator.pushReplacementNamed(context, '/setupPassword');
    } else if (newStatus == 'normal') {
      // Save the new status to SharedPreferences
      Globals.curUserJson?['status'] = newStatus;
      await prefs.setString(
          'userJson', convert.jsonEncode(Globals.curUserJson));

      await Utils.showAlertDialog(
        context,
        'okNow'.tr(),
        'statusSeemsOk'.tr(),
      );

      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _onBtnRegister(context) {
    developer.log(StackTrace.current.toString().split('\n')[0]);
    Navigator.pushReplacementNamed(context, '/register');
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? userJson = Globals.curUserJson;

    late String unitType;
    if (userJson?['unit_type'] == 'resident') {
      unitType = 'Resident';
    } else if (userJson?['unit_type'] == 'carpark') {
      unitType = 'Carpark';
    } else if (userJson?['unit_type'] == 'shop') {
      unitType = 'Shop';
    }
    String unit = '';
    if (userJson?['phase'] != '') {
      unit += 'Phase ${userJson?['phase']} ';
    }
    if (userJson?['block'] != '') {
      unit += 'Block ${userJson?['block']} ';
    }
    if (userJson?['floor'] != '') {
      unit += 'Floor ${userJson?['floor']} ';
    }
    if (userJson?['number'] != '') {
      unit += 'No. ${userJson?['number']} ';
    }
    String role = '';
    if (userJson?['role'] == 'owner') {
      role = 'Owner';
    } else if (userJson?['role'] == 'tenant') {
      role = 'Tenant';
    } else if (userJson?['role'] == 'occupant') {
      role = 'Occupant';
    } else if (userJson?['role'] == 'agent') {
      role = 'Agent';
    }

    String header = '', title = '';
    if (userJson?['status'] == 'rejected') {
      header = 'Registration Rejected';
      title =
          'Your Registration is rejected. Please contact management office verify your application. Tap the [Update Status] when done';
    } else if (userJson?['status'] == 'disabled') {
      header = 'Access denied';
      title =
          'Your account is disabled for some reason. Please contact management office to resolve your problem. If the problem is resolved, please tap [Update Status] button below';
    }

    return Scaffold(
      // drawer: NavBar(),
      appBar: AppBar(
        title: Text(header),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Container(
          color: Colors.grey[100],
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Center(
            child: Column(
              children: <Widget>[
                Card(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ListTile(
                        title: null,
                        subtitle: Text(
                          title,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                Card(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ListTile(
                        title: Text(unitType),
                        subtitle: Text(unit),
                      ),
                    ],
                  ),
                ),
                Card(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ListTile(
                        title: Text(role),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Name: ${Globals.curUserJson?['name']}',
                            ),
                            Text(
                              'Mobile: ${Globals.curUserJson?['mobile']}',
                            ),
                            Text(
                              'Email: ${Globals.curUserJson?['email']}',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: Colors.orange[100],
                      ),
                      onPressed: () {
                        _onBtnUpdate(context);
                      },
                      child: const Text(
                        'Status\nUpdate',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: Colors.orange[100],
                      ),
                      onPressed: () {
                        _onBtnRegister(context);
                      },
                      child: const Text(
                        'Register\nAgain',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
