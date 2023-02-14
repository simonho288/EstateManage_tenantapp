import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:easy_localization/easy_localization.dart';
// import 'package:form_builder_validators/localization/l10n.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:global_configuration/global_configuration.dart';
import 'dart:developer' as developer;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path/path.dart' as Path;
import 'package:sqflite/sqflite.dart';

import 'include.dart';
import 'constants.dart' as Constants;
import 'globals.dart' as Globals;
import 'pages/receipt.dart';
// import 'pages/suspended.dart';
import 'utils.dart' as Utils;
import 'ajax.dart' as Ajax;
// import 'theme.dart' as Theme;

// import 'objectbox.g.dart';
import 'pages/login.dart';
import 'pages/register.dart';
import 'pages/home.dart';
import 'pages/about.dart';
import 'pages/amenities.dart';
import 'pages/booking.dart';
import 'pages/amenityBooking.dart';
import 'pages/marketPlace.dart';
import 'pages/notice.dart';
// import 'pages/notifications.dart.del';
import 'pages/settings.dart';
import 'pages/scanEstateQr.dart';
import 'pages/terms.dart';
import 'pages/setupPassword.dart';
import 'pages/rejected.dart';
// import 'pages/pending.dart';
import 'pages/tenantQrcode.dart';

FirebaseMessaging _messaging = FirebaseMessaging.instance;
// Create a [AndroidNotificationChannel] for heads up notifications
late AndroidNotificationChannel _channel;
// Initialize the [FlutterLocalNotificationsPlugin] package.
late FlutterLocalNotificationsPlugin _fltNotification;

// Define a top-level named handler which background/terminated messages will
// call.
// Ref: https://github.com/FirebaseExtended/flutterfire/blob/master/packages/firebase_messaging/firebase_messaging/example/lib/main.dart
// To verify things are working, check out the native platform logs.
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();

  // print('Handling a background message ${message.messageId}');
} // firebaseMessagingBackgroundHandler()

void main() async {
  developer.log(StackTrace.current.toString().split('\n')[0]);

  await _initialize();

  // Get the settings from the SharedPreferences...
  Map<String, dynamic> data = await _loadStartupData();

  // Pass default language ID (which stored in SharedPreferences)
  // Globals.curLang = data['langId'];
  // Locale locale = Utils.langIdToLocale(Globals.curLang);
  var defaultLocale = Locale('en', 'US');
  Globals.curLang = 'en';
  // runApp(MainApp(locale));
  runApp(
    EasyLocalization(
      supportedLocales: [defaultLocale],
      path: 'assets/langs',
      fallbackLocale: defaultLocale,
      child: MainApp(defaultLocale),
    ),
  );
}

// Application initializatioin
Future<void> _initialize() async {
  developer.log(StackTrace.current.toString().split('\n')[0]);

  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Assign the global variables
  Globals.isDebug = kDebugMode;
  String configFileName = Globals.configFileName = kDebugMode ? 'dev' : 'prod';

  // Load config json file
  developer
      .log('Loading config file: /assets/cfg/${Globals.configFileName}.json');
  await GlobalConfiguration().loadFromAsset(configFileName);
  await GlobalConfiguration().loadFromAsset('secrets');

  await _initFirebaseMessaging();
}

Future<void> _initFirebaseMessaging() async {
  // Firebase initialization
  await Firebase.initializeApp();

  if (!kIsWeb) {
    // Set the background messaging handler early on, as a named top-level function
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    _channel = const AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description:
          'This channel is used for important notifications.', // description
      importance: Importance.high,
    );

    _fltNotification = FlutterLocalNotificationsPlugin();

    // Create an Android Notification Channel.
    // We use this channel in the `AndroidManifest.xml` file to override the
    // default FCM channel to enable heads up notifications.
    await _fltNotification
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Update the iOS foreground notification presentation options to allow
    // heads up notifications.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: false,
      sound: true,
    );

    await _messaging.requestPermission(
      alert: true,
      badge: false,
      sound: true,
    );
  }
}

Future<Map<String, dynamic>> _loadStartupData() async {
  developer.log(StackTrace.current.toString().split('\n')[0]);

  // Load data from SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  Globals.hostApiUri = GlobalConfiguration().getValue("hostApiUri");
  Globals.encryptSecretKey = GlobalConfiguration().getValue('enc_secret_key');
  Globals.encryptIv = GlobalConfiguration().getValue('enc_iv');

  // Get the package info from pubspec.yaml
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  Globals.appVersion = packageInfo.version;
  final dbPath =
      Path.join(await getDatabasesPath(), Constants.LOCAL_DB_FILENAME);

  // If version is upgraded, delete the old version database
  String? lastVersion = prefs.getString("lastVersion");
  if (lastVersion != Globals.appVersion) {
    await deleteDatabase(dbPath);
    await prefs.setString('lastVersion', Globals.appVersion!);
  }
  await Utils.openLocalDatabase(dbPath);

  String? langId = prefs.getString('language');
  if (langId == null) {
    langId = 'en'; // 'zh_HK';
  }

  return {
    'langId': langId,
  };
}

