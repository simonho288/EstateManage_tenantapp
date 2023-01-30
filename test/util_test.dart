import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:path/path.dart' as Path;

// import 'package:estatemanage_tenantapp/main.dart';
// import 'package:estatemanage_tenantapp/ajax.dart' as Ajax;
import 'package:estatemanage_tenantapp/constants.dart' as Constants;
import 'package:estatemanage_tenantapp/globals.dart' as Globals;
import 'package:estatemanage_tenantapp/utils.dart' as Utils;
import 'package:sqflite/sqflite.dart';
// import 'package:estatemanage_tenantapp/models.dart' as Models;
// import 'package:estatemanage_tenantapp/utils.dart' as Utils;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  Globals.encryptSecretKey = GlobalConfiguration().getValue('enc_secret_key');
  Globals.encryptIv = GlobalConfiguration().getValue('enc_iv');

  await EasyLocalization.ensureInitialized();
  // EasyLocalization(
  //   supportedLocales: [defaultLocale],
  //   path: 'assets/langs',
  //   fallbackLocale: defaultLocale,
  //   child: Container(),
  // );

  test('getDbStringByCurLocale()', () {
    expect(Utils.getDbStringByCurLocale('{"en":"<dummy>"}'), equals('<dummy>'));
  });

  test('getDbMapByCurLocale()', () {
    expect(Utils.getDbMapByCurLocale({"en": "<dummy>"}), equals('<dummy>'));
  });

  test('isFieldEmpty()', () {
    expect(Utils.isFieldEmpty(''), equals('cantEmpty'));
  });

  test('formatDate()', () {
    expect(Utils.formatDate('2022-12-31 23:59:59'), equals('2022-12-31'));
  });

  test('formatTime()', () {
    expect(Utils.formatTime('23:59:59'), equals('11:59 pm'));
  });

  test('formatDatetime()', () {
    expect(Utils.formatDatetime('2022-12-31 23:59:59'),
        equals('22-12-31 11:59 pm'));
    expect(Utils.formatDatetime('2022-12-31T23:59:59-08:00'),
        equals('22-12-31 11:59 pm'));
  });

  test('formatNumber()', () {
    expect(Utils.formatNumber(123456), equals('123K'));
    expect(Utils.formatNumber(12345678), equals('12.3M'));
    expect(Utils.formatNumber(1234567890), equals('1.23B'));
  });

  test('buildUnitNameWithLangByJson()', () {
    expect(
        Utils.buildUnitNameWithLangByJson(
            {'type': 'res', 'block': 'A', 'floor': '2', 'number': '4'}),
        equals('residencecolonblock2 A, floor2 2, room2 4'));
    expect(
        Utils.buildUnitNameWithLangByJson(
            {'type': 'car', 'floor': 'G', 'number': '4'}),
        equals('carparkcolonfloor2 G, number2 4'));
    expect(
        Utils.buildUnitNameWithLangByJson(
            {'type': 'shp', 'floor': 'B1', 'number': 'C'}),
        equals('shopcolonfloor2 B1, number2 C'));
  });

  test('buildUnitNameWithLangByCode()', () async {
    expect(
      Utils.buildUnitNameWithLangByCode('res', 'B|B1|C', null),
      equals(
        {
          'unitType': 'residence',
          'unitName': 'block2 B, floor2 B1, room2 C',
        },
      ),
    );
  });

  test('encryptStringAES256CTR()', () async {
    const orgString = '<dummy string for encryption>';
    String encrypted = Utils.encryptStringAES256CTR(orgString);
    expect(Utils.decryptStringAES256CTR(encrypted), equals(orgString));
  });

  test('getRandomInt()', () {
    expect(Utils.getRandomInt(0, 10), inInclusiveRange(0, 10));
    expect(Utils.getRandomInt(0, 100), inInclusiveRange(0, 100));
    expect(Utils.getRandomInt(0, 1000), inInclusiveRange(0, 1000));
    expect(Utils.getRandomInt(0, 10000), inInclusiveRange(0, 10000));
    expect(Utils.getRandomInt(0, 100000), inInclusiveRange(0, 100000));
  });

  test('langIdToLocale()', () {
    expect(Utils.langIdToLocale('en'), equals(Locale('en')));
    expect(Utils.langIdToLocale('zh_HK'), equals(Locale('zh', 'HK')));
    expect(Utils.langIdToLocale('zh_CN'), equals(Locale('zh', 'CN')));
  });

  test('findTimeMinMax()', () {
    expect(
      Utils.findTimeMinMax(
        [
          {'begin': '22:30', 'end': '23:30'},
          {'begin': '12:00', 'end': '13:00'},
          {'begin': '18:00', 'end': '19:30'},
          {'begin': '08:00', 'end': '09:00'},
        ],
      ),
      equals(
        {
          'min': '08:00',
          'max': '23:30',
        },
      ),
    );
  });

  test('durationText()', () {
    expect(Utils.durationText(61), equals('1 hr 1 min'));
    expect(Utils.durationText(270), equals('4 hr 30 min'));
    expect(Utils.durationText(345), equals('5 hr 45 min'));
    expect(Utils.durationText(521), equals('8 hr 41 min'));
    expect(Utils.durationText(1796), equals('29 hr 56 min'));
  });

  test('truncateString()', () {
    expect(Utils.truncateString('<this is a long string to truncate>', 10),
        equals('<this is a...'));
    expect(Utils.truncateString('<this is a long string to truncate>', 20),
        equals('<this is a long stri...'));
  });

  test('isoDatetimeToLocal()', () {
    final now = DateTime.now();
    expect(
        Utils.isoDatetimeToLocal(now.toIso8601String()), equals(now.toLocal()));
  });

  test('parseDbBoolean()', () {
    expect(Utils.parseDbBoolean(null), isFalse);
    expect(Utils.parseDbBoolean(true), isTrue);
    expect(Utils.parseDbBoolean(1), isTrue);
    expect(Utils.parseDbBoolean(1.0), isTrue);
    expect(Utils.parseDbBoolean('1'), isTrue);
    expect(Utils.parseDbBoolean('Y'), isTrue);
    expect(Utils.parseDbBoolean('True'), isTrue);
    expect(Utils.parseDbBoolean('Yes'), isTrue);
    expect(Utils.parseDbBoolean(false), isFalse);
    expect(Utils.parseDbBoolean(0), isFalse);
    expect(Utils.parseDbBoolean(0.0), isFalse);
    expect(Utils.parseDbBoolean('0'), isFalse);
    expect(Utils.parseDbBoolean('N'), isFalse);
    expect(Utils.parseDbBoolean('False'), isFalse);
    expect(Utils.parseDbBoolean('No'), isFalse);
  });

  // testWidgets('Widget test', (WidgetTester tester) async {
  //   // Build our app and trigger a frame.

  //   // await Future.delayed(        const Duration(milliseconds: 1000), () {}); // this line
  //   await tester.pumpWidget(
  //     EasyLocalization(
  //       supportedLocales: [defaultLocale],
  //       path: 'assets/langs',
  //       fallbackLocale: defaultLocale,
  //       child: TestWidget(locale: defaultLocale),
  //     ),
  //   );

  //   test('getDbStringByCurLocale()', () async {
  //     expect(
  //         Utils.getDbStringByCurLocale('{"en":"<dummy>"}'), equals('<dummy>'));
  //   });

  //   test('getDbMapByCurLocale()', () async {
  //     expect(Utils.getDbMapByCurLocale({"en": "<dummy>"}), equals('<dummy>'));
  //   });

  //   test('isFieldEmpty()', () async {
  //     print(Utils.isFieldEmpty(''));
  //   });
  // });
}

// class TestWidget extends StatelessWidget {
//   final Locale locale;
//   const TestWidget({super.key, required this.locale});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Testing widget',
//       home: Scaffold(
//         appBar: AppBar(
//           title: Text('Testing'),
//         ),
//         body: Center(
//           child: Text('Testing'),
//         ),
//       ),
//     );
//   }
// }
