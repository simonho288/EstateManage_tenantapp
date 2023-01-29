import 'dart:developer' as developer;
// import 'dart:io';
import 'dart:convert' as convert;
// import 'dart:html';
// import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:whatsapp_unilink/whatsapp_unilink.dart';

import '../components/rawBackground.dart';

import '../include.dart';
import '../constants.dart' as Constants;
import '../models.dart' as Models;
import '../ajax.dart' as Ajax;
import '../utils.dart' as Utils;
import '../globals.dart' as Globals;
import '../loopTranslate.dart' as LoopTranslate;

class BookingPage extends StatefulWidget {
  late Models.Loop _loop;
  BookingPage({Key? key, args}) : super(key: key) {
    _loop = args!['rec'];
  }

  @override
  _BookingPageState createState() => _BookingPageState(_loop);
}

class _BookingPageState extends State<BookingPage> {
  late Models.Loop _loop; // The Loop record
  late Future<Map<String, dynamic>> _futureData;
  late Models.Amenity _amenity;
  late Models.Estate _estate;

  _BookingPageState(Models.Loop loop) {
    _loop = loop;
  }

  @override
  void initState() {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    _futureData = _loadInitialData();
    super.initState();
  }

  Future<Map<String, dynamic>> _loadInitialData() async {
    developer.log(StackTrace.current.toString().split('\n')[0]);
    assert(Globals.curTenantJson != null);

    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    assert(_loop.paramsJson != null);
    var loopParams = convert.jsonDecode(_loop.paramsJson!);
    Ajax.ApiResponse resp = await Ajax.getAmenityById(
        // clientCode: Globals.curClientJson?['code'],
        id: loopParams['amenityId']);
    Map<String, dynamic> data = resp.data;
    String photo =
        data['photo'] == null ? Globals.defaultAmenityCanvas : data['photo'];

    Map<String, dynamic> availableDays =
        convert.jsonDecode(data['availableDays']);
    Map<String, dynamic> timeBased = convert.jsonDecode(data['timeBased']);
    List<Map<String, dynamic>> sectionBased = List<Map<String, dynamic>>.from(
        convert.jsonDecode(data['sectionBased']));
    Map<String, dynamic> contact = convert.jsonDecode(data['contact']);
    Map<String, dynamic> whatsapp = contact['whatsapp'];

    _amenity = Models.Amenity(
      id: data['id'],
      dateCreated: data['dateCreated'],
      name: Utils.getDbStringByCurLocale(data['name']),
      details: Utils.getDbStringByCurLocale(data['details']),
      photo: photo,
      monday: availableDays['mon'],
      tuesday: availableDays['tue'],
      wednesday: availableDays['wed'],
      thursday: availableDays['thu'],
      friday: availableDays['fri'],
      saturday: availableDays['sat'],
      sunday: availableDays['sun'],
      status: data['status'],
      fee: data['fee'] != null ? data['fee'].toDouble() : null,
      timeOpen: timeBased['timeOpen'] != null
          ? DateTime.parse(today + ' ' + timeBased['timeOpen'])
          : null,
      timeClose: timeBased['timeClose'] != null
          ? DateTime.parse(today + ' ' + timeBased['timeClose'])
          : null,
      timeMinimum: int.parse(timeBased['timeMinimum']),
      timeMaximum: int.parse(timeBased['timeMaximum']),
      timeIncrement: int.parse(timeBased['timeIncrement']),
      bookingTimeBasic: data['bookingTimeBasic'],
      isRepetitiveBooking: data['isRepetitiveBooking'] == 1,
      bookingAdvanceDays: data['bookingAdvanceDays'] ?? 0,
      autoCancelHours: data['autoCancelHours'],
      contactWhatsapp: whatsapp,
    );

    resp = await Ajax.getEstateById(
      // clientCode: Globals.curClientJson?['code'],
      id: Globals.curEstateJson?['id'],
      // fields: 'stripe_publishable_key,stripe_secret_key,payment_currency',
    );
    data = resp.data;
    contact = convert.jsonDecode(data['contact']);
    contact['name'] = Utils.getDbMapByCurLocale(contact['name']);
    Map<String, dynamic> tenantApp = convert.jsonDecode(data['tenantApp']);
    Map<String, dynamic> timezoneMeta =
        convert.jsonDecode(data['timezoneMeta']);
    Map<String, dynamic> onlinePayments =
        convert.jsonDecode(data['onlinePayments']);

    _estate = Models.Estate(
      dateCreated: data['dateCreated'],
      name: Utils.getDbStringByCurLocale(data['name']),
      address: Utils.getDbStringByCurLocale(data['address']),
      contact: contact['name'],
      tel: contact['tel'],
      email: contact['email'],
      website: data['website'],
      langEntries: data['langEntries'],
      tenantAppEstateImage: tenantApp['estateImageApp'],
      currency: data['currency'],
    );

    return {}; // Assign to _datum
  }

