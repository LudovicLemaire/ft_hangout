import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:globy/src/contact/contact_add_view.dart';
import 'package:globy/src/contact/contact_edit_view.dart';
import 'package:globy/src/contact/contact_list_view.dart';
import 'package:globy/src/contact/contact_messages_view.dart';
import 'package:globy/src/database/database.dart';

import 'settings/settings_controller.dart';
import 'settings/settings_view.dart';

import 'dart:async';

import 'package:telephony/telephony.dart';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// The Widget that configures your application.
class MyApp extends StatefulWidget {
  final SettingsController settingsController;

  const MyApp({
    super.key,
    required this.settingsController,
  });

  @override
  State<MyApp> createState() => _MyAppState();
  // ignore: library_private_types_in_public_api
  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Timer? timer;
  bool receiveSmsSet = false;
  final Telephony telephony = Telephony.instance;
  static const platform = MethodChannel('samples.flutter.dev/main_channel');
  DateTime date = DateTime.now();
  ValueNotifier<String> stateNotifier = ValueNotifier<String>("RESUMED");
  late Null Function() stateNotifierListener;
  bool isFirstInit = true;
  final GlobalKey<ScaffoldMessengerState> snackbarKey =
      GlobalKey<ScaffoldMessengerState>();

  ValueNotifier<bool> cheatNotifier = ValueNotifier<bool>(true);
  late Null Function() cheatNotifierListener;
  ValueNotifier<Message> messageNotifier = ValueNotifier<Message>(const Message(
      content: '', date: 0, type: SmsType.MESSAGE_TYPE_INBOX, phoneNumber: ''));

