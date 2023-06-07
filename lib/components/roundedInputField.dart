import 'package:flutter/material.dart';

import '../globals.dart' as Globals;

class TextFieldContainer extends StatelessWidget {
  final Widget child;

  const TextFieldContainer({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      width: size.width * 0.8,
      decoration: BoxDecoration(
        color: Globals.primaryLightColor,
        borderRadius: BorderRadius.circular(29),
      ),
      child: child,
    );
  }
}

class DropdownContainer extends StatelessWidget {
  final Widget child;

  const DropdownContainer({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      // margin: EdgeInsets.symmetric(vertical: 5),
      margin: EdgeInsets.symmetric(vertical: 5),
      // padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 3),
      width: size.width * 0.8,
      decoration: BoxDecoration(
        color: Globals.primaryLightColor,
        borderRadius: BorderRadius.circular(29),
      ),
      child: child,
    );
  }
}

class RoundedInputField extends StatelessWidget {
  final String hintText;
  final IconData? icon;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  const RoundedInputField({
    Key? key,
    required this.hintText,
    this.initialValue,
    this.icon,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFieldContainer(
      child: TextFormField(
        onChanged: onChanged,
        initialValue: initialValue,
        decoration: InputDecoration(
          icon: Icon(
            icon != null ? icon : Icons.person,
            color: Globals.primaryColor,
          ),
          hintText: hintText,
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class RoundedPasswordField extends StatefulWidget {
  final String hintText;
  final String initialValue;
  final ValueChanged<String>? onChanged;

  const RoundedPasswordField({
    Key? key,
    required this.hintText,
    required this.initialValue,
    this.onChanged,
  }) : super(key: key);

  @override
  _RoundedPasswordFieldState createState() =>
      _RoundedPasswordFieldState(hintText, initialValue, onChanged);
}

class _RoundedPasswordFieldState extends State<RoundedPasswordField> {
  final String hintText;
  final String initialValue;
  final ValueChanged<String>? onChanged;
  bool _passwordVisible = false;

  _RoundedPasswordFieldState(this.hintText, this.initialValue, this.onChanged);

  @override
  Widget build(BuildContext context) {
    return TextFieldContainer(
      child: TextFormField(
        initialValue: initialValue,
        obscureText: !_passwordVisible,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          icon: Icon(
            Icons.lock,
            color: Globals.primaryColor,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _passwordVisible ? Icons.visibility : Icons.visibility_off,
              color: Globals.primaryColor,
            ),
            onPressed: () {
              setState(() {
                _passwordVisible = !_passwordVisible; // show/hide the password
              });
            },
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
