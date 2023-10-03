import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:globy/src/contact/contact_list_view.dart';

import '../database/database.dart';

/// Displays detailed information about a SampleItem.
class ContactAddView extends StatefulWidget {
  const ContactAddView({super.key});

  static const routeName = '/contact_add';

  @override
  State<ContactAddView> createState() => _ContactAddViewState();
}

String? validateName(BuildContext context, String value) {
  if (value.isEmpty) {
    return AppLocalizations.of(context)!.validateIsEmpty;
  } else if (value.length < 2) {
    return '${AppLocalizations.of(context)!.validateTooShort} 2';
  } else {
    return null;
  }
}

String? validateMobile(BuildContext context, String value) {
  String patttern = r'(^(?:[+])?[0-9]{10,12}$)';
  RegExp regExp = RegExp(patttern);
  if (value.isEmpty) {
    return AppLocalizations.of(context)!.validateIsEmpty;
  } else if (!regExp.hasMatch(value)) {
    return AppLocalizations.of(context)!.validateInvalidePhoneNumber;
  }
  return null;
}

class _ContactAddViewState extends State<ContactAddView> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final aliasController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  late Contact? contact;

  String? firstNameError;
  String? phoneError;

  Future<bool> saveContact(BuildContext context) async {
    String? tmpFirstNameError = validateName(context, firstNameController.text);
    String? tmpPhoneError = validateMobile(context, phoneController.text);

    setState(() {
      firstNameError = tmpFirstNameError;
      phoneError = tmpPhoneError;
    });

    Contact newContact = Contact(
        firstName: firstNameController.text,
        lastName: lastNameController.text,
        phone: phoneController.text,
        address: addressController.text,
        alias: aliasController.text);

    if (tmpFirstNameError == null && tmpPhoneError == null) {
      bool? existAlready = await checkContactExistAlready(context, newContact);
      if (existAlready == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!.failedConnectDatabase),
          ));
          return false;
        }
      } else if (existAlready == true) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text(AppLocalizations.of(context)!.failedAlreadyUsedNumber),
          ));
          return false;
        }
      } else {
        if (context.mounted) {
          bool? resultInsert = await insertContact(context, newContact);
          if (resultInsert == true) {
            return true;
          }
        }
      }
    }
    return false;
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    aliasController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.addContact),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () async {
                if (await saveContact(context) == true) {
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                        context, ContactListView.routeName, (r) => false);
                  }
                }
              },
            ),
          ],
        ),
        body: Container(
            padding: const EdgeInsets.all(15.0),
            child: SingleChildScrollView(
                child: Column(children: <Widget>[
              const Padding(padding: EdgeInsets.all(5.0)),
              TextField(
                controller: firstNameController,
                decoration: InputDecoration(
                  labelText:
                      '${AppLocalizations.of(context)!.firstNameContact}*',
                  errorText: firstNameError,
                ),
              ),
              const Padding(padding: EdgeInsets.all(5.0)),
              TextField(
                controller: lastNameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.lastNameContact,
                ),
              ),
              const Padding(padding: EdgeInsets.all(5.0)),
              TextField(
                controller: aliasController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.aliasContact,
                ),
              ),
              const Padding(padding: EdgeInsets.all(5.0)),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: '${AppLocalizations.of(context)!.phoneContact}*',
                  errorText: phoneError,
                ),
              ),
              const Padding(padding: EdgeInsets.all(5.0)),
              TextField(
                controller: addressController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.addressContact,
                ),
              )
            ]))));
  }
}
