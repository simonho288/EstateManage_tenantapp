import 'dart:developer' as developer;
// import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:open_file/open_file.dart';
// import 'package:url_launcher/url_launcher.dart';

// import '../objectbox.g.dart'; // created by `flutter pub run build_runner build`
// import 'package:intl/intl.dart';

// import '../components/navBar.dart';
import '../components/rawBackground.dart';
// import '../components/dialogBuilder.dart';

import '../include.dart';
import '../models.dart' as Models;
import '../ajax.dart' as Ajax;
import '../utils.dart' as Utils;
import '../globals.dart' as Globals;
import '../constants.dart' as Constants;

class AmenitiesPage extends StatefulWidget {
  const AmenitiesPage({Key? key}) : super(key: key);

  @override
  _AmenitiesPageState createState() => _AmenitiesPageState();
}

class _AmenitiesPageState extends State<AmenitiesPage> {
  late Future<Map<String, dynamic>> _futureData;
  late Map<String, dynamic> _datum;
  final GlobalKey<ScaffoldState> _key = GlobalKey();

  @override
  void initState() {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    _futureData = _loadInitialData();
    super.initState();
  }

  Future<Map<String, dynamic>> _loadInitialData() async {
    developer.log(StackTrace.current.toString().split('\n')[0]);
    assert(Globals.curUserJson != null);

    Map<String, dynamic> rtnVal = {}; // Return JSON (equivalent _datum)

    // Get any new records where are exclude existing records
    Ajax.ApiResponse resp = await Ajax.getBookableAmenities();
    List<Map<String, dynamic>> remoteData =
        new List<Map<String, dynamic>>.from(resp.data as List);
    List<Models.Amenity> amenities = [];
    for (int i = 0; i < remoteData.length; ++i) {
      var e = remoteData[i];
      String photo = e['photo'] == null
          ? Globals.defaultAmenityCanvas
          : '${Globals.hostApiUri}/assets/${e['photo']}?key=amenity-photo-img&access_token=${Globals.accessToken}';
      // : Globals.hostS3Base! + '/${e['photo']}.jpg';
      DateTime? dtOpen = null;
      DateTime? dtClose = null;
      int? timeMinimum = null;
      int? timeMaximum = null;
      int? timeIncrement = null;
      List<Models.AmenityBookingSection> bookingSections = [];
      if (e['booking_time_basic'] == 'time') {
        if (e['time_open'] != null) {
          dtOpen = DateTime.parse('2000-01-01 ' + e['time_open']);
        }
        if (e['time_close'] != null) {
          dtClose = DateTime.parse('2000-01-01 ' + e['time_close']);
        }
        if (e['time_minimum'] != null) {
          timeMinimum = e['time_minimum'];
        }
        if (e['time_maximum'] != null) {
          timeMaximum = e['time_maximum'];
        }
        if (e['time_increment'] != null) {
          timeIncrement = e['time_increment'];
        }
      } else if (e['booking_time_basic'] == 'section') {
        resp = await Ajax.getAmenityBookingSections(
          // clientCode: Globals.curClientJson?['code'],
          amenityId: e['id'],
        );
        List<Map<String, dynamic>> remoteData =
            new List<Map<String, dynamic>>.from(resp.data as List);
        for (int j = 0; j < remoteData.length; ++j) {
          var e2 = remoteData[j];
          DateTime timeBegin = DateTime.parse(
              '2000-01-01 ' + e2['booking_sections_id']['time_begin']);
          DateTime timeEnd = DateTime.parse(
              '2000-01-01 ' + e2['booking_sections_id']['time_end']);
          final bs = Models.AmenityBookingSection(
            id: e2['id'],
            amenityId: e2['amenities_id'],
            bookingSectionId: e2['booking_sections_id']['id'],
            name: e2['booking_sections_id']['name'],
            timeBegin: DateFormat('HH:mm').format(timeBegin),
            timeEnd: DateFormat('HH:mm').format(timeEnd),
          );
          bookingSections.add(bs);
        }
      }
      final amenity = Models.Amenity(
        id: e['id'],
        dateCreated: e['date_created'],
        name: e['name'],
        details: e['details'] ?? '',
        photo: photo,
        monday: e['monday'],
        tuesday: e['tuesday'],
        wednesday: e['wednesday'],
        thursday: e['thursday'],
        friday: e['friday'],
        saturday: e['saturday'],
        sunday: e['sunday'],
        status: e['status'],
        fee: e['fee'],
        timeOpen: dtOpen,
        timeClose: dtClose,
        timeMinimum: timeMinimum,
        timeMaximum: timeMaximum,
        timeIncrement: timeIncrement,
        bookingTimeBasic: e['booking_time_basic'],
        isRepetitiveBooking: Utils.parseDbBoolean(e['is_repetitive_booking']),
        bookingAdvanceDays: e['booking_advance_days'] ?? 0,
        autoCancelHours: e['auto_cancel_hours'],
        contactWhatsapp: e['contact_whatsapp'],
      );
      amenity.bookingSections = bookingSections;
      amenities.add(amenity);
    }

    rtnVal['amenities'] = amenities; // Need for rendering

    return rtnVal; // Assign to _datum
  }

