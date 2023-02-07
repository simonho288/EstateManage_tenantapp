// import 'dart:io';
import 'dart:developer' as developer;
import 'dart:convert' as convert;
// import 'package:collection/collection.dart' as Collection;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../include.dart';
import '../globals.dart' as Globals;
import '../main.dart';
import '../utils.dart' as Utils;
import '../ajax.dart' as Ajax;
// import '../components/navBar.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  String _langDdv = 'English';
  late Future<bool> _future;
  late Map<String, dynamic> _unitJson;
  List<DropdownMenuItem<String>>? _ddmiRoles;
  String? _selectedRole;
  final _formKey = GlobalKey<FormState>();
  final _ctrlrName = TextEditingController();
  final _ctrlrMobile = TextEditingController();
  final _ctrlrEmail = TextEditingController();
  final _ctrlrPassword = TextEditingController();
  final _ctrlrPasswordVerify = TextEditingController();

  @override
  void dispose() {
    _ctrlrName.dispose();
    _ctrlrMobile.dispose();
    _ctrlrEmail.dispose();
    super.dispose();
  }

  @override
  void initState() {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    _future = _loadInitialData();

    super.initState();
  } // initState()

  Future<bool> _loadInitialData() async {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    // SharedPreferences prefs = await SharedPreferences.getInstance();
    // _unitJson = convert.jsonDecode(prefs.getString('unitJson')!);
    _unitJson = Globals.curUnitJson!;

    return true;
  }

  // Setup the controls when everything data ready
  void _setupUnitControls() {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    // Base dropdown control(s)
    // if (_ddmiRoles == null) {
    _ddmiRoles = [
      DropdownMenuItem(child: Text('owner'.tr()), value: 'owner'),
      DropdownMenuItem(child: Text('tenant'.tr()), value: 'tenant'),
      DropdownMenuItem(child: Text('occupant'.tr()), value: 'occupant'),
      DropdownMenuItem(child: Text('agent'.tr()), value: 'agent'),
    ];
    if (_selectedRole == null) {
      _selectedRole = _ddmiRoles?[0].value;
    }
  }

  Future<void> _onLangChanged(String? val) async {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    String lid = (val == '简体中文')
        ? 'zh_CN'
        : (val == '繁體中文')
            ? 'zh_HK'
            : 'en';
    // Lang.setCurrentLanguage(lid);

    Locale lc = Locale('en');
    if (lid == 'zh_HK') {
      lc = Locale('zh', 'HK');
    } else if (lid == 'zh_CN') {
      lc = Locale('zh', 'CN');
    }

    MainApp.changeLanguage(context, lc);

    _langDdv = val!;

    // Save the language to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('language', lid);

    _setupUnitControls();

    // Refresh the screen
    setState(() {});
  }

  Future<void> _onBtnSubmit() async {
    if (_formKey.currentState!.validate()) {
      String role = _selectedRole!;
      String name = _ctrlrName.text;
      String mobile = _ctrlrMobile.text;
      String email = _ctrlrEmail.text;
      String password = _ctrlrPassword.text;
      String? fcmDeviceToken = await Utils.generateDeviceToken();

      assert(Globals.curEstateJson != null);
      fcmDeviceToken = fcmDeviceToken != null ? fcmDeviceToken : '';

      Ajax.ApiResponse resp = await Ajax.createNewTenant(
        unitId: _unitJson['id'],
        userId: Globals.userId!,
        role: role,
        name: name,
        mobile: mobile,
        email: email,
        password: password,
        fcmDeviceToken: fcmDeviceToken,
      );

      if (resp.error != null) {
        if (resp.error == 'email_exist') {
          // Tenant exists
          await Utils.showAlertDialog(
            context,
            'forbidden'.tr(),
            'tenantEmailExist'.tr(),
          );
        } else {
          // Tenant exists
          await Utils.showAlertDialog(
            context,
            'error'.tr(),
            resp.error!,
          );
        }
      } else {
        // Save the result from backend to SharedPreferences
        Map<String, dynamic> result = resp.data as Map<String, dynamic>;
        String tenantId = result['tenantId'];
        Globals.curTenantJson = {
          'id': tenantId,
          'name': name,
          'email': email,
          'mobile': mobile,
        };
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'tenantJson', convert.jsonEncode(Globals.curTenantJson));

        await Utils.showAlertDialog(
          context,
          'success'.tr(),
          'confirmEmailSent'.tr(),
        );

        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  } // onBtnSubmit()

  Widget _renderBody() {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    const double TextSpanFontSize = 18;

    // Needs to show:
    // 1 - Phase, Block, Floor, Room dropdown
    // 2 - [Confirm] button
    // 3 - Display the QRcode

    // This is the widgets to be shown
    List<Widget> widgets = [];
    const MARGIN1 = 10.0;
    const MARGIN2 = 5.0;

    widgets.add(
      Center(
        child: Text(
          Globals.curEstateJson!['name'],
          style: TextStyle(fontSize: 20),
          textAlign: TextAlign.center,
        ),
      ),
    );
    widgets.add(SizedBox(height: MARGIN2));
    // TODO: Support multi-languages
    /*
    widgets.add(
      DropdownButton<String>(
        value: _langDdv, // language dropdown value
        icon: Icon(
          Icons.arrow_downward,
          // color: Theme.of(context).primaryColor,
        ),
        iconSize: 24,
        elevation: 16,
        // style: TextStyle(color: Theme.of(context).primaryColor),
        underline: Container(
          height: 2,
        ),
        onChanged: _onLangChanged,
        items: <String>[
          'English',
          '繁體中文', /*'简体中文'*/
        ].map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
      ),
    );
    */
    widgets.add(SizedBox(height: MARGIN1));
    widgets.add(
      RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          children: <TextSpan>[
            TextSpan(
              text: 'ifYouRegistered'.tr(),
              style: TextStyle(fontSize: TextSpanFontSize, color: Colors.black),
            ),
            TextSpan(
              text: 'pleaseLogin'.tr(),
              style: TextStyle(fontSize: TextSpanFontSize, color: Colors.blue),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  Navigator.pushNamed(context, '/login');
                },
            ),
          ],
        ),
      ),
    );
    widgets.add(SizedBox(height: MARGIN1));
    String msgConfirmUnit = 'pleaseVerifyUnitBelow'.tr();
    String unitName = Utils.buildUnitNameWithLangByJson(_unitJson);
    msgConfirmUnit = msgConfirmUnit.replaceFirst('{unit}', unitName);
    widgets.add(
      RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          children: <TextSpan>[
            TextSpan(
              text: msgConfirmUnit,
              style: TextStyle(fontSize: TextSpanFontSize, color: Colors.black),
            ),
            TextSpan(
              text: 'rescanUnitQrcode'.tr(),
              style: TextStyle(fontSize: TextSpanFontSize, color: Colors.blue),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  Navigator.pushNamed(context, '/scanEstateQr');
                },
            ),
          ],
        ),
      ),
    );

    widgets.add(SizedBox(height: MARGIN1));
    widgets.add(
      Text(
        'pleaseSubmitFormBelow'.tr(),
        style: TextStyle(
          fontSize: 15.0,
          color: Colors.grey,
        ),
        textAlign: TextAlign.center,
      ),
    );

    // Select Role dropdown
    // widgets.add(SizedBox(height: MARGIN2));
    widgets.add(Row(children: [
      Container(
        width: 110,
        child: Text('role'.tr(), style: Theme.of(context).textTheme.bodyText2),
      ),
      DropdownButton(
        value: _selectedRole,
        items: _ddmiRoles,
        style: TextStyle(fontSize: 16.0, color: Colors.black),
        onChanged: (value) {
          setState(() {
            _selectedRole = value;
          });
        },
      ),
    ]));

    // Next, input personal info -> name
    widgets.add(
      TextFormField(
        controller: _ctrlrName,
        decoration: InputDecoration(
          labelText: 'yourName'.tr() + '*',
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'cantEmpty'.tr();
          }
          return null;
        },
      ),
    );

    // Next, input personal info -> email
    widgets.add(SizedBox(height: MARGIN2));
    widgets.add(
      TextFormField(
        keyboardType: TextInputType.emailAddress,
        controller: _ctrlrEmail,
        decoration: InputDecoration(
          labelText: 'email'.tr() + '*',
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'cantEmpty'.tr();
          }
          if (!RegExp(
                  r"^([a-zA-Z0-9_\-\.]+)@([a-zA-Z0-9_\-\.]+)\.([a-zA-Z]{2,5})$")
              .hasMatch(value)) {
            return 'invalidEmail'.tr();
          }
          return null;
        },
      ),
    );

    // Next, input personal info -> tel
    widgets.add(SizedBox(height: MARGIN2));
    widgets.add(
      TextFormField(
        keyboardType: TextInputType.phone,
        controller: _ctrlrMobile,
        decoration: InputDecoration(
          labelText: 'mobileNo'.tr(),
        ),
        // validator: (value) {
        //   if (!RegExp(r"^\b\d{8}\b$").hasMatch(value)) {
        //     return 'invalidPhoneno'.tr();
        //   }
        //   return null;
        // },
      ),
    );

    // Next, input personal info -> password
    widgets.add(SizedBox(height: MARGIN2));
    widgets.add(
      TextFormField(
        keyboardType: TextInputType.text,
        controller: _ctrlrPassword,
        obscureText: true,
        decoration: InputDecoration(
          labelText: 'password'.tr() + '*',
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'cantEmpty'.tr();
          }
          if (value.length < 6) {
            String msg = 'passwordTooShort'.tr();
            return msg.replaceFirst('{n}', '6');
          }
          return null;
        },
      ),
    );

    // Next, input personal info -> passwordVerify
    widgets.add(SizedBox(height: MARGIN2));
    widgets.add(
      TextFormField(
        keyboardType: TextInputType.text,
        controller: _ctrlrPasswordVerify,
        obscureText: true,
        decoration: InputDecoration(
          labelText: 'verifyPassword'.tr() + '*',
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'cantEmpty'.tr();
          }
          if (value != _ctrlrPassword.text) {
            return 'passwordMismatch'.tr();
          }
          return null;
        },
      ),
    );

    // Next, the action button(s)
    widgets.add(SizedBox(height: MARGIN2));
    widgets.add(
      Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: MaterialButton(
                child: Text(
                  'submit'.tr(),
                  textAlign: TextAlign.center,
                ),
                // minWidth: 100,
                height: 50,
                color: Globals.primaryColor,
                textColor: Colors.white,
                onPressed: _onBtnSubmit,
              ),
            ),
          ),
        ],
      ),
    );
    widgets.add(SizedBox(height: MARGIN2));
    widgets.add(
      Text(
        Globals.appVersion != null ? 'v${Globals.appVersion!}' : '',
        style: TextStyle(fontSize: 12.0),
      ),
    );

    return Form(
      key: _formKey,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: widgets,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    return Scaffold(
      // drawer: NavBar(),
      appBar: AppBar(
        title: Text('tenantRegister'.tr()),
        centerTitle: true,
      ),
      body: FutureBuilder<bool>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            developer.inspect(snapshot.data); // dump the data to console
            _setupUnitControls();
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
