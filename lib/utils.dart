library utils;

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math' as Math;
// import 'package:stack_trace/stack_trace.dart';
// import 'dart:convert' as convert;
// import 'dart:io';
// import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as Path;
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart' as intl;
import 'package:encrypt/encrypt.dart' as encrypt;
// import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';
// import 'package:path_provider/path_provider.dart';

import 'components/dialogBuilder.dart';
import 'include.dart';
import 'constants.dart' as Constants;
import 'globals.dart' as Globals;
// import 'ajax.dart' as Ajax;
// import 'lang.dart' as Lang;

Future<void> showAlertDialog(
  BuildContext context,
  String title,
  String msg, {
  String? okText,
  Color? backgroundColor,
}) async {
  developer.log(StackTrace.current.toString().split('\n')[0]);

  // Make this function async
  final Completer cmptr = Completer();

  // var context = Globals.navigatorKey.currentContext;
  // okText = okText != null ? okText : 'ok'.tr();
  okText = okText != null ? okText : 'ok'.tr();

  // set up the button
  Widget okButton = TextButton(
    child: Text(okText),
    onPressed: () {
      Navigator.of(context, rootNavigator: true).pop(); // dismiss dialog
      cmptr.complete(); // resolve the future
    },
  );

  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: Text(title),
    content: Text(msg),
    backgroundColor: backgroundColor,
    actions: [
      okButton,
    ],
  );

  // show the dialog
  showDialog(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return alert;
    },
  );

  return cmptr.future;
}

Future<bool> showConfirmDialog(
  BuildContext context,
  String title,
  String msg, {
  String? okText,
  String? cancelText,
}) async {
  developer.log(StackTrace.current.toString().split('\n')[0]);

  // Make this function async
  final cmptr = Completer<bool>();

  // var context = Globals.navigatorKey.currentContext;
  // okText = okText != null ? okText : 'ok'.tr();
  okText = okText != null ? okText : 'ok'.tr();
  // cancelText = cancelText != null ? cancelText : 'cancel'.tr();
  cancelText = cancelText != null ? cancelText : 'cancel'.tr();

  // set up the buttons (cancel & ok)
  Widget cancelButton = TextButton(
    child: Text(cancelText),
    onPressed: () {
      Navigator.of(context, rootNavigator: true).pop(); // dismiss the dialog
      cmptr.complete(false); // resolve the future
    },
  );
  Widget okButton = TextButton(
    child: Text(okText),
    onPressed: () {
      Navigator.of(context, rootNavigator: true).pop(); // dismiss the dialog
      cmptr.complete(true); // resolve the future
    },
  );

  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: Text(title),
    content: Text(msg),
    actions: [
      cancelButton,
      okButton,
    ],
  );

  // show the dialog
  showDialog<void>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return alert;
    },
  );

  return cmptr.future;
}

Future<String?> showInputDialog(
  BuildContext context, {
  required String title,
  required String msg,
  String? okText,
  String? cancelText,
}) async {
  developer.log(StackTrace.current.toString().split('\n')[0]);

  // Make this function async
  final cmptr = Completer<String?>();

  // var context = Globals.navigatorKey.currentContext;
  // okText = okText != null ? okText : 'ok'.tr();
  okText = okText != null ? okText : 'OK';
  // cancelText = cancelText != null ? cancelText : 'cancel'.tr();
  cancelText = cancelText != null ? cancelText : 'Cancel';
  TextEditingController tfCtrl = TextEditingController();

  // set up the buttons
  Widget cancelButton = TextButton(
    child: Text(cancelText),
    onPressed: () {
      Navigator.of(context, rootNavigator: true).pop(); // dismiss dialog
      cmptr.complete(null); // resolve the future
    },
  );
  Widget continueButton = TextButton(
    child: Text(okText),
    onPressed: () {
      Navigator.of(context, rootNavigator: true).pop(); // dismiss dialog
      cmptr.complete(tfCtrl.text); // resolve the future
    },
  );

  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: Text(title),
    content: Wrap(
      children: [
        Text(msg),
        TextField(
          controller: tfCtrl,
        ),
      ],
    ),
    actions: [
      cancelButton,
      continueButton,
    ],
  );

  // show the dialog
  showDialog(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return alert;
    },
  );

  return cmptr.future;
}

String getDbStringByCurLocale(String dbJsonStr) {
  var json = jsonDecode(dbJsonStr);
  if (Globals.curLang == 'en') return json['en'];
  throw 'Unhandled curLang: ${Globals.curLang}';
}

String getDbMapByCurLocale(Map<String, dynamic> dbJson) {
  if (Globals.curLang == 'en') return dbJson['en'];
  throw 'Unhandled curLang: ${Globals.curLang}';
}

