import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:globy/src/app.dart';
import 'package:globy/src/contact/contact_edit_view.dart';
import 'package:globy/src/contact/contact_list_view.dart';
import 'dart:async';
import 'package:telephony/telephony.dart';

import '../database/database.dart';

class Message {
  final String phoneNumber;
  final String content;
  final int date;
  final SmsType type;
  final String? serviceCenterAddress;
  final SmsStatus? status;

  const Message(
      {required this.phoneNumber,
      required this.content,
      required this.date,
      required this.type,
      this.serviceCenterAddress,
      this.status});

  // Convert a Message into a Map. The keys must correspond to the names of the
  // columns in the database.
  Map<String, dynamic> toMap() {
    return {
      'phoneNumber': phoneNumber,
      'content': content,
      'date': date,
      'type': type,
      'serviceCenterAddress': serviceCenterAddress,
      'status': status
    };
  }

  // Implement toString to make it easier to see information about
  // each message received when using the print statement.
  @override
  String toString() {
    return 'Message{phoneNumber: $phoneNumber, content: $content, date: $date, type: $type, serviceCenterAddress: $serviceCenterAddress, status: $status}';
  }
}

class ContactMessagesView extends StatefulWidget {
  const ContactMessagesView({super.key});

  static const routeName = '/contact_messages';

  @override
  State<ContactMessagesView> createState() => _ContactMessagesViewState();
}

Widget cancelButton(BuildContext context) {
  return TextButton(
    child: Text(AppLocalizations.of(context)!.cancel),
    onPressed: () {
      Navigator.of(context).pop();
    },
  );
}

Widget continueButton(BuildContext context, Contact contact) {
  return TextButton(
    child: Text(AppLocalizations.of(context)!.delete),
    onPressed: () async {
      if (await deleteContact(context, contact) == true) {
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(
              context, ContactListView.routeName, (r) => false);
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!.failedConnectDatabase),
          ));
        }
      }
    },
  );
}

AlertDialog alertDialog(BuildContext context, Contact? contact) {
  return AlertDialog(
    content: Text(
        "${AppLocalizations.of(context)!.confirmDelete} ${'${contact!.firstName} ${contact.lastName ?? ''} ${contact.alias != null && contact.alias!.isNotEmpty ? '(${contact.alias})' : ''}'} ?"),
    actions: [
      cancelButton(context),
      continueButton(context, contact),
    ],
  );
}