  Future<void> _onBtnContactUs() async {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    // TODO: Currently support whatsapp only
    String wano = '';
    if (this._amenity.contactWhatsapp != null) {
      wano = this._amenity.contactWhatsapp!['number'];
    }

    String msg = 'bookingWhatsappMessage'.tr();
    var loopParams = convert.jsonDecode(_loop.paramsJson!);
    msg = msg.replaceAll('{bookingNo}', loopParams['bookingId'].toString());
    final link = WhatsAppUnilink(
      phoneNumber: wano,
      text: msg,
    );
    // Convert the WhatsAppUnilink instance to a string.
    // Use either Dart's string interpolation or the toString() method.
    // The "launch" method is part of "url_launcher".
    await launch('$link');
  }

  Widget _renderBody() {
    // Main content of this page.
    developer.log(StackTrace.current.toString().split('\n')[0]);

    // DateTime now = DateTime.now();
    late String title;
    late IconData icon = Icons.bookmark_border;

    switch (this._loop.titleId) {
      case Constants.LOOP_TITLE_NEW_AMENITY_BOOKING:
        title = 'bookingLoopDate'.tr();
        if (_amenity.fee == 0) {
          title = 'bookingConfirm'.tr();
        } else {
          icon = Icons.notifications_none;
          title = 'actionRequired'.tr() + ' ' + 'tentativeBooking'.tr();
        }
        break;
      case Constants.LOOP_TITLE_AMENITY_BOOKING_CONFIRMED:
        title = 'bookingConfirm'.tr();
        break;
      case Constants.LOOP_TITLE_AMENITY_BOOKING_CANCELLED:
        title = 'bookingCancel'.tr();
        break;
      default:
        throw Exception('Unknown loop titleId: ${this._loop.titleId}');
    }

    // title = this.loop.type;
    // icon = Icons.arrow_drop_down_circle;

    // Translate the parameters
    Map<String, dynamic> params = convert.jsonDecode(this._loop.paramsJson!);
    Map<String, dynamic> translated = LoopTranslate.byTitleId(
        context: context,
        titleId: params['titleId'],
        type: this._loop.type,
        meta: params);
    String body = translated['body'];
    String subTitle = "created".tr() +
        ': ' +
        DateFormat('yyyy-MM-dd').format(this._loop.dateCreated);
    // String subTitle = translated['title'];

    List<Widget> contents = [];
    contents.add(
      ListTile(
        leading: Icon(icon),
        title: Text(title, style: TextStyle(fontSize: 20.0)),
        subtitle: Text(
          subTitle,
          style: TextStyle(color: Colors.black.withOpacity(0.6)),
        ),
      ),
    );
    contents.add(
      const Divider(height: 1, indent: 10, endIndent: 10, thickness: 2),
    );
    contents.add(
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Html(data: body, style: Constants.HTML_MKUP_OPTIONS),
      ),
    );
    // Not all situations show all contents
    if (this._loop.titleId == Constants.LOOP_TITLE_NEW_AMENITY_BOOKING ||
        this._loop.titleId == Constants.LOOP_TITLE_AMENITY_BOOKING_CONFIRMED) {
      contents.add(
        CachedNetworkImage(imageUrl: _amenity.photo, fit: BoxFit.fill),
      );
      contents.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
          child:
              Html(data: _amenity.details, style: Constants.HTML_MKUP_OPTIONS),
        ),
      );
      if (this._loop.titleId == Constants.LOOP_TITLE_NEW_AMENITY_BOOKING &&
          this._amenity.contactWhatsapp != null) {
        contents.add(
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              primary: Globals.primaryColor,
            ),
            onPressed: _onBtnContactUs,
            child: Text(
              'bookingWhatsappContact'.tr(),
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
        contents.add(SizedBox(height: 20));
      }
    }

    // Draw the card
    return RawBackground(
      title: 'bookingHeader'.tr(),
      child: SingleChildScrollView(
        // Card appearence: https://material.io/components/cards/flutter#card
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: contents,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // drawer: NavBar(),
      // appBar: AppBar(
      //   title: Text('bookingHeader'.tr()),
      //   centerTitle: true,
      // ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _futureData,
        builder: (ctx, snapshot) {
          if (snapshot.hasData) {
            return _renderBody();
          } else if (snapshot.hasError) {
            return Container(
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Error ${snapshot.error}',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