// A generic empty text field checking
// e.g.: validator: (text) { return Utils.isFieldEmpty(text); }
String isFieldEmpty(String text) {
  if (text.isEmpty) {
    return 'cantEmpty'.tr();
  }
  return '';
}

String formatDate(String date) {
  DateTime ad = DateTime.parse(date).toLocal();
  return intl.DateFormat('yyyy-MM-dd').format(ad);
}

String formatTime(String time) {
  DateTime now = DateTime.now();
  DateTime ad =
      DateTime.parse(DateFormat('yyyy-MM-dd').format(now) + ' ' + time);
  return intl.DateFormat('h:mm a').format(ad).toLowerCase();
}

String formatDatetime(String dt) {
  DateTime d2 = DateTime.parse(dt).toLocal();
  return intl.DateFormat('yy-MM-dd h:mm a').format(d2).toLowerCase();
}

String formatNumber(int value) {
  return intl.NumberFormat.compact(locale: 'en_US').format(value);
}

String formatCurrency(int value) {
  final oCcy = intl.NumberFormat('#,##0', 'en_US');
  return oCcy.format(value);
}

String buildUnitNameWithLangByJson(
  Map<String, dynamic> unitJson,
) {
  developer.log(StackTrace.current.toString().split('\n')[0]);

  // Convert the parameters to match buildUnitNameWithLangByCode().
  String block = unitJson['block'] != null ? unitJson['block'] : '';
  String floor = unitJson['floor'] != null ? unitJson['floor'] : '';
  String number = unitJson['number'];
  String? authorizer = null; // unitJson['authorizer'];
  String unitType = unitJson['type'];
  late String unitCode;
  late String propTypeName;

  if (unitType == 'res') {
    unitCode = '$block|$floor|$number';
    propTypeName = 'residence'.tr();
  } else if (unitType == 'car') {
    unitCode = '$block|$floor|$number';
    propTypeName = 'carpark'.tr();
  } else if (unitType == 'shp') {
    unitCode = '$block|$floor|$number';
    propTypeName = 'shop'.tr();
  } else {
    throw 'Invalid unit type: $unitType';
  }

  Map<String, dynamic> rst =
      buildUnitNameWithLangByCode(unitType, unitCode, authorizer);

  return propTypeName + 'colon'.tr() + rst['unitName'];
}

