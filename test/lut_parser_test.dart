import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:luts/lut_parser.dart';

void main() {
  test('LutParser parseCubeContent parses valid CUBE string', () {
    const String mockCubeData = '''
TITLE "Test"
LUT_3D_SIZE 2
0.0 0.0 0.0
1.0 0.0 0.0
0.0 1.0 0.0
1.0 1.0 0.0
0.0 0.0 1.0
1.0 0.0 1.0
0.0 1.0 1.0
1.0 1.0 1.0
'''; // 8 entries for 2x2x2

    final LutData result = LutParser.parseCubeContent(mockCubeData);
    
    // Expect 2x2x2 size.
    // Width = 2*2 = 4.
    // Height = 2.
    // Length = 4 * 2 * 4 = 32 floats.
    expect(result.size, 2);
    expect(result.pixels.length, 32);
    
    final Float32List pixels = result.pixels;
    
    // Check first pixel (0,0,0) -> 0,0,0
    expect(pixels[0], 0.0);
    expect(pixels[1], 0.0);
    expect(pixels[2], 0.0);
    expect(pixels[3], 1.0); // Alpha

    // Check pixel at (1,0) -> (1,0,0) -> 1.0, 0.0, 0.0
    // Index 4,5,6,7
    expect(pixels[4], 1.0);
    expect(pixels[5], 0.0);
    expect(pixels[6], 0.0);
    expect(pixels[7], 1.0);
    
    // Check last pixel (index 31 -> alpha, 30 -> b, 29 -> g, 28 -> r)
    // Last entry is 1.0 1.0 1.0
    expect(pixels[28], 1.0);
    expect(pixels[29], 1.0);
    expect(pixels[30], 1.0);
    expect(pixels[31], 1.0);
  });
}
