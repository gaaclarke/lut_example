import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For AssetManifest
import 'lut_parser.dart';

// This is disabled by default since the API is experimental in 3.41. There is
// a known bug in Vulkan that is fixed in the `main` branch. I'm not certain
// when it will be available in a stable release.
bool useGetUniformAPI = false;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LUT Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'LUT Filter Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ui.Image? _image;
  ui.Image? _lutImage;
  ui.FragmentProgram? _program;
  List<String> _lutFiles = [];
  String? _selectedLut;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    _program = await ui.FragmentProgram.fromAsset('shaders/lut.frag');

    final ByteData imageData = await rootBundle.load('assets/wonka.png');
    final ui.Codec codec = await ui.instantiateImageCodec(
      imageData.buffer.asUint8List(),
    );
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    _image = frameInfo.image;

    final AssetManifest manifest = await AssetManifest.loadFromAssetBundle(
      rootBundle,
    );
    final List<String> assets = manifest.listAssets();
    _lutFiles = assets
        .where(
          (path) => path.startsWith('assets/luts/') && path.endsWith('.CUBE'),
        )
        .toList();
    _lutFiles.sort();

    if (_lutFiles.isNotEmpty) {
      _selectedLut = _lutFiles.first;
      await _loadLut(_selectedLut!);
    }

    setState(() {
      _loading = false;
    });
  }

  Future<void> _loadLut(String path) async {
    final ui.Image lut = await LutParser.parseCube(path);
    setState(() {
      _lutImage = lut;
      _selectedLut = path;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_image != null && _program != null)
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                          width: _image!.width.toDouble(),
                          height: _image!.height.toDouble(),
                          child: CustomPaint(
                            painter: LutPainter(
                              image: _image!,
                              lut: _lutImage,
                              program: _program!,
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  DropdownButton<String>(
                    value: _selectedLut,
                    items: _lutFiles.map((String path) {
                      final String name = path
                          .split('/')
                          .last
                          .replaceAll('.CUBE', '');
                      return DropdownMenuItem<String>(
                        value: path,
                        child: Text(name),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        _loadLut(newValue);
                      }
                    },
                  ),
                  const SizedBox(height: 50),
                ],
              ),
      ),
    );
  }
}

/// A custom painter that applies a LUT shader to an image.
class LutPainter extends CustomPainter {
  final ui.Image image;
  final ui.Image? lut;
  final ui.FragmentProgram program;

  /// Creates a [LutPainter].
  ///
  /// - [image]: The source image to be filtered.
  /// - [lut]: The flattened 2D LUT texture (e.g., 1024x32).
  /// - [program]: A compiled [ui.FragmentProgram] for the 'lut.frag' shader.
  ///
  /// If [lut] is provided, it configures the shader with the image and LUT samplers
  /// and draws the filtered result. Otherwise, it draws the raw [image].
  LutPainter({required this.image, required this.lut, required this.program});

  @override
  void paint(Canvas canvas, Size size) {
    if (lut == null) {
      canvas.drawImage(image, Offset.zero, Paint());
      return;
    }

    final ui.FragmentShader shader = program.fragmentShader();

    if (useGetUniformAPI) {
      shader.getImageSampler('uTexture').set(image);
      shader.getImageSampler('uLut').set(lut!);
      shader.getUniformVec2('uSize').set(size.width, size.height);
      shader.getUniformFloat('uIntensity').set(1.0);
    } else {
      shader.setImageSampler(0, image);
      shader.setImageSampler(1, lut!);
      shader.setFloat(0, size.width);
      shader.setFloat(1, size.height);
      shader.setFloat(2, 1.0); // uIntensity
    }

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(covariant LutPainter oldDelegate) {
    return oldDelegate.image != image || oldDelegate.lut != lut;
  }
}
