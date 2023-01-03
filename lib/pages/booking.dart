import 'dart:developer' as developer;
// import 'dart:io';
import 'dart:convert' as convert;
// import 'dart:html';
import 'package:easy_localization/easy_localization.dart';
// import 'package:dio/dio.dart';
import 'package:flutter_html/flutter_html.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:open_file/open_file.dart';
// import 'package:sqflite/sqflite.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:whatsapp_unilink/whatsapp_unilink.dart';
// import 'package:flutter_stripe/flutter_stripe.dart' as Stripe;

// import '../components/navBar.dart';
// import '../components/dialogBuilder.dart';

import '../components/rawBackground.dart';

import '../include.dart';
import '../constants.dart' as Constants;
import '../models.dart' as Models;
import '../ajax.dart' as Ajax;
import '../utils.dart' as Utils;
import '../globals.dart' as Globals;

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
  late Models.Client _client;

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
    assert(Globals.curUserJson != null);

    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    assert(_loop.paramsJson != null);
    var loopParams = convert.jsonDecode(_loop.paramsJson!);
    Ajax.ApiResponse resp = await Ajax.getOneAmenity(
        // clientCode: Globals.curClientJson?['code'],
        id: loopParams['amenityId']);
    Map<String, dynamic> data = resp.data;
    String photo = data['photo'] == null
        ? Globals.defaultAmenityCanvas
        : Globals.hostS3Base! + '/${data['photo']}.jpg';

    _amenity = Models.Amenity(
      id: data['id'],
      dateCreated: data['date_created'],
      name: data['name'],
      details: data['details'],
      photo: photo,
      monday: data['monday'],
      tuesday: data['tuesday'],
      wednesday: data['wednesday'],
      thursday: data['thursday'],
      friday: data['friday'],
      saturday: data['saturday'],
      sunday: data['sunday'],
      status: data['status'],
      fee: data['fee'],
      timeOpen: data['time_open'] != null
          ? DateTime.parse(today + ' ' + data['time_open'])
          : null,
      timeClose: data['time_close'] != null
          ? DateTime.parse(today + ' ' + data['time_close'])
          : null,
      timeMinimum: data['time_minimum'],
      timeMaximum: data['time_maximum'],
      timeIncrement: data['time_increment'],
      bookingTimeBasic: data['booking_time_basic'],
      isRepetitiveBooking: data['is_repetitive_booking'],
      bookingAdvanceDays: data['booking_advance_days'] ?? 0,
      autoCancelHours: data['auto_cancel_hours'],
      contactWhatsapp: data['contact_whatsapp'],
    );

    resp = await Ajax.getClient(
      // clientCode: Globals.curClientJson?['code'],
      id: Globals.curClientJson?['id'],
      fields: 'stripe_publishable_key,stripe_secret_key,payment_currency',
    );
    data = resp.data[0];
    _client = Models.Client(
      stripePublishableKey: data['stripe_publishable_key'],
      stripeSecretKey: data['stripe_secret_key'],
      stripeCurrency: data['payment_currency'],
    );

    return {}; // Assign to _datum
  }

  Future<void> _onBtnContactUs() async {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    String wano = this._amenity.contactWhatsapp!;
    if (!wano.startsWith('+')) {
      wano = '+852-' + wano;
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

/*
  Future<void> _onBtnPayWithCard() async {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    // Ref: https://github.com/flutter-stripe/flutter_stripe/blob/main/example/lib/screens/payment_sheet/payment_sheet_screen.dart

    try {
      var loopParams = convert.jsonDecode(_loop.paramsJson!);

      final Ajax.ApiResponse resp = await Ajax.fetchPaymentSheetData(
        clientCode: Globals.curClientJson?['code'],
        tenantAmenityBookingId: loopParams['bookingId'],
      );
      final paymentSheetData = resp.data;
      Stripe.Stripe.publishableKey = paymentSheetData['publishableKey'];
      // paymentSheetData['publishableKey'];
      await Stripe.Stripe.instance.initPaymentSheet(
        paymentSheetParameters: Stripe.SetupPaymentSheetParameters(
          applePay: true,
          googlePay: true,
          style: ThemeMode.dark,
          testEnv: true,
          merchantCountryCode: 'HK',
          merchantDisplayName: paymentSheetData['estateName'],
          customerId: paymentSheetData['customerId'],
          paymentIntentClientSecret:
              paymentSheetData['paymentIntentClientSecret'],
          customerEphemeralKeySecret:
              paymentSheetData['customerEphemeralKeySecret'],
        ),
      );
      await Stripe.Stripe.instance.presentPaymentSheet();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment succesfully completed'),
        ),
      );
    } on Exception catch (e) {
      if (e is Stripe.StripeException) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error from Stripe: ${e.error.localizedMessage}'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unforeseen error: ${e}'),
          ),
        );
      }
    }
  }
*/

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
          title = 'actionRequired'.tr() + 'tentativeBooking'.tr();
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
    String subTitle = DateFormat('yyyy-MM-dd').format(this._loop.dateCreated);

    // Translate the parameters
    Map<String, dynamic> params = convert.jsonDecode(this._loop.paramsJson!);
    Map<String, dynamic> translated = Utils.translateLoopTitleId(
        context: context,
        titleId: params['title_id'],
        type: this._loop.type,
        params: params);
    String body = translated['body'];

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

/*
      if (this._loop.titleId == Constants.LOOP_TITLE_NEW_AMENITY_BOOKING &&
          _amenity.fee != 0 &&
          _client.stripeCurrency != null) {
        contents.add(
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              primary: Globals.primaryColor,
            ),
            onPressed: _onBtnPayWithCard,
            child: Text(
              'bookingPayByCard'.tr(),
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
        contents.add(SizedBox(height: 20));
      }
*/
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

// class PaymentService {
//   final int amount;
//   final String url;

//   PaymentService(this.amount, this.url);

//   static init() {
//     StripePayment.setOptions(
//       StripeOptions(
//         publishableKey: Globals.stripePublishableKey,
//         merchantId: Globals.stripeMerchantId,
//         androidPayMode: 'test',
//       ),
//       )
//     )
//   }
// }
