import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../config/disease_ml_config.dart';
import 'tflite_helper.dart';

/// Result of running YOLOv8-seg once on a photo.
class FruitAnalysis {
  /// Largest fruit only, background painted gray — input for the
  /// validator and the disease classifier (same as Colab make_crop()).
  final img.Image crop;

  /// affected area / whole fruit × 100 (same formula as Colab).
  final double severityPercent;

  /// Number of fruits YOLO found (only the largest is analysed).
  final int fruitCount;

  final int affectedPixels;
  final int fruitPixels;

  /// Whole photo with the affected area painted red and the fruit outlined
  /// green (only when analyze(..., withMarks: true)).
  final img.Image? marked;

  const FruitAnalysis({
    required this.crop,
    required this.severityPercent,
    required this.fruitCount,
    required this.affectedPixels,
    required this.fruitPixels,
    this.marked,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal YOLO helpers
// ─────────────────────────────────────────────────────────────────────────────

class _Letterbox {
  final Float32List data;
  final int padX, padY, newW, newH;
  final double scale; // model pixels per original pixel
  _Letterbox(this.data, this.padX, this.padY, this.newW, this.newH, this.scale);
}

class _Detection {
  final double x1, y1, x2, y2; // model-input pixels
  final double score;
  final int cls;
  final int anchor;
  _Detection(
    this.x1,
    this.y1,
    this.x2,
    this.y2,
    this.score,
    this.cls,
    this.anchor,
  );
  double get area => math.max(0, x2 - x1) * math.max(0, y2 - y1);
}

double _iou(_Detection a, _Detection b) {
  final ix = math.max(0.0, math.min(a.x2, b.x2) - math.max(a.x1, b.x1));
  final iy = math.max(0.0, math.min(a.y2, b.y2) - math.max(a.y1, b.y1));
  final inter = ix * iy;
  final union = a.area + b.area - inter;
  return union <= 0 ? 0 : inter / union;
}

List<_Detection> _nms(List<_Detection> dets, double iouThreshold) {
  dets.sort((a, b) => b.score.compareTo(a.score));
  final kept = <_Detection>[];
  for (final d in dets) {
    final overlaps = kept.any(
      (k) => k.cls == d.cls && _iou(k, d) > iouThreshold,
    );
    if (!overlaps) kept.add(d);
  }
  return kept;
}

/// Fills enclosed holes in a binary mask (pixels not reachable from the border).
Uint8List _fillHoles(Uint8List m, int w, int h) {
  final outside = Uint8List(w * h);
  final queue = ListQueue<int>();
  void push(int x, int y) {
    final i = y * w + x;
    if (m[i] == 0 && outside[i] == 0) {
      outside[i] = 1;
      queue.add(i);
    }
  }

  for (var x = 0; x < w; x++) {
    push(x, 0);
    push(x, h - 1);
  }
  for (var y = 0; y < h; y++) {
    push(0, y);
    push(w - 1, y);
  }
  while (queue.isNotEmpty) {
    final i = queue.removeFirst();
    final x = i % w, y = i ~/ w;
    if (x > 0) push(x - 1, y);
    if (x < w - 1) push(x + 1, y);
    if (y > 0) push(x, y - 1);
    if (y < h - 1) push(x, y + 1);
  }
  final out = Uint8List(w * h);
  for (var i = 0; i < out.length; i++) {
    out[i] = outside[i] == 1 ? 0 : 1;
  }
  return out;
}

/// Square dilation with radius [r].
Uint8List _dilate(Uint8List m, int w, int h, int r) {
  final out = Uint8List(w * h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (m[y * w + x] == 0) continue;
      for (var dy = -r; dy <= r; dy++) {
        final yy = y + dy;
        if (yy < 0 || yy >= h) continue;
        for (var dx = -r; dx <= r; dx++) {
          final xx = x + dx;
          if (xx < 0 || xx >= w) continue;
          out[yy * w + xx] = 1;
        }
      }
    }
  }
  return out;
}

int _ci(int v, int lo, int hi) => v < lo ? lo : (v > hi ? hi : v);

int _count(Uint8List m) {
  var n = 0;
  for (final v in m) {
    n += v;
  }
  return n;
}

// ─────────────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────────────

/// YOLOv8-seg: finds the pomegranate, measures severity and makes the
/// gray-background fruit crop. Runs ONCE per photo; everything else reuses it.
class FruitSegmentationService {
  FruitSegmentationService._();
  static final FruitSegmentationService instance = FruitSegmentationService._();

  Interpreter? _seg;
  bool get isLoaded => _seg != null;

  Future<void> load() async {
    _seg ??= await TfliteHelper.load(DiseaseModels.segmenter, 'segmentation');
  }

  /// Returns `null` when no pomegranate fruit is detected.
  /// [image] should come from ImageUtils.loadForInference().
  /// [withMarks] = also draw the marked image (red lesions + green outline).
  Future<FruitAnalysis?> analyze(
    img.Image image, {
    bool withMarks = false,
    bool showAffected = true,
  }) async {
    await load();
    final seg = _seg!;

    // ── Input: [1,3,S,S] (NCHW) or [1,S,S,3] (NHWC) ──
    final inShape = seg.getInputTensor(0).shape;
    final nchw = inShape[1] == 3;
    final size = nchw ? inShape[2] : inShape[1];
    final lb = _letterbox(image, size, nchw);

    seg.getInputTensor(0).data = lb.data.buffer.asUint8List();
    seg.invoke();

    // ── Outputs: identify by rank (export order is not guaranteed) ──
    final outs = seg.getOutputTensors();
    final detT = outs.firstWhere((t) => t.shape.length == 3);
    final protoT = outs.firstWhere((t) => t.shape.length == 4);

    final out = TfliteHelper.readFloats(detT);
    final os = detT.shape;
    final channelsFirst = os[1] < os[2];
    final numCh = channelsFirst ? os[1] : os[2];
    final numAnchors = channelsFirst ? os[2] : os[1];
    double at(int c, int i) =>
        channelsFirst ? out[c * numAnchors + i] : out[i * numCh + c];

    final numClasses = DiseaseLabels.segClasses.length;
    final numCoeffs = numCh - 4 - numClasses;
    final affectedCls = DiseaseLabels.segClasses.indexOf('affected_region');
    final fruitCls = DiseaseLabels.segClasses.indexOf('fruit');

    final protos = TfliteHelper.readFloats(protoT);
    final ps = protoT.shape;
    final protoChFirst = ps[1] == numCoeffs;
    final mh = protoChFirst ? ps[2] : ps[1];
    final mw = protoChFirst ? ps[3] : ps[2];
    double proto(int k, int py, int px) => protoChFirst
        ? protos[(k * mh + py) * mw + px]
        : protos[(py * mw + px) * numCoeffs + k];

    // ── Candidate boxes ──
    final candidates = <_Detection>[];
    double maxCoord = 0;
    for (var i = 0; i < numAnchors; i++) {
      var bestCls = 0;
      var best = at(4, i);
      for (var c = 1; c < numClasses; c++) {
        final s = at(4 + c, i);
        if (s > best) {
          best = s;
          bestCls = c;
        }
      }
      if (best < DiseaseThresholds.segConfidence) continue;
      final cx = at(0, i), cy = at(1, i), w = at(2, i), h = at(3, i);
      maxCoord = math.max(maxCoord, math.max(cx + w / 2, cy + h / 2));
      candidates.add(
        _Detection(
          cx - w / 2,
          cy - h / 2,
          cx + w / 2,
          cy + h / 2,
          best,
          bestCls,
          i,
        ),
      );
    }
    // Some exports give boxes in 0..1 instead of pixels.
    final boxScale = maxCoord <= 2.0 ? size.toDouble() : 1.0;
    final dets = _nms([
      for (final d in candidates)
        _Detection(
          d.x1 * boxScale,
          d.y1 * boxScale,
          d.x2 * boxScale,
          d.y2 * boxScale,
          d.score,
          d.cls,
          d.anchor,
        ),
    ], DiseaseThresholds.segIou);

    final fruits = dets.where((d) => d.cls == fruitCls).toList();
    if (fruits.isEmpty) {
      debugPrint('🔍 Seg: no fruit detected (${dets.length} detections)');
      return null;
    }

    // ── Mask decoding at prototype resolution (e.g. 160×160) ──
    final sx = mw / size, sy = mh / size;
    final vx0 = _ci((lb.padX * sx).floor(), 0, mw);
    final vx1 = _ci(((lb.padX + lb.newW) * sx).ceil(), 0, mw);
    final vy0 = _ci((lb.padY * sy).floor(), 0, mh);
    final vy1 = _ci(((lb.padY + lb.newH) * sy).ceil(), 0, mh);

    Uint8List decode(_Detection d) {
      final m = Uint8List(mw * mh);
      final coeffs = List<double>.generate(
        numCoeffs,
        (k) => at(4 + numClasses + k, d.anchor),
      );
      final px0 = math.max(vx0, (d.x1 * sx).floor());
      final px1 = math.min(vx1, (d.x2 * sx).ceil());
      final py0 = math.max(vy0, (d.y1 * sy).floor());
      final py1 = math.min(vy1, (d.y2 * sy).ceil());
      for (var py = py0; py < py1; py++) {
        for (var px = px0; px < px1; px++) {
          var v = 0.0;
          for (var k = 0; k < numCoeffs; k++) {
            v += coeffs[k] * proto(k, py, px);
          }
          if (v > 0) m[py * mw + px] = 1; // sigmoid(v) > 0.5
        }
      }
      return m;
    }

    // 1) Largest fruit only
    Uint8List? fruitMask;
    _Detection? fruitDet;
    var bestArea = 0;
    for (final f in fruits) {
      final m = decode(f);
      final a = _count(m);
      if (a > bestArea) {
        bestArea = a;
        fruitMask = m;
        fruitDet = f;
      }
    }
    if (fruitMask == null || fruitDet == null) return null;

    // 2) Affected regions inside the fruit box (+5%)
    final ex = 0.05 * (fruitDet.x2 - fruitDet.x1);
    final ey = 0.05 * (fruitDet.y2 - fruitDet.y1);
    final bx0 = _ci(((fruitDet.x1 - ex) * sx).floor(), 0, mw);
    final bx1 = _ci(((fruitDet.x2 + ex) * sx).ceil(), 0, mw);
    final by0 = _ci(((fruitDet.y1 - ey) * sy).floor(), 0, mh);
    final by1 = _ci(((fruitDet.y2 + ey) * sy).ceil(), 0, mh);
    final affected = Uint8List(mw * mh);
    for (final d in dets.where((d) => d.cls == affectedCls)) {
      final m = decode(d);
      for (var py = by0; py < by1; py++) {
        for (var px = bx0; px < bx1; px++) {
          final i = py * mw + px;
          if (m[i] == 1) affected[i] = 1;
        }
      }
    }

    // 3) Colab severity_from_masks(): whole fruit = fruit ∪ nearby lesions,
    //    holes filled; severity = lesion / whole fruit.
    final nearR = math.max(1, (0.01 * math.max(vx1 - vx0, vy1 - vy0)).round());
    final near = _dilate(_fillHoles(fruitMask, mw, mh), mw, mh, nearR);
    final lesion = Uint8List(mw * mh);
    final union = Uint8List(mw * mh);
    for (var i = 0; i < lesion.length; i++) {
      lesion[i] = (affected[i] == 1 && near[i] == 1) ? 1 : 0;
      union[i] = (fruitMask[i] == 1 || lesion[i] == 1) ? 1 : 0;
    }
    final full = _fillHoles(union, mw, mh);
    var fullPx = 0, lesionPx = 0;
    var minX = mw, minY = mh, maxX = -1, maxY = -1;
    for (var py = 0; py < mh; py++) {
      for (var px = 0; px < mw; px++) {
        final i = py * mw + px;
        if (full[i] == 0) continue;
        fullPx++;
        if (lesion[i] == 1) lesionPx++;
        if (px < minX) minX = px;
        if (px > maxX) maxX = px;
        if (py < minY) minY = py;
        if (py > maxY) maxY = py;
      }
    }
    if (fullPx == 0) return null;
    final severity = double.parse(
      math.min(100.0, (lesionPx / fullPx) * 100).toStringAsFixed(2),
    );

    // 4) Gray-background crop in ORIGINAL image coordinates (Colab make_crop)
    double toOrigX(double px) => ((px / sx) - lb.padX) / lb.scale;
    double toOrigY(double py) => ((py / sy) - lb.padY) / lb.scale;
    final ox0 = toOrigX(minX.toDouble()), ox1 = toOrigX((maxX + 1).toDouble());
    final oy0 = toOrigY(minY.toDouble()), oy1 = toOrigY((maxY + 1).toDouble());
    final padW = (ox1 - ox0) * DiseaseImageConfig.cropPadding;
    final padH = (oy1 - oy0) * DiseaseImageConfig.cropPadding;
    final cx0 = math.max(0, (ox0 - padW).floor());
    final cy0 = math.max(0, (oy0 - padH).floor());
    final cx1 = math.min(image.width, (ox1 + padW).ceil());
    final cy1 = math.min(image.height, (oy1 + padH).ceil());
    if (cx1 - cx0 < 2 || cy1 - cy0 < 2) return null;

    final keep = _dilate(full, mw, mh, 1);
    final cw = cx1 - cx0, ch = cy1 - cy0;
    final colPx = List<int>.generate(
      cw,
      (x) => _ci((((cx0 + x) * lb.scale + lb.padX) * sx).floor(), 0, mw - 1),
    );
    final rowPy = List<int>.generate(
      ch,
      (y) => _ci((((cy0 + y) * lb.scale + lb.padY) * sy).floor(), 0, mh - 1),
    );
    const gray = DiseaseImageConfig.backgroundGray;
    final crop = img.Image(width: cw, height: ch);
    for (var y = 0; y < ch; y++) {
      final rowBase = rowPy[y] * mw;
      for (var x = 0; x < cw; x++) {
        if (keep[rowBase + colPx[x]] == 1) {
          final p = image.getPixel(cx0 + x, cy0 + y);
          crop.setPixelRgb(x, y, p.r, p.g, p.b);
        } else {
          crop.setPixelRgb(x, y, gray, gray, gray);
        }
      }
    }

    debugPrint(
      '🔍 Seg: ${fruits.length} fruit, '
      '${dets.where((d) => d.cls == affectedCls).length} affected, '
      'lesionPx=$lesionPx fruitPx=$fullPx severity=$severity%',
    );

    // 5) Marked image: red = affected area, green = fruit outline
    img.Image? marked;
    if (withMarks) {
      try {
        marked = _drawMarks(image, full, lesion, mw,
          mh,
          lb,
          sx,
          sy,
          showAffected: showAffected,
        );
      } catch (e) {
        debugPrint('Marked image failed: $e');
      }
    }

    return FruitAnalysis(
      crop: crop,
      severityPercent: severity,
      fruitCount: fruits.length,
      affectedPixels: lesionPx,
      fruitPixels: fullPx,
      marked: marked,
    );
  }

  /// Paints lesions red (60% blend) and a green outline around the fruit,
  /// on a copy of the original photo (same look as the Colab result image).
  img.Image _drawMarks(
    img.Image image,
    Uint8List full,
    Uint8List lesion,
    int mw,
    int mh,
    _Letterbox lb,
    double sx,
    double sy, {
    bool showAffected = true,
  }) {
    final w = image.width, h = image.height;
    final colPx = List<int>.generate(
      w,
      (x) => _ci(((x * lb.scale + lb.padX) * sx).floor(), 0, mw - 1),
    );
    final rowPy = List<int>.generate(
      h,
      (y) => _ci(((y * lb.scale + lb.padY) * sy).floor(), 0, mh - 1),
    );
    final t = math.max(2, (math.min(w, h) / 250).round()); // outline thickness

    bool inFruit(int x, int y) {
      if (x < 0 || y < 0 || x >= w || y >= h) return false;
      return full[rowPy[y] * mw + colPx[x]] == 1;
    }

    const a = 0.6; // red strength
    final out = img.Image.from(image);
    for (var y = 0; y < h; y++) {
      final rowBase = rowPy[y] * mw;
      for (var x = 0; x < w; x++) {
        final i = rowBase + colPx[x];
        if (full[i] == 0) continue;
        final edge =
            !inFruit(x - t, y) ||
            !inFruit(x + t, y) ||
            !inFruit(x, y - t) ||
            !inFruit(x, y + t);
        if (edge) {
          out.setPixelRgb(x, y, 34, 197, 94); // green outline
        } else if (showAffected && lesion[i] == 1) {  
          final p = image.getPixel(x, y);
          out.setPixelRgb(
            x,
            y,
            (p.r * (1 - a) + 220 * a).round(),
            (p.g * (1 - a) + 38 * a).round(),
            (p.b * (1 - a) + 38 * a).round(),
          );
        }
      }
    }
    return out;
  }

  /// Ultralytics-style letterbox: keep aspect ratio, pad with gray 114.
  _Letterbox _letterbox(img.Image src, int size, bool nchw) {
    final r = math.min(size / src.width, size / src.height);
    final newW = (src.width * r).round();
    final newH = (src.height * r).round();
    final resized = img.copyResize(
      src,
      width: newW,
      height: newH,
      interpolation: img.Interpolation.linear,
    );
    final padX = (size - newW) ~/ 2;
    final padY = (size - newH) ~/ 2;

    final plane = size * size;
    final data = Float32List(3 * plane)..fillRange(0, 3 * plane, 114 / 255.0);
    for (var y = 0; y < newH; y++) {
      for (var x = 0; x < newW; x++) {
        final p = resized.getPixel(x, y);
        final ix = (y + padY) * size + (x + padX);
        if (nchw) {
          data[ix] = p.r / 255.0;
          data[plane + ix] = p.g / 255.0;
          data[2 * plane + ix] = p.b / 255.0;
        } else {
          data[ix * 3] = p.r / 255.0;
          data[ix * 3 + 1] = p.g / 255.0;
          data[ix * 3 + 2] = p.b / 255.0;
        }
      }
    }
    return _Letterbox(data, padX, padY, newW, newH, newW / src.width);
  }

  void dispose() {
    _seg?.close();
    _seg = null;
  }
}