// Where unitType: residences/carparks/shops
// unitCode: <phase>|<block>|<floor>|<number>
Map<String, dynamic> buildUnitNameWithLangByCode(
    String unitType, String? unitCode, String? authorizer) {
  developer.log(StackTrace.current.toString().split('\n')[0]);

  // String curLoc = Intl.getCurrentLocale();
  String rstUnitType = '';
  String rstUnitName = '';
  if (unitCode != null) {
    List<String> unitParts = unitCode.split('|');
    if (unitType == 'res') {
      // rstUnitType = 'residence'.tr();
      rstUnitType = 'residence'.tr();
      String block = unitParts[0].trim();
      String floor = unitParts[1].trim();
      String room = unitParts[2].trim();
      if (block != '') {
        if (Globals.curLang == 'en') {
          rstUnitName += '${'block2'.tr()} $block, ';
          // rstUnitName += 'Block $block, ';
        } else {
          rstUnitName += '$block${'block2'.tr()}, ';
          // rstUnitName += 'Block $block, ';
        }
      }
      if (floor != '') {
        if (Globals.curLang == 'en') {
          rstUnitName += '${'floor2'.tr()} $floor, ';
          // rstUnitName += 'Floor $floor, ';
        } else {
          rstUnitName += '$floor${'floor2'.tr()}, ';
          // rstUnitName += 'Floor $floor, ';
        }
      }
      if (room != '') {
        if (Globals.curLang == 'en') {
          rstUnitName += '${'room2'.tr()} $room';
          // rstUnitName += 'Room $room';
        } else {
          rstUnitName += '$room${'room2'.tr()}';
          // rstUnitName += 'Room $room';
        }
      }
    } else if (unitType == 'car') {
      rstUnitType = 'carpark'.tr();
      // rstUnitType = 'Carpark';
      String stage = unitParts[0].trim();
      String floor = unitParts[1].trim();
      String room = unitParts[2].trim();
      if (stage != '') {
        if (Globals.curLang == 'en') {
          rstUnitName += '${'stage2'.tr()} $stage, ';
          // rstUnitName += 'Phase $stage, ';
        } else {
          rstUnitName += '$stage${'stage2'.tr()}, ';
          // rstUnitName += 'Phase $stage, ';
        }
      }
      if (floor != '') {
        if (Globals.curLang == 'en') {
          rstUnitName += '${'floor2'.tr()} $floor, ';
          // rstUnitName += 'Floor $floor, ';
        } else {
          rstUnitName += '$floor${'floor2'.tr()}, ';
          // rstUnitName += 'Floor $floor, ';
        }
      }
      if (room != '') {
        if (Globals.curLang == 'en') {
          rstUnitName += '${'number2'.tr()} $room';
          // rstUnitName += 'Room $room';
        } else {
          rstUnitName += '$room${'number2'.tr()}, ';
          // rstUnitName += 'Room $room';
        }
      }
    } else if (unitType == 'shp') {
      rstUnitType = 'shop'.tr();
      // rstUnitType = 'Shop';
      String stage = unitParts[0].trim();
      String floor = unitParts[1].trim();
      String room = unitParts[2].trim();
      if (stage != '') {
        if (Globals.curLang == 'en') {
          rstUnitName += '${'stage2'.tr()} $stage, ';
          // rstUnitName += 'Phase $stage, ';
        } else {
          rstUnitName += '$stage${'stage2'.tr()}, ';
          // rstUnitName += 'Phase $stage, ';
        }
      }
      if (floor != '') {
        if (Globals.curLang == 'en') {
          rstUnitName += '${'floor2'.tr()} $floor, ';
          // rstUnitName += 'Floor $floor, ';
        } else {
          rstUnitName += '$floor${'floor2'.tr()}, ';
          // rstUnitName += 'Floor $floor, ';
        }
      }
      if (room != '') {
        if (Globals.curLang == 'en') {
          rstUnitName += '${'number2'.tr()} $room';
          // rstUnitName += 'Room $room';
        } else {
          rstUnitName += '$room${'number2'.tr()}, ';
          // rstUnitName += 'Room $room';
        }
      }
    } else {
      throw 'Invalid unit type: $unitType';
    }
  } else if (authorizer != null) {
    rstUnitName = authorizer;
    if (unitType == 'res') {
      rstUnitType = 'residence'.tr();
    } else if (unitType == 'car') {
      rstUnitType = 'carpark'.tr();
    } else if (unitType == 'shp') {
      rstUnitType = 'shop'.tr();
    } else {
      assert(false);
    }
  } else {
    assert(false, 'Should has "uid" or "authrz" property');
  }

  return {
    'unitType': rstUnitType,
    'unitName': rstUnitName,
  };
}

// Encrypt a string using AES-256-CTR & return the string in base64 format
// The encryption key & iv is assigned in assets/cfg/secrets.json
String encryptStringAES256CTR(val) {
  developer.log(StackTrace.current.toString().split('\n')[0]);
  assert(val != null);

  final encrypt.Key key = encrypt.Key.fromBase64(Globals.encryptSecretKey);
  final encrypt.IV iv = encrypt.IV.fromBase64(Globals.encryptIv);

  // AES256, Mode = CTR, No Padding, https://pub.dev/packages/encrypt
  final algorithm = encrypt.AES(key, mode: encrypt.AESMode.ctr, padding: null);
  final encrypter = encrypt.Encrypter(algorithm);
  final encrypted = encrypter.encrypt(val, iv: iv);

  return encrypted.base64; // The encrypted can be view as base64 String
}

// Decrypt a string which encrypted by above function.
String decryptStringAES256CTR(String val) {
  developer.log(StackTrace.current.toString().split('\n')[0]);

  final encrypt.Key key = encrypt.Key.fromBase64(Globals.encryptSecretKey);
  final encrypt.IV iv = encrypt.IV.fromBase64(Globals.encryptIv);

  // AES256, Mode = CTR, No Padding, https://pub.dev/packages/encrypt
  final algorithm = encrypt.AES(key, mode: encrypt.AESMode.ctr, padding: null);
  final encrypter = encrypt.Encrypter(algorithm);
  final decrypted =
      encrypter.decrypt(encrypt.Encrypted.fromBase64(val), iv: iv);

  return decrypted; // The decrypted can be view as String
}

int getRandomInt(int min, int max) {
  // Generate a random integer within range
  var random = new Math.Random();
  return min + random.nextInt(max - min);
}

Locale langIdToLocale(String langId) {
  developer.log(StackTrace.current.toString().split('\n')[0]);
  assert(['en', 'zh_HK', 'zh_CN'].contains(langId));

  Locale lc = Locale('en');
  if (langId == 'zh_HK') {
    lc = Locale('zh', 'HK');
  } else if (langId == 'zh_CN') {
    lc = Locale('zh', 'CN');
  }
  return lc;
}

