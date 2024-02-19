import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:globy/src/app.dart';
import 'package:globy/src/contact/contact_add_view.dart';
import 'package:globy/src/database/database.dart';
import 'package:globy/src/contact/contact_messages_view.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../settings/settings_view.dart';

/// Displays a list of SampleItems.
class ContactListView extends StatefulWidget {
  const ContactListView({
    super.key,
  });

  static const routeName = '/';

  @override
  State<ContactListView> createState() => _ContactListViewState();
}

Future<List<Contact>> getContact(context) async {
  List<Contact>? contactList = await getContactsMini(context);
  contactList ??= List<Contact>.empty();
  return contactList;
}

class _ContactListViewState extends State<ContactListView>
    with WidgetsBindingObserver {
  static const platform = MethodChannel('samples.flutter.dev/main_channel');

  late ValueNotifier<bool> cheatNotifier;
  late Null Function() cheatNotifierListener;

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      cheatNotifier =
          MyApp.of(context)?.getCheatNotifier() as ValueNotifier<bool>;
      cheatNotifierListener = () {
        setState(() {});
      };
      cheatNotifier.addListener(cheatNotifierListener);
    });

    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    cheatNotifier.removeListener(cheatNotifierListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Contact>>(
      future: getContact(context),
      builder: (BuildContext context, AsyncSnapshot<List<Contact>> snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else {
          // data loaded:
          final data = snapshot.data;
          return Scaffold(
              appBar: AppBar(
                title: Text(
                    "${AppLocalizations.of(context)!.listViewTitle} (${data!.length})"),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.person_add),
                    onPressed: () {
                      Navigator.restorablePushNamed(
                          context, ContactAddView.routeName);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () {
                      Navigator.restorablePushNamed(
                          context, SettingsView.routeName);
                    },
                  ),
                ],
              ),
              body: ListView.builder(
                restorationId: 'ContactListView',
                itemCount: data.length,
                itemBuilder: (BuildContext context, int index) {
                  final item = data[index];
                  print(item.toString());
                  return Card(
                      child: ListTile(
                          title: Text(
                              '${item.firstName} ${item.lastName ?? ''} ${item.alias != null && item.alias!.isNotEmpty ? '(${item.alias})' : ''}'),
                          leading: (item.imagePath != null &&
                                  item.imagePath!.isEmpty == false)
                              ? CircleAvatar(
                                  backgroundImage:
                                      FileImage(File(item.imagePath!)),
                                  backgroundColor: Colors.white,
                                )
                              : CircleAvatar(
                                  foregroundImage: AssetImage(
                                      'assets/images/dino_${(item.id! % 18) + 1}.png'),
                                  backgroundColor: Colors.white,
                                ),
                          onTap: () async {
                            if (await platform.invokeMethod('check_permission',
                                <String, dynamic>{"type": 'all_sms'})) {
                              if (context.mounted) {
                                Navigator.pushNamed(
                                        context, ContactMessagesView.routeName,
                                        arguments: {'contactId': item.id})
                                    .then((_) => setState(() {}));
                              }
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(
                                      '${AppLocalizations.of(context)!.noPermission} [READ_SMS].'),
                                ));
                              }
                            }
                          }));
                },
              ));
        }
      },
    );
  }
}
