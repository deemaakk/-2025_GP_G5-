import 'dart:typed_data';
import 'dart:math';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

/// Modified YoloSign with dynamic input/output handling and detailed tracing.
class YoloSign {
  Interpreter? _interpreter;
  // ignore: unused_field
  bool _isLoaded = false;
  bool ready = false;

  // default fallback (will be overwritten if model provides shape)
  int inputSize = 640;
  final int numClasses = 32;

  /// model asset path (change if needed)
  String modelAsset = 'assets/models/best_float16.tflite';

  /// Optional logger callback (pass a function that accepts String to receive logs)
  void Function(String message)? logger;

  // ===========================================================
  // YOLO CLASS ORDER (training names)
  // ===========================================================
  static const List<String> modelClasses = [
    'ain', 'al', 'aleff', 'bb', 'dal',
    'dha', 'dhad', 'fa', 'gaaf', 'ghain',
    'ha', 'haa', 'jeem', 'kaaf', 'khaa',
    'la', 'laam', 'meem', 'nun', 'ra',
    'saad', 'seen', 'sheen', 'ta', 'taa',
    'thaa', 'thal', 'toot', 'waw', 'ya',
    'yaa', 'zay'
  ];

  // ===========================================================
  // English → Arabic map
  // ===========================================================
  static const Map<String, String> toArabic = {
    'ain': 'ع', 'al': 'ال', 'aleff': 'أ', 'bb': 'ب', 'dal': 'د',
    'dha': 'ذ', 'dhad': 'ض', 'fa': 'ف', 'gaaf': 'ج', 'ghain': 'غ',
    'ha': 'ه', 'haa': 'ح', 'jeem': 'ج', 'kaaf': 'ك', 'khaa': 'خ',
    'la': 'لا', 'laam': 'ل', 'meem': 'م', 'nun': 'ن', 'ra': 'ر',
    'saad': 'ص', 'seen': 'س', 'sheen': 'ش', 'ta': 'ط', 'taa': 'ت',
    'thaa': 'ث', 'thal': 'ذ', 'toot': 'ط', 'waw': 'و', 'ya': 'ي',
    'yaa': 'ي', 'zay': 'ز'
  };

  String labelFromId(int id) {
    if (id < 0 || id >= modelClasses.length) return "?";
    return toArabic[modelClasses[id]] ?? "?";
  }

  // ===========================================================
  // Logging helpers
  // ===========================================================
  void _log(String s) {
    final msg = "[${DateTime.now().toIso8601String()}] $s";
    // print to console
    // ignore: avoid_print
    print(msg);
    // optional callback
    try {
      if (logger != null) logger!(msg);
    } catch (_) {}
  }

  void _logException(Object e, [StackTrace? st]) {
    _log("EXCEPTION: $e");
    if (st != null) _log("STACKTRACE:\n$st");
  }

  // ===========================================================
  // INIT
  // ===========================================================
  /// init: optionally pass model asset path and a log callback
  Future<void> init({String? assetPath, void Function(String)? logCallback, int? threads}) async {
    try {
      if (assetPath != null) modelAsset = assetPath;
      logger = logCallback;

      _log("Loading TFLite model from: $modelAsset ...");
      final opts = InterpreterOptions()..threads = (threads ?? 4);
      _interpreter = await Interpreter.fromAsset(modelAsset, options: opts);

      _isLoaded = true;
      ready = true;
      _log("YOLO Model Loaded ✔");

      await debugDescribeModel();
      printClassMapping();
    } catch (e, st) {
      _logException(e, st);
      rethrow;
    }
  }

