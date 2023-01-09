/**
 * This module handles the loop translation. Loop is similar to feed which
 * produced by backend according to the activities. The activities are:
 * - _newAmenityBkg
 * - _amenityBkgConfirmed
 * - _amenityBkgCancelled
 * - _mgrmReceipt
 * - _mgrmtNotice
 * - _newAdWithImg
 * - _reqAccess
 * 
 * The translation is to generate a body with meaningful information in JSON.
 * Where the JSON has title & body properties for caller to display.
 * See byTitleId() for the logic
 */

library loopTranslate;

import 'dart:developer' as developer;
import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';

import 'include.dart';
import 'constants.dart' as Constants;
import 'utils.dart' as Utils;

Map<String, String> _newAmenityBkg({
  required BuildContext context,
  required Map<String, dynamic> params,
  required String type,
}) {
  developer.log(StackTrace.current.toString().split('\n')[0]);

  Map<String, String> rtnVal = {};
  String amenityName = Utils.getDbStringByCurLocale(params['amenityName']);
  int fee = params['fee'];
  String date = Utils.formatDate(params['date']);
  // String bookingId = params['bookingId'].toString();
  int bookingNo = params['bookingNo'];
  String status = (params['status'] == 'pending')
      ? 'pending'.tr()
      : (params['status'] == 'confirmed')
          ? 'confirmed'.tr()
          : (params['status'] == 'cancelled')
              ? 'cancelled'.tr()
              : params['status'];
  List<dynamic> slots = jsonDecode(params['slots']);
  List<String> timeSlots = []; // Store the string of time range
  for (int i = 0; i < slots.length; i++) {
    var slot = slots[i];
    String timeBegin = Utils.formatTime(slot['timeBegin']);
    String timeEnd = Utils.formatTime(slot['timeEnd']);
    timeSlots.add(timeBegin + ' - ' + timeEnd);
  }

  String timeSlotsUl = '<ul>'; // Store the string of time range in <ul>
  for (int i = 0; i < timeSlots.length; ++i) {
    timeSlotsUl += '<li>${timeSlots[i]}</li>';
  }
  timeSlotsUl += '</ul>';

  late String title;
  late String points;
  late String finalLine;
  if (params['fee'] == 0) {
    title =
        '${'bookingConfirm'.tr()} "$amenityName" ${'at'.tr()} $date. ${'bookingNo'.tr()}: $bookingNo';
    finalLine = 'plsComeToAmenityOntime'.tr();
    points = '''
    <ul>
      <li>${'bookingNo'.tr()}: $bookingNo</li>
      <li>${'status'.tr()}: $status</li>
      <li>${'date'.tr()}: $date</li>
      <li>${'fee'.tr()}: \$$fee</li>
    </ul>
      ''';
  } else {
    title =
        '${'actionRequired'.tr()} ${'tentativeBooking'.tr()} "$amenityName" ${'at'.tr()} $date. ${'bookingNo'.tr()}: $bookingNo${'fullstop'.tr()}';
    finalLine = 'pleasePayAmenityFee'.tr();
    // finalLine = 'thankYouUsingAmenity'.tr();
    // String remindToPay = 'remindToPayBookingFee'.tr();
    // remindToPay = remindToPay.replaceAll('{fee}', fee.toString());

    String payBefore = '-';
    if (params['payBefore'] != null) {
      payBefore = Utils.formatDatetime(params['payBefore']);
    }

    points = '''
    <ul>
      <li>${'bookingNo'.tr()}: $bookingNo</li>
      <li>${'status'.tr()}: $status</li>
      <li>${'date'.tr()}: $date</li>
      <li>${'fee'.tr()}: \$$fee</li>
      <li>${'payBefore'.tr()}: $payBefore</li>
    </ul>
''';
  }

  rtnVal['title'] = title;
  rtnVal['body'] = '''
    <p>${'youHaveBooked'.tr()} <b>$amenityName</b>. ${'bookingDetails'.tr()}:</p>
    $points
    <p>${'amenityBkgTimeslot'.tr()}:</p>
    $timeSlotsUl
    <p>$finalLine</p>
''';

/*
  if (params['fee'] == 0) {
    rtnVal['title'] =
        '${'bookingConfirm'.tr()} "$amenityName" ${'at'.tr()} $date. ${'bookingNo'.tr()}: $bookingNo';
    rtnVal['body'] = '''
          <p>${'youHaveBooked'.tr()} <b>$amenityName</b>. ${'detailsAsBelow'.tr()}:</p>
          <ul>
            <li>${'bookingNo'.tr()}: $bookingNo</li>
            <li>${'status'.tr()}: $status</li>
            <li>${'date'.tr()}: $date</li>
            <li>${'fee'.tr()}: \$$fee</li>
          </ul>
          <p>${'amenityBkgTimeslot'.tr()}:</p>
          $timeSlotsUl
          <p>${'plsComeToAmenityOntime'.tr()}</p>
           ''';
  } else {
    rtnVal['title'] =
        '${'actionRequired'.tr()} ${'tentativeBooking'.tr()} "$amenityName" ${'at'.tr()} $date. ${'bookingNo'.tr()}: $bookingNo${'fullstop'.tr()}${'pleasePayAmenityFee'.tr()}';
    String remindToPay = 'remindToPayBookingFee'.tr();
    remindToPay = remindToPay.replaceAll('{fee}', fee.toString());

    String payBefore = '-';
    if (params['payBefore'] != null) {
      payBefore = Utils.formatDatetime(params['payBefore']);
    }
    rtnVal['body'] = '''
          <h3>${'youHaveBooked'.tr()} <b>$amenityName</b>. ${'detailsAsBelow'.tr()}:</h3>
          <ul>
            <li>${'bookingNo'.tr()}: $bookingNo</li>
            <li>${'status'.tr()}: $status</li>
            <li>${'date'.tr()}: $date</li>
            <li>${'fee'.tr()}: \$$fee</li>
            <li>${'payBefore'.tr()}: $payBefore</li>
          </ul>
          <p>${'amenityBkgTimeslot'.tr()}</p>
          $timeSlotsUl
          <p>${'thankYouUsingAmenity'.tr()}</p>
          ''';
  }
*/

  return rtnVal;
}

