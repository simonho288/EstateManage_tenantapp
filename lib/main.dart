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
import 'pages/suspended.dart';
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
import 'pages/pending.dart';
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

  final dbPath =
      Path.join(await getDatabasesPath(), Constants.LOCAL_DB_FILENAME);

  // TODO Comment it out in production
  // Delete the local database & create a new one everytime.
  await deleteDatabase(dbPath);
  await Utils.openLocalDatabase();

  // Assign the global variables
  Globals.isDebug = kDebugMode;
  String configFileName = Globals.configFileName = kDebugMode ? 'dev' : 'prod';

  // Load config json
  developer
      .log('Loading config file: /assets/cfg/${Globals.configFileName}.json');
  await GlobalConfiguration().loadFromAsset(configFileName);

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
  // Globals.hostApiUri = prefs.getString('hostApiUri');
  // Globals.hostSocketUri = prefs.getString('hostSocketUri');
  Globals.hostS3Base = GlobalConfiguration().getValue('hostS3Base');

  // developer.log(
  //     'hostApiUri: ${Globals.hostApiUri}, hostSocketUri: ${Globals.hostSocketUri}, hostS3Base: ${Globals.hostS3Base}');

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
    // List<LocalizationsDelegate<dynamic>> locs =
    //     List.from(AppLocalizations.localizationsDelegates);
    // locs.add(FormBuilderLocalizations.delegate);

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
        '/marketplaces': (ctx) => HomePage(args: {'filter': 'new_marketplace'}),
        '/notice': (ctx) =>
            NoticePage(args: ModalRoute.of(ctx)?.settings.arguments),
        '/notices': (ctx) => HomePage(args: {'filter': 'management_notice'}),
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

    // For debugging, get the device token for Firebase console to send instant test message
    if (kDebugMode) {
      _getDeviceFCMtoken();
    }
    _initPushMessaging();
    _future = _loadInitialData();
  }

  void _getDeviceFCMtoken() async {
    String? token = await _messaging.getToken();

    print('FCM key for firebase console: $token');
  }

  void _initPushMessaging() {
    // Setup Firebase messaging notification
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        developer.log('Firebase initial message received');

        // Navigator.pushNamed(context, '/notifications', arguments: message);
      }
    });

    // Setup Firebase foreground messaging listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      AppleNotification? apple = message.notification?.apple;
      if (notification != null && !kIsWeb) {
        if (Platform.isAndroid) {
          _fltNotification.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                _channel.id,
                _channel.name,
                channelDescription: _channel.description,
                icon: 'launch_background',
                // '1',
                // 'channelName',
                // 'channel Description',
              ),
            ),
          );
        } else if (Platform.isIOS) {
          _fltNotification.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              iOS: IOSNotificationDetails(
                presentSound: true,
                presentAlert: true,
              ),
            ),
          );
        }
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      developer.log('A new onMessageOpenedApp event was published!');

      // TODO Handle push notification from OS
      // Navigator.pushNamed(context, '/home', arguments: message);
      Navigator.pushNamed(context, '/');
    });
  }

  Future<bool> _loadInitialData() async {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    Map<String, dynamic> rtnVal = {}; // will be assigned to _datum

    // Get the package info from pubspec.yaml
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    // String appName = packageInfo.appName;
    // String packageName = packageInfo.packageName;
    Globals.appVersion = packageInfo.version;
    // String buildNumber = packageInfo.buildNumber;

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
            Globals.curTenantJson!['status'] = resp.data[0]['status'];
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
        /*
        // State 2
        int status = Globals.curTenantJson?['status'];
        if (status == 0) {
          home = PendingPage();
        } else if (status == 2) {
          home = SuspendedPage();
        } else if (status == 1) {
          home = LoginPage();
        }
        */
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