  Future<void> debugDescribeModel() async {
    if (_interpreter == null) {
      _log("Interpreter is null - cannot describe model.");
      return;
    }

    try {
      _log("=== Model Input Tensors ===");
      final inTensors = _interpreter!.getInputTensors();
      for (var t in inTensors) {
        _log("Input: ${t.name} - Shape: ${t.shape} - Type: ${t.type}");
      }

      _log("=== Model Output Tensors ===");
      final outTensors = _interpreter!.getOutputTensors();
      for (var t in outTensors) {
        _log("Output: ${t.name} - Shape: ${t.shape} - Type: ${t.type}");
      }

      // if possible update inputSize from tensor shape (assume 4D: [1,H,W,3] or [1,3,H,W])
      if (inTensors.isNotEmpty) {
        final s = inTensors.first.shape;
        if (s.length == 4) {
          // try NHWC first [1,H,W,3]
          if (s[3] == 3) {
            inputSize = s[1];
            _log("Detected NHWC input. Set inputSize = $inputSize");
          } else if (s[1] == 3) {
            // NCHW [1,3,H,W]
            inputSize = s[2];
            _log("Detected NCHW input. Set inputSize = $inputSize");
          } else {
            _log("Unknown 4D input layout; keeping fallback inputSize=$inputSize");
          }
        } else {
          // ignore: unnecessary_brace_in_string_interps
          _log("Input tensor is not 4D: ${s}. Keeping inputSize=$inputSize");
        }
      }
    } catch (e, st) {
      _logException(e, st);
    }
  }

  void printClassMapping() {
    _log("=== Class ID to Arabic Mapping ===");
    for (int i = 0; i < numClasses; i++) {
      _log("ID $i → ${labelFromId(i)}");
    }
  }

  // ===========================================================
  // 🔥 Return letter only (always fallback)
  // ===========================================================
  Future<String> detectLetter(Uint8List bytes) async {
    final detections = await detectBytes(bytes);
    detections.sort((a, b) => b.confidence.compareTo(a.confidence));
    final best = detections.first;
    _log("🎯 Best Letter: ${best.label} (Conf: ${best.confidence.toStringAsFixed(3)})");
    return best.label;
  }

