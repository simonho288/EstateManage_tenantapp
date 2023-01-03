import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;
import 'dart:convert' as convert;
// import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:easy_localization/easy_localization.dart';

import '../include.dart';
import '../ajax.dart' as Ajax;
import '../utils.dart' as Utils;
import '../globals.dart' as Globals;
// import '../components/navBar.dart';
// import 'register.dart';

const DEBUG_DIRECTUS_USERID = 'd7ea95ae-92cd-41c9-aa44-b042f6cccde7';
const DEBUG_UNIT_CLASS = 'R'; // R, C, S
const DEBUG_UNIT_ID = '6d346f75-90c0-4691-a228-a9a5e66699c7';

class ScanEstateQrPage extends StatefulWidget {
  const ScanEstateQrPage({Key? key}) : super(key: key);

  @override
  _ScanEstateQrPageState createState() => _ScanEstateQrPageState();
}

class _ScanEstateQrPageState extends State<ScanEstateQrPage> {
  MobileScannerController? _controller;
  final GlobalKey qrKey = GlobalKey(/*debugLabel: 'QR'*/);

  @override
  initState() {
    developer.log('ScanEstateQrPage initState');

    _controller = MobileScannerController(
      facing: CameraFacing.back,
    );
    super.initState();
    setState(() {});
  }

  @override
  void dispose() {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    if (_controller != null) {
      _controller?.stop();
      _controller?.dispose();
    }

    super.dispose();
  } // dispose()

  Future<void> _onCodeScanned(Barcode code, var args) async {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    if (code.rawValue == null) return;
    String qrcode = code.rawValue!;
    if (!qrcode.startsWith('V-')) {
      return;
    }

    _controller!.stop();

    String? title, message;
    late Ajax.ApiResponse resp;

    // Extract the unit QRcode into 3 portions: estate id, property type, property id
    List<String> codes = qrcode.split('|');
    String directusUserId = codes[0];
    directusUserId = directusUserId.substring(2); // Remove the V- prefix

    if (codes.length != 3) {
      // Restart the camera & return
      _controller!.start();
      return;
    }

    try {
      resp = await Ajax.scanUnitQrcode(
        userId: directusUserId,
        cls: codes[1],
        unitId: codes[2],
      );

      if (resp.error != null) {
        throw resp.error!;
        // throw Exception(resp.error);
      }
    } catch (ex) {
      if (ex == 'invalid_qrcode' || ex == 'invalid_client') {
        title = 'errorEngCht'.tr();
        message = 'invalidEstateQRCode'.tr();
      } else if (ex == 'host_not_found') {
        title = 'errorEngCht'.tr();
        message = 'hostNotFound'.tr();
      } else {
        title = 'errorEngCht'.tr();
        message = 'serverResponseError'.tr() + ex.toString();
      }
    }

    if (title != null && message != null) {
      await Utils.showAlertDialog(
        context,
        title,
        message,
        backgroundColor: Colors.red[50],
      );

      SystemNavigator.pop();
      return;
    }

    // Parse the response & make unit, client JSON
    // assert(resp.data['unit'] != null);
    assert(resp.data['client'] != null);
    assert(resp.data['token'] != null);
    Map<String, dynamic> unitJson = resp.data['unit'];
    unitJson['cls'] = codes[1];
    unitJson['id'] = codes[2];
    Globals.curUnitJson = unitJson;
    Globals.curClientJson = resp.data['client'];
    Globals.accessToken = resp.data['token'];

    if (Globals.curClientJson!['membership_status'] == 'trial') {
      await Utils.showAlertDialog(
        context,
        'trialVersionTitle'.tr(),
        'trialVersion'.tr(),
      );
    } else if (Globals.curClientJson!['membership_status'] != 'active') {
      await Utils.showAlertDialog(
        context,
        'notEffective'.tr(),
        'estateDisabled'.tr(),
      );
      return;
    }

    // Save all the Json to local storage
    SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.setString(
        'clientJson', convert.jsonEncode(Globals.curClientJson));
    await pref.setString('unitJson', convert.jsonEncode(Globals.curUnitJson));
    await pref.setString('accessToken', Globals.accessToken!);

    Timer(Duration(milliseconds: 500), () {
      Navigator.of(context).pushReplacementNamed('/register');
    });

    // // Restart the camera
    // _controller!.start();
  }

  Widget _buildQrView(BuildContext context) {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    // var scanArea = (MediaQuery.of(context).size.width < 400 ||
    //         MediaQuery.of(context).size.height < 400)
    //     ? 150.0
    //     : 300.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller

    return MobileScanner(
      controller: _controller,
      allowDuplicates: false,
      onDetect: _onCodeScanned,
    );
  }

  @override
  Widget build(BuildContext context) {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    List<Widget> additionalWidgets = [];
    additionalWidgets.add(
      Text(
        'Please scan unit QR-code',
        style: TextStyle(fontSize: 16),
        textAlign: TextAlign.center,
      ),
    );

    return Scaffold(
      // drawer: NavBar(),
      appBar: AppBar(
        title: Text('Estate Manage Tenant App'),
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Text(
            'ver ${Globals.appVersion}',
            style: TextStyle(fontSize: 12),
          ),
          Expanded(flex: 4, child: _buildQrView(context)),
          if (Globals.isDebug) _SimulateQrScan(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: additionalWidgets,
          ),
        ],
      ),
    );
  }
}

///
/// This widget is to simulate the QRcode scan
///
class _SimulateQrScan extends StatelessWidget {
  // To obtain the IDs, login to MySql console and run the following queries:
  //
  // 1. Directus User ID
  // select id,email from directus_users;
  // 2. Unit ID
  // select * from residences where user_created="[userID]" and floor=1;
  // final _directusUserId = 'e89e2f20-cf0e-46c1-aead-050dc02e10e7';
  // final _cls = 'R'; // R, C, S
  // final _unitId = '0261737f-d4c5-4950-b23f-bbf02a851222';

  const _SimulateQrScan({Key? key}) : super(key: key);

  Future<void> _onBtnSimulateScan(BuildContext context) async {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    Ajax.ApiResponse resp = await Ajax.scanUnitQrcode(
      userId: DEBUG_DIRECTUS_USERID,
      cls: DEBUG_UNIT_CLASS,
      unitId: DEBUG_UNIT_ID,
    );

    // Parse the response & make unit, client JSON
    // assert(resp.data['unit'] != null);
    assert(resp.data['client'] != null);
    assert(resp.data['token'] != null);
    Map<String, dynamic> unitJson = resp.data['unit'];
    unitJson['cls'] = DEBUG_UNIT_CLASS;
    unitJson['id'] = DEBUG_UNIT_ID;
    Globals.curUnitJson = unitJson;
    Globals.curClientJson = resp.data['client'];
    Globals.accessToken = resp.data['token'];

    // Save all the Json to local storage
    SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.setString(
        'clientJson', convert.jsonEncode(Globals.curClientJson));
    await pref.setString('unitJson', convert.jsonEncode(Globals.curUnitJson));
    await pref.setString('accessToken', Globals.accessToken!);

    Navigator.of(context).pushReplacementNamed('/register');
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Debug Mode: Simulate QRcode scan\n',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text('Directus User ID'),
          Text('$DEBUG_DIRECTUS_USERID\n'),
          Text('Class'),
          Text('$DEBUG_UNIT_CLASS\n'),
          Text('Unit ID'),
          Text('$DEBUG_UNIT_ID\n'),
          ElevatedButton(
            child: Text('Confirm QR-Code scan'),
            onPressed: () => _onBtnSimulateScan(context),
          ),
        ],
      ),
    );
  }
}
