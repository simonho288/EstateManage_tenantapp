import 'dart:developer' as developer;
import 'dart:convert' as convert;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
// import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter/gestures.dart';
// import 'package:form_builder_validators/form_builder_validators.dart';
// import 'package:intl/intl.dart';

import '/components/roundedButton.dart';
import '/components/roundedInputField.dart';

import '../globals.dart' as Globals;
import '../utils.dart' as Utils;
import '../ajax.dart' as Ajax;

// The background of this page (the upper & lower circle shapes)
class Background extends StatelessWidget {
  final Widget child;
  const Background({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Container(
      height: size.height,
      width: size.width, // double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned(
            top: 0,
            left: 0,
            child: Image.asset(
              'assets/images/circle1.png',
              width: size.width * 0.35,
              color: Color.fromRGBO(255, 255, 255, 0.6),
              colorBlendMode: BlendMode.modulate,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Image.asset(
              'assets/images/circle2.png',
              width: size.width * 0.25,
              color: Color.fromRGBO(255, 255, 255, 0.3),
              colorBlendMode: BlendMode.modulate,
            ),
          ),
          child,
        ],
      ),
    );
  }
} // Background

// The main body of this page (the heading, image)
class Body extends StatelessWidget {
  final Widget child;

  const Body({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Size size = MediaQuery.of(context).size;
    return Background(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(height: 50),
            // Heading
            Text(
              'loginHeader'.tr(),
              style: TextStyle(
                // fontWeight: FontWeight.bold,
                fontSize: 24.0,
                color: Globals.primaryColor,
              ),
            ),
            // SizedBox(height: 10),
            // Woman image
            /*
            Image.asset(
              'assets/images/woman2.png',
              width: size.width * 0.6,
              color: Color.fromRGBO(255, 255, 255, 0.4),
              colorBlendMode: BlendMode.modulate,
            ),
            */
            child,
          ],
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // final _formKey = GlobalKey<FormBuilderState>();
  final _formKey = GlobalKey<FormState>();
  late List<DropdownMenuItem> _ddiLanguages;
  bool _hidePassword = true;
  late SharedPreferences _prefs;
  String? _password;
  late Future<bool> _future;
  bool _isLoginPressed = false;
  TextEditingController _nameController = TextEditingController();
  TextEditingController _pwdController = TextEditingController();
  bool _remember = false;

  @override
  void initState() {
    List<Map<String, dynamic>> langs = [
      {'name': 'English', 'value': 'en'},
      {'name': '繁體中文', 'value': 'zh_HK'},
      // {'name': '简体中文', 'value': 'zh_CN'}
    ];
    _ddiLanguages = langs
        .map(
          (opt) => DropdownMenuItem(
            value: opt['value'],
            child: Text(opt['name'].toString()),
          ),
        )
        .toList();

    _future = _getInitialData();

    super.initState();
  }

  Future<bool> _getInitialData() async {
    developer.log('_getInitialData');

    _prefs = await SharedPreferences.getInstance();

    String? encPwd = _prefs.getString('loginPassword');
    if (encPwd != null) {
      _password = Utils.decryptStringAES256CTR(encPwd);
      _remember = true;
      _pwdController.text = _password!;
    }

    final email = Globals.curTenantJson?['email'] ?? '';
    _nameController.text = email;

    return true;
  }

  // late BuildContext context;

  Future<void> _onBtnLogin() async {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    if (_isLoginPressed) return;

    _formKey.currentState?.save();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _isLoginPressed = true; // prevent re-entrant

    // Map<String, dynamic> values = _formKey.currentState!.value;
    // String mobileOrEmail = values['name'];
    // String password = values['password'];
    // bool isRemember = values['remember'];
    String mobileOrEmail = _nameController.text;
    String password = _pwdController.text;
    String? fcmDeviceToken = await Utils.generateDeviceToken();

    late Ajax.ApiResponse resp;
    try {
      resp = await Ajax.tenantLogin(
        userId: Globals.userId!,
        mobileOrEmail: mobileOrEmail,
        password: password,
        fcmDeviceToken: fcmDeviceToken,
      );

      if (resp.error != null) {
        String err = resp.error!;
        if (err == 'tenant_not_found' || err == 'invalid_password') {
          await Utils.showAlertDialog(
            context,
            'loginFailed'.tr(),
            'invalidMobileNoOrEmail'.tr(),
          );
        } else if (err == 'account_pending') {
          await Utils.showAlertDialog(
            context,
            'loginFailed'.tr(),
            'accountPendingApproval'.tr(),
          );
        } else if (err == 'account_suspended') {
          await Utils.showAlertDialog(
            context,
            'loginFailed'.tr(),
            'accountIsSuspended'.tr(),
          );
        } else {
          await Utils.showAlertDialog(
            context,
            'sysError'.tr(),
            'serverError'.tr() + err.toString(),
          );
        }
      } else {
        Map<String, dynamic> data = resp.data;

        Globals.accessToken = data['token']; // jwt token
        Globals.curTenantJson = data['tenant'];
        if (_remember) {
          if (_password != password) {
            // Encrypt the password
            await _prefs.setString(
                'loginPassword', Utils.encryptStringAES256CTR(password));
          }
          await _prefs.setString(
              'tenantJson', convert.jsonEncode(Globals.curTenantJson));
        } else {
          await _prefs.remove('loginPassword');
        }

        // Read the client image background
        resp = await Ajax.getEstateById(
          id: Globals.curEstateJson?['id'],
        );
        data = resp.data;
        Map<String, dynamic> estate = data;
        Globals.curEstateJson?['estateImageApp'] = estate['estateImageApp'];

        Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
      }
    } catch (e) {
      await Utils.showAlertDialog(
        context,
        "error".tr(),
        "serverResponseError".tr(),
      );
    }

    _isLoginPressed = false;
  }

/* Only supported English at the moment
  Future<void> _onLangChanged(dynamic value) async {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    // Save to SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', value);
    Globals.curLang = value;

    Locale loc = Utils.langIdToLocale(value);
    MainApp.changeLanguage(context, loc);
  }
*/

  Body _renderBody() {
    return Body(
      child: Column(
        children: <Widget>[
          Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.disabled,
            child: Column(
              children: <Widget>[
                SizedBox(height: 10),
                /* Only support English at this moment
                DropdownContainer(
                  child: FormBuilderDropdown(
                    name: 'language',
                    initialValue: 'en',
                    onChanged: _onLangChanged,
                    style: TextStyle(
                      fontSize: 15.5,
                      color: Colors.black,
                    ),
                    decoration: InputDecoration(
                      icon: Icon(
                        Icons.language,
                        color: Globals.primaryColor,
                      ),
                      border: InputBorder.none,
                    ),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(),
                    ]),
                    items: _ddiLanguages,
                  ),
                ),
                */
                /*
                TextFieldContainer(
                  child: FormBuilderTextField(
                    name: 'name',
                    initialValue: email,
                    decoration: InputDecoration(
                      icon: Icon(
                        Icons.person,
                        color: Globals.primaryColor,
                      ),
                      hintText: 'loginMobileOrEmail'.tr(),
                      border: InputBorder.none,
                    ),
                    // onChanged: _onChanged,
                    // valueTransformer: (text) => num.tryParse(text),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(),
                    ]),
                  ),
                ),
                */
                // Create a textformfield for input email
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    icon: Icon(
                      Icons.person,
                      color: Globals.primaryColor,
                    ),
                    labelText: 'loginMobileOrEmail'.tr(),
                    // border: InputBorder.none,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'cantEmpty'.tr();
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _pwdController,
                  obscureText: _hidePassword,
                  decoration: InputDecoration(
                    icon: Icon(
                      Icons.lock,
                      color: Globals.primaryColor,
                    ),
                    labelText: 'password'.tr(),
                    // border: InputBorder.none,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _hidePassword ? Icons.visibility : Icons.visibility_off,
                        color: Globals.primaryColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _hidePassword =
                              !_hidePassword; // show/hide the password
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'cantEmpty'.tr();
                    }
                    return null;
                  },
                ),
/*
                TextFieldContainer(
                  child: FormBuilderTextField(
                    name: 'password',
                    initialValue: password,
                    obscureText: _hidePassword,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: InputDecoration(
                      // labelText: 'Password',
                      hintText: 'password'.tr(),
                      icon: Icon(
                        Icons.lock,
                        color: Globals.primaryColor,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _hidePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Globals.primaryColor,
                        ),
                        onPressed: () {
                          setState(() {
                            _hidePassword =
                                !_hidePassword; // show/hide the password
                          });
                        },
                      ),
                      border: InputBorder.none,
                    ),
                    // onChanged: _onChanged,
                    // valueTransformer: (text) => num.tryParse(text),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(),
                    ]),
                  ),
                ),
                */
                SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(width: 15),
                    SizedBox(
                      width: 200,
                      child: CheckboxListTile(
                        title: Text('rememberMe'.tr()),
                        controlAffinity: ListTileControlAffinity.leading,
                        value: _remember,
                        onChanged: (newValue) {
                          setState(() {
                            _remember = newValue!;
                          });
                        },
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          SizedBox(height: 10),
          RoundedButton(
            text: 'login'.tr(),
            color: Globals.primaryColor,
            press: _onBtnLogin,
          ),
          SizedBox(height: 20.0),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: <TextSpan>[
                TextSpan(
                  text: 'or'.tr() + ' ',
                  style: TextStyle(fontSize: 20, color: Colors.black),
                ),
                TextSpan(
                  text: 'signUp'.tr(),
                  style: TextStyle(fontSize: 20, color: Colors.blue),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      Navigator.pushNamed(context, '/register');
                    },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String title = 'programTitle'.tr();
    if (Globals.appVersion != null) {
      title += ' v' + Globals.appVersion.toString();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0.0,
      ),
      extendBodyBehindAppBar: true,
      // Rely on Body (and it's hosted inside Background as well)
      body: FutureBuilder<bool>(
        future: _future,
        builder: (context, snapshot) {
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