  // ===========================================================
  // YOLO INFERENCE (dynamic buffers)
  // ===========================================================
  Future<List<Detection>> detectBytes(Uint8List bytes) async {
    if (!ready || _interpreter == null) throw Exception("Model not initialized");

    try {
      final img.Image? original = img.decodeImage(bytes);
      if (original == null) {
        _log("Failed to decode image bytes.");
        return [];
      }

      // get input tensor info
      final inTensors = _interpreter!.getInputTensors();
      if (inTensors.isEmpty) throw Exception("Model has no input tensors");

      final inShape = inTensors.first.shape; // e.g. [1,224,224,3] or [1,3,224,224]
      final inType = inTensors.first.type;
      _log("Input tensor shape from model: $inShape, type=$inType");

      // decide layout (NHWC vs NCHW)
      bool isNHWC = false;
      if (inShape.length == 4 && inShape[3] == 3) {
        isNHWC = true;
      } else if (inShape.length == 4 && inShape[1] == 3) {
        isNHWC = false;
      } else {
        // fallback: assume NHWC with square H==W
        isNHWC = true;
      }

      // determine target size from model or fallback field
      int modelSize = inputSize;
      if (inShape.length == 4) {
        modelSize = isNHWC ? inShape[1] : inShape[2];
      }
      _log("Using model input size = $modelSize (isNHWC=$isNHWC)");

      // resize input image
      final resized = img.copyResize(original, width: modelSize, height: modelSize);
      _log("Resized image from (${original.width}x${original.height}) -> (${resized.width}x${resized.height})");

      // build input buffer (Float32)
      final inputTensorElementCount = inShape.reduce((a, b) => a * b);
      final Float32List inputBuffer = Float32List(inputTensorElementCount);

      // Fill inputBuffer in correct order
      if (isNHWC) {
        // layout: [1,H,W,3]
        int idx = 0;
        for (int y = 0; y < modelSize; y++) {
          for (int x = 0; x < modelSize; x++) {
            final p = resized.getPixel(x, y);
            inputBuffer[idx++] = (img.getRed(p) / 255.0);
            inputBuffer[idx++] = (img.getGreen(p) / 255.0);
            inputBuffer[idx++] = (img.getBlue(p) / 255.0);
          }
        }
      } else {
        // layout: [1,3,H,W] -> channel-first
        // fill all R then G then B
        int planeSize = modelSize * modelSize;
        int rIdx = 0;
        int gIdx = planeSize;
        int bIdx = planeSize * 2;
        for (int y = 0; y < modelSize; y++) {
          for (int x = 0; x < modelSize; x++) {
            final p = resized.getPixel(x, y);
            inputBuffer[rIdx++] = (img.getRed(p) / 255.0);
            inputBuffer[gIdx++] = (img.getGreen(p) / 255.0);
            inputBuffer[bIdx++] = (img.getBlue(p) / 255.0);
          }
        }
      }

      _log("Built input buffer of length ${inputBuffer.length}");

      // Build output buffer(s) dynamically based on model output shapes
      final outTensors = _interpreter!.getOutputTensors();
      if (outTensors.isEmpty) throw Exception("Model has no output tensors");
      _log("Model has ${outTensors.length} output tensor(s).");

      // prepare a map for multiple outputs if necessary
      // but for common YOLO exported by Ultralytics it's often a single output.
      dynamic outputBuffer;
      List<int> outShape = outTensors.first.shape; // e.g. [1,36,8400] or [1,32,1029]
      _log("Primary output shape: $outShape");

      // Build nested list for interpreter.run
      dynamic makeNestedList(List<int> shape) {
        if (shape.length == 1) return List<double>.filled(shape[0], 0.0);
        return List.generate(shape[0], (_) => makeNestedList(shape.sublist(1)));
      }

      outputBuffer = makeNestedList(outShape);

      _log("Calling interpreter.run() ...");
      // run
      try {
        // TFLite interpreter accepts Float32List for NHWC/NCHW if shape matches,
        // but run(input, output) also accepts nested Lists.
        // input must be shaped as model expects: we pass typed buffer reshaped via typed list + shape info:
        // The tflite_flutter Interpreter will accept a List with nested structure or a TypedData.
        // We pass Float32List but need to provide it as nested List with outermost dimension equals batch.
        // Simplest: convert Float32List to nested List matching inShape.
        dynamic inputNested;
        if (isNHWC) {
          // shape [1,H,W,3]
          int offset = 0;
          inputNested = List.generate(inShape[0], (_) {
            return List.generate(inShape[1], (_) {
              return List.generate(inShape[2], (_) {
                final r = inputBuffer[offset++]; // R
                final g = inputBuffer[offset++]; // G
                final b = inputBuffer[offset++]; // B
                return [r, g, b];
              });
            });
          });
        } else {
          // shape [1,3,H,W]
          int planeSize = modelSize * modelSize;
          // split inputBuffer into channels
          final rPlane = inputBuffer.sublist(0, planeSize);
          final gPlane = inputBuffer.sublist(planeSize, planeSize * 2);
          final bPlane = inputBuffer.sublist(planeSize * 2, planeSize * 3);
          inputNested = List.generate(inShape[0], (_) {
            return List.generate(inShape[1], (c) {
              return List.generate(inShape[2], (y) {
                return List.generate(inShape[3], (x) {
                  if (c == 0) return rPlane[y * modelSize + x];
                  if (c == 1) return gPlane[y * modelSize + x];
                  return bPlane[y * modelSize + x];
                });
              });
            });
          });
        }

        _interpreter!.run(inputNested, outputBuffer);
      } catch (e, st) {
        _logException(e, st);
        return [];
      }

      _log("Interpreter.run() finished. Converting outputs to double lists...");

      // convert outputBuffer to a stable List<List<double>> shape: [channels][numBoxes]
      // accept different output layouts: [1,C,N] or [1,N,C] etc.
      List<List<double>> finalP = [];

      // Helper to flatten nested lists to List<double>
      List<double> flattenToDoubles(dynamic arr) {
        if (arr is double) return [arr];
        if (arr is int) return [arr.toDouble()];
        if (arr is List) {
          List<double> out = [];
          for (var e in arr) {
            out.addAll(flattenToDoubles(e));
          }
          return out;
        }
        return [];
      }

      // Cases:
      // 1) outShape == [1, C, N] -> good: finalP length C, each length N
      // 2) outShape == [1, N, C] -> transpose to [C,N]
      // 3) other shapes -> try to flatten and guess.

      if (outShape.length == 3) {
        int a = outShape[0], b = outShape[1], c = outShape[2];
        // assume first dim is batch (1)
        if (a != 1) _log("Warning: batch dimension != 1: $a");
        // determine whether second dim is channels or boxes:
        // heuristic: if b == (4 + numClasses + ?) but we don't know; we prefer common formats:
        // Ultralytics often produces [1, 36, 8400] => [1, C, N]
        // If b <= 128 likely channels; if c <= 128 could be channels; we'll use heuristic:
        bool secondIsChannels = b <= 1024 && c > 32; // heuristic
        if (b <= 1024 && c > 32) secondIsChannels = true;
        if (c <= 1024 && b > 32) secondIsChannels = false;

        if (secondIsChannels) {
          // outputBuffer[0] is List of length b (channels), each is List length c
          dynamic raw = outputBuffer[0];
          for (int ch = 0; ch < b; ch++) {
            final row = raw[ch];
            final flat = flattenToDoubles(row);
            finalP.add(flat);
          }
          _log("Interpreted output as [1, C, N] => C=$b, N=$c");
        } else {
          // treat as [1, N, C] => transpose
          dynamic raw = outputBuffer[0];
          _log("Interpreting output as [1, N, C] and transposing...");
          // raw is List length N, each element is List length C
          for (int ch = 0; ch < c; ch++) {
            finalP.add(List<double>.filled(b, 0.0));
          }
          for (int n = 0; n < b; n++) {
            final row = raw[n];
            final rowFlat = flattenToDoubles(row);
            for (int ch = 0; ch < c; ch++) {
              finalP[ch][n] = rowFlat[ch];
            }
          }
          _log("Transposed output to shape [C=$c, N=$b]");
        }
      } else {
        // fallback: flatten everything and try to shape into [C, N] where C = 4 + numClasses
        final flat = flattenToDoubles(outputBuffer);
        _log("Output shape not 3D. total elements = ${flat.length}");
        int C = 4 + numClasses;
        if (flat.length % C != 0) {
          _log("Warning: total elements ${flat.length} not divisible by C=$C. Trying to proceed.");
        }
        int N = (flat.length / C).floor();
        for (int ch = 0; ch < C; ch++) {
          finalP.add(List<double>.filled(N, 0.0));
        }
        for (int n = 0; n < N; n++) {
          for (int ch = 0; ch < C; ch++) {
            int idx = n * C + ch;
            if (idx < flat.length) finalP[ch][n] = flat[idx];
          }
        }
        _log("Fallback shaped output to [C=$C, N=$N]");
      }

      // Debug: print top-10 probabilities (like before)
      try {
        _printTop10Probabilities(finalP);
      } catch (e, st) {
        _logException(e, st);
      }

      // process to detections (use original image dimensions)
      return _process(finalP, original.width, original.height);
    } catch (e, st) {
      _logException(e, st);
      return [];
    }
  }