// Generate the device token for the user. This will check with the user
// db record is this device is already existed. If else, it will add it
// and save to the database.
Future<String?> generateDeviceToken() async {
  developer.log(StackTrace.current.toString().split('\n')[0]);

  String? rtnVal;

  if (await FirebaseMessaging.instance.isSupported()) {
    String? token = await FirebaseMessaging.instance.getToken();

    if (token != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('deviceToken', token);
      rtnVal = token;

      if (kDebugMode) {
        print('fcmDeviceToken: ' + token);
      }
    }
  }

  return rtnVal;
}

// This is to findout the min/max time from the list of time begin/end.
// Usage: tbe = [{'begin':'08:00','end':'09:00'}, ... {'begin':'22:00','end':'23:00'}}]
// Result of findTimeMinMax(tbe) = {'min': '08:00', 'max': '23:00'}
Map<String, String> findTimeMinMax(List<Map<String, String>> timeBeginEnds) {
  String timeMin = '23:59';
  String timeMax = '00:00';

  for (int i = 0; i < timeBeginEnds.length; ++i) {
    String begin = timeBeginEnds[i]['begin']!;
    String end = timeBeginEnds[i]['end']!;

    assert(begin.length == 5);
    assert(end.length == 5);

    if (begin.compareTo(timeMin) < 0) {
      timeMin = begin;
    }

    if (end.compareTo(timeMax) > 0) {
      timeMax = end;
    }
  }

  return {'min': timeMin, 'max': timeMax};
}

String durationText(int mins) {
  if (mins < 60) {
    return '$mins mins';
  } else {
    int hr = mins ~/ 60;
    mins = mins - hr * 60;
    if (mins == 0) {
      return '$hr hr';
    } else {
      return '$hr hr $mins min';
    }
  }
}

String truncateString(String val, int len) {
  if (val.length > len) {
    return val.substring(0, len) + '...';
  }
  return val;
}

DateTime isoDatetimeToLocal(String isoDatetime) {
  return DateTime.parse(isoDatetime).toLocal();
}

// Using Dio, to download the file by URL to local specified path (temp dir)
Future<Response?> downloadFile(
  BuildContext context,
  String title,
  String url,
  String fullPath,
) async {
  developer.log(StackTrace.current.toString().split('\n')[0]);

  /*
  Map<Permission, PermissionStatus> statuses = await [
    Permission.storage,
    //add more permission to request here.
  ].request();
  */

  // if (statuses[Permission.storage]!.isGranted) {
  Dio dio = Dio();
  Response? resp;
  try {
    DialogBuilder(context)
        .showLoadingIndicator(title + 'fullstop'.tr() + 'pleaseWait'.tr());

    resp = await dio.download(
      url,
      fullPath,
      // onReceiveProgress: (receive, total) {
      //   setState(() {
      //     _downloadProgress =
      //         ((receive / total) * 100).toStringAsFixed(0) + '%';
      //     print(_downloadProgress);
      //     // progDlg.update(message: 'Downloading $_downloadProgress');
      //   });
      // },
    );
  } on DioError catch (e) {
    resp = e.response;
  } finally {
    DialogBuilder(context).hideOpenDialog();
  }

  return resp;
  // } else {
  //   return null;
  // }
}

void showSnackBar(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'error'.tr() + ": " + msg,
        style: TextStyle(
          fontSize: 16,
        ),
      ),
      duration: Duration(seconds: 5),
    ),
  );
}

bool parseDbBoolean(dynamic value) {
  if (value == null) {
    return false;
  } else if (value is bool) {
    return value;
  } else if (value is int) {
    return value > 0 ? true : false;
  } else if (value is double) {
    return value > 0.0 ? true : false;
  } else if (value is String) {
    return value == '1' ||
        value.toLowerCase() == 'true' ||
        value.toLowerCase() == 'yes' ||
        value.toLowerCase() == 'y';
  }
  return false;
}

Future<void> openLocalDatabase(String dbPath) async {
  developer.log(StackTrace.current.toString().split('\n')[0]);

  // Open the database and store the reference
  Globals.sqlite = await openDatabase(
    // Set the path to the database. Note: Using the `join` function from the
    // `path` package is best practice to ensure the path is correctly
    // constructed for each platform.
    dbPath,

    // When the database is first created, create a table to store models.
    onCreate: (db, version) async {
      // Create local database to store "Loops"
      await db.execute(
          'CREATE TABLE Loops(id TEXT PRIMARY KEY, dateCreated TEXT, titleId TEXT, titleTranslated TEXT, url TEXT, type TEXT, sender TEXT, paramsJson TEXT, isRead INTEGER)');
    },
    // Set the version. This executes the onCreate function and provides a
    // path to perform database upgrades and downgrades.
    version: 1,
  );
}
