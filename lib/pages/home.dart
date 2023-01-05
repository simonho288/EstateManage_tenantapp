/**
 * The design of this page followed:
 * Top & background:
 * https://youtu.be/8abMF1Y2Xnk?t=357
 */

import 'dart:developer' as developer;
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert' as convert;

import '../include.dart';
import '../constants.dart' as Constants;
import '../models.dart' as Models;
import '../ajax.dart' as Ajax;
import '../utils.dart' as Utils;
import '../globals.dart' as Globals;
import '../components/navBar.dart';

class HomePage extends StatefulWidget {
  String? _filter;
  late _HomePageState _appState;

  HomePage({Key? key, args}) : super(key: key) {
    Globals.homePage = this;
    if (args != null) {
      _filter = args['filter'];
    }
    _appState = _HomePageState(_filter);
  }

  @override
  State<HomePage> createState() => _appState;

  // Allow all other widgets to call this to refresh home page loop records
  // eg. await Globals.homePage.refreshData();
  refreshData() {
    _appState.refreshData();
  }
} // HomePage

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _key = GlobalKey();
  late String? _filter; // filter what type of loop to show?
  late Future<Map<String, dynamic>> _futureData;
  late Map<String, dynamic> _datum; // All data records for this page
  late Database _database;
  static late BuildContext homePageContext;

  _HomePageState(String? filter) {
    _filter = filter;
  }

  @override
  void initState() {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    homePageContext = context;
    _futureData = _loadInitialData();
    super.initState();
  }

  Future<Map<String, dynamic>> _loadInitialData() async {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    _database = await Globals.sqlite;
    Map<String, dynamic> rtnVal = {}; // Return JSON (equivalent _datum)

    // Get existing records from Sqflite
    List<Models.Loop> records;
    if (this._filter == null) {
      records = await Models.Loop.getAll(_database);
      // Sort by date
      records.sort(
          (a, b) => b.dateCreated.compareTo(a.dateCreated)); // Sort descending
    } else {
      String sql = 'SELECT * FROM Loops WHERE type=? ORDER BY dateCreated DESC';
      records = await Models.Loop.query(_database, sql, [_filter]);
    }

    // Read all newest Loops only in homepage.
    if (this._filter == null) {
      // Read remote data without duplication
      List<String> existingIDs = records.map((e) => e.id).toList();

      // Get any new records where are exclude existing records
      Ajax.ApiResponse resp = await Ajax.getLoops(
        // clientCode: Globals.curClientJson?['code'],
        tenantId: Globals.curTenantJson?['id'],
        excludeIDs: existingIDs,
      );
      List<Map<String, dynamic>> remoteData =
          new List<Map<String, dynamic>>.from(resp.data as List);

      // Add the remote records to Sqlite
      if (remoteData.length > 0) {
        // Copy the records from server to local db
        remoteData.forEach((e) async {
          Map<String, dynamic> params = convert.jsonDecode(e['params_json']);
          // Add the title_id to the paramsJson
          params['title_id'] = e['title_id'];
          Map<String, dynamic> translated = await Utils.translateLoopTitleId(
            context: homePageContext,
            titleId: e['title_id'],
            type: e['type'],
            params: params,
          );

          final notice = Models.Loop(
            id: e['id'],
            dateCreated: Utils.isoDatetimeToLocal(e['date_created']),
            titleId: e['title_id'],
            titleTranslated: translated['title'],
            url: e['url'],
            type: e['type'],
            sender: params['senderName'],
            paramsJson: convert.jsonEncode(params),
            isNew: true,
          );
          notice.insert(_database); // Save to Sqlite
          records.insert(0, notice); // Don't forget to add to this memory
        });
      }
    }

    rtnVal['loops'] = records;

    return rtnVal; // Assign to _datum
  }

  // Called by host widget method
  Future<void> refreshData() async {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    _futureData = _loadInitialData();
    await _futureData;
    setState(() {});
  }

  void _onTap(Models.Loop rec) {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    developer.log(rec.id.toString());
    switch (rec.titleId) {
      case Constants.LOOP_TITLE_MANAGEMENT_NOTICE:
        Navigator.pushNamed(context, '/notice', arguments: {'rec': rec});
        break;
      case Constants.LOOP_TITLE_NEW_AMENITY_BOOKING:
      case Constants.LOOP_TITLE_AMENITY_BOOKING_CONFIRMED:
      case Constants.LOOP_TITLE_AMENITY_BOOKING_CANCELLED:
        Navigator.pushNamed(context, '/booking', arguments: {'rec': rec});
        break;
      case Constants.LOOP_TITLE_NEW_AD_WITH_IMAGE:
        Navigator.pushNamed(context, '/marketplace', arguments: {'rec': rec});
        break;
      case Constants.LOOP_TITLE_MANAGEMENT_RECEIPT:
        Navigator.pushNamed(context, '/receipt', arguments: {'rec': rec});
        break;
      default:
        developer.log('Unhandled loop type: ${rec.titleId}');
        break;
    }
  }

  Widget _renderBackground() {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    List<Models.Loop> loops = _datum['loops'];
    List<Widget> widgets = []; // The widgets of the main contents
    String title = 'homeLoopsHeader'.tr();
    if (this._filter == 'management_notice') {
      title = 'homeLoopsNotices'.tr();
    } else if (this._filter == 'new_marketplace') {
      title = 'homeLoopsMarketplaces'.tr();
    }

    // The title of the contents
    widgets.add(
      Text(
        title,
        style: TextStyle(
          fontSize: 24,
          color: Globals.primaryColor,
        ),
      ),
    );

    if (loops.length > 0) {
      // Render all loop records
      // Note: Must pass the UniqueKey otherwise the stateful widgets are not redrawn
      // https://medium.com/flutter/keys-what-are-they-good-for-13cb51742e7d
      loops.forEach((rec) {
        widgets.add(
          _LoopTile(
            key: UniqueKey(),
            onTap: _onTap,
            loop: rec,
          ),
        );
      });
      widgets.add(SizedBox(height: 135));
    } else {
      widgets.addAll(
        [
          SizedBox(height: 20),
          Text(
            'homeNoLoops'.tr(),
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12.0,
            ),
          ),
        ],
      );
    }

    // Determine the estate background image
    String? imageUrl = Globals.curEstateJson?['estateImageApp'];
    if (imageUrl == null) {
      imageUrl = Globals
          .defaultEstateImage; // When the user didn't upload their estate image
    } else {
      imageUrl = Globals.hostS3Base! + '/' + imageUrl + '.jpg';
    }

    return _Background(
      openDrawer: () {
        // Called when the hamburger menu tapped
        developer.log(StackTrace.current.toString().split('\n')[0]);
        _key.currentState!.openDrawer();
      },
      backgroundImageUrl: imageUrl,
      contents: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: widgets,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    // Warning before exit
    return WillPopScope(
      onWillPop: () async {
        final value = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: Text('sureToExit'.tr()),
              actions: <Widget>[
                TextButton(
                  child: Text('no'.tr()),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                TextButton(
                  child: Text('yes'.tr()),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            );
          },
        );
        return value == true;
      },
      child: Scaffold(
        key: _key,
        drawer: NavBar(),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _futureData,
          builder: (ctx, snapshot) {
            if (snapshot.hasData) {
              _datum = snapshot.data as Map<String, dynamic>;
              return _renderBackground();
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
      ),
    );
  }
}

// Local widget for this home page background
class _Background extends StatelessWidget {
  final String backgroundImageUrl;
  final Widget contents;
  final void Function() openDrawer;
  const _Background(
      {Key? key,
      required this.backgroundImageUrl,
      required this.contents,
      required this.openDrawer})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    // Keep the background image same aspect ratio as specified (640x300)
    double imgHeg = size.width * 300.0 / 640.0;

    return Container(
      width: size.width,
      height: size.height,
      child: Stack(
        children: <Widget>[
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              // The estate background image (custom image)
              height: imgHeg,
              width: size.width,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: backgroundImageUrl,
                    fit: BoxFit.fill,
                  ),
                  Container(
                    width: size.width,
                    height: size.height,
                    color: Globals.primaryColor.withOpacity(0.2),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            // hamburger menu
            top: 30,
            left: 10,
            child: GestureDetector(
              onTap: () async {
                developer.log(StackTrace.current.toString().split('\n')[0]);
                openDrawer(); // Call parent to open the drawer
                // key.currentState!.openDrawer();
              },
              child: Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: Icon(Icons.menu),
              ),
            ),
          ),
          Positioned(
            // The information main body
            top: imgHeg - 50, //135,
            child: Container(
              width: size.width,
              height: size.height,
              decoration: BoxDecoration(
                // color: Colors.white,
                color: Globals.primaryLighterColor2,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                child: SingleChildScrollView(
                  child: contents, // The child is the main contents
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Local widget to display the loop record
class _LoopTile extends StatelessWidget {
  final Models.Loop loop;
  final void Function(Models.Loop rec) onTap;

  _LoopTile({Key? key, required this.loop, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isClickable = false;
    IconData icon = Icons.help_center; // for all unhandled titleId

    switch (loop.titleId) {
      case Constants.LOOP_TITLE_TENANT_REQUEST_ACCESS:
        icon = Icons.verified_user;
        break;
      case Constants.LOOP_TITLE_MANAGEMENT_NOTICE:
        isClickable = true;
        icon = Icons.campaign;
        break;
      case Constants.LOOP_TITLE_MANAGEMENT_RECEIPT:
        isClickable = true;
        icon = Icons.monetization_on_outlined;
        break;
      case Constants.LOOP_TITLE_NEW_AMENITY_BOOKING:
      case Constants.LOOP_TITLE_AMENITY_BOOKING_CONFIRMED:
      case Constants.LOOP_TITLE_AMENITY_BOOKING_CANCELLED:
        isClickable = true;
        icon = Icons.bookmark_border;
        break;
      case Constants.LOOP_TITLE_NEW_AD_WITH_IMAGE:
        isClickable = true;
        icon = Icons.volunteer_activism;
        break;
    }

    Size size = MediaQuery.of(context).size;

    return InkWell(
      onTap: () {
        developer.log(StackTrace.current.toString().split('\n')[0]);
        onTap(this.loop);
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 10),
        // height: feedHeg,
        decoration: BoxDecoration(
          // color: Globals.primaryLighterColor,
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              offset: Offset(0, 17),
              blurRadius: 5,
              spreadRadius: -13,
              color: Colors.grey[400]!,
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            SizedBox(width: 15),
            Icon(
              icon,
              size: 32,
              color: Globals.primaryColor,
            ),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(DateFormat('yyyy-MM-dd').format(loop.dateCreated),
                      style: TextStyle(fontSize: 16.0)),
                  Text(
                    Utils.truncateString(loop.titleTranslated, 100),
                    style: TextStyle(fontSize: 22.0, color: Colors.black54),
                  )
                ],
              ),
            ),
            isClickable
                ? Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.chevron_right),
                  )
                : SizedBox(width: 10),
          ],
        ),
      ),
    );
  }
}
