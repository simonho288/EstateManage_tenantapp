library ajax;

import 'dart:developer' as developer;
// import 'package:stack_trace/stack_trace.dart';
import 'dart:async';
import 'dart:convert' as convert;
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:intl/intl.dart';
// import '../objectbox.g.dart'; // created by `flutter pub run build_runner

import 'include.dart';
import 'utils.dart' as Utils;
import 'globals.dart' as Globals;
import '../models.dart' as Models;

final TIMEOUT = Globals.isDebug ? 600 : 15; // 15 secs

// Generic API Response to indicate the result from REST APIs
class ApiResponse {
  // Map<String, dynamic> data; // Server returns data when successful
  var data; // Server returns data when successful
  String? error; // Error message from server
  int? statusCode; // Server returns status code
}

// Common function to build the ApiResponse
ApiResponse _returnResponse(var postResp) {
  // developer.log(StackTrace.current.toString().split('\n')[0]);

  if (postResp.statusCode > 299) {
    throw 'error ${postResp.statusCode}';
  }

  ApiResponse resp = new ApiResponse();

  resp.statusCode = postResp.statusCode;
  String respBody = postResp.body;
  var data;
  String? error;
  if (respBody.length > 0) {
    Map<String, dynamic> bodyJson = convert.jsonDecode(respBody);
    if (bodyJson['data'] != null) {
      data = bodyJson['data'];
    } else if (bodyJson['error'] != null) {
      error = bodyJson['error'];
    }
  }

  if (error != null) {
    resp.error = error;
  } else if (data != null) {
    resp.data = data;
  } else if (postResp.statusCode == 502) {
    // Bad gateway
    resp.error = 'bad_gateway_or_server_halted';
  }
  return resp;
}

//////////////////////////////////////////////////////////////////////////

Future<ApiResponse> getTenantStatus({required String tenantId}) async {
  developer.log(StackTrace.current.toString().split('\n')[0]);

  final response = await http.get(
    Uri.parse('${Globals.hostApiUri}/api/tl/getTenantStatus'),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      HttpHeaders.authorizationHeader: 'Bearer ' + Globals.accessToken!,
    },
  ).timeout(Duration(seconds: TIMEOUT));

  return _returnResponse(response);
}

