import '../models/prediction_result_model.dart';

class HistoryService {
  static final List<PredictionResultModel> _history = [];

  static void addHistory(PredictionResultModel result) {
    _history.insert(0, result);
  }

  static List<PredictionResultModel> getHistory() => _history;

  static void deleteItem(int index) {
    if (index >= 0 && index < _history.length) {
      _history.removeAt(index);
    }
  }

  static void clearAll() => _history.clear();
}
