import 'package:stopwatch/features/stopwatch/models/round_model.dart';

// you mentioned that you don't use riverpod for DI
// so i put an interface here, maybe it helps testing in your solution
abstract class ILocalDataSource {
  //I is for Interface, helps autocomplete not suggest the interface instead of the default implementation
  Future<List<RoundModel>> getAll();
  Future<RoundModel?> get(String id);
  Future<bool> upsert(RoundModel model);
}

class LocalDataSource implements ILocalDataSource {
  @override
  Future<RoundModel?> get(String id) async {
    final jsonString = await SharedPreferencesAsync().getString(id);
    if (jsonString == null) return null;
    return RoundModel.fromJson(jsonDecode(jsonString));
  }

  @override
  Future<List<RoundModel>> getAll() async {
    final sp = SharedPreferencesAsync();
    final keys = await sp.getStringList(_allEntriesKey);
    if (keys == null || keys.isEmpty) return [];
    final modelsAndNulls = await Future.wait(keys.map((key) => get(key)));
    return modelsAndNulls.whereType<RoundModel>().toList();
  }

  @override
  Future<bool> upsert(RoundModel model) {
    //cannot have ACID compliant insert here;
    SharedPreferencesAsync().setString(model.id, jsonEncode(model.toJson()));
  }

  //why use this key instead of just [SharedPreferencesAsync.getAll()] ?
  //thanks for asking! If in the future SharedPreferences gets used for something else in the project,
  //it would pollute the getAll. This is more defensive.
  static const _allEntriesKey = "allRoundModelEndtries";
}
