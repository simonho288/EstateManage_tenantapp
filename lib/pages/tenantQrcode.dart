import 'dart:developer' as developer;
import 'dart:convert' as convert;
import 'package:easy_localization/easy_localization.dart';
import 'package:qr_flutter/qr_flutter.dart'; // For generate QR-code

import '../include.dart';
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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userJsonS = prefs.getString('userJson')!;
    var userJson = convert.jsonDecode(userJsonS);
    String unitJsonS = prefs.getString('unitJson')!;
    var unitJson = convert.jsonDecode(unitJsonS);
    String unitId = unitJson['id'];
    String tenantId = userJson['id'];
    String unitType = userJson['unit_type'];
    String? unitCls = (unitType == 'resident')
        ? 'R'
        : (unitType == 'carpark')
            ? 'C'
            : (unitType == 'shop')
                ? 'S'
                : '';
    if (unitCls == '') {
      Utils.showAlertDialog(context, 'Internal Error', 'Invalid unit type');
      return;
    }

    String qrcode = 'v1|$tenantId|$unitCls|$unitId';

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
          children: <Widget>[
            QrImage(
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
