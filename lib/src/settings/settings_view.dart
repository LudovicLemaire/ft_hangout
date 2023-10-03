import 'package:flutter/material.dart';
import 'package:globy/src/app.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:globy/src/contact/contact_list_view.dart';
import 'package:globy/src/database/database.dart';
import 'settings_controller.dart';
import 'package:flutter/services.dart';

/// Displays the various settings that can be customized by the user.
///
/// When a user changes a setting, the SettingsController is updated and
/// Widgets that listen to the SettingsController are rebuilt.
class SettingsView extends StatefulWidget {
  final SettingsController controller;

  const SettingsView({super.key, required this.controller});

  static const routeName = '/settings';

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

typedef MultiUseCallback = void Function(dynamic msg);
typedef CancelListening = void Function();

class _SettingsViewState extends State<SettingsView> {
  static const platform = MethodChannel('samples.flutter.dev/main_channel');
  int _i = 0;

  String _batteryLevel = '';
  String _batteryInfo = 'unknown';

  Future<void> _getBatteryLevel() async {
    String batteryLevel;
    String batteryInfo;
    try {
      final int result = await platform.invokeMethod('get_battery_level');
      batteryLevel = '$result';
      batteryInfo = 'success';
    } on PlatformException catch (e) {
      batteryLevel = "'${e.message}'.";
      batteryInfo = 'failed';
    }

    setState(() {
      _batteryLevel = batteryLevel;
      _batteryInfo = batteryInfo;
    });
  }

  String getEmojiFlag(String country) {
    int flagOffset = 0x1F1E6;
    int asciiOffset = 0x41;

    int firstChar = country.codeUnitAt(0) - asciiOffset + flagOffset;
    int secondChar = country.codeUnitAt(1) - asciiOffset + flagOffset;

    String emoji =
        String.fromCharCode(firstChar) + String.fromCharCode(secondChar);
    return emoji;
  }

  Icon getIconBatery(int batPercent) {
    if (batPercent == 100) {
      return const Icon(Icons.battery_full);
    } else if (batPercent > 90) {
      return const Icon(Icons.battery_6_bar);
    } else if (batPercent > 75) {
      return const Icon(Icons.battery_5_bar);
    } else if (batPercent > 60) {
      return const Icon(Icons.battery_4_bar);
    } else if (batPercent > 45) {
      return const Icon(Icons.battery_3_bar);
    } else if (batPercent > 30) {
      return const Icon(Icons.battery_2_bar);
    } else if (batPercent > 15) {
      return const Icon(Icons.battery_1_bar);
    } else {
      return const Icon(Icons.battery_0_bar);
    }
  }