  // ===========================================================
  // PREPROCESS - not used externally now since preprocess integrated above,
  // but kept for compatibility (returns nested NHWC List if still used)
  // ===========================================================
  // ignore: unused_element
  List<List<List<List<double>>>> _preprocess(img.Image image) {
    // keep original signature (NHWC nested list)
    int size = inputSize;
    return [
      List.generate(
        size,
            (y) => List.generate(
          size,
              (x) {
            final p = image.getPixel(x, y);
            return [
              img.getRed(p) / 255.0,
              img.getGreen(p) / 255.0,
              img.getBlue(p) / 255.0,
            ];
          },
        ),
      )
    ];
  }

  // ===========================================================
  // 🔥 Print TOP 10 PROBABILITIES Raw (expects finalP: [C][N])
  // ===========================================================
  void _printTop10Probabilities(List<List<double>> preds) {
    _log("=== 🔥 TOP 10 RAW PROBABILITIES (debug) ===");
    List<Map<String, dynamic>> list = [];

    int C = preds.length;
    int N = (preds.isNotEmpty ? preds[0].length : 0);

    // we assume classes start at index 4
    for (int i = 0; i < N; i++) {
      for (int c = 4; c < min(C, 4 + numClasses); c++) {
        list.add({
          "classId": c - 4,
          "prob": preds[c][i],
          "label": labelFromId(c - 4),
        });
      }
    }

    list.sort((a, b) => (b["prob"] as double).compareTo(a["prob"] as double));

    for (int i = 0; i < min(10, list.length); i++) {
      _log("${i + 1}) ${list[i]["label"]} (${list[i]["classId"]}) → ${(list[i]["prob"] as double).toStringAsFixed(6)}");
    }
  }

