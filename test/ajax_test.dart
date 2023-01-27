// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:nanoid/nanoid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:convert/convert.dart';
// import 'package:test/test.dart';

import 'package:estatemanage_tenantapp/ajax.dart' as Ajax;
import 'package:estatemanage_tenantapp/globals.dart' as Globals;
import 'package:estatemanage_tenantapp/utils.dart' as Utils;
import 'package:estatemanage_tenantapp/models.dart' as Models;

const USER_ID = 'adminuserid123';
const UNIT_ID = 'AprTvXkFWkxp6X765kfo3';
const TENANT_EMAIL = 'simonho288@gmail.com';
const TENANT_PASSWORD = 'password';
const TENANT_ID = '2dh71lyQgEC4dLJGm3T97';
const DEBUG_QRCODE =
    'https://www.estatemanage.net/appdl/index.html/?a=$USER_ID&b=$UNIT_ID&c=aCfFPPdSR3tLJ2QRN5VXl';

void main() async {
  final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
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
  Models.Amenity? amenity = null;
  late String tenAmenBkgId;
  late String loopId;

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
    Globals.curEstateJson = resp.data['estate'];
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
    expect(newTenantEmail, isNotNull);
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

  test('deleteTenant', () async {
    Ajax.ApiResponse resp = await Ajax.deleteTenant(tenantId: newTenantId);
    expect(resp.data, contains('success'));
    expect(resp.data['success'], equals(true));
  });

  test('getAllUnits', () async {
    Ajax.ApiResponse resp = await Ajax.getAllUnits(type: 'res');
    expect(resp.data, isNotNull);
    expect(resp.data, isList);
    for (var data in resp.data) {
      expect(data, isMap);
      expect(data['id'], isNotNull);
      expect(data['type'], equals('res'));
      expect(data['block'], isNotNull);
      expect(data['floor'], isNotNull);
      expect(data['number'], isNotNull);
    }

    resp = await Ajax.getAllUnits(type: 'car');
    expect(resp.data, isNotNull);
    expect(resp.data, isList);
    for (var data in resp.data) {
      expect(data, isMap);
      expect(data['id'], isNotNull);
      expect(data['type'], equals('car'));
      expect(data['block'], isNotNull);
      expect(data['floor'], isNotNull);
      expect(data['number'], isNotNull);
    }

    resp = await Ajax.getAllUnits(type: 'shp');
    expect(resp.data, isNotNull);
    expect(resp.data, isList);
    for (var data in resp.data) {
      expect(data, isMap);
      expect(data['id'], isNotNull);
      expect(data['type'], equals('shp'));
      expect(data['block'], isNotNull);
      expect(data['floor'], isNotNull);
      expect(data['number'], isNotNull);
    }
  });

  test('getLoops', () async {
    Ajax.ApiResponse resp = await Ajax.getLoops(tenantId: TENANT_ID);
    expect(resp.data, isNotNull);
    expect(resp.data, isList);
    List<String> ids = [];
    for (var data in resp.data) {
      expect(data, isMap);
      expect(data['id'], isNotNull);
      expect(data['tenantId'], equals(TENANT_ID));
      ids.add(data['id']);
    }

    // Get the loops again with excluded IDs. Which the results should be empty
    resp = await Ajax.getLoops(tenantId: TENANT_ID, excludeIDs: ids);
    expect(resp.data, isNotNull);
    expect(resp.data, isList);
    expect(resp.data.length, equals(0));
  });

  test('getNotices', () async {
    // Testing type: res
    Ajax.ApiResponse resp = await Ajax.getNotices(unitType: 'res');
    expect(resp.data, isNotNull);
    expect(resp.data, isList);
    List<String> ids = [];
    for (var data in resp.data) {
      expect(data, isMap);
      expect(data['id'], isNotNull);
      ids.add(data['id']);

      Ajax.ApiResponse resp2 = await Ajax.getNoticeById(id: data['id']);
      expect(resp2.data, isMap);
      expect(resp2.data, isNotNull);
      expect(resp2.data['id'], equals(data['id']));
    }

    // Get the records again with excluded IDs. Which the results should be empty
    resp = await Ajax.getNotices(unitType: 'res', excludeIDs: ids);
    expect(resp.data, isNotNull);
    expect(resp.data, isList);
    expect(resp.data.length, equals(0));

    // Testing type: car
    resp = await Ajax.getNotices(unitType: 'car');
    expect(resp.data, isNotNull);
    expect(resp.data, isList);
    ids = [];
    for (var data in resp.data) {
      expect(data, isMap);
      expect(data['id'], isNotNull);
      ids.add(data['id']);
    }

    // Get the records again with excluded IDs. Which the results should be empty
    resp = await Ajax.getNotices(unitType: 'car', excludeIDs: ids);
    expect(resp.data, isNotNull);
    expect(resp.data, isList);
    expect(resp.data.length, equals(0));

    // Testing type: shp
    resp = await Ajax.getNotices(unitType: 'shp');
    expect(resp.data, isNotNull);
    expect(resp.data, isList);
    ids = [];
    for (var data in resp.data) {
      expect(data, isMap);
      expect(data['id'], isNotNull);
      ids.add(data['id']);
    }

    // Get the records again with excluded IDs. Which the results should be empty
    resp = await Ajax.getNotices(unitType: 'shp', excludeIDs: ids);
    expect(resp.data, isNotNull);
    expect(resp.data, isList);
    expect(resp.data.length, equals(0));
  });

  test('getMarketplaces', () async {
    // Testing type: res
    Ajax.ApiResponse resp = await Ajax.getMarketplaces(unitType: 'res');
    expect(resp.data, isNotNull);
    expect(resp.data, isList);
    List<String> ids = [];
    for (var data in resp.data) {
      expect(data, isMap);
      expect(data['id'], isNotNull);
      ids.add(data['id']);

      Ajax.ApiResponse resp2 = await Ajax.getMarketplaceById(id: data['id']);
      expect(resp2.data, isMap);
      expect(resp2.data, isNotNull);
      expect(resp2.data['id'], equals(data['id']));
    }

    // Get the records again with excluded IDs. Which the results should be empty
    resp = await Ajax.getMarketplaces(unitType: 'res', excludeIDs: ids);
    expect(resp.data, isNotNull);
    expect(resp.data, isList);
    expect(resp.data.length, equals(0));

    // Testing type: car
    resp = await Ajax.getMarketplaces(unitType: 'car');
    expect(resp.data, isNotNull);
    expect(resp.data, isList);
    ids = [];
    for (var data in resp.data) {
      expect(data, isMap);
      expect(data['id'], isNotNull);
      ids.add(data['id']);
    }

    // Get the records again with excluded IDs. Which the results should be empty
    resp = await Ajax.getMarketplaces(unitType: 'car', excludeIDs: ids);
    expect(resp.data, isNotNull);
    expect(resp.data, isList);
    expect(resp.data.length, equals(0));

    // Testing type: shp
    resp = await Ajax.getMarketplaces(unitType: 'shp');
    expect(resp.data, isNotNull);
    expect(resp.data, isList);
    ids = [];
    for (var data in resp.data) {
      expect(data, isMap);
      expect(data['id'], isNotNull);
      ids.add(data['id']);
    }

    // Get the records again with excluded IDs. Which the results should be empty
    resp = await Ajax.getMarketplaces(unitType: 'shp', excludeIDs: ids);
    expect(resp.data, isNotNull);
    expect(resp.data, isList);
    expect(resp.data.length, equals(0));
  });

  test('getBookableAmenities', () async {
    Ajax.ApiResponse resp = await Ajax.getBookableAmenities();
    // print(resp.data);
    expect(resp.data, isNotNull);
    expect(resp.data, isList);
    expect(resp.data.length, greaterThan(0));
    for (var data in resp.data) {
      expect(data, isMap);
      expect(data['id'], isNotNull);

      Ajax.ApiResponse resp2 = await Ajax.getAmenityById(id: data['id']);
      expect(resp2.data['name'], equals(data['name']));
      expect(resp2.data['details'], equals(data['details']));
      expect(resp2.data['photo'], equals(data['photo']));
      expect(resp2.data['status'], equals(data['status']));
      expect(resp2.data['fee'], equals(data['fee']));
      expect(resp2.data['currency'], equals(data['currency']));
      expect(resp2.data['availableDays'], equals(data['availableDays']));
      expect(resp2.data['bookingTimeBasic'], equals(data['bookingTimeBasic']));
      expect(resp2.data['timeBased'], equals(data['timeBased']));
      expect(resp2.data['sectionBased'], equals(data['sectionBased']));
      expect(
          resp2.data['bookingAdvanceDays'], equals(data['bookingAdvanceDays']));
      expect(resp2.data['autoCancelHours'], equals(data['autoCancelHours']));
      expect(resp2.data['contact'], equals(data['contact']));
      expect(resp2.data['isRepetitiveBooking'],
          equals(data['isRepetitiveBooking']));

      if (amenity == null) {
        // print(resp2.data);
        Map<String, dynamic> availableDays =
            jsonDecode(resp2.data['availableDays']);
        Map<String, dynamic> timeBased = jsonDecode(resp2.data['timeBased']);
        Map<String, dynamic> contact = jsonDecode(resp2.data['contact']);
        amenity = new Models.Amenity(
          id: resp2.data['id'],
          dateCreated: resp2.data['dateCreated'],
          name: resp2.data['name'],
          details: resp2.data['details'],
          photo: resp2.data['photo'],
          monday: availableDays['mon'],
          tuesday: availableDays['tue'],
          wednesday: availableDays['wed'],
          thursday: availableDays['thu'],
          friday: availableDays['fri'],
          saturday: availableDays['sat'],
          sunday: availableDays['sun'],
          status: resp2.data['status'],
          fee: resp2.data['fee'] != null ? resp2.data['fee'].toDouble() : null,
          timeOpen: timeBased['timeOpen'] != null
              ? DateTime.parse(today + ' ' + timeBased['timeOpen'])
              : null,
          timeClose: timeBased['timeClose'] != null
              ? DateTime.parse(today + ' ' + timeBased['timeClose'])
              : null,
          timeMinimum: int.parse(timeBased['timeMinimum']),
          timeMaximum: int.parse(timeBased['timeMaximum']),
          timeIncrement: int.parse(timeBased['timeIncrement']),
          bookingTimeBasic: resp2.data['bookingTimeBasic'],
          isRepetitiveBooking: resp2.data['isRepetitiveBooking'] == 1,
          bookingAdvanceDays: resp2.data['bookingAdvanceDays'] != null
              ? int.parse(resp2.data['bookingAdvanceDays'])
              : null,
          autoCancelHours: resp2.data['autoCancelHours'],
          contactEmail: contact['email'],
          contactWhatsapp: contact['whatsapp'],
        );
      }
    }
  });

  test('getEstateById', () async {
    String id = Globals.curEstateJson!['id'];
    Ajax.ApiResponse resp = await Ajax.getEstateById(id: id);
    // print(resp.data);
    expect(resp.data, isNotNull);
    expect(resp.data['id'], equals(id));
    expect(resp.data['name'], isNotNull);
  });

  test('getTenantBookingsByDate', () async {
    expect(amenity, isNotNull);
    Ajax.ApiResponse resp =
        await Ajax.getTenantBookingsByDate(date: today, amenityId: amenity!.id);
    // print(resp.data);
    expect(resp.data, isNotNull);
    expect(resp.data, isList);
  });

  test('saveAmenityBooking', () async {
    expect(amenity, isNotNull);

    Models.TenantAmenityBooking booking = Models.TenantAmenityBooking(
      id: nanoid(),
      dateCreated: DateTime.now(),
      tenantId: TENANT_ID,
      amenityId: amenity!.id,
      bookingTimeBasic: amenity!.bookingTimeBasic,
      date: today,
      totalFee: amenity!.fee,
      isPaid: false,
      slots: [],
    );

    List<Models.TenantAmenityBookingSlot> tabslots = [];
    tabslots.add(Models.TenantAmenityBookingSlot(
      timeStart: '09:00',
      timeEnd: '09:30',
    ));

    Ajax.ApiResponse resp = await Ajax.saveAmenityBooking(
      amenity: amenity!,
      booking: booking,
      slots: tabslots,
      status: 'pending',
      currency: Globals.curEstateJson!['currency'],
      loopTitle: '<dummy>',
    );
    // print(jsonEncode(resp.data));
    expect(resp.data, isNotNull);
    expect(resp.data['tenAmenBkg'], isNotNull);
    expect(resp.data['loop'], isNotNull);
    // expect(resp.data['loop'], isNotNull);
    tenAmenBkgId = resp.data['tenAmenBkg']['id'];
    loopId = resp.data['loop']['id'];
  });

  test('deleteTenantBooking', () async {
    List<String> ids = [tenAmenBkgId];
    Ajax.ApiResponse resp =
        await Ajax.deleteTenantBooking(tenantAmenityBookingIds: ids);
    expect(resp.data, contains('success'));
    expect(resp.data['success'], equals(true));
  });

  test('deleteTenantLoops', () async {
    List<String> ids = [loopId];
    Ajax.ApiResponse resp = await Ajax.deleteTenantLoops(loopIds: ids);
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
