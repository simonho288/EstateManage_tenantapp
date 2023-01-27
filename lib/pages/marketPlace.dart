import 'dart:developer' as developer;
import 'dart:io';
import 'dart:convert' as convert;
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
// import 'package:sqflite/sqflite.dart';

// import '../objectbox.g.dart'; // created by `flutter pub run build_runner build`
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

// import '../components/navBar.dart';
import '../components/rawBackground.dart';
import '../components/dialogBuilder.dart';

import '../include.dart';
import '../constants.dart' as Constants;
import '../models.dart' as Models;
import '../ajax.dart' as Ajax;
import '../utils.dart' as Utils;
import '../globals.dart' as Globals;
import '../loopTranslate.dart' as LoopTranslate;

class MarketplacePage extends StatefulWidget {
  late Models.Loop _loop;

  MarketplacePage({Key? key, args}) : super(key: key) {
    _loop = args!['rec'];
  }

  @override
  _MarketplacePageState createState() => _MarketplacePageState(_loop);
}

class _MarketplacePageState extends State<MarketplacePage> {
  late Models.Loop _loop; // the Loop record
  late Future<Map<String, dynamic>> _futureData;
  String _downloadProgress = '';
  late Models.Marketplace _marketplace;
  late Dio _dio;
  final GlobalKey<ScaffoldState> _key = GlobalKey();

  _MarketplacePageState(Models.Loop loop) {
    _loop = loop;
  }

  @override
  void initState() {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    _dio = Dio();
    _futureData = _loadInitialData();
    super.initState();
  } // initState()

  Future<Map<String, dynamic>> _loadInitialData() async {
    developer.log(StackTrace.current.toString().split('\n')[0]);
    assert(Globals.curTenantJson != null);

    assert(_loop.paramsJson != null);
    var loopParams = convert.jsonDecode(_loop.paramsJson!);
    Ajax.ApiResponse resp = await Ajax.getMarketplaceById(
        // clientCode: Globals.curClientJson?['code'],
        id: loopParams['adId']);

    if (resp.data == null) {
      return {'error': 'rec_not_found'};
    } else {
      Map<String, dynamic> data = resp.data;
      // Get the thumbnail by Direcuts custom transform. See:
      // https://docs.directus.io/reference/files/#custom-transformations
      _marketplace = Models.Marketplace(
        id: data['id'],
        dateCreated: DateTime.parse(data['dateCreated']),
        postDate: data['dateStart'],
        title: data['title'],
        adImage: data['adImage'],
        adImageThm: data['adImage'],
        commerceUrl: data['commerceUrl'],
      );

      return {'status': 'success'};
    }
  }

  Future<void> _onBtnDownloadImage() async {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    Directory dir = await getTemporaryDirectory();
    String srcUrl = _marketplace.adImage;
    String dstPath = '${dir.path}/${_marketplace.title}.jpg';
    Response? resp = await Utils.downloadFile(
        context, 'marketplaceDownloadingImg'.tr(), srcUrl, dstPath);
    if (resp != null && resp.statusCode == 200) {
      OpenFile.open(dstPath);
    } else {
      Utils.showSnackBar(
        context,
        'errorDownloadingFile'.tr(),
      );
    }
  }

  Future<void> _onBtnOpenUrl() async {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    await canLaunch(_marketplace.commerceUrl!)
        ? await launch(_marketplace.commerceUrl!)
        : throw 'Could not launch ${_marketplace.commerceUrl}';
  }

  // Main content of this page.
  Widget _renderBody() {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    IconData icon = Icons.event_note;
    String title = Utils.getDbStringByCurLocale(_marketplace.title);
    String subTitle = "created".tr() + ': ' + _marketplace.postDate;

    // Translate the parameters
    Map<String, dynamic> params = convert.jsonDecode(this._loop.paramsJson!);
    Map<String, dynamic> translated = LoopTranslate.byTitleId(
        context: context,
        titleId: params['titleId'],
        type: this._loop.type,
        meta: params);
    String body = translated['body'];

    return RawBackground(
      title: 'navbarMarketplace'.tr(),
      child: SingleChildScrollView(
        // Card appearence: https://material.io/components/cards/flutter#card
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              ListTile(
                leading: Icon(icon),
                title: Text(title, style: TextStyle(fontSize: 20.0)),
                subtitle: Text(
                  subTitle,
                  style: TextStyle(color: Colors.black.withOpacity(0.6)),
                ),
              ),
              const Divider(height: 1, indent: 10, endIndent: 10, thickness: 2),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Html(data: body, style: Constants.HTML_MKUP_OPTIONS),
              ),
              GestureDetector(
                onTap: _onBtnDownloadImage,
                child: CachedNetworkImage(imageUrl: _marketplace.adImageThm),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 5),
                    Container(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          primary: Globals.primaryLightColor,
                          textStyle: TextStyle(fontSize: 20.0),
                        ),
                        onPressed: _onBtnDownloadImage,
                        child: Text('marketplaceDownloadAdImg'.tr()),
                      ),
                    ),
                    _marketplace.commerceUrl != null
                        ? Container(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                primary: Globals.primaryLightColor,
                                textStyle: TextStyle(fontSize: 20.0),
                              ),
                              onPressed: _onBtnOpenUrl,
                              child: Text('marketBrowseWebsite'.tr()),
                            ),
                          )
                        : Container(), // Show nothing
                    SizedBox(height: 5),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _renderError(String err) {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    String errMsg =
        err == 'rec_not_found' ? 'errMarketplaceRecNotFound'.tr() : err;

    return RawBackground(
      title: 'navbarMarketplace'.tr(),
      child: Center(
        child: Text(
          errMsg,
          style: TextStyle(
            fontSize: 14,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _key,
      // drawer: NavBar(),
      // appBar: AppBar(
      //   title: Text('navbarMarketplace'.tr()),
      //   centerTitle: true,
      // ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _futureData,
        builder: (ctx, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data?['error'] != null) {
              return _renderError(snapshot.data?['error']);
            } else {
              return _renderBody();
            }
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
