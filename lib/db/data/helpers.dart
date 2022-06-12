import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:sqflite/sqflite.dart';
import './account.dart';
import './seek.dart';
import './history.dart';

class Helpers {
  final AccountHelper account;
  final SeekHelper seek;
  final HistoryHelper history;
  Helpers(Database db)
      : account = AccountHelper(db),
        seek = SeekHelper(db),
        history = HistoryHelper(db);

  static FutureOr<void> onCreate(Database db, int version) async {
    debugPrint('onCreate: $version');
    await AccountHelper.onCreate(db, version);
    await SeekHelper.onCreate(db, version);
    await HistoryHelper.onCreate(db, version);
  }

  static FutureOr<void> onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    debugPrint('onUpgrade: $oldVersion -> $newVersion');
    await AccountHelper.onUpgrade(db, oldVersion, newVersion);
    await SeekHelper.onUpgrade(db, oldVersion, newVersion);
    await HistoryHelper.onUpgrade(db, oldVersion, newVersion);
  }
}
