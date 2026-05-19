import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stopwatch/core/app_exception.dart';
import 'package:stopwatch/core/box.dart';
import 'package:stopwatch/features/stopwatch/models/round_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:stopwatch/features/stopwatch/models/stopwatch_event.dart';

final roundModelLocalDataSourceProvider = Provider<IRoundModelLocalDataSource>((_) => RoundModelLocalDataSource());

//I is for Interface, helps autocomplete not suggest the interface instead of the default implementation
abstract class IRoundModelLocalDataSource {
  Future<Box<List<RoundModel>>> getAllHistory();
  Future<Box<RoundModel>> get(int id);
  Future<Box<List<RoundModel?>>> getLatestTwo();
  Future<Box<Null>> upsert(RoundModel model);
}

class RoundModelLocalDataSource extends IRoundModelLocalDataSource {
  late final Future _inited;
  late final Database _db;

  RoundModelLocalDataSource() {
    _inited = _initFunc();
  }

  Future _initFunc() async {
    _db = await openDatabase(
      'stopwatch_core.db', //descriptive name in case we need other ones in the future
      version: 1,
      onConfigure: (Database db) async {
        await db.execute(
          'PRAGMA foreign_keys = ON;', // Enables foreign key enforcement
        );
      },
      onUpgrade: (db, _, version) async {
        switch (version) {
          case 1:
            await db.transaction((transaction) async {
              await transaction.execute(
                'CREATE TABLE IF NOT EXISTS $_tableRoundModel (id INTEGER PRIMARY KEY, ${RoundModel.totalRunningDurationKey} INTEGER);',
              );
              await transaction.execute(
                //compound key so pause and end at the same timestamp can be both inserted
                'CREATE TABLE IF NOT EXISTS $_tableStopwatchEvent ($columnTimestamp INTEGER, $columnType TEXT, $columnRoundModelId INTEGER REFERENCES $_tableRoundModel(id), PRIMARY KEY ($columnTimestamp, $columnType));',
              );
            });
            continue toV1;
          toV1:
          case 2:
          //here to demonstrate how we can run migrations safely
        }
      },
      onOpen: (db) async {
        // await db.delete(_tableStopwatchEvent);
        // await db.delete(_tableRoundModel);
        // await db.execute(
        //   'CREATE TABLE IF NOT EXISTS $_tableRoundModel (id INTEGER PRIMARY KEY, ${RoundModel.totalRunningDurationKey} INTEGER);',
        // );
        // await db.execute(
        //   'CREATE TABLE IF NOT EXISTS $_tableStopwatchEvent ($columnTimestamp INTEGER, $columnType TEXT, $columnRoundModelId INTEGER REFERENCES $_tableRoundModel(id), PRIMARY KEY ($columnTimestamp, $columnType));',
        // );
      },
    );
  }

  @override
  Future<Box<RoundModel>> get(int id) async {
    await _inited;
    try {
      return _db.transaction((trx) async {
        //runnign the futures in parallel to speed things up
        final modelMaps = await Future.wait([
          trx.query(_tableRoundModel, where: 'id = ?', whereArgs: [id]),
          trx.query(
            _tableStopwatchEvent,
            where: '$columnRoundModelId = ?',
            whereArgs: [id],
            //make sure End comes after Stop
            orderBy: '$columnTimestamp ASC, $columnType DESC',
          ),
        ]);
        final modelMap = modelMaps[0].firstOrNull;
        final eventsMap = modelMaps[1];
        if (modelMap == null) throw Exception('RoundModel $id not found');
        return RoundModel.fromMap({
          ...modelMap,
          RoundModel.eventsKey: eventsMap.isNotEmpty ? eventsMap : [Start(id)],
        }).box();
      });
    } catch (e) {
      return AppExceptionNotFound().box();
    }
  }

  @override
  Future<Box<List<RoundModel>>> getAllHistory() async {
    try {
      await _inited;
      return _db.transaction((trx) async {
        final modelsMaps = await Future.wait([
          trx.query(_tableRoundModel, where: "${RoundModel.totalRunningDurationKey} IS NOT NULL", orderBy: 'id DESC'),
          trx.query(_tableStopwatchEvent),
        ]);
        final modelMaps = modelsMaps[0];
        //store modelMaps in a map for efficient lookup
        final mapOfModelMaps = <int, Map<String, Object?>>{};
        for (final modelMap in modelMaps) {
          mapOfModelMaps[modelMap['id'] as int] = {
            ...modelMap, //create a modifiable copy of them
            RoundModel.eventsKey: <Map<String, dynamic>>[], //make space for the incoming events
          };
        }
        final eventsMap = modelsMaps[1];
        //iterate over the events and copy them into the appropriate models
        for (final eventMap in eventsMap) {
          (((mapOfModelMaps[eventMap[columnTimestamp] as int]?[RoundModel.eventsKey] as Iterable?)
                          ?.cast<Map<String, dynamic>>())
                      ?.toList() ??
                  [].toList())
              .add(eventMap);
        }
        return mapOfModelMaps.values.map((map) => RoundModel.fromMap(map)).toList().box();
      });
    } catch (e) {
      return AppExceptionNotFound().box();
    }
  }

  @override
  Future<Box<Null>> upsert(RoundModel model) async {
    try {
      await _inited;
      return _db.transaction((trx) async {
        await trx.insert(
          _tableRoundModel,
          model.toMap()..remove(RoundModel.eventsKey), //we store those in another table
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        final batch = trx.batch();
        for (final event in model.events) {
          batch.insert(
            _tableStopwatchEvent,
            event.toMap(model.id),
            //do not rewrite the past. If [StopWatchEvent] gets editable fields, change this to .replace
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
        batch.commit(noResult: true);
      }).box();
    } catch (e) {
      return AppExceptionUpsertFailed().box();
    }
  }

  @override
  Future<Box<List<RoundModel?>>> getLatestTwo() async {
    try {
      await _inited;
      return _db.transaction((trx) async {
        final modelMaps = await trx.query(_tableRoundModel, orderBy: 'id DESC', limit: 2);
        if (modelMaps.isEmpty) return <RoundModel>[].box();
        return Future.wait(
          modelMaps.map((modelMap) async {
            final eventsMap = await trx.query(
              _tableStopwatchEvent,
              where: '$columnRoundModelId = ?',
              whereArgs: [modelMap["id"]],
              //make sure End comes after Stop
              orderBy: '$columnTimestamp ASC, $columnType DESC',
            );
            if (eventsMap.isEmpty) {
              throw Exception('no events for latest model found');
            }
            return RoundModel.fromMap({...modelMap, RoundModel.eventsKey: eventsMap});
          }),
        ).box();
      });
    } catch (e) {
      return AppExceptionNotFound().box();
    }
  }
}

const _tableRoundModel = 'round_model';
const _tableStopwatchEvent = 'stopwatch_event';
