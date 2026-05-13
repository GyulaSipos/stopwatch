import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stopwatch/core/app_exception.dart';
import 'package:stopwatch/core/box.dart';
import 'package:stopwatch/features/stopwatch/models/round_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:stopwatch/features/stopwatch/models/stopwatch_event.dart';

final roundModelLocalDataSourceProvider = Provider<IRoundModelLocalDataSource>(
  (_) => RoundModelLocalDataSource(),
);

//I is for Interface, helps autocomplete not suggest the interface instead of the default implementation
abstract class IRoundModelLocalDataSource {
  Future<Box<List<RoundModel>>> getAll();
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
      version: 0,
      onConfigure: (Database db) async {
        await db.execute(
          'PRAGMA foreign_keys = ON;', // Enables foreign key enforcement
        );
      },
      onUpgrade: (db, _, version) async {
        switch (version) {
          case 0:
            await db.transaction((transaction) async {
              await transaction.execute(
                'CREATE TABLE IF NOT EXISTS $_tableRoundModel (id INTEGER PRIMARY KEY);',
              );
              await transaction.execute(
                'CREATE TABLE IF NOT EXISTS $_tableStopwatchEvent ($columnTimestamp INTEGER PRIMARY KEY, $columnType TEXT, $columnRoundModelId INTEGER REFERENCES $_tableRoundModel(id));',
              );
            });
            continue toV1;
          toV1:
          case 1:
          //here to demonstrate how we can run migrations safely
        }
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
          trx.query(_tableRoundModel, where: 'id = $id'),
          trx.query(
            _tableStopwatchEvent,
            where: '$columnRoundModelId = $id',
            orderBy: '$columnTimestamp ASC',
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
  Future<Box<List<RoundModel>>> getAll() async {
    try {
      await _inited;
      return _db.transaction((trx) async {
        final modelsMaps = await Future.wait([
          trx.query(_tableRoundModel, orderBy: 'id ASC'),
          trx.query(_tableStopwatchEvent, orderBy: '$columnTimestamp ASC'),
        ]);
        final modelMaps = modelsMaps[0];
        //store modelMaps in a map for efficient lookup
        final mapOfModelMaps = <int, Map<String, Object?>>{};
        for (final modelMap in modelMaps) {
          mapOfModelMaps[modelMap['id'] as int] = {
            ...modelMap, //create a modifiable copy of them
            RoundModel.eventsKey: [], //make space for the incoming events
          };
        }
        final eventsMap = modelsMaps[1];
        //iterate over the events and copy them into the appropriate models
        for (final eventMap in eventsMap) {
          (mapOfModelMaps[eventMap[columnTimestamp]
                      as int]?[RoundModel.eventsKey]
                  as List)
              .add(eventMap);
        }
        return mapOfModelMaps.values
            .map((map) => RoundModel.fromMap(map))
            .toList()
            .box();
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
        final batch = trx.batch();
        for (final event in model.events) {
          batch.insert(
            _tableStopwatchEvent,
            event.toMap(model.id),
            //do not rewrite the past. If [StopWatchEvent] gets editable fields, change this to .replace
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
        await Future.wait([
          trx.insert(
            _tableRoundModel,
            model.toMap()
              ..remove(RoundModel.eventsKey), //we store those in another table
            conflictAlgorithm: ConflictAlgorithm.replace,
          ),
          batch.commit(noResult: true),
        ]);
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
        final modelMaps = await trx.query(
          _tableRoundModel,
          orderBy: 'id DESC',
          limit: 2,
        );
        if (modelMaps.isEmpty) return <RoundModel>[].box();
        return Future.wait(
          modelMaps.map((modelMap) async {
            final eventsMap = await trx.query(
              _tableStopwatchEvent,
              where: '$columnRoundModelId = ${modelMap["id"]}',
              orderBy: '$columnTimestamp ASC',
            );
            if (eventsMap.isEmpty) {
              throw Exception('no events for latest model found');
            }
            return RoundModel.fromMap({
              ...modelMap,
              RoundModel.eventsKey: eventsMap,
            });
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
