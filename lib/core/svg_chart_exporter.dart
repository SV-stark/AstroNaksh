import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';

/// SVG chart export service (E8).
/// Generates scalable SVG representations of North Indian charts
/// for high-quality print and web sharing.
class SvgChartExporter {
  static const _signNames = [
    'Ari',
    'Tau',
    'Gem',
    'Can',
    'Leo',
    'Vir',
    'Lib',
    'Sco',
    'Sag',
    'Cap',
    'Aqu',
    'Pis',
  ];

  /// Export a chart as SVG string.
  static String toSvg({
    required Map<int, List<String>> planetsBySign,
    required int ascendantSign,
    double size = 500,
    String? title,
  }) {
    final half = size / 2;
    final q = size / 4;

    final sb = StringBuffer();
    sb.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    sb.writeln(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 $size $size" width="$size" height="$size">',
    );

    // Background
    sb.writeln('<rect width="$size" height="$size" fill="#1a1a2e"/>');

    // Chart lines (North Indian diamond pattern)
    sb.writeln('<g stroke="#e0e0e0" stroke-width="1.5" fill="none">');
    sb.writeln('<rect x="0" y="0" width="$size" height="$size"/>');
    sb.writeln('<line x1="0" y1="0" x2="$size" y2="$size"/>');
    sb.writeln('<line x1="$size" y1="0" x2="0" y2="$size"/>');
    sb.writeln('<polygon points="$half,0 $size,$half $half,$size 0,$half"/>');
    sb.writeln('</g>');

    // House numbers
    sb.writeln(
      '<g font-size="${size * 0.025}" fill="#888" font-family="monospace" text-anchor="middle">',
    );
    final housePositions = _getHousePositions(half, q);
    for (var i = 0; i < 12; i++) {
      final p = housePositions[i];
      sb.writeln('<text x="${p.x}" y="${p.y}">${i + 1}</text>');
    }
    sb.writeln('</g>');

    // Ascendant marker
    final ascPos = housePositions[0];
    sb.writeln(
      '<text x="${ascPos.x}" y="${ascPos.y - size * 0.01}" '
      'font-size="${size * 0.02}" fill="#00e5ff" font-family="monospace" '
      'text-anchor="middle" font-weight="bold">Asc</text>',
    );

    // Planets by sign
    final signHouseMap = _signToHouse(ascendantSign);
    sb.writeln(
      '<g font-size="${size * 0.03}" fill="#fff" font-family="monospace" text-anchor="middle">',
    );
    for (final entry in planetsBySign.entries) {
      final signIndex = entry.key;
      final houseIndex = signHouseMap[signIndex] ?? 0;
      final planets = entry.value;
      if (planets.isEmpty) continue;

      final center = _houseCenter(houseIndex, half, q);
      for (var i = 0; i < planets.length; i++) {
        final y = center.y + (i - (planets.length - 1) / 2) * size * 0.04;
        sb.writeln('<text x="${center.x}" y="$y">${planets[i]}</text>');
      }
    }
    sb.writeln('</g>');

    // Sign labels at house corners
    sb.writeln(
      '<g font-size="${size * 0.018}" fill="#666" font-family="monospace" text-anchor="middle">',
    );
    for (var i = 0; i < 12; i++) {
      final signIdx = (ascendantSign + i) % 12;
      final pos = _houseCenter(i, half, q);
      sb.writeln(
        '<text x="${pos.x}" y="${pos.y + size * 0.035}">${_signNames[signIdx]}</text>',
      );
    }
    sb.writeln('</g>');

    // Title
    if (title != null) {
      sb.writeln(
        '<text x="$half" y="${size - size * 0.03}" '
        'font-size="${size * 0.035}" fill="#e0e0e0" font-family="sans-serif" '
        'text-anchor="middle" font-weight="bold">$title</text>',
      );
    }

    sb.writeln('</svg>');
    return sb.toString();
  }

  /// Save chart as SVG file.
  static Future<String> saveAsFile({
    required Map<int, List<String>> planetsBySign,
    required int ascendantSign,
    required String fileName,
    double size = 500,
    String? title,
  }) async {
    final svg = toSvg(
      planetsBySign: planetsBySign,
      ascendantSign: ascendantSign,
      size: size,
      title: title,
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(svg);
    return file.path;
  }

  static Map<int, int> _signToHouse(int ascendantSign) {
    final map = <int, int>{};
    for (var house = 0; house < 12; house++) {
      final sign = (ascendantSign + house) % 12;
      map[sign] = house;
    }
    return map;
  }

  static List<_Pt> _getHousePositions(double half, double q) => [
    _Pt(half, q),
    _Pt(q * 3, q * 0.5),
    _Pt(q * 3, q * 1.5),
    _Pt(q * 3, q * 2.5),
    _Pt(q * 3, q * 3.5),
    _Pt(half, q * 3),
    _Pt(q, q * 3.5),
    _Pt(q, q * 2.5),
    _Pt(q, q * 1.5),
    _Pt(q, q * 0.5),
    _Pt(half, q * 0.5),
    _Pt(half, q * 1.5),
  ];

  static _Pt _houseCenter(int house, double half, double q) {
    switch (house) {
      case 0:
        return _Pt(half, q);
      case 1:
        return _Pt(q * 3, q * 0.5);
      case 2:
        return _Pt(q * 3, q * 1.5);
      case 3:
        return _Pt(q * 3, q * 2.5);
      case 4:
        return _Pt(q * 3, q * 3.5);
      case 5:
        return _Pt(half, q * 3);
      case 6:
        return _Pt(q, q * 3.5);
      case 7:
        return _Pt(q, q * 2.5);
      case 8:
        return _Pt(q, q * 1.5);
      case 9:
        return _Pt(q, q * 0.5);
      case 10:
        return _Pt(half, q * 0.5);
      case 11:
        return _Pt(half, q * 1.5);
      default:
        return _Pt(half, half);
    }
  }
}

class _Pt {
  final double x;
  final double y;
  const _Pt(this.x, this.y);
}
