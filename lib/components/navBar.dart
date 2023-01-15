import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sqflite/sqflite.dart';
import '../include.dart';
import 'dart:developer' as developer;
import 'package:path/path.dart' as Path;

import '../constants.dart' as Constants;
import '../globals.dart' as Globals;
import '../ajax.dart' as Ajax;
import '../utils.dart' as Utils;

class NavBar extends StatelessWidget {
  // const NavBar({Key? key}) : super(key: key);
  static Page _currentSelected = Page.none;

  Widget buildHeader() {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    assert(Globals.curTenantJson != null);
    String name = Globals.curTenantJson?['name'] ?? '';
    // String name = '陳大文';
    String email = Globals.curTenantJson?['mobile'] ??
        Globals.curTenantJson?['email'] ??
        '';
    // String email = '9876-5432';

    return UserAccountsDrawerHeader(
      margin: const EdgeInsets.all(0),
      accountName: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              name,
              overflow: TextOverflow.ellipsis, // ...
              style: TextStyle(fontSize: 18.0),
            ),
          ),
          Text(
            Globals.appVersion != null ? 'v${Globals.appVersion!}' : '',
            style: TextStyle(fontSize: 12.0),
          ),
        ],
      ),
      accountEmail: Text(
        email,
        style: TextStyle(fontSize: 18.0),
      ),
      currentAccountPictureSize: const Size.square(58.0),
      currentAccountPicture: CircleAvatar(
        child: ClipOval(
          child: Image(
            image: AssetImage('assets/images/generic_user_icon.png'),
            // width: 48.0, // 72.0,
            // height: 48.0, // 72.0,
            fit: BoxFit.cover,
          ),
        ),
      ),
      decoration: BoxDecoration(
        color: Globals.primaryColor,
      ),
      onDetailsPressed: () {
        developer.log(StackTrace.current.toString().split('\n')[0]);

        // TODO When user details pressed...
      },
    );
  } // buildHeader()

  Widget buildAnMenuItem({
    required Page page,
    required String text,
    required IconData icon,
    VoidCallback? onClicked,
  }) {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    Color color = Colors.white;
    final hoverColor = Colors.white70;

    bool isSelected = _currentSelected == page;

    return ListTile(
      selected: isSelected,
      selectedTileColor: Colors.white30,
      leading: Icon(icon, color: color),
      title: Text(text, style: TextStyle(color: color, fontSize: 18.0)),
      hoverColor: hoverColor,
      onTap: onClicked,
    );
  } // buildAnMenuItem()

  // When an menu item clicked
  void navigateItem(BuildContext context, Page page) {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    // Let parent page close the drawer
    // Navigator.of(context).pop();

    _currentSelected = page;

    switch (page) {
      case Page.home:
        Navigator.of(context).pushNamedAndRemoveUntil(
            '/home',
            (route) =>
                false); //.pushReplacementNamed('/home', arguments: null);
        break;
      case Page.tenantQrcode:
        Navigator.of(context).pushNamed('/tenantQrcode', arguments: null);
        break;
      case Page.notices:
        // Navigator.of(context).pushReplacement(
        //   MaterialPageRoute(
        //     builder: (context) => NoticesPage(),
        //   ),
        // );
        Navigator.of(context).popAndPushNamed('/notices', arguments: null);
        break;
      case Page.amenities:
        Navigator.of(context).popAndPushNamed('/amenities', arguments: null);
        break;
      case Page.marketplace:
        Navigator.of(context).popAndPushNamed('/marketplaces', arguments: null);
        break;
      case Page.notification:
        Navigator.of(context)
            .popAndPushNamed('/notifications', arguments: null);
        break;
      case Page.about:
        Navigator.of(context).popAndPushNamed('/about', arguments: null);
        break;
      case Page.settings:
        Navigator.of(context).pushNamed('/settings', arguments: null);
        break;
      case Page.signOut:
        break;
      default:
        throw 'Unhandled page: $page';
    }
  } // navigateItem()

  void onSignout(BuildContext context) async {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    bool rst = await Utils.showConfirmDialog(
      context,
      'navbarSignout'.tr(),
      'sureSignout'.tr(),
    );

    if (rst) {
      // Call backend to sign out
      await Ajax.tenantLogout(tenantId: Globals.curTenantJson?['id']);

      // Clean the shared preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      Globals.accessToken = null;
      Globals.curTenantJson = null;
      await prefs.remove('tenantJson');
      await prefs.remove('loginPassword');

      // Delete the local database coz other tenant login nexttime.
      final dbPath =
          Path.join(await getDatabasesPath(), Constants.LOCAL_DB_FILENAME);
      await deleteDatabase(dbPath);
      await Utils.openLocalDatabase(dbPath);

      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  } // onSignout()

  @override
  Widget build(BuildContext context) {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    return Container(
      width: 250,
      child: Drawer(
        child: Material(
          color: Globals.primaryColor,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              buildHeader(),
              buildAnMenuItem(
                page: Page.home,
                icon: Icons.home,
                text: 'navbarHome'.tr(),
                onClicked: () => navigateItem(context, Page.home),
              ),
              buildAnMenuItem(
                page: Page.tenantQrcode,
                icon: Icons.qr_code,
                text: 'navbarTenantQrcode'.tr(),
                onClicked: () => navigateItem(context, Page.tenantQrcode),
              ),
              buildAnMenuItem(
                page: Page.notices,
                icon: Icons.picture_as_pdf,
                text: 'navbarNotice'.tr(),
                onClicked: () => navigateItem(context, Page.notices),
              ),
              buildAnMenuItem(
                page: Page.amenities,
                icon: Icons.sports_tennis,
                text: 'navbarAmenityBooking'.tr(),
                onClicked: () => navigateItem(context, Page.amenities),
              ),
              buildAnMenuItem(
                page: Page.marketplace,
                icon: Icons.storefront,
                text: 'navbarMarketplace'.tr(),
                onClicked: () => navigateItem(context, Page.marketplace),
              ),
              /*
              _buildMenuItem(
                page: Page.notification,
                icon: Icons.notifications,
                text: 'Notification',
                onClicked: () => _navigateItem(context, Page.notification),
              ),
              */
              Divider(color: Colors.white70),
              /*
              _buildMenuItem(
                page: Page.about,
                icon: Icons.phonelink,
                text: 'About',
                onClicked: () => _navigateItem(context, Page.about),
              ),
              _buildMenuItem(
                page: Page.settings,
                icon: Icons.settings,
                text: 'Settings',
                onClicked: () => _navigateItem(context, Page.settings),
              ),
              */
              buildAnMenuItem(
                page: Page.signOut,
                icon: Icons.logout,
                text: 'navbarSignout'.tr(),
                onClicked: () => onSignout(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum Page {
  none,
  home,
  tenantQrcode,
  notices,
  amenities,
  marketplace,
  notification,
  about,
  settings,
  signOut,
}
