///
/// This screen is to show the tenant ID as QR-Code. At the time
/// of the development. It is no any place to use this.
/// It is for future use.
///
/// The QrCode is actually is constants + tenant ID 'tc|v1|$tenantId'
/// And it is encrypted by Utils.encryptStringAES256CTR()
///

import 'dart:developer' as developer;
import 'dart:convert' as convert;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:qr_flutter/qr_flutter.dart'; // For generate QR-code

import '../Utils.dart' as Utils;

class TenantQrcodePage extends StatefulWidget {
  const TenantQrcodePage({Key? key}) : super(key: key);

  @override
  State<TenantQrcodePage> createState() => TenantQrcodePageState();
}

class TenantQrcodePageState extends State<TenantQrcodePage> {
  late String _qrcode;

  TenantQrcodePageState({args}) {
    _qrcode = 'hello';
  }

  @override
  initState() {
    super.initState();
    loadInitialData();
  }

  loadInitialData() async {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String tenantJsonS = prefs.getString('tenantJson')!;
    var tenantJson = convert.jsonDecode(tenantJsonS);
    // String unitJsonS = prefs.getString('unitJson')!;
    // var unitJson = convert.jsonDecode(unitJsonS);
    // String unitId = unitJson['id'];
    String tenantId = tenantJson['id'];
    // String unitType = tenantJson['unit_type'];
    // String? unitCls = (unitType == 'resident')
    //     ? 'R'
    //     : (unitType == 'carpark')
    //         ? 'C'
    //         : (unitType == 'shop')
    //             ? 'S'
    //             : '';
    // if (unitCls == '') {
    //   Utils.showAlertDialog(context, 'Internal Error', 'Invalid unit type');
    //   return;
    // }

    String qrcode = 'tc|v1|$tenantId';

    // TODO Generate tenant QR-code
    qrcode = Utils.encryptStringAES256CTR(qrcode);

    setState(() {
      _qrcode = qrcode;
    });
  }

  @override
  Widget build(BuildContext context) {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    Size size = MediaQuery.of(context).size;

    return Scaffold(
      // drawer: NavBar(),
      appBar: AppBar(
        title: Text('tenantQrcode'.tr()),
      ),
      // body: Center(child: Text('TenantQrcodePage')),
      // Just for demo: Open the drawer programmatically
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            QrImageView(
              data: _qrcode,
              version: QrVersions.auto,
              size: size.width * 0.8,
            ),
            SizedBox(height: 20),
            Text(
              '(' + 'dontShareQrcode'.tr() + ')',
              style: TextStyle(color: Colors.black, fontSize: 20),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