// When a new user scan the QR-code on unit sheet
Future<ApiResponse> scanUnitQrcode(String qrcode) async {
  developer.log(StackTrace.current.toString().split('\n')[0]);
  developer.log('hostApiUri: ${Globals.hostApiUri}');

  // Get the unit ID
  final Map<String, dynamic> param = {
    'url': qrcode,
  };
  Response response = await http
      .post(
        Uri.parse('${Globals.hostApiUri}/api/nl/scanUnitQrcode'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: convert.jsonEncode(param),
      )
      .timeout(Duration(seconds: TIMEOUT));

  if (response.statusCode > 299) {
    return _returnResponse(response);
  }

  return _returnResponse(response);
}

// New version of submitJoinRequest()
Future<ApiResponse> createNewTenant(
    {required String unitId,
    required String userId,
    required String role,
    required String name,
    required String mobile,
    required String email,
    required String password,
    required String fcmDeviceToken}) async {
  developer.log(StackTrace.current.toString().split('\n')[0]);

  final Map<String, dynamic> param = {
    'unitId': unitId,
    'userId': userId,
    'role': role,
    'name': name,
    'phone': mobile,
    'email': email,
    'password': password,
    'fcmDeviceToken': fcmDeviceToken,
  };

  final response = await http
      .post(
        Uri.parse('${Globals.hostApiUri}/api/nl/createNewTenant'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          // HttpHeaders.authorizationHeader: 'Bearer ' + Globals.accessToken!,
        },
        body: convert.jsonEncode(param),
      )
      .timeout(Duration(seconds: TIMEOUT));

  return _returnResponse(response);
}

Future<ApiResponse> setTenantPassword({
  required String tenantId,
  required String password,
}) async {
  developer.log(StackTrace.current.toString().split('\n')[0]);

  final Map<String, dynamic> param = {
    'tenantId': tenantId,
    'password': password,
  };

  final response = await http
      .post(
        Uri.parse('${Globals.hostApiUri}/api/tl/setPassword'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          HttpHeaders.authorizationHeader: 'Bearer ' + Globals.accessToken!,
        },
        body: convert.jsonEncode(param),
      )
      .timeout(Duration(seconds: TIMEOUT));

  return _returnResponse(response);
}

Future<ApiResponse> tenantLogin({
  // required String clientCode,
  required String userId,
  required String mobileOrEmail,
  required String password,
  String? fcmDeviceToken,
}) async {
  developer.log(StackTrace.current.toString().split('\n')[0]);

  final Map<String, dynamic> param = {
    'userId': userId,
    'mobileOrEmail': mobileOrEmail,
    'password': password,
    'fcmDeviceToken': fcmDeviceToken,
  };
  // final String ccEnc = Utils.encryptStringAES256CTR(clientCode);

  final response = await http
      .post(
        Uri.parse('${Globals.hostApiUri}/api/nl/tenant/auth'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: convert.jsonEncode(param),
      )
      .timeout(Duration(seconds: TIMEOUT));

  return _returnResponse(response);
}

Future<ApiResponse> tenantLogout({
  required String tenantId,
}) async {
  developer.log(StackTrace.current.toString().split('\n')[0]);

  final Map<String, dynamic> param = {
    'tenantId': tenantId,
  };
  // final String ccEnc = Utils.encryptStringAES256CTR(clientCode);

  final response = await http
      .post(
        Uri.parse('${Globals.hostApiUri}/api/tl/signout'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          HttpHeaders.authorizationHeader: 'Bearer ' + Globals.accessToken!,
        },
        body: convert.jsonEncode(param),
      )
      .timeout(Duration(seconds: TIMEOUT));

  return _returnResponse(response);
}

Future<ApiResponse> getAllUnits({
  required String clientCode,
  required bool isWithAuthorizer,
  required bool isWithMgrFee,
}) async {
  developer.log(StackTrace.current.toString().split('\n')[0]);

  final Map<String, dynamic> param = {
    'isWithAuthorizer': isWithAuthorizer,
    'isWithMgrFee': isWithMgrFee,
  };
  // final String ccEnc = Utils.encryptStringAES256CTR(clientCode);

  final response = await http
      .post(
        Uri.parse('${Globals.hostApiUri}/api/tenant/getAllUnits'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          HttpHeaders.authorizationHeader: 'Bearer ' + Globals.accessToken!,
        },
        body: convert.jsonEncode(param),
      )
      .timeout(Duration(seconds: TIMEOUT));

  return _returnResponse(response);
}

Future<ApiResponse> getLoops({
  required String tenantId,
  required List<String> excludeIDs,
}) async {
  developer.log(StackTrace.current.toString().split('\n')[0]);
  assert(Globals.curTenantJson != null);

  final Map<String, dynamic> param = {
    'excludeIDs': excludeIDs,
  };

  final response = await http
      .post(
        Uri.parse('${Globals.hostApiUri}/api/tl/getHomepageLoops'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          HttpHeaders.authorizationHeader: 'Bearer ' + Globals.accessToken!,
        },
        body: convert.jsonEncode(param),
      )
      .timeout(Duration(seconds: TIMEOUT));

  return _returnResponse(response);
}

Future<ApiResponse> getNotices({
  required String unitType,
  required List<int> excludeIDs,
}) async {
  developer.log(StackTrace.current.toString().split('\n')[0]);

  // Directus query filter
  // Doc: https://docs.directus.io/reference/api/query/#filter
  Map<String, dynamic> filter = {};
  if (unitType == 'res') {
    filter['for_residence'] = true;
  } else if (unitType == 'car') {
    filter['for_carpark'] = true;
  } else if (unitType == 'shp') {
    filter['for_shop'] = true;
  } else {
    throw 'Unhandled unitType: $unitType';
  }

  // If there're existing IDs to exclude, use 'not in': _nin
  if (excludeIDs.length > 0) {
    filter['id'] = {'_nin': excludeIDs};
  }

  const sort = 'date_created';
  const fields = 'id,title,issue_date,pdf';

  final response = await http.get(
    Uri.parse(
        '${Globals.hostApiUri}/items/notices?filter=${convert.jsonEncode(filter)}&sort=$sort&fields=$fields'),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      HttpHeaders.authorizationHeader: 'Bearer ' + Globals.accessToken!,
    },
    // body: convert.jsonEncode({'s': s}),
  ).timeout(Duration(seconds: TIMEOUT));

  return _returnResponse(response);
}

Future<ApiResponse> getMarketplaces({
  // required String clientCode,
  required String unitType,
  required List<int> excludeIDs,
}) async {
  developer.log(StackTrace.current.toString().split('\n')[0]);

  // Directus query filter
  // Doc: https://docs.directus.io/reference/api/query/#filter
  Map<String, dynamic> filter = {};
  if (unitType == 'res') {
    filter['for_residence'] = true;
  } else if (unitType == 'car') {
    filter['for_carpark'] = true;
  } else if (unitType == 'shp') {
    filter['for_shop'] = true;
  } else {
    throw 'Unhandled unitType: $unitType';
  }

  // If there're existing IDs to exclude, use 'not in': _nin
  if (excludeIDs.length > 0) {
    filter['id'] = {'_nin': excludeIDs};
  }

  const sort = 'date_created';
  const fields = 'id,title,post_date,ad_image,commerce_url';

  final response = await http.get(
    Uri.parse(
        '${Globals.hostApiUri}/items/marketplaces?filter=${convert.jsonEncode(filter)}&sort=$sort&fields=$fields'),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      HttpHeaders.authorizationHeader: 'Bearer ' + Globals.accessToken!,
    },
    // body: convert.jsonEncode({'s': s}),
  ).timeout(Duration(seconds: TIMEOUT));

  return _returnResponse(response);
}

