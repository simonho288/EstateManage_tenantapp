import 'dart:developer' as developer;
import 'dart:io';
import 'dart:convert' as convert;
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'package:sqflite/sqflite.dart';

// import 'package:intl/intl.dart';

import '../components/rawBackground.dart';
import '../components/dialogBuilder.dart';

import '../include.dart';
import '../constants.dart' as Constants;
import '../models.dart' as Models;
import '../ajax.dart' as Ajax;
import '../utils.dart' as Utils;
import '../globals.dart' as Globals;
import '../loopTranslate.dart' as LoopTranslate;

class NoticePage extends StatefulWidget {
  late Models.Loop _loop;

  NoticePage({Key? key, args}) : super(key: key) {
    _loop = args!['rec'];
  }

  @override
  _NoticePageState createState() => _NoticePageState(_loop);
}

class _NoticePageState extends State<NoticePage> {
  late Models.Loop _loop; // the Loop record
  late Future<Map<String, dynamic>> _futureData;
  // String _downloadProgress = '';
  late Models.Notice _notice;
  late Dio _dio;
  final GlobalKey<ScaffoldState> _key = GlobalKey();

  _NoticePageState(Models.Loop loop) {
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
    Ajax.ApiResponse resp = await Ajax.getNotice(id: loopParams['noticeId']);

    if (resp.data == null) {
      return {'error': 'rec_not_found'};
    } else {
      Map<String, dynamic> data = resp.data;
      _notice = Models.Notice(
        id: data['id'],
        dateCreated: DateTime.parse(data['dateCreated']),
        issueDate: data['issueDate'],
        title: data['title'],
        pdfUrl: data['pdf'],
        // pdfUrl: Globals.hostS3Base! + '/' + data['pdf'] + '.pdf',
      );

      return {'status': 'success'};
    }
  }

  Future<void> _onBtnDownloadPdf() async {
    // if (await Permission.storage.request().isGranted) {
    Directory dir = await getTemporaryDirectory();
    String srcUrl = _notice.pdfUrl;
    String dstPath = '${dir.path}/${_notice.title}.pdf';
    Response? resp = await Utils.downloadFile(
        context, 'noticeDownloadPdf'.tr(), srcUrl, dstPath);
    if (resp != null && resp.statusCode == 200) {
      final rst = await OpenFile.open(dstPath);
      print(rst);
    } else {
      Utils.showSnackBar(
        context,
        'errorDownloadingFile'.tr(),
      );
    }
    // }
  }

  // Main content of this page.
  Widget _renderBody() {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    IconData icon = Icons.event_note;
    String title = Utils.getDbStringByCurLocale(_notice.title);
    String subTitle = "created".tr() + ': ' + _notice.issueDate;

    // Translate the parameters
    Map<String, dynamic> params = convert.jsonDecode(this._loop.paramsJson!);
    Map<String, dynamic> translated = LoopTranslate.byTitleId(
        context: context,
        titleId: params['titleId'],
        type: this._loop.type,
        params: params);
    String body = translated['body'];
    // Size size = MediaQuery.of(context).size;

    return RawBackground(
      title: 'navbarNotice'.tr(),
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
                title: Text(title),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: ButtonBar(
                  alignment: MainAxisAlignment.start,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          primary: Globals.primaryLightColor,
                          textStyle: TextStyle(fontSize: 20.0)),
                      onPressed: _onBtnDownloadPdf,
                      child: Text('noticeDownloadNotice'.tr()),
                    ),
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

    String errMsg = err == 'rec_not_found' ? 'errNoticeRecNotFound'.tr() : err;

    return RawBackground(
      title: 'navbarNotice'.tr(),
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
      //   title: Text('navbarNotice'.tr()),
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
                'sysError'.tr() + " ${snapshot.error}",
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