Map<String, String> _amenityBkgConfirmed({
  required BuildContext context,
  required Map<String, dynamic> params,
  required String type,
}) {
  developer.log(StackTrace.current.toString().split('\n')[0]);

  Map<String, String> rtnVal = {};
  String amenityName = params['amenityName'];
  int fee = params['totalFee'];
  String date = params['date'];
  String bookingId = params['bookingId'].toString();
  String status = (params['status'] == 'pending')
      ? 'pending'.tr()
      : (params['status'] == 'confirmed')
          ? 'confirmed'.tr()
          : (params['status'] == 'cancelled')
              ? 'cancelled'.tr()
              : params['status'];
  List<String> timeSlots = []; // Store the string of time range
  for (int i = 0; i < params['slots'].length; ++i) {
    Map<String, dynamic> slot = params['slots'][i];
    String timeBegin = Utils.formatTime(slot['timeBegin']);
    String timeEnd = Utils.formatTime(slot['timeEnd']);
    timeSlots.add(timeBegin + ' - ' + timeEnd);
  }

  String timeSlotsUl = '<ul>'; // Store the string of time range in <ul>
  for (int i = 0; i < timeSlots.length; ++i) {
    timeSlotsUl += '<li>${timeSlots[i]}</li>';
  }
  timeSlotsUl += '</ul>';

  String? isPaidStr;
  if (params['isPaid'] != null) {
    isPaidStr =
        params['isPaid'] ? 'paymentConfirmed'.tr() : 'paymentNotConfirmed'.tr();
  }

  rtnVal['title'] =
      '${'bookingConfirm'.tr()} "$amenityName" ${'at'.tr()} $date${'fullstop'.tr()}${'bookingNo'.tr()}: $bookingId';
  rtnVal['body'] = '''
      <h3>${'youHaveBooked'.tr()} <b>${params["amenityName"]}</b>. ${'detailsAsBelow'.tr()}:</h3>
      <ul>
        <li>${'bookingNo'.tr()}: $bookingId</li>
        <li>${'status'.tr()}: $status</li>
        <li>${'date'.tr()}: $date</li>
        <li>${'fee'.tr()}: \$$fee</li>
        ${isPaidStr != null ? "<li>$isPaidStr</li>" : ''}
      </ul>
      <p>${'amenityBkgTimeslot'.tr()}:</p>
      $timeSlotsUl
      <p>${'plsComeToAmenityOntime'.tr()}</p>
           ''';
  return rtnVal;
}

