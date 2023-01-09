import 'dart:developer' as developer;
import 'dart:io';
import 'dart:convert' as convert;
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

import '../components/rawBackground.dart';
import '../components/dialogBuilder.dart';

import '../include.dart';
import '../constants.dart' as Constants;
import '../models.dart' as Models;
import '../ajax.dart' as Ajax;
import '../utils.dart' as Utils;
import '../loopTranslate.dart' as LoopTranslate;
import '../globals.dart' as Globals;

class ReceiptPage extends StatefulWidget {
  late Models.Loop _loop;

  ReceiptPage({Key? key, args}) : super(key: key) {
    _loop = args!['rec'];
  }

  @override
  _ReceiptPageState createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  final GlobalKey<ScaffoldState> _key = GlobalKey();
  String _downloadProgress = '';
  late Future<Map<String, dynamic>> _futureData;
  late Dio _dio;
  late Map<String, dynamic> _loopJson;

  @override
  void initState() {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    _dio = Dio();
    _futureData = _loadInitialData();
    super.initState();
  }

  Future<Map<String, dynamic>> _loadInitialData() async {
    developer.log(StackTrace.current.toString().split('\n')[0]);
    assert(Globals.curTenantJson != null);

    assert(widget._loop.paramsJson != null);
    _loopJson = convert.jsonDecode(widget._loop.paramsJson!);

    return {'status': 'success'}; // Actually, always return success
  }

/*
  // Using Dio, to download the file by URL to local specified path (temp dir)
  Future<void> _downloadFile(String url, String fullPath) async {
    try {
      DialogBuilder(context).showLoadingIndicator(
          'noticeDownloadPdf'.tr() +
              'fullstop'.tr() +
              'pleaseWait'.tr());
      await _dio.download(
        url,
        fullPath,
        onReceiveProgress: (receive, total) {
          setState(() {
            _downloadProgress =
                ((receive / total) * 100).toStringAsFixed(0) + '%';
            print(_downloadProgress);
            // progDlg.update(message: 'Downloading $_downloadProgress');
          });
        },
      );
    } catch (e) {
      print(e);
    } finally {
      DialogBuilder(context).hideOpenDialog();
    }
  }
*/

  Future<void> _onBtnDownloadPdf() async {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    Directory dir = await getTemporaryDirectory();
    String srcUrl = _loopJson['pdfUrl'];
    String dstPath = '${dir.path}/receipt.pdf';
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

  // Main content of this page.
  Widget _renderBody() {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    IconData icon = Icons.event_note;
    print(_loopJson);
    // String title = _notice.title;
    // String subTitle = _notice.issueDate;
    String title = 'mgroffReceipt'.tr();

    // Translate the parameters
    Map<String, dynamic> translated = LoopTranslate.byTitleId(
        context: context,
        titleId: _loopJson['title_id'],
        type: widget._loop.type,
        params: _loopJson);
    String body = translated['body'];
    // Size size = MediaQuery.of(context).size;

    return RawBackground(
      title: 'mgroffReceipt'.tr(),
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
                      child: Text('downloadReceipt'.tr()),
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
      title: 'mgroffReceipt'.tr(),
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
