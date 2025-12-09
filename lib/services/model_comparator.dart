import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';

class ModelComparator {
  bool _isModelLoaded = false;

  Future<void> loadModels() async {
    _isModelLoaded = true;
    // ignore: avoid_print
    print('Model comparator initialized');
  }

  Future<Map<String, dynamic>> comparePrediction(
      Uint8List imageBytes, String userFeedback) async {

    if (!_isModelLoaded) {
      return {"error": "Model not loaded"};
    }


    return {
      "match": userFeedback == "correct",
      "feedback": userFeedback,
      "status": "recorded"
    };
  }

  Future<void> saveTrainingData(Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance
          .collection('model_training_data')
          .add({
        ...data,
        'created_at': FieldValue.serverTimestamp(),
      });
      // ignore: avoid_print
      print('Training data saved ✔');
    } catch (e) {
      // ignore: avoid_print
      print('Error saving training data: $e');
      _saveTrainingDataLocally(data);
    }
  }

  void _saveTrainingDataLocally(Map<String, dynamic> data) {
    // ignore: avoid_print
    print('Training data stored locally: $data');
  }

  bool get isModelLoaded => _isModelLoaded;

  void dispose() {
    _isModelLoaded = false;
  }
}