  @override
  void initState() {
    timer = Timer.periodic(
        const Duration(seconds: 1), (Timer t) => initReceiveSms());
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    timer?.cancel();
    stateNotifier.removeListener(stateNotifierListener);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void initReceiveSms() async {
    if (receiveSmsSet == false) {
      if (await platform.invokeMethod('can_start_receive_sms')) {
        telephony.listenIncomingSms(
            onNewMessage: (SmsMessage msg) async {
              if (msg.address != null && msg.body != null && msg.date != null) {
                messageNotifier.value = Message(
                    phoneNumber: msg.address!,
                    content: msg.body!,
                    date: msg.date!,
                    type: SmsType.MESSAGE_TYPE_INBOX,
                    serviceCenterAddress: msg.serviceCenterAddress,
                    status: msg.status);
                Contact currContact =
                    Contact(firstName: msg.address!, phone: msg.address!);
                if (await checkContactExistAlreadyDb(
                        await database, currContact) ==
                    false) {
                  late bool? res;
                  if (currContact.phone.length == 10 &&
                      currContact.phone.startsWith('0')) {
                    Contact nContact = Contact(
                        firstName: msg.address!,
                        phone: '+33${currContact.phone.substring(1)}');
                    res = await insertContactDb(await database, nContact);
                  } else {
                    res = await insertContactDb(await database, currContact);
                  }
                  if (res == true) {
                    final SnackBar snackBar = SnackBar(
                      content: Text(
                          '${currContact.firstName} ${_locale.countryCode == 'FR' ? 'a été créé' : 'contact has been created'}'),
                    );
                    snackbarKey.currentState?.showSnackBar(snackBar);
                    cheatNotifier.value = !cheatNotifier.value;
                  }
                }
              }
            },
            listenInBackground: false);
        receiveSmsSet = true;
        timer?.cancel();
      }
    }
  }

  late Future<Database> database;
  static void _createDb(Database db) {
    db.execute(
        'CREATE TABLE contacts(id INTEGER PRIMARY KEY AUTOINCREMENT, firstName TEXT NOT NULL, lastName TEXT, address TEXT, alias TEXT, phone TEXT NOT NULL)');
  }

  void initDatabase() async {
    // Future<void> deleteDatabase(String path) =>
    //     databaseFactory.deleteDatabase(path);
    // await deleteDatabase('globy_database.db');

    final db = openDatabase(
      // Set the path to the database. Note: Using the `join` function from the
      // `path` package is best practice to ensure the path is correctly
      // constructed for each platform.
      join(await getDatabasesPath(), 'globy_database.db'),
      // When the database is first created, create a table to store dogs.
      onCreate: (db, version) => _createDb(db),
      // Set the version. This executes the onCreate function and provides a
      // path to perform database upgrades and downgrades.
      version: 1,
    );
    setState(() {
      database = db;
    });
  }

  Locale _locale = Locale(
      Platform.localeName.split('_')[0], Platform.localeName.split('_')[1]);

  MaterialColor _headerColor = Colors.blue;

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  void setHeaderColor(MaterialColor headerColor) {
    setState(() {
      _headerColor = headerColor;
    });
  }

  Locale getLocale() {
    return _locale;
  }

  MaterialColor getHeaderColor() {
    return _headerColor;
  }

  Future<Database> getDatabase() {
    return database;
  }

  Telephony getTelephony() {
    return telephony;
  }

  ValueNotifier<Message> getMessageNotifier() {
    return messageNotifier;
  }

  ValueNotifier<bool> getCheatNotifier() {
    return cheatNotifier;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        stateNotifier.value = "RESUMED";
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        stateNotifier.value = "PAUSED";
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isFirstInit) {
      initDatabase();

      stateNotifierListener = () {
        if (stateNotifier.value == "RESUMED") {
          final SnackBar snackBar = SnackBar(
            content: Text(date.toLocal().toString()),
          );
          snackbarKey.currentState?.showSnackBar(snackBar);
        } else {
          date = DateTime.now();
        }
      };
      stateNotifier.addListener(stateNotifierListener);
      isFirstInit = false;
    }

    // Glue the SettingsController to the MaterialApp.
    //
    // The ListenableBuilder Widget listens to the SettingsController for changes.
    // Whenever the user updates their settings, the MaterialApp is rebuilt.
    return ListenableBuilder(
      listenable: widget.settingsController,
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          // Providing a restorationScopeId allows the Navigator built by the
          // MaterialApp to restore the navigation stack when a user leaves and
          // returns to the app after it has been killed while running in the
          // background.
          restorationScopeId: 'app',

          // Provide the generated AppLocalizations to the MaterialApp. This
          // allows descendant Widgets to display the correct translations
          // depending on the user's locale.
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', 'US'),
            Locale('fr', 'FR'),
          ],
          locale: _locale,

          // Use AppLocalizations to configure the correct application title
          // depending on the user's locale.
          //
          // The appTitle is defined in .arb files found in the localization
          // directory.
          onGenerateTitle: (BuildContext context) =>
              AppLocalizations.of(context)!.appTitle,

          // Define a light and dark color theme. Then, read the user's
          // preferred ThemeMode (light, dark, or system default) from the
          // SettingsController to display the correct theme.
          theme: ThemeData(
            useMaterial3: false,
            primarySwatch: _headerColor,
          ),
          darkTheme: ThemeData.dark(useMaterial3: false),
          themeMode: widget.settingsController.themeMode,

          scaffoldMessengerKey: snackbarKey,

          // Define a function to handle named routes in order to support
          // Flutter web url navigation and deep linking.
          onGenerateRoute: (RouteSettings routeSettings) {
            return MaterialPageRoute<void>(
              settings: routeSettings,
              builder: (BuildContext context) {
                switch (routeSettings.name) {
                  case SettingsView.routeName:
                    return SettingsView(controller: widget.settingsController);
                  case ContactAddView.routeName:
                    return const ContactAddView();
                  case ContactEditView.routeName:
                    return const ContactEditView();
                  case ContactMessagesView.routeName:
                    return const ContactMessagesView();
                  case ContactListView.routeName:
                  default:
                    return const ContactListView();
                }
              },
            );
          },
        );
      },
    );
  }
}