  // Render single amenity feed
  Widget _feedBuilder(Models.Amenity rec) {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    // final box = Globals.oboxStore.box<Models.Marketplace>();

    Widget? trailing = null;
    late String dspt;

    if (rec.fee == 0) {
      dspt = 'freeFee'.tr();
    } else {
      if (rec.bookingTimeBasic == 'time') {
        dspt = '\$${rec.fee} ${'per'.tr()} ${rec.timeIncrement} ${'min'.tr()}';
      } else if (rec.bookingTimeBasic == 'section') {
        dspt = '\$${rec.fee} ${'perSection'.tr()}';
      } else {
        throw 'Unhandled booking time basic: ${rec.bookingTimeBasic}';
      }
    }
    trailing = Text(dspt);

    Size size = MediaQuery.of(context).size;
    print('size: $size');

    return InkWell(
      onTap: () {
        developer.log(StackTrace.current.toString().split('\n')[0]);

        if (rec.status == 'open') {
          Navigator.pushNamed(context, '/amenityBooking',
              arguments: {'amenity': rec});
        }
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 5, // shadow
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Stack(
            //   alignment: Alignment.topCenter,
            //   children: [
            // Use CachedNetworkImage to reduce network traffic
            // Inside the CachedNetworkImage, it provides an image
            // which is used to make Ink.image because Ink.image supports
            // GestureDetector to let the user to download the full image.
            CachedNetworkImage(
              // fit: BoxFit.cover,
              imageUrl: rec.photo,
              placeholder: (context, url) =>
                  const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) =>
                  const Center(child: Icon(Icons.error)),
              imageBuilder: (context, imageProvider) => Ink.image(
                fit: BoxFit.fitWidth,
                height: (size.width - 50.0) * 0.546875,
                width: double.infinity,
                // height: double.infinity,
                // height: 145,
                // fit: BoxFit.fitWidth,
                // image: NetworkImage(rec.adImageThm),
                image: imageProvider,
              ),
            ),
            // ],
            // ),
            ListTile(
              title: Text(
                rec.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                rec.status == 'open' ? 'amenityOpen'.tr() : 'amenityClose'.tr(),
                style: TextStyle(
                  color: rec.status == 'open' ? Colors.green[600] : Colors.red,
                  fontSize: 14.0,
                ),
              ),
              trailing: trailing,
            ),
          ],
        ),
      ),
    );
  }

  // Main content of this page.
  Widget _renderBody() {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    final List<Models.Amenity> records = _datum['amenities'];

    late Widget contents;
    if (records.length == 0) {
      contents = Text(
        'amenityNotDefined'.tr(),
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey,
        ),
      );
    } else {
      contents = SingleChildScrollView(
        // physics: ScrollPhysics(),
        child: Column(
          children: [
            Text('amenitySelect'.tr()),
            ListView.builder(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: records.length,
              itemBuilder: (context, index) {
                return _feedBuilder(records[index]);
              },
            ),
            SizedBox(height: 10),
          ],
        ),
      );
    }

    return RawBackground(
      title: 'navbarAmenityBooking'.tr(),
      child: contents,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _key,
      // drawer: NavBar(),
      // appBar: AppBar(
      //   title: Text('navbarAmenityBooking'.tr()),
      //   centerTitle: true,
      // ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _futureData,
        builder: (ctx, snapshot) {
          if (snapshot.hasData) {
            _datum = snapshot.data as Map<String, dynamic>;
            return _renderBody();
          } else if (snapshot.hasError) {
            return Container(
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'sysError'.tr() + ' ${snapshot.error}',
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
  } // build()
} // _AmenitiesPageState