Map<String, String> _amenityBkgCancelled({
  required BuildContext context,
  required Map<String, dynamic> params,
  required String type,
}) {
  developer.log(StackTrace.current.toString().split('\n')[0]);

  Map<String, String> rtnVal = {};
  String amenityName = params['amenityName'];
  int fee = params['totalFee'];
  String date = params['date'];
  String bookingId = params['bookingId'].toString();
  String status = (params['status'] == 'pending')
      ? 'pending'.tr()
      : (params['status'] == 'confirmed')
          ? 'confirmed'.tr()
          : (params['status'] == 'cancelled')
              ? 'cancelled'.tr()
              : params['status'];
  List<String> timeSlots = []; // Store the string of time range
  for (int i = 0; i < params['slots'].length; ++i) {
    Map<String, dynamic> slot = params['slots'][i];
    String timeBegin = Utils.formatTime(slot['timeBegin']);
    String timeEnd = Utils.formatTime(slot['timeEnd']);
    timeSlots.add(timeBegin + ' - ' + timeEnd);
  }

  String timeSlotsUl = '<ul>'; // Store the string of time range in <ul>
  for (int i = 0; i < timeSlots.length; ++i) {
    timeSlotsUl += '<li>${timeSlots[i]}</li>';
  }
  timeSlotsUl += '</ul>';

  String? payBefore = null;
  if (params['payBefore'] != null) {
    payBefore = Utils.formatDatetime(params['payBefore']);
  }

  rtnVal['title'] =
      '${'bookingCancel'.tr()} "$amenityName" ${'at'.tr()}$date${'fullstop'.tr()}${'bookingNo'.tr()}: $bookingId';
  rtnVal['body'] = '''
      <h3>${'youHaveBooked'.tr()} <b>${params["amenityName"]}</b>. ${'detailsAsBelow'.tr()}:</h3>
      <ul>
        <li>${'bookingNo'.tr()}: $bookingId</li>
        <li>${'status'.tr()}: $status</li>
        <li>${'date'.tr()}: $date</li>
        <li>${'fee'.tr()}: \$$fee</li>
        ${payBefore == null ? '' : '<li>${'payBefore'.tr()}: $payBefore</li>'}
      </ul>
      <p>${'amenityBkgTimeslot'.tr()}:</p>
      $timeSlotsUl
      <p>${'bookingAutoCancelled'.tr()}</p>
           ''';

  return rtnVal;
}

Map<String, String> _mgrmReceipt({
  required BuildContext context,
  required Map<String, dynamic> params,
  required String type,
}) {
  developer.log(StackTrace.current.toString().split('\n')[0]);

  Map<String, String> rtnVal = {};

  var unitJson = params['unit'];
  unitJson['cls'] = params['unitType'];
  String month = params['month'];
  String unitName = Utils.buildUnitNameWithLangByJson(context, params['unit']);
  String paidDate = params['paidRec']['paidRec']['paid']['paidDate'];
  String paidDate2 = Utils.formatDate(paidDate);

  rtnVal['title'] =
      '${'mgroffReceipt'.tr()}: ${params['month']} ${'mgrfeeReceipt'.tr()}';
  rtnVal['body'] = '''
    <h3>${'mgrfeeReceipt'.tr()}</h3>
    <p>${'title'.tr()}: ${'officialReceipt'.tr()}</p>
    <p>${'theMonth'.tr()}: $month</p>
    <p>${'paidDate'.tr()}: $paidDate2</p>
    <p>${'unit'.tr()}: $unitName</p>
    ''';

  return rtnVal;
}

