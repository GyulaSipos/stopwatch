//I is for Interface, helps autocomplete not suggest the interface instead of the default implementation
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stopwatch/core/box.dart';
import 'package:stopwatch/features/stopwatch/models/round_model.dart';
import 'package:stopwatch/features/stopwatch/services/round_model_local_data_source.dart';

final stopwatchRepositoryProvider = Provider<IStopwatchRepository>(
  (ref) => StopwatchRepository(localDataSource: ref.watch(roundModelLocalDataSourceProvider)),
);

abstract class IStopwatchRepository {
  Future<Box<List<RoundModel>>> getAllHistory();
  Future<Box<RoundModel>> get(int id);
  Future<Box<List<RoundModel?>>> getLatestTwo();
  Future<Box<Null>> upsert(RoundModel model);
  Future<Box<Null>> deleteLapsForId(int id);
}

//Right now this layer does nothing, jusst passes calls.
//Yet, i don't like skipping layers. Eventually they get a use
class StopwatchRepository extends IStopwatchRepository {
  final IRoundModelLocalDataSource localDataSource;

  StopwatchRepository({required this.localDataSource});
  @override
  Future<Box<RoundModel>> get(int id) => localDataSource.get(id);

  @override
  Future<Box<List<RoundModel>>> getAllHistory() => localDataSource.getAllHistory();

  @override
  Future<Box<List<RoundModel?>>> getLatestTwo() => localDataSource.getLatestTwo();

  @override
  Future<Box<Null>> upsert(RoundModel model) => localDataSource.upsert(model);
  
  @override
  Future<Box<Null>> deleteLapsForId(int id) => localDataSource.deleteLapsForId(id);
  }

