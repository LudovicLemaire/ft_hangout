import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:flutter/material.dart';
import 'package:globy/src/app.dart';
import 'package:sqflite/sqflite.dart';

class Contact {
  final int? id;
  final String firstName;
  final String? lastName;
  final String? address;
  final String? alias;
  final String phone;
  final String? imagePath;

  const Contact(
      {this.id,
      required this.firstName,
      this.lastName,
      this.address,
      this.alias,
      required this.phone,
      this.imagePath});

  // Convert a Contact into a Map. The keys must correspond to the names of the
  // columns in the database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'address': address ?? '',
      'alias': alias ?? '',
      'phone': phone,
      'imagePath': imagePath ?? ''
    };
  }

  // Implement toString to make it easier to see information about
  // each contact when using the print statement.
  @override
  String toString() {
    return 'Contact{id: $id, firstName: $firstName, lastName: $lastName, address: $address, alias: $alias, phone: $phone, imagePath: $imagePath}';
  }
}

Future<bool?> insertContact(BuildContext context, Contact contact) async {
  // Get a reference to the database.
  final db = await MyApp.of(context)?.getDatabase();

  // Insert the Contact into the correct table.
  if (db != null) {
    int result = await db.insert(
      'contacts',
      contact.toMap(),
    );
    if (result > 0) {
      return true;
    } else {
      return false;
    }
  }
  return null;
}

Future<bool?> insertContactAndCheck(
    BuildContext context, Contact contact) async {
  // Get a reference to the database.
  final db = await MyApp.of(context)?.getDatabase();

  // Insert the Contact into the correct table.
  if (db != null) {
    if (context.mounted) {
      final checked = await checkContactExistAlready(context, contact);
      if (checked == false) {
        int result = await db.insert(
          'contacts',
          contact.toMap(),
        );
        if (result > 0) {
          return true;
        } else {
          return false;
        }
      }
    }
  }
  return null;
}

Future<bool?> insertContactDb(Database db, Contact contact) async {
  int result = await db.insert(
    'contacts',
    contact.toMap(),
  );
  if (result > 0) {
    return true;
  } else {
    return false;
  }
}

Future<bool?> editContact(BuildContext context, Contact contact) async {
  // Get a reference to the database.
  final db = await MyApp.of(context)?.getDatabase();

  // Insert the Contact into the correct table.
  if (db != null) {
    int result = await db.update('contacts', contact.toMap(),
        where: 'id = ?', whereArgs: [contact.id]);
    if (result > 0) {
      return true;
    } else {
      return false;
    }
  }
  return null;
}

Future<bool?> checkContactExistAlready(
    BuildContext context, Contact contact) async {
  // Get a reference to the database.
  final db = await MyApp.of(context)?.getDatabase();

  if (db == null) return null;

  // Query the table for all The Contacts.
  final List<Map<String, dynamic>> maps = await db
      .rawQuery("SELECT * FROM contacts WHERE phone='${contact.phone}'");

  if (maps.isEmpty) {
    return false;
  }
  return true;
}

Future<bool?> checkContactExistAlreadyDb(Database db, Contact contact) async {
  final List<Map<String, dynamic>> maps = await db
      .rawQuery("SELECT * FROM contacts WHERE phone='${contact.phone}'");
  if (maps.isEmpty) {
    return false;
  }
  return true;
}

Future<bool?> deleteContact(BuildContext context, Contact contact) async {
  // Get a reference to the database.
  final db = await MyApp.of(context)?.getDatabase();

  if (db != null) {
    int result = await db.delete(
      'contacts',
      where: "id = ?",
      whereArgs: [contact.id],
    );
    if (result > 0) {
      return true;
    } else {
      return false;
    }
  }
  return false;
}

Future<void> truncateContact(BuildContext context) async {
  final db = await MyApp.of(context)?.getDatabase();
  if (db != null) {
    await db.execute("DELETE FROM contacts");
  }
}

Future<List<Contact>?> getContactsMini(BuildContext context) async {
  // Get a reference to the database.
  final db = await MyApp.of(context)?.getDatabase();

  if (db == null) return null;

  // Query the table for all The Contacts.
  final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT id, firstName, lastName, alias, imagePath FROM contacts');

  // Convert the List<Map<String, dynamic> into a List<Contact>.
  return List.generate(maps.length, (i) {
    return Contact(
      id: maps[i]['id'],
      firstName: maps[i]['firstName'],
      lastName: maps[i]['lastName'],
      address: null,
      alias: maps[i]['alias'],
      phone: '',
      imagePath: maps[i]['imagePath'],
    );
  });
}

Future<Contact?> getContactInfo(BuildContext context, int contactId) async {
  // Get a reference to the database.
  final db = await MyApp.of(context)?.getDatabase();

  if (db == null) return null;

  // Query the table for all The Contacts.
  final List<Map<String, dynamic>> maps =
      await db.rawQuery('SELECT * FROM contacts WHERE id=$contactId');

  if (maps.isEmpty) {
    return null;
  }

  return Contact(
    id: maps[0]['id'],
    firstName: maps[0]['firstName'],
    lastName: maps[0]['lastName'],
    address: maps[0]['address'],
    alias: maps[0]['alias'],
    phone: maps[0]['phone'],
    imagePath: maps[0]['imagePath'],
  );
}