Map<String, String> _mgrmtNotice({
  required BuildContext context,
  required Map<String, dynamic> params,
  required String type,
}) {
  developer.log(StackTrace.current.toString().split('\n')[0]);

  Map<String, String> rtnVal = {};
  String noticeTitle = Utils.getDbStringByCurLocale(params["title"]);
  String issueDate = Utils.formatDate(params["issueDate"]);

  List<String> audiences = List<String>.from(jsonDecode(params['audiences']));
  rtnVal['title'] =
      '${'navbarNotice'.tr()}: $noticeTitle ${'at'.tr()} $issueDate';
  rtnVal['body'] = '''
    <h3>${'navbarNotice'.tr()}</h3>
    <p>${'title'.tr()}: $noticeTitle</p>
    <p>${'date'.tr()}: $issueDate</p>
    <p>${'audience'.tr()}: ${audiences.join(", ")}</p>
  ''';

  return rtnVal;
}

Map<String, String> _newAdWithImg({
  required BuildContext context,
  required Map<String, dynamic> params,
  required String type,
}) {
  developer.log(StackTrace.current.toString().split('\n')[0]);

  Map<String, String> rtnVal = {};
  String title = Utils.getDbStringByCurLocale(params["title"]);
  String postDate = Utils.formatDate(params["postDate"]);

  rtnVal['title'] = 'Ad: $title';
  rtnVal['body'] = '''
    <h3>${'marketplace'.tr()}</h3>
    <p>$title</p>
    <p>$postDate</p>
    ''';

  return rtnVal;
}

Map<String, String> _reqAccess({
  required BuildContext context,
  required Map<String, dynamic> params,
  required String type,
}) {
  developer.log(StackTrace.current.toString().split('\n')[0]);

  Map<String, String> rtnVal = {};
  rtnVal['title'] = 'accessApprovedAndThanks'.tr();
  rtnVal['body'] = '';

  return rtnVal;
}

// This is to translate the Loop record by title_id, to
// human readable title (text) & body (html)
Map<String, dynamic> byTitleId({
  required BuildContext context,
  required String titleId,
  required String type,
  required Map<String, dynamic> params,
}) {
  developer.log(StackTrace.current.toString().split('\n')[0]);
  developer.log('Processing Loop translate: $titleId');

  Map<String, String> rtnVal;

  if (titleId == Constants.LOOP_TITLE_NEW_AMENITY_BOOKING) {
    rtnVal = _newAmenityBkg(context: context, params: params, type: type);
  } else if (titleId == Constants.LOOP_TITLE_AMENITY_BOOKING_CONFIRMED) {
    rtnVal = _amenityBkgConfirmed(context: context, params: params, type: type);
  } else if (titleId == Constants.LOOP_TITLE_AMENITY_BOOKING_CANCELLED) {
    rtnVal = _amenityBkgCancelled(context: context, params: params, type: type);
  } else if (titleId == Constants.LOOP_TITLE_MANAGEMENT_NOTICE) {
    rtnVal = _mgrmtNotice(context: context, params: params, type: type);
  } else if (titleId == Constants.LOOP_TITLE_NEW_AD_WITH_IMAGE) {
    rtnVal = _newAdWithImg(context: context, params: params, type: type);
  } else if (titleId == Constants.LOOP_TITLE_TENANT_REQUEST_ACCESS) {
    rtnVal = _reqAccess(context: context, params: params, type: type);
  } else if (titleId == Constants.LOOP_TITLE_MANAGEMENT_RECEIPT) {
    rtnVal = _mgrmReceipt(context: context, params: params, type: type);
  } else {
    throw 'Unhandled titleId: $titleId';
  }

  return rtnVal;
}