Future<ApiResponse> getAmenity({
  required String id,
}) async {
  developer.log(StackTrace.current.toString().split('\n')[0]);

  final response = await http.get(
    Uri.parse('${Globals.hostApiUri}/api/tl/getAmenity/$id'),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      HttpHeaders.authorizationHeader: 'Bearer ' + Globals.accessToken!,
    },
    // body: convert.jsonEncode({'s': s}),
  ).timeout(Duration(seconds: TIMEOUT));

  return _returnResponse(response);
}

Future<ApiResponse> getEstate({
  // required String clientCode,
  required String id,
}) async {
  developer.log(StackTrace.current.toString().split('\n')[0]);

  // Calling Directus API ItemServices
  final response = await http.get(
    Uri.parse('${Globals.hostApiUri}/api/tl/getEstate/${id}'),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      HttpHeaders.authorizationHeader: 'Bearer ' + Globals.accessToken!,
    },
    // body: convert.jsonEncode({'s': s}),
  ).timeout(Duration(seconds: TIMEOUT));

  return _returnResponse(response);
}

Future<ApiResponse> getNotice({
  required String id,
}) async {
  developer.log(StackTrace.current.toString().split('\n')[0]);

  final response = await http.get(
    Uri.parse('${Globals.hostApiUri}/api/tl/getNotice/$id'),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      HttpHeaders.authorizationHeader: 'Bearer ' + Globals.accessToken!,
    },
    // body: convert.jsonEncode({'s': s}),
  ).timeout(Duration(seconds: TIMEOUT));

  return _returnResponse(response);
}

Future<ApiResponse> getOneMarketplace({
  // required String clientCode,
  required String id,
}) async {
  developer.log(StackTrace.current.toString().split('\n')[0]);

  final response = await http.get(
    Uri.parse('${Globals.hostApiUri}/api/tl/getMarketplace/$id'),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      HttpHeaders.authorizationHeader: 'Bearer ' + Globals.accessToken!,
    },
    // body: convert.jsonEncode({'s': s}),
  ).timeout(Duration(seconds: TIMEOUT));

  return _returnResponse(response);
}

Future<ApiResponse> getBookableAmenities() async {
  developer.log(StackTrace.current.toString().split('\n')[0]);

  final response = await http.get(
    Uri.parse('${Globals.hostApiUri}/api/tl/getBookableAmenities'),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      HttpHeaders.authorizationHeader: 'Bearer ' + Globals.accessToken!,
    },
    // body: convert.jsonEncode({'s': s}),
  ).timeout(Duration(seconds: TIMEOUT));

  return _returnResponse(response);
}

Future<ApiResponse> getAmenityBookingSections({
  // required String clientCode,
  required String amenityId,
}) async {
  developer.log(StackTrace.current.toString().split('\n')[0]);

  Map<String, dynamic> filter = {
    'amenities_id': {
      '_eq': amenityId,
    },
  };
  const fields =
      '*,booking_sections_id.*,booking_sections.booking_sections_id.name,booking_sections.booking_sections_id.time_begin,booking_sections.booking_sections_id.time_end';

  final response = await http.get(
    Uri.parse(
        '${Globals.hostApiUri}/items/amenities_booking_sections?filter=${convert.jsonEncode(filter)}&fields=$fields'),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      HttpHeaders.authorizationHeader: 'Bearer ' + Globals.accessToken!,
    },
    // body: convert.jsonEncode({'s': s}),
  ).timeout(Duration(seconds: TIMEOUT));

  return _returnResponse(response);
}

