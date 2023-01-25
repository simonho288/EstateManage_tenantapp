// import 'dart:io';
import 'dart:developer' as developer;
import 'dart:convert' as convert;
import 'package:easy_localization/easy_localization.dart';
import 'package:collection/collection.dart' as Collection;
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
// import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../include.dart';
import '../globals.dart' as Globals;
import '../main.dart';
import '../utils.dart' as Utils;
import '../ajax.dart' as Ajax;
// import '../components/navBar.dart';
import '/components/roundedInputField.dart';

class SetupPasswordPage extends StatefulWidget {
  const SetupPasswordPage({Key? key}) : super(key: key);

  @override
  _setupPasswordPageState createState() => _setupPasswordPageState();
}

class _setupPasswordPageState extends State<SetupPasswordPage> {
  final _formKey = GlobalKey<FormBuilderState>();
  String _langDdv = 'English';

  _setupPasswordPageState() {
    developer.log(StackTrace.current.toString().split('\n')[0]);
  }

  @override
  void initState() {
    List<Map<String, dynamic>> langs = [
      {'name': 'English', 'value': 'en'},
      {'name': '繁體中文', 'value': 'zh_HK'},
      // {'name': '简体中文', 'value': 'zh_CN'}
    ];

    super.initState();
  } // initState()

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

    // Refresh the screen
    setState(() {});
  }

  void _onTermsTapped() {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    Navigator.of(context).pushNamed('/terms', arguments: null);
  }

  Future<void> _savePassword(String password) async {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    Ajax.ApiResponse resp = await Ajax.setTenantPassword(
      tenantId: Globals.curTenantJson?['id'],
      password: password,
    );

    // Is password saved successfully?
    String status = resp.data;
    if (status == 'normal') {
      // Change the user status & save it
      Globals.curTenantJson?['status'] = status;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'userJson', convert.jsonEncode(Globals.curTenantJson));

      await Utils.showAlertDialog(
        context,
        'success'.tr(),
        'passwordSavedDspt'.tr(),
      );

      Navigator.pushReplacementNamed(context, '/login');
    } else {
      await Utils.showAlertDialog(
        context,
        'networkError'.tr(),
        'passwordSaveFailed'.tr(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const int minPwdChars = 8;
    const int maxPwdChars = 50;
    String minChars = 'minChars'.tr();
    minChars = minChars.replaceFirst('{n}', minPwdChars.toString());
    String maxChars = 'minChars'.tr();
    maxChars = maxChars.replaceFirst('{n}', maxPwdChars.toString());

    return Scaffold(
      appBar: AppBar(
        title: Text('setupPassword'.tr()),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Text('requestApproved2'.tr()),
              FormBuilder(
                key: _formKey,
                autovalidateMode: AutovalidateMode.disabled,
                child: Column(
                  children: <Widget>[
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
                    FormBuilderTextField(
                      name: 'password',
                      obscureText: true,
                      enableSuggestions: false,
                      autocorrect: false,
                      decoration: InputDecoration(
                        labelText: 'password'.tr(),
                      ),
                      // onChanged: _onChanged,
                      // valueTransformer: (text) => num.tryParse(text),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        FormBuilderValidators.minLength(minPwdChars,
                            errorText: minChars),
                        FormBuilderValidators.maxLength(maxPwdChars,
                            errorText: maxChars)
                        // FormBuilderValidators.max(context, 50),
                      ]),
                    ),
                    FormBuilderTextField(
                      name: 'verify',
                      obscureText: true,
                      enableSuggestions: false,
                      autocorrect: false,
                      decoration: InputDecoration(
                        labelText: 'verifyPassword'.tr(),
                      ),
                      // onChanged: _onChanged,
                      // valueTransformer: (text) => num.tryParse(text),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        (val) {
                          if (val !=
                              _formKey
                                  .currentState?.fields['password']?.value) {
                            return 'passwordMismatch'.tr();
                          }
                          return null;
                        }
                      ]),
                    ),
                    FormBuilderCheckbox(
                      name: 'accept_terms',
                      initialValue: false,
                      // onChanged: _onChanged,
                      title: RichText(
                        text: TextSpan(
                          children: <TextSpan>[
                            TextSpan(
                              text: 'clickToAcceptTc'.tr(),
                              style: TextStyle(color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                      validator: FormBuilderValidators.equal(
                        true,
                        errorText: 'mustAcceptTnc'.tr(),
                      ),
                    ),
                  ],
                ),
              ),
              Center(
                child: RichText(
                  text: TextSpan(
                    text: 'termsAndConditions'.tr(),
                    recognizer: TapGestureRecognizer()..onTap = _onTermsTapped,
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Expanded(
                    child: MaterialButton(
                      color: Theme.of(context).accentColor,
                      child: Text(
                        'submit'.tr(),
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () async {
                        _formKey.currentState?.save();
                        if (_formKey.currentState!.validate()) {
                          String password =
                              _formKey.currentState!.value['password'];
                          await _savePassword(password);
                        }
                      },
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: MaterialButton(
                      color: Theme.of(context).accentColor,
                      child: Text(
                        'reset'.tr(),
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () {
                        _formKey.currentState!.reset();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
