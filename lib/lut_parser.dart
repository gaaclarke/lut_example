import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

class LutParser {
  static Future<ui.Image> parseCube(
    String assetPath, {
    AssetBundle? bundle,
  }) async {
    final String content = await (bundle ?? rootBundle).loadString(assetPath);
    final LutData lutData = parseCubeContent(content);

    final int width = lutData.size * lutData.size;
    final int height = lutData.size;

    final ui.Image image = ui.decodeImageFromPixelsSync(
      lutData.pixels.buffer.asUint8List(),
      width,
      height,
      ui.PixelFormat.rgbaFloat32,
    );
    return image;
  }

  /// Parses the string content of a .cube file.
  ///
  /// This method expects the content to be in the Adobe Cube format.
  /// It parses the 3D LUT size and data points, then flattens the 3D data
  /// into a 2D texture strip suitable for use in shaders.
  ///
  /// The resulting [LutData] contains:
  /// - [size]: The dimension of the 3D LUT (e.g., 32 for a 32x32x32 LUT).
  /// - [pixels]: A [Float32List] of RGBA values.
  ///
  /// The layout of the flattened texture is:
  /// - Width: size * size
  /// - Height: size
  /// - Each "slice" of the cube (for a given Blue value) is laid out horizontally.
  /// - Within each slice, R is the X-axis and G is the Y-axis.
  static LutData parseCubeContent(String content) {
    final List<String> lines = content.split('\n');

    int size = 0;
    final List<double> data = [];

    // Simple parser
    for (String line in lines) {
      line = line.trim();
      if (line.isEmpty || line.startsWith('#')) continue;

      if (line.startsWith('LUT_3D_SIZE')) {
        size = int.parse(line.split(' ').last);
        continue;
      }

      if (line.startsWith('TITLE') || line.startsWith('DOMAIN')) continue;

      // Parse data points
      final parts = line.split(RegExp(r'\s+'));
      if (parts.length >= 3) {
        try {
          data.add(double.parse(parts[0]));
          data.add(double.parse(parts[1]));
          data.add(double.parse(parts[2]));
        } catch (e) {
          // Skip headers or malformed lines that might have slipped through
        }
      }
    }

    if (size == 0) {
      if (data.length == 32 * 32 * 32 * 3) {
        size = 32;
      } else {
        throw Exception('Invalid LUT size or missing LUT_3D_SIZE');
      }
    }

    // Convert to RGBA Float32
    final int width = size * size;
    final int height = size;
    final Float32List pixels = Float32List(width * height * 4);

    // Data is R G B floats 0..1
    // Layout: B outer, G middle, R inner.
    // We map to Texture (X, Y):
    // X = b * size + r
    // Y = g

    int dataIndex = 0;
    for (int b = 0; b < size; b++) {
      for (int g = 0; g < size; g++) {
        for (int r = 0; r < size; r++) {
          final double red = data[dataIndex++];
          final double green = data[dataIndex++];
          final double blue = data[dataIndex++];

          final int x = b * size + r;
          final int y = g;
          final int pixelIndex = (y * width + x) * 4;

          pixels[pixelIndex + 0] = red;
          pixels[pixelIndex + 1] = green;
          pixels[pixelIndex + 2] = blue;
          pixels[pixelIndex + 3] = 1.0;
        }
      }
    }

    return LutData(size, pixels);
  }
}

class LutData {
  final int size;
  final Float32List pixels;

  LutData(this.size, this.pixels);
}