// To get daily bookings, it returns list of booking for specific amenity
Future<ApiResponse> getTenantBookingsByDate({
  // required String clientCode,
  required String date,
  required String amenityId,
  List<String>? times,
}) async {
  developer.log(StackTrace.current.toString().split('\n')[0]);

  Map<String, dynamic> params = {
    'date': date,
    'amenity': amenityId,
    'times': times,
  };

  final response = await http
      .post(
        Uri.parse('${Globals.hostApiUri}/api/tl/getAmenityBookingsByDate'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          HttpHeaders.authorizationHeader: 'Bearer ' + Globals.accessToken!,
        },
        body: convert.jsonEncode(params),
      )
      .timeout(Duration(seconds: TIMEOUT));

  return _returnResponse(response);
}

Future<ApiResponse> saveAmenityBooking({
  required Models.Amenity amenity,
  required Models.TenantAmenityBooking booking,
  required List<Models.TenantAmenityBookingSlot> slots,
  required String status,
  required String currency,
  DateTime? autoCancelTime,
  required String loopTitle,
}) async {
  developer.log(StackTrace.current.toString().split('\n')[0]);
  assert(slots.length > 0);

  String? payBefore;
  if (autoCancelTime != null) {
    payBefore = autoCancelTime.toIso8601String();
  } else if (amenity.fee != 0) {
    DateTime dt = DateTime.parse(booking.date + ' ' + slots[0].timeStart);
    payBefore = dt.toIso8601String();
  }

  String senderName = convert.jsonEncode({'en': 'TenantApp'});

  // Map Models.TenantAmenityBooking to Directus M2M create JSON
  Map<String, dynamic> param = {
    'tenantId': booking.tenantId,
    'amenityId': booking.amenityId,
    'amenityName': amenity.name,
    'amenityPhoto': amenity.photo,
    'bookingTimeBasic': booking.bookingTimeBasic,
    'senderName': senderName,
    'date': booking.date,
    'fee': amenity.fee,
    'status': status,
    'title': loopTitle,
    'totalFee': booking.totalFee,
    'currency': currency,
    'isPaid': booking.isPaid,
    'slots': [],
    'autoCancelTime': autoCancelTime?.toIso8601String(),
    'localTime': DateFormat('yyyy-MM-dd').format(DateTime.now()),
    'payBefore': payBefore,
  };
  slots.forEach((slot) {
    param['slots'].add({
      // 'booking_time_basic': slot.bookingTimeBasic,
      'name': slot.name,
      'from': slot.timeStart,
      'to': slot.timeEnd,
      // 'section': slot.section,
      // 'fee': slot.fee,
    });
  });

  final response = await http
      .post(
        Uri.parse('${Globals.hostApiUri}/api/tl/saveAmenityBooking'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          HttpHeaders.authorizationHeader: 'Bearer ' + Globals.accessToken!,
        },
        body: convert.jsonEncode(param),
      )
      .timeout(Duration(seconds: TIMEOUT));

  return _returnResponse(response);
} // saveAmenityBooking()

Future<ApiResponse> deleteTenantBooking({
  // required String clientCode,
  required List<String> tenantAmenityBookingIds,
}) async {
  developer.log(StackTrace.current.toString().split('\n')[0]);

  final response = await http
      .delete(
        Uri.parse('${Globals.hostApiUri}/items/tenant_amenity_bookings'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          HttpHeaders.authorizationHeader: 'Bearer ' + Globals.accessToken!,
        },
        body: convert.jsonEncode(
            tenantAmenityBookingIds), // the encrypted param put to 's'
      )
      .timeout(Duration(seconds: TIMEOUT));

  return _returnResponse(response);
}

Future<ApiResponse> fetchPaymentSheetData({
  required String clientCode,
  required int tenantAmenityBookingId,
}) async {
  developer.log(StackTrace.current.toString().split('\n')[0]);

  // Parameters for backend
  final Map<String, dynamic> param = {
    'bkgId': tenantAmenityBookingId,
  };
  // final String ccEnc = Utils.encryptStringAES256CTR(clientCode);
  // Encrypt the parameter body since it is directus specific

  final response = await http
      .post(
        Uri.parse('${Globals.hostApiUri}/api/tenant/fetchPaymentSheetData'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          HttpHeaders.authorizationHeader: 'Bearer ' + Globals.accessToken!,
        },
        body: convert.jsonEncode(param),
      )
      .timeout(Duration(seconds: TIMEOUT));

  return _returnResponse(response);
}