  // ===========================================================
  // PROCESS OUTPUT -> same logic as before, but uses dynamic dims
  // finalP is [C][N]
  // ===========================================================
  List<Detection> _process(List<List<double>> p, int w0, int h0) {
    final detections = <Detection>[];
    Detection? fallback;

    final C = p.length;
    final N = (C > 0 ? p[0].length : 0);
    _log("Processing outputs: channels=$C, boxes=$N");

    for (int i = 0; i < N; i++) {
      double bestProb = -99;
      int bestClass = -1;

      // prediction classes (assume classes start at index 4)
      for (int c = 4; c < min(C, 4 + numClasses); c++) {
        double val = p[c][i];
        if (val > bestProb) {
          bestProb = val;
          bestClass = c - 4;
        }
      }

      if (fallback == null || bestProb > fallback.confidence) {
        fallback = Detection(labelFromId(bestClass), bestProb, BBox(l: 0, t: 0, r: 0, b: 0));
      }

      if (bestProb < 0.10) continue;

      // ensure indices exist for bbox coords at p[0..3][i]
      // ignore: prefer_is_empty
      final cx = (p.length > 0 && p[0].length > i) ? p[0][i] : 0.0;
      final cy = (p.length > 1 && p[1].length > i) ? p[1][i] : 0.0;
      final w = (p.length > 2 && p[2].length > i) ? p[2][i] : 0.0;
      final h = (p.length > 3 && p[3].length > i) ? p[3][i] : 0.0;

      final left = (cx - w / 2) * w0 / inputSize;
      final top = (cy - h / 2) * h0 / inputSize;
      final right = (cx + w / 2) * w0 / inputSize;
      final bottom = (cy + h / 2) * h0 / inputSize;

      detections.add(Detection(
        labelFromId(bestClass),
        bestProb,
        BBox(
          l: left.clamp(0, w0.toDouble()),
          t: top.clamp(0, h0.toDouble()),
          r: right.clamp(0, w0.toDouble()),
          b: bottom.clamp(0, h0.toDouble()),
        ),
      ));
    }

    if (detections.isEmpty) {
      if (fallback != null) return [fallback];
      return [];
    }

    return detections;
  }

  // ===========================================================
  // close interpreter
  // ===========================================================
  void close() {
    try {
      _interpreter?.close();
      ready = false;
      _log("YOLO Interpreter closed ✔");
    } catch (e, st) {
      _logException(e, st);
    }
  }
}

class Detection {
  final String label;
  final double confidence;
  final BBox bbox;

  Detection(this.label, this.confidence, this.bbox);
}

class BBox {
  final double l, t, r, b;
  BBox({required this.l, required this.t, required this.r, required this.b});
}