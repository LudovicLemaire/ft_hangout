import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../database/database.dart';

/// Displays detailed information about a SampleItem.
class ContactEditView extends StatefulWidget {
  const ContactEditView({super.key});

  static const routeName = '/contact_edit';

  @override
  State<ContactEditView> createState() => _ContactEditViewState();
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

Future<Contact> getContact(BuildContext context, int contactId) async {
  Contact? contactList = await getContactInfo(context, contactId);

  return contactList!;
}

class _ContactEditViewState extends State<ContactEditView> {
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
        id: contact!.id,
        firstName: firstNameController.text,
        lastName: lastNameController.text,
        phone: phoneController.text,
        address: addressController.text,
        alias: aliasController.text);

    if (tmpFirstNameError == null && tmpPhoneError == null) {
      bool? resultInsert = await editContact(context, newContact);
      if (resultInsert == true) {
        return true;
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
    final args = (ModalRoute.of(context)?.settings.arguments ??
        <String, dynamic>{}) as Map;
    final int contactId = args['contactId'];

    return FutureBuilder<Contact>(
      future: getContact(context, contactId),
      builder: (BuildContext context, AsyncSnapshot<Contact> snapshot) {
        if (!snapshot.hasData) {
          // while data is loading:
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else {
          // data loaded:
          final data = snapshot.data;
          contact = data;
          if (data == null) {
            return Text(
                '${AppLocalizations.of(context)!.failedGetContact} $contactId');
          }
          firstNameController.value = TextEditingValue(
              text: contact!.firstName.isEmpty ? '' : contact!.firstName);
          if (contact!.lastName != null && contact!.lastName!.isNotEmpty) {
            lastNameController.value =
                TextEditingValue(text: contact!.lastName!);
          }
          if (contact!.alias != null && contact!.alias!.isNotEmpty) {
            aliasController.value = TextEditingValue(text: contact!.alias!);
          }
          phoneController.value = TextEditingValue(
              text: contact!.phone.isEmpty ? '' : contact!.phone);
          if (contact!.address != null && contact!.address!.isNotEmpty) {
            addressController.value = TextEditingValue(text: contact!.address!);
          }
          return Scaffold(
              appBar: AppBar(
                title: Text(AppLocalizations.of(context)!.editContact),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.save),
                    onPressed: () async {
                      if (await saveContact(context) == true) {
                        if (context.mounted) {
                          Navigator.pop(context);
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
                        labelText:
                            AppLocalizations.of(context)!.lastNameContact,
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
                        labelText:
                            '${AppLocalizations.of(context)!.phoneContact}*',
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
      },
    );
  }
}