  Future<void> _sendSms() async {
    try {
      if (await platform.invokeMethod(
          'check_permission', <String, dynamic>{"type": 'send_sms'})) {
        await platform.invokeMethod('send_sms', <String, dynamic>{
          "phone": "+33683357915",
          "msg": "Hello! I'm sent programatically. $_i"
        });
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                '${AppLocalizations.of(context)!.noPermission} [SEND_SMS].'),
          ));
        }
      }
    } on PlatformException catch (e) {
      print(e.toString());
    }
    setState(() {
      _i++;
    });
  }

  @override
  Widget build(BuildContext context) {
    _getBatteryLevel();
    AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    Locale? locale = MyApp.of(context)?.getLocale();
    MaterialColor? headerColor = MyApp.of(context)?.getHeaderColor();
    return Scaffold(
        appBar: AppBar(
          title: Text(appLocalizations.settings),
        ),
        body: Container(
          padding: const EdgeInsets.all(15.0),
          child: SingleChildScrollView(
              child: Column(children: <Widget>[
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              DropdownButton<ThemeMode>(
                value: widget.controller.themeMode,
                onChanged: widget.controller.updateThemeMode,
                items: [
                  DropdownMenuItem(
                    value: ThemeMode.system,
                    child: Text(appLocalizations.systemTheme),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.light,
                    child: Text(appLocalizations.lightTheme),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.dark,
                    child: Text(appLocalizations.darkTheme),
                  )
                ],
              ),
              DropdownButton<Locale>(
                value: locale,
                onChanged: (Locale? newValue) {
                  setState(() {
                    if (newValue != null) {
                      MyApp.of(context)?.setLocale(newValue);
                      locale = newValue;
                    }
                  });
                },
                items: [
                  DropdownMenuItem(
                    value: const Locale('en', 'US'),
                    child: Text('US: ${getEmojiFlag('US')}'),
                  ),
                  DropdownMenuItem(
                    value: const Locale('fr', 'FR'),
                    child: Text('FR: ${getEmojiFlag('FR')}'),
                  ),
                ],
              ),
              DropdownButton<MaterialColor>(
                value: headerColor,
                onChanged: (MaterialColor? newValue) {
                  setState(() {
                    if (newValue != null) {
                      MyApp.of(context)?.setHeaderColor(newValue);
                      headerColor = newValue;
                    }
                  });
                },
                underline: Container(
                  height: 2,
                  color: headerColor,
                ),
                items: [
                  DropdownMenuItem(
                    value: Colors.blue,
                    child: Text(
                      appLocalizations.blue,
                      style: const TextStyle(
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: Colors.red,
                    child: Text(
                      appLocalizations.red,
                      style: const TextStyle(
                        color: Colors.red,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: Colors.green,
                    child: Text(appLocalizations.green,
                        style: const TextStyle(
                          color: Colors.green,
                        )),
                  ),
                  DropdownMenuItem(
                    value: Colors.purple,
                    child: Text(appLocalizations.purple,
                        style: const TextStyle(
                          color: Colors.purple,
                        )),
                  ),
                  DropdownMenuItem(
                    value: Colors.yellow,
                    child: Text(appLocalizations.yellow,
                        style: const TextStyle(
                          color: Colors.yellow,
                        )),
                  ),
                  DropdownMenuItem(
                    value: Colors.pink,
                    child: Text(appLocalizations.pink,
                        style: const TextStyle(
                          color: Colors.pink,
                        )),
                  ),
                  DropdownMenuItem(
                    value: Colors.cyan,
                    child: Text(appLocalizations.cyan,
                        style: const TextStyle(
                          color: Colors.cyan,
                        )),
                  ),
                  DropdownMenuItem(
                    value: Colors.brown,
                    child: Text(appLocalizations.brown,
                        style: const TextStyle(
                          color: Colors.brown,
                        )),
                  ),
                  DropdownMenuItem(
                    value: Colors.indigo,
                    child: Text(appLocalizations.indigo,
                        style: const TextStyle(
                          color: Colors.indigo,
                        )),
                  ),
                ],
              ),
            ]),
            Wrap(
              direction: Axis.horizontal,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Text(_batteryInfo == 'unknown'
                    ? appLocalizations.unknownBatteryLevel
                    : _batteryInfo == 'failed'
                        ? appLocalizations.failedBatteryLevel
                        : "${appLocalizations.batteryLevel} $_batteryLevel%"),
                _batteryInfo == 'unknown' || _batteryInfo == 'failed'
                    ? const Icon(Icons.battery_unknown)
                    : getIconBatery(int.parse(_batteryLevel))
              ],
            ),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              ElevatedButton.icon(
                label: Text(appLocalizations.settingAddMyself),
                onPressed: () async {
                  await addMyself(context);
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                        context, ContactListView.routeName, (r) => false);
                  }
                },
                icon: const Icon(Icons.person),
                style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all(Colors.lightGreen)),
              ),
              ElevatedButton.icon(
                label: Text(appLocalizations.settingAddFakeContacts),
                onPressed: () async {
                  await addFakeContacts(context);
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                        context, ContactListView.routeName, (r) => false);
                  }
                },
                icon: const Icon(Icons.supervisor_account),
                style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all(Colors.lightBlue)),
              ),
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              ElevatedButton.icon(
                label: Text(appLocalizations.settingSendSms),
                onPressed: () async {
                  if (await platform.invokeMethod('check_permission',
                      <String, dynamic>{"type": 'send_sms'})) {
                    await _sendSms();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                          context, ContactListView.routeName, (r) => false);
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            '${AppLocalizations.of(context)!.noPermission} [SEND_SMS].'),
                      ));
                    }
                  }
                },
                icon: const Icon(Icons.priority_high),
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.orange)),
              ),
              ElevatedButton.icon(
                label: Text(appLocalizations.settingDeleteAllContacts),
                onPressed: () async {
                  await truncateContact(context);
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                        context, ContactListView.routeName, (r) => false);
                  }
                },
                icon: const Icon(Icons.report_outlined),
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.red)),
              ),
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              ElevatedButton.icon(
                label: Text(appLocalizations.settingAddContactsFromPhone),
                onPressed: () async {
                  if (await platform.invokeMethod('check_permission',
                      <String, dynamic>{"type": 'contact'})) {
                    final List<Object?> result =
                        await platform.invokeMethod('get_contacts');
                    for (Object? obj in result) {
                      final dataObj = obj.toString().split(',');
                      String phoneNumber = dataObj[2].replaceAll(' ', '');
                      final name = dataObj[1];
                      if (phoneNumber.length == 10 &&
                          phoneNumber.startsWith('0')) {
                        phoneNumber = '+33${phoneNumber.substring(1)}';
                        if (context.mounted) {
                          await insertContactAndCheck(context,
                              Contact(firstName: name, phone: phoneNumber));
                        }
                      } else if (phoneNumber.startsWith('+33')) {
                        if (context.mounted) {
                          await insertContactAndCheck(context,
                              Contact(firstName: name, phone: phoneNumber));
                        }
                      }
                    }
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                          context, ContactListView.routeName, (r) => false);
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            '${AppLocalizations.of(context)!.noPermission} [READ_CONTACTS].'),
                      ));
                    }
                  }
                },
                icon: const Icon(Icons.supervisor_account),
                style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all(Colors.deepPurple)),
              ),
            ]),
          ])),
        ));
  }
}