class _ContactMessagesViewState extends State<ContactMessagesView>
    with WidgetsBindingObserver {
  final messageController = TextEditingController();
  late Contact? contact;
  late Telephony? telephony;
  late ValueNotifier<Message> messageNotifier;
  late Null Function() messageNotifierListener;
  static const platform = MethodChannel('samples.flutter.dev/main_channel');
  late List<Message> allMsg = [];
  bool isFirstLoading = true;
  final ScrollController scrollControllerListView = ScrollController();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _getRequiredDatas(context, 1, true);
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      telephony = MyApp.of(context)?.getTelephony();
      messageNotifier =
          MyApp.of(context)?.getMessageNotifier() as ValueNotifier<Message>;
      messageNotifierListener = () {
        if (messageNotifier.value.phoneNumber == contact?.phone) {
          setState(() {
            allMsg = [...allMsg, messageNotifier.value];
          });

          scrollControllerListView
              .jumpTo(scrollControllerListView.position.maxScrollExtent + 75);
        }
      };
      messageNotifier.addListener(messageNotifierListener);
    });

    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    messageNotifier.removeListener(messageNotifierListener);
    messageController.dispose();
    super.dispose();
  }

  String _getFormatedDate(int dateFromEpoch) {
    DateTime dt =
        DateTime.fromMicrosecondsSinceEpoch(dateFromEpoch * 1000).toLocal();
    String formatedDate =
        '${dt.hour}:${dt.minute}   ${dt.day}/${dt.month}/${dt.year.toString().substring(2)}';
    return formatedDate;
  }

  double _getWidthFactor(Message msg) {
    double r = msg.content.length.toDouble() / 50 + 0.25;
    if (msg.type == SmsType.MESSAGE_TYPE_INBOX) {
      r += 0.075;
    }
    if (r > 0.85) {
      r = 0.85;
    }
    return r;
  }

  Future<void> _sendSms() async {
    try {
      if (messageController.text.isNotEmpty) {
        if (await platform.invokeMethod(
            'check_permission', <String, dynamic>{"type": 'send_sms'})) {
          final String result = await platform.invokeMethod(
              'send_sms', <String, dynamic>{
            "phone": contact!.phone,
            "msg": messageController.text
          });
          if (result.startsWith("SMS Sent at")) {
            setState(() {
              allMsg = [
                ...allMsg,
                Message(
                    phoneNumber: contact!.phone,
                    content: messageController.text,
                    date: DateTime.now().millisecondsSinceEpoch,
                    type: SmsType.MESSAGE_TYPE_SENT)
              ];
            });
            messageController.text = '';
            scrollControllerListView
                .jumpTo(scrollControllerListView.position.maxScrollExtent + 75);
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  '${AppLocalizations.of(context)!.noPermission} [SEND_SMS].'),
            ));
          }
        }
      }
    } on PlatformException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
        ));
      }
    }
  }

  Future<void> _phoneCall() async {
    try {
      if (await platform.invokeMethod(
          'check_permission', <String, dynamic>{"type": 'call_phone'})) {
        await platform.invokeMethod(
            'call_phone', <String, dynamic>{"phone": contact!.phone});
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                '${AppLocalizations.of(context)!.noPermission} [CALL_PHONE].'),
          ));
        }
      }
    } on PlatformException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
        ));
      }
    }
  }

  Future<Contact> _getContact(BuildContext context, int contactId) async {
    Contact? currContact = await getContactInfo(context, contactId);
    currContact =
        currContact ?? const Contact(firstName: '', lastName: '', phone: '');
    return currContact;
  }

  Future<List<SmsMessage>?> _getInboxMessages() async {
    List<SmsMessage> msg = [];
    if (telephony != null && contact?.phone != null) {
      msg = await telephony!.getInboxSms(
        columns: [
          SmsColumn.TYPE,
          SmsColumn.ADDRESS,
          SmsColumn.BODY,
          SmsColumn.DATE,
          SmsColumn.TYPE
        ],
        filter: SmsFilter.where(SmsColumn.ADDRESS).equals(contact!.phone),
      );

      return msg;
    }
    return null;
  }

  Future<List<SmsMessage>?> _getSentMessages() async {
    List<SmsMessage> msg = [];
    if (telephony != null && contact?.phone != null) {
      msg = await telephony!.getSentSms(
        columns: [
          SmsColumn.TYPE,
          SmsColumn.ADDRESS,
          SmsColumn.BODY,
          SmsColumn.DATE,
          SmsColumn.TYPE
        ],
        filter: SmsFilter.where(SmsColumn.ADDRESS).equals(contact!.phone),
      );

      return msg;
    }
    return null;
  }

  Future<bool> _getRequiredDatas(
      BuildContext context, int contactId, bool specialRequest) async {
    if (isFirstLoading == false && specialRequest == false) {
      return true;
    }
    if (await platform.invokeMethod(
        'check_permission', <String, dynamic>{"type": 'read_sms'})) {
      if (context.mounted) {
        if (specialRequest == false) {
          contact = await _getContact(context, contactId);
        }
        List<SmsMessage>? inboxMessages = await _getInboxMessages();
        List<SmsMessage>? sentMessages = await _getSentMessages();
        if (inboxMessages != null && sentMessages != null) {
          allMsg = [];
          List<SmsMessage>? allMessages = inboxMessages + sentMessages;
          allMessages.sort((a, b) => a.date!.compareTo(b.date!));
          for (SmsMessage msg in allMessages) {
            allMsg.add(Message(
                phoneNumber: msg.address!,
                content: msg.body!,
                date: msg.date!,
                type: msg.type!));
          }
          if (specialRequest == true) {
            setState(() {
              allMsg = [...allMsg];
            });
            scrollControllerListView
                .jumpTo(scrollControllerListView.position.maxScrollExtent + 75);
          }
        } else {
          return false;
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                '${AppLocalizations.of(context)!.noPermission} [READ_SMS].'),
          ));
        }
        return false;
      }
    } else {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final args = (ModalRoute.of(context)?.settings.arguments ??
        <String, dynamic>{}) as Map;
    final int contactId = args['contactId'];

    return FutureBuilder<bool>(
      future: _getRequiredDatas(context, contactId, false),
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (!snapshot.hasData) {
          // while data is loading:
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else {
          // data loaded:
          final data = snapshot.data;
          if (isFirstLoading == true) {
            SchedulerBinding.instance.addPostFrameCallback((_) {
              scrollControllerListView.jumpTo(
                  scrollControllerListView.position.maxScrollExtent * 1.25);
            });
            isFirstLoading = false;
          }
          if (data == null || data == false) {
            return Scaffold(
                appBar: AppBar(title: const Text('')),
                body: Text(
                    '${AppLocalizations.of(context)!.failedGetContact} $contactId'));
          }
          return Scaffold(
            appBar: AppBar(
              title: Text(
                  '${contact!.firstName} ${contact!.lastName ?? ''} ${contact!.alias != null && contact!.alias!.isNotEmpty ? '(${contact!.alias})' : ''}'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_forever),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return alertDialog(context, contact);
                      },
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.pushNamed(context, ContactEditView.routeName,
                            arguments: {'contactId': contact!.id})
                        .then((_) => setState(() {}));
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.phone),
                  onPressed: () {
                    _phoneCall();
                    // telephony!.openDialer(contact!.phone);
                  },
                ),
              ],
            ),
            body: Column(children: [
              Flexible(
                  flex: 0,
                  child: Container(
                      padding: const EdgeInsets.fromLTRB(0, 5, 0, 0),
                      child: Text(contact!.phone,
                          style: const TextStyle(fontSize: 12)))),
              Expanded(
                  child: ListView.builder(
                restorationId: 'ContactMessagesView',
                itemCount: allMsg.length,
                controller: scrollControllerListView,
                itemBuilder: (BuildContext context, int index) {
                  final item = allMsg[index];
                  return Column(
                      crossAxisAlignment:
                          item.type == SmsType.MESSAGE_TYPE_INBOX
                              ? CrossAxisAlignment.start
                              : CrossAxisAlignment.end,
                      children: [
                        FractionallySizedBox(
                            widthFactor: _getWidthFactor(item),
                            child: Card(
                              color: item.type == SmsType.MESSAGE_TYPE_INBOX
                                  ? Colors.green
                                  : MyApp.of(context)?.getHeaderColor(),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(2.0),
                              ),
                              elevation: 2,
                              child: ListTile(
                                title: Text(
                                  item.content,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                leading: item.type == SmsType.MESSAGE_TYPE_INBOX
                                    ? CircleAvatar(
                                        foregroundImage: AssetImage(
                                            'assets/images/dino_${(contact!.id! % 18) + 1}.png'),
                                        backgroundColor: const Color.fromARGB(
                                            255, 255, 255, 255),
                                      )
                                    : null,
                              ),
                            )),
                        Container(
                            padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                            child: Text(
                              _getFormatedDate(item.date),
                              style: const TextStyle(fontSize: 7),
                            ))
                      ]);
                },
              )),
              Expanded(
                flex: 0,
                child: Align(
                    alignment: FractionalOffset.bottomCenter,
                    child: Row(
                      children: [
                        Flexible(
                            child: TextField(
                          controller: messageController,
                          keyboardType: TextInputType.multiline,
                          maxLines: null,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            labelText:
                                AppLocalizations.of(context)!.typeMessage,
                            suffixIcon: TextButton(
                              onPressed: () {
                                _sendSms();
                              },
                              child: const Icon(Icons.send),
                            ),
                          ),
                        )),
                      ],
                    )),
              ),
            ]),
          );
        }
      },
    );
  }
}
