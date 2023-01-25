// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
// import 'package:test/test.dart';

import 'package:estatemanage_tenantapp/ajax.dart' as Ajax;
import 'package:estatemanage_tenantapp/globals.dart' as Globals;
import 'package:estatemanage_tenantapp/utils.dart' as Utils;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

const USER_ID = 'adminuserid123';
const UNIT_ID = 'AprTvXkFWkxp6X765kfo3';
const TENANT_EMAIL = 'simonho288@gmail.com';
const TENANT_PASSWORD = 'password';
const TENANT_ID = '2dh71lyQgEC4dLJGm3T97';
const DEBUG_QRCODE =
    'https://www.estatemanage.net/appdl/index.html/?a=$USER_ID&b=$UNIT_ID&c=aCfFPPdSR3tLJ2QRN5VXl';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await EasyLocalization.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  PackageInfo.setMockInitialValues(
    appName: 'estatemanage_tenantapp',
    packageName: 'estatemanage_tenantapp',
    version: '0.5',
    buildNumber: '1',
    buildSignature: '',
  );
  var defaultLocale = Locale('en', 'US');
  Globals.curLang = 'en';
  String configFileName = Globals.configFileName = 'dev';
  await GlobalConfiguration().loadFromAsset(configFileName);
  await GlobalConfiguration().loadFromAsset('secrets');
  late String newTenantId;
  late String newTenantEmail;

  Globals.isDebug = true;
  Globals.hostApiUri = GlobalConfiguration().getValue("hostApiUri");

  test('scanUnitQrcode', () async {
    // Expected result JSON.
    // The unit is created by insertSampleOthers.ts in backend
    Map<String, dynamic> expectedJson = {
      "userId": USER_ID,
      "success": true,
      "unitId": UNIT_ID,
      "type": "res",
      "block": "A",
      "floor": "1",
      "number": "1",
      "estate": {
        "id": "aN2gsOUpMnzyC8CoxumSr",
        "name": '{"en":"Harbour View Garden Tower 3"}',
        "address": '{"en":"No.21 North Street, Kennedy Town, Hong Kong"}',
        "contact":
            '{"name":{"en":"<Estate Admin Name>"},"tel":"<Admin Phone no>","email":"go@simonho.net"}',
        "langEntries": "en",
        "timezone": "8",
        "timezoneMeta":
            '{"value":"China Standard Time","offset":28800000,"text":"(UTC+08:00) Beijing, Chongqing, Hong Kong, Urumqi"}',
        "currency": "HKD",
        "tenantApp":
            '{"estateImageApp":"https://f004.backblazeb2.com/file/vpms-hk/assets/tenantapp_default_estate_640x360.jpg","unitQrcodeSheetDspt":{"en":"<u>Please scan this QR code to register</u>"}}',
      }
    };
    Ajax.ApiResponse resp = await Ajax.scanUnitQrcode(DEBUG_QRCODE);
    expect(resp.data, equals(expectedJson));

    Globals.userId = resp.data['userId'];
  });

  test('tenant login', () async {
    Ajax.ApiResponse resp = await Ajax.tenantLogin(
      userId: Globals.userId!,
      mobileOrEmail: TENANT_EMAIL,
      password: TENANT_PASSWORD,
    );
    // print(resp.data);
    expect(resp.data, contains('token'));
    expect(resp.data, contains('tenant'));
    Globals.accessToken = resp.data['token'];
    Globals.curTenantJson = resp.data['tenant'];
  });

  test('getTenantStatus', () async {
    Ajax.ApiResponse resp = await Ajax.getTenantStatus(tenantId: TENANT_ID);
    // print(resp.data);
    expect(resp.data, contains('status'));
    expect(resp.data['status'], equals(1));
  });

  test('createNewTenant', () async {
    newTenantEmail = 'dummy@example${Utils.getRandomInt(1, 10000)}.com';
    Ajax.ApiResponse resp = await Ajax.createNewTenant(
      unitId: UNIT_ID,
      userId: USER_ID,
      role: 'tenant',
      name: '<dummy name>',
      mobile: '11122233333',
      email: newTenantEmail,
      password: 'password',
      fcmDeviceToken: '',
    );
    expect(resp.data, contains('tenantId'));
    newTenantId = resp.data['tenantId'];
  });

  test('new tenant login', () async {
    Ajax.ApiResponse resp = await Ajax.tenantLogin(
      userId: Globals.userId!,
      mobileOrEmail: newTenantEmail,
      password: 'password',
    );
    expect(resp.error, equals('account_pending'));
  });

  test('setTenantPassword', () async {
    Ajax.ApiResponse resp = await Ajax.setTenantPassword(
        tenantId: newTenantId, password: 'password2');
    expect(resp.data, contains('success'));
    expect(resp.data['success'], equals(true));
  });

  test('new tenant login with new password', () async {
    Ajax.ApiResponse resp = await Ajax.tenantLogin(
      userId: Globals.userId!,
      mobileOrEmail: newTenantEmail,
      password: 'password2',
    );
    expect(resp.error, equals('account_pending'));
  });

  test('tenantLogout', () async {
    Ajax.ApiResponse resp = await Ajax.tenantLogout(tenantId: newTenantId);
    expect(resp.data, contains('success'));
    expect(resp.data['success'], equals(true));
  });

/*
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.

    await tester.pumpWidget(MainApp(defaultLocale));

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
*/
}
