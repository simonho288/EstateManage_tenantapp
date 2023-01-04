library globals;

import 'include.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:sqflite/sqflite.dart';
// import 'package:objectbox/objectbox.dart';

import 'pages/home.dart';

const FlexScheme usedFlexScheme = FlexScheme.mango;
const defaultEstateImage =
    'https://vpms-hk.s3.us-west-004.backblazeb2.com/assets/tenantapp_default_estate_640x360.jpg';
const defaultAmenityCanvas =
    'https://vpms-hk.s3.us-west-004.backblazeb2.com/assets/generic_amenity.jpg';

const Color primaryColor = const Color(0xFFC08D30);
const Color primaryLightDarkColor = const Color(0xFFDAAB55);
const Color primaryLightColor = const Color(0xFFF0CF93);
const Color primaryLighterColor = const Color(0xFFF9ECD5);
const Color primaryLighterColor2 = const Color(0xFFF9F0DF);

// Current logged-in user json
Map<String, dynamic>? curUserJson;

// Current client config record (collection client)
String? accessToken;
Map<String, dynamic>? curEstateJson;
Map<String, dynamic>? curUnitJson;

// Configuration file name. dev.json or prod.json
String? configFileName;

// App version from pubspec.yaml
String? appVersion;

// Current Language (en, zh_HK, zh_CN)
late String curLang;

// Is debug mode
late bool isDebug;

// Url of the backend
String? hostApiUri;
// String? hostSocketUri;
String? hostS3Base; // https://vpms-hk.s3.us-west-004.backblazeb2.com

// Can get the "context" anywhere
final navigatorKey = GlobalKey<NavigatorState>();

// Current language ID & language mapping table
// String curLangId = 'eng';

// All units
// Map<String, dynamic>? allUnits;

// late Store oboxStore; // ObjectBox store
late Database sqlite;

// Homepage widget
late HomePage homePage;