// Application Main Widget
class MainApp extends StatefulWidget {
  final Locale _locale;

  MainApp(this._locale);

  @override
  State<StatefulWidget> createState() => _MainAppState(_locale);

  // Can be called by anywhere MyApp.changeLanguage(...)
  static void changeLanguage(BuildContext context, Locale value) {
    _MainAppState? state = context.findAncestorStateOfType<_MainAppState>();
    if (state != null) {
      state.changeLanguage(value);
    }
  }
}

class _MainAppState extends State<MainApp> {
  Locale _locale;

  _MainAppState(this._locale);

  // Called by MainApp only
  void changeLanguage(Locale value) {
    setState(() {
      _locale = value;
      Globals.curLang = _locale.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Estate Manage Tenant App',
      // theme: Theme.buildShrineTheme(),
      theme: ThemeData(
        fontFamily: 'NotoSansHK',
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // localizationsDelegates: locs,
      localizationsDelegates: context.localizationDelegates,
      // supportedLocales: [
      //   Locale.fromSubtags(languageCode: 'en'), // enable app_en.arb
      //   Locale.fromSubtags(
      //       languageCode: 'zh', countryCode: 'HK'), // enable app_zh_HK.arb
      //   Locale.fromSubtags(
      //       languageCode: 'zh', countryCode: 'CN'), // enable app_zh_CN.arb
      // ],
      supportedLocales: context.supportedLocales,
      // locale:
      //     _locale, // Set default locale, e.g. Locale('en'), Locale('zh', 'HK') or Locale('en', 'CN') is ok
      locale: context.locale,
      initialRoute: '/',
      routes: {
        '/': (ctx) => RootPage(),
        '/login': (ctx) => LoginPage(),
        '/register': (ctx) =>
            RegisterPage(/*args: ModalRoute.of(ctx)?.settings.arguments*/),
        '/home': (ctx) => HomePage(args: null),
        '/about': (ctx) => AboutPage(),
        '/booking': (ctx) =>
            BookingPage(args: ModalRoute.of(ctx)?.settings.arguments),
        '/amenities': (ctx) => AmenitiesPage(),
        '/amenityBooking': (ctx) =>
            AmenityBookingPage(args: ModalRoute.of(ctx)?.settings.arguments),
        '/marketplace': (ctx) =>
            MarketplacePage(args: ModalRoute.of(ctx)?.settings.arguments),
        '/marketplaces': (ctx) => HomePage(args: {'filter': 'marketplace'}),
        '/notice': (ctx) =>
            NoticePage(args: ModalRoute.of(ctx)?.settings.arguments),
        '/notices': (ctx) => HomePage(args: {'filter': 'notice'}),
        '/receipt': (ctx) =>
            ReceiptPage(args: ModalRoute.of(ctx)?.settings.arguments),
        '/settings': (ctx) => SettingsPage(),
        '/scanEstateQr': (ctx) => ScanEstateQrPage(),
        '/setupPassword': (ctx) => SetupPasswordPage(),
        '/rejectedPage': (ctx) => RejectedPage(),
        '/terms': (ctx) => TermsPage(),
        '/tenantQrcode': (ctx) => TenantQrcodePage(),
      },
    );
  }
}

// Second Application Widget to handle Firebase FCM
class RootPage extends StatefulWidget {
  const RootPage({Key? key}) : super(key: key);

  @override
  _RootPageState createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  late Future<bool> _future;
  String? _futureError;
  // late Map<String, dynamic> _datum;

  @override
  void initState() {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    super.initState();

    _initPushMessaging();
    _future = _loadInitialData();
  }

  // Setup Firebase foreground messaging listener
  // Docs: https://firebase.google.com/docs/cloud-messaging/flutter/receive
  void _initPushMessaging() async {
    // initialMessage is the message delivered by system notification.
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage, 'from getInitialMessage');
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
      // Ignore the message if it is received when the App is running
      // _handleMessage(msg, 'from onMessage');
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage msg) {
      _handleMessage(msg, 'from onMessageOpenedApp');
    });
  }

  _handleMessage(RemoteMessage msg, String debugInfo) {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    RemoteNotification? notification = msg.notification;
    Map<String, dynamic> data = msg.data;
    print(data);
    if (notification != null && !kIsWeb) {
      AndroidNotification? android = notification.android;
      AppleNotification? apple = notification.apple;

      // if (Platform.isAndroid || Platform.isIOS) {
      //   _fltNotification.show(
      //     notification.hashCode,
      //     notification.title,
      //     notification.body! + ',' + addMsg,
      //     NotificationDetails(
      //       android: AndroidNotificationDetails(
      //         _channel.id,
      //         _channel.name,
      //         channelDescription: _channel.description,
      //         icon: 'launch_background',
      //         // '1',
      //         // 'channelName',
      //         // 'channel Description',
      //       ),
      //       iOS: IOSNotificationDetails(
      //         presentSound: true,
      //         presentAlert: true,
      //       ),
      //     ),
      //   );
      // }

      Globals.goToPageData = data;
      // Navigator.pushNamed(context, '/notice', arguments: {'rec': rec});
    }
  }

  Future<bool> _loadInitialData() async {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    Map<String, dynamic> rtnVal = {}; // will be assigned to _datum

    // Load the SharedPreference
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // For debugging, do some reset things
    // prefs.clear; // Reset everything
    // prefs.remove('userJson'); // Remove userJson

    // Map<String, dynamic>? clientJson, userJson;

    try {
      String? sn = prefs.getString('accessToken');
      if (sn != null) {
        rtnVal['accessToken'] = sn;
        Globals.accessToken = sn;
      }
      sn = prefs.getString('userId');
      if (sn != null) {
        Globals.userId = sn;
      }
      sn = prefs.getString('tenantJson');
      if (sn != null) {
        Globals.curTenantJson = jsonDecode(sn);
      }
      sn = prefs.getString('estateJson');
      if (sn != null) {
        Globals.curEstateJson = jsonDecode(sn);
        var nameJson = jsonDecode(Globals.curEstateJson!['name']);
        Globals.curEstateJson!['name'] = nameJson[Globals.curLang];
      }
      sn = prefs.getString('unitJson');
      if (sn != null) {
        Globals.curUnitJson = jsonDecode(sn);
      }
      sn = prefs.getString('userJson');
      if (sn != null) {
        Globals.curTenantJson = jsonDecode(sn);
        // rtnVal['userJson'] = userJson;

        if (Globals.curTenantJson!['status'] == 'pending') {
          // Is the user approved;
          Ajax.ApiResponse resp = await Ajax.getTenantStatus(
            // clientCode: clientJson!['code'],
            tenantId: Globals.curTenantJson!['id'],
          );

          if (resp.data.length == 0) {
            // Remove the userJson from the return value
            rtnVal['userJson'] = null;
          } else {
            Globals.curTenantJson!['status'] = resp.data['status'];
          }
        }
      }
    } catch (e) {
      if (e.toString() == 'error 502') {
        _futureError = 'cantConnectServer'.tr();
      } else {
        _futureError = e.toString();
      }
    }

    return true;
  }

  // TODO VERY IMPORTANT logic to handle user states
  Widget _determineHomePage() {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    late Widget home;

    // Is clientCode exists?
    // Globals.curClientJson = _datum['clientJson'] ?? null;
    // Globals.curUserJson = _datum['userJson'] ?? null;
    // Globals.accessToken = _datum['accessToken'] ?? null;

    // State 0: Clean stage: Estate QR-Code not scanned -> clientJson=null
    // Stage 1: Estate QR-Code scanned -> clientJson!=null, userJson=null
    // Stage 2: User registered (status=pending,approved,normal,rejected,disabled)
    if (Globals.curEstateJson == null) {
      // State 0
      home = ScanEstateQrPage();
    } else {
      if (Globals.curTenantJson == null) {
        // State 1
        home = RegisterPage();
      } else {
        home = LoginPage();
      }
    }

    return Scaffold(
      body: home,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<bool?> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else {
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (snapshot.hasData) {
              if (_futureError != null) {
                // It needs delay to show the error message. Reason:
                // https://stackoverflow.com/questions/47592301/setstate-or-markneedsbuild-called-during-build-phase
                Future.delayed(Duration.zero, () async {
                  await Utils.showAlertDialog(
                    context,
                    'sysError'.tr(),
                    '$_futureError\n${'sysHalted'.tr()}',
                  );
                });
              } else {
                return _determineHomePage();
              }
            }
          }

          return CircularProgressIndicator();
        },
      ),
    );
  }
}
