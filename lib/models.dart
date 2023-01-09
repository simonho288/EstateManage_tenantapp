///
/// To generate model. run `flutter pub run build_runner build`
///

// import 'dart:async';
import 'package:sqflite/sqflite.dart';

// Sync with sqflite table 'Loops'
class Loop {
  static String tableName = 'Loops'; // required to save to sqflite
  String id;
  DateTime dateCreated;
  String titleId;
  String titleTranslated;
  String? url;
  String type;
  String sender;
  String? paramsJson; // original JSON parameter
  bool isNew; // just read from database?

  Loop({
    required this.id,
    required this.dateCreated,
    required this.titleId,
    required this.titleTranslated,
    required this.url,
    required this.type,
    required this.sender,
    this.paramsJson = null,
    this.isNew = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dateCreated': dateCreated.toIso8601String(),
      'titleId': titleId,
      'titleTranslated': titleTranslated,
      'url': url,
      'type': type,
      'sender': sender,
      'paramsJson': paramsJson,
    };
  }

  // final db = await Globals.sqlite;
  Future<void> insert(Database db) async {
    await db.insert(
      tableName,
      this.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Loop>> getAll(Database db) async {
    // Query the table for all records
    final List<Map<String, dynamic>> maps = await db.query(tableName);

    // Convert the List of records
    return List.generate(maps.length, (i) {
      return Loop(
        id: maps[i]['id'],
        dateCreated: DateTime.parse(maps[i]['dateCreated']),
        titleId: maps[i]['titleId'],
        titleTranslated: maps[i]['titleTranslated'],
        url: maps[i]['url'],
        type: maps[i]['type'],
        sender: maps[i]['sender'],
        paramsJson: maps[i]['paramsJson'],
      );
    });
  }

  static Future<List<Loop>> query(
      Database db, String sql, List<dynamic> params) async {
    // Query the table for all records
    final List<Map<String, dynamic>> maps = await db.rawQuery(sql, params);
    return List.generate(maps.length, (i) {
      return Loop(
        id: maps[i]['id'],
        dateCreated: DateTime.parse(maps[i]['dateCreated']),
        titleId: maps[i]['titleId'],
        titleTranslated: maps[i]['titleTranslated'],
        url: maps[i]['url'],
        type: maps[i]['type'],
        sender: maps[i]['sender'],
        paramsJson: maps[i]['paramsJson'],
      );
    });
  }

  Future<void> update(Database db) async {
    // Update the givien record.
    await db.update(
      tableName,
      this.toMap(),
      where: 'id=?',
      whereArgs: [id],
    );
  }

  static Future<void> delete(Database db, String id) async {
    await db.delete(
      tableName,
      where: 'id=?',
      whereArgs: [id],
    );
  }
}

// Schema for Notices.
class Notice {
  static String tableName = 'Notices'; // required to save to sqflite
  String id;
  DateTime dateCreated;
  String issueDate; // issue_date
  String title;
  String pdfUrl;
  bool isNew;

  Notice({
    required this.id,
    required this.dateCreated,
    required this.issueDate,
    required this.title,
    required this.pdfUrl,
    this.isNew = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dateCreated': dateCreated.toIso8601String(),
      'issueDate': issueDate,
      'title': title,
      'pdfUrl': pdfUrl,
    };
  }

  // final db = await Globals.sqlite;
  Future<void> insert(Database db) async {
    await db.insert(
      tableName,
      this.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Notice>> getAll(Database db) async {
    // Query the table for all records
    final List<Map<String, dynamic>> maps = await db.query(tableName);

    // Convert the List of records
    return List.generate(maps.length, (i) {
      return Notice(
        id: maps[i]['id'],
        dateCreated: DateTime.parse(maps[i]['dateCreated']),
        issueDate: maps[i]['issueDate'],
        title: maps[i]['title'],
        pdfUrl: maps[i]['pdfUrl'],
      );
    });
  }

  Future<void> update(Database db) async {
    // Update the givien record.
    await db.update(
      tableName,
      this.toMap(),
      where: 'id=?',
      whereArgs: [id],
    );
  }

  static Future<void> delete(Database db, String id) async {
    await db.delete(
      tableName,
      where: 'id=?',
      whereArgs: [id],
    );
  }
}

// Schema for Marketplaces.
class Marketplace {
  static String tableName = 'Marketplaces'; // required to save to sqflite
  String id;
  DateTime dateCreated;
  String postDate;
  String title;
  String adImage;
  String adImageThm;
  String? commerceUrl;
  bool isNew; // Is just read from backend?

  Marketplace({
    required this.id,
    required this.dateCreated,
    required this.postDate,
    required this.title,
    required this.adImage,
    required this.adImageThm,
    required this.commerceUrl,
    this.isNew = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dateCreated': dateCreated.toIso8601String(),
      'postDate': postDate,
      'title': title,
      'adImage': adImage,
      'adImageThm': adImageThm,
      'commerceUrl': commerceUrl,
    };
  }

  Future<void> insert(Database db) async {
    await db.insert(
      tableName,
      this.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Marketplace>> getAll(Database db) async {
    // Query the table for all records
    final List<Map<String, dynamic>> maps = await db.query(tableName);

    // Convert the List of records
    return List.generate(maps.length, (i) {
      return Marketplace(
        id: maps[i]['id'],
        dateCreated: DateTime.parse(maps[i]['dateCreated']),
        postDate: maps[i]['postDate'],
        title: maps[i]['title'],
        adImage: maps[i]['adImage'],
        adImageThm: maps[i]['adImageThm'],
        commerceUrl: maps[i]['commerceUrl'],
      );
    });
  }

  Future<void> update(Database db) async {
    // Update the givien record.
    await db.update(
      tableName,
      this.toMap(),
      where: 'id=?',
      whereArgs: [id],
    );
  }

  static Future<void> delete(Database db, String id) async {
    await db.delete(
      tableName,
      where: 'id=?',
      whereArgs: [id],
    );
  }
}

// Schema for amenities_booking_sections
class AmenityBookingSection {
  String id;
  // String amenityId;
  // String bookingSectionId;
  String name;
  String timeBegin;
  String timeEnd;

  AmenityBookingSection({
    required this.id,
    // required this.amenityId,
    // required this.bookingSectionId,
    required this.name,
    required this.timeBegin,
    required this.timeEnd,
  });
}

// Schema for client (Estate)
class Estate {
  String? dateCreated;
  String? name;
  String? address;
  String? contact;
  String? tel;
  String? email;
  String? website;
  String? langEntries;
  // int? committeeTerm;
  // String? termDate;
  // int? mgrfeePaymentDays;
  // String? chequePayableTo;
  // bool? isEffect;
  // String? srvLangMode;
  // DateTime? trialExpiry;
  // String? mgrfeeTitle;
  // bool? isModMiscIncome;
  String? tenantAppEstateImage;
  // String? stripePublishableKey;
  // String? stripeSecretKey;
  String? currency;

  Estate({
    this.dateCreated,
    this.name,
    this.address,
    this.contact,
    this.tel,
    this.email,
    this.website,
    this.langEntries,
    // this.committeeTerm,
    // this.termDate,
    // this.mgrfeePaymentDays,
    // this.chequePayableTo,
    // this.isEffect,
    // this.srvLangMode,
    // this.trialExpiry,
    // this.mgrfeeTitle,
    // this.isModMiscIncome,
    this.tenantAppEstateImage,
    // this.stripePublishableKey,
    // this.stripeSecretKey,
    this.currency,
  });
}

// Schema for Marketplaces.
class Amenity {
  String id;
  String dateCreated;
  String name;
  String details;
  String photo;
  bool monday;
  bool tuesday;
  bool wednesday;
  bool thursday;
  bool friday;
  bool saturday;
  bool sunday;
  String status;
  int fee;
  DateTime? timeOpen;
  DateTime? timeClose;
  int? timeMinimum;
  int? timeMaximum;
  int? timeIncrement;
  String bookingTimeBasic;
  List<AmenityBookingSection>? bookingSections;
  bool isRepetitiveBooking;
  int bookingAdvanceDays;
  int? autoCancelHours;
  Map<String, dynamic>? contactWhatsapp;
  Map<String, dynamic>? contactEmail;

  Amenity({
    required this.id,
    required this.dateCreated,
    required this.name,
    required this.details,
    required this.photo,
    required this.monday,
    required this.tuesday,
    required this.wednesday,
    required this.thursday,
    required this.friday,
    required this.saturday,
    required this.sunday,
    required this.status,
    required this.fee,
    required this.timeOpen,
    required this.timeClose,
    required this.timeMinimum,
    required this.timeMaximum,
    required this.timeIncrement,
    required this.bookingTimeBasic,
    required this.isRepetitiveBooking,
    required this.bookingAdvanceDays,
    required this.autoCancelHours,
    this.contactEmail,
    this.contactWhatsapp,
  });
}

// Schema for tenant_amenity_booking.
class TenantAmenityBooking {
  String id;
  DateTime dateCreated;
  String tenantId;
  String amenityId;
  String bookingTimeBasic;
  String date;
  double? totalFee;
  bool isPaid;
  List<TenantAmenityBookingSlot> slots;

  TenantAmenityBooking({
    required this.id,
    required this.dateCreated,
    required this.tenantId,
    required this.amenityId,
    required this.bookingTimeBasic,
    required this.date,
    required this.totalFee,
    required this.isPaid,
    required this.slots,
  });
}

class TenantAmenityBookingSlot {
  String id;
  // int tenantAmenityBookingId; // Point to Models.TenantAmenityBooking
  // String bookingTimeBasic;
  String timeStart;
  String timeEnd;
  String? bookingSection;
  double? fee;

  TenantAmenityBookingSlot({
    required this.id,
    // required this.tenantAmenityBookingId,
    // required this.bookingTimeBasic,
    required this.timeStart,
    required this.timeEnd,
    this.bookingSection,
    this.fee,
  });
}