Future<void> addFakeContacts(BuildContext context) async {
  var cList = <Contact>{};
  cList.add(const Contact(
      firstName: 'Terry', lastName: 'Dicule', phone: '+33756495950'));
  cList.add(const Contact(
      firstName: 'Céline', lastName: 'Évitable', phone: '+33644621316'));
  cList.add(const Contact(
      firstName: 'Alex', lastName: 'Ception', phone: '+33644621317'));
  cList.add(const Contact(
      firstName: 'Eve', lastName: 'Itement', phone: '+33644621318'));
  cList.add(const Contact(
      firstName: 'Théo', lastName: 'Rible', phone: '+33644626211'));
  cList.add(const Contact(
      firstName: 'Al', lastName: 'Kollyck', phone: '+33644626212'));
  cList.add(const Contact(
      firstName: 'Marie', lastName: 'Ruana', phone: '+33644626213'));
  cList.add(const Contact(
      firstName: 'Juda', lastName: 'Bricot', phone: '+33644626214'));
  cList.add(const Contact(
      firstName: 'Andy', lastName: 'Kapé', phone: '+33644626215'));
  cList.add(const Contact(
      firstName: 'Axel', lastName: 'Aire', phone: '+33644626216'));
  cList.add(const Contact(
      firstName: 'Kelly', lastName: 'Diote', phone: '+33644626217'));
  cList.add(const Contact(
      firstName: 'Hank', lastName: 'Huler', phone: '+33644626218'));
  cList.add(const Contact(
      firstName: 'Alain', lastName: 'Proviste', phone: '+33644626219'));
  cList.add(const Contact(
      firstName: 'Jean', lastName: 'Bambois', phone: '+33644626946'));
  cList.add(const Contact(
      firstName: 'Jean Phil', lastName: 'Tamaire', phone: '+33644626947'));
  cList.add(const Contact(
      firstName: 'Sam', lastName: 'Venere', phone: '+33644626948'));
  cList.add(const Contact(
      firstName: 'Oussama', lastName: 'Faimal', phone: '+33644626945'));
  cList.add(const Contact(
      firstName: 'Maude', lastName: 'Erateur', phone: '+33644626945'));
  cList.add(const Contact(
      firstName: 'Marc', lastName: 'Assain', phone: '+33644626945'));
  cList.add(const Contact(
      firstName: 'Matt', lastName: 'Messin', phone: '+33644626945'));
  cList.add(
      const Contact(firstName: 'Amar', lastName: 'Di', phone: '+33644626945'));
  cList.add(const Contact(
      firstName: 'Sarah', lastName: 'Fréchi', phone: '+33644626945'));
  cList.add(const Contact(
      firstName: 'Laurent', lastName: 'Outan', phone: '+33644626945'));
  cList.add(const Contact(
      firstName: 'Jerry', lastName: 'Kan', phone: '+33644626945'));
  cList.add(const Contact(
      firstName: 'Gaara', lastName: 'Toncul', phone: '+33644626945'));
  cList.add(const Contact(
      firstName: 'Lorie', lastName: 'Fice', phone: '+33644626945'));
  cList.add(const Contact(
      firstName: 'Eugène', lastName: 'Nie', phone: '+33644626945'));
  cList.add(const Contact(
      firstName: 'Larry', lastName: 'Golade', phone: '+33644626945'));
  cList.add(const Contact(
      firstName: 'Mehdi', lastName: 'Donk', phone: '+33644626945'));
  cList.add(const Contact(
      firstName: 'Claude', lastName: 'Eau', phone: '+33644626945'));
  cList.add(const Contact(
      firstName: 'Max', lastName: 'Hymôme', phone: '+33644626945'));
  cList.add(const Contact(
      firstName: 'Mick', lastName: 'Emmaus', phone: '+33644626945'));
  cList.add(
      const Contact(firstName: 'Lila', lastName: 'Doc', phone: '+33644626945'));
  cList.add(const Contact(
      firstName: 'Lee', lastName: 'Terature', phone: '+33644626945'));
  cList.add(
      const Contact(firstName: 'Pit', lastName: 'Za', phone: '+33644626945'));
  cList.add(const Contact(
      firstName: 'Gérard', lastName: 'Manchot', phone: '+33644626945'));
  for (final contact in cList) {
    insertContact(context, contact);
  }
}

Future<void> addMyself(BuildContext context) async {
  var cList = <Contact>{};
  cList.add(const Contact(
      firstName: 'Ludovic',
      lastName: 'Lemaire',
      alias: 'lulemair',
      phone: '+33683357915'));
  for (final contact in cList) {
    insertContact(context, contact);
  }
}
