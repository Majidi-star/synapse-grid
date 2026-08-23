import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class OcclusionRegion {
  final double x; // 0.0 to 1.0
  final double y; // 0.0 to 1.0
  final double width; // 0.0 to 1.0
  final double height; // 0.0 to 1.0

  OcclusionRegion({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory OcclusionRegion.fromJson(Map<String, dynamic> json) {
    return OcclusionRegion(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'width': width,
        'height': height,
      };
}

class ImageOcclusionEditor extends StatefulWidget {
  final String? initialImageFilePath;
  final List<OcclusionRegion> initialRegions;
  final Function(String? imageFilePath, List<OcclusionRegion> regions) onChanged;

  const ImageOcclusionEditor({
    Key? key,
    this.initialImageFilePath,
    required this.initialRegions,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<ImageOcclusionEditor> createState() => _ImageOcclusionEditorState();
}

class _ImageOcclusionEditorState extends State<ImageOcclusionEditor> {
  String? _imageFilePath;
  List<OcclusionRegion> _regions = [];
  final ImagePicker _picker = ImagePicker();

  Offset? _startNormalizedOffset;
  Offset? _currentNormalizedOffset;

  final GlobalKey _imageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _imageFilePath = widget.initialImageFilePath;
    _regions = List.from(widget.initialRegions);
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFilePath = image.path;
        _regions.clear();
      });
      widget.onChanged(_imageFilePath, _regions);
    }
  }

  void _clearRegions() {
    setState(() {
      _regions.clear();
    });
    widget.onChanged(_imageFilePath, _regions);
  }

  void _handlePanStart(DragStartDetails details) {
    final RenderBox? renderBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPosition = renderBox.globalToLocal(details.globalPosition);
    final size = renderBox.size;

    if (localPosition.dx >= 0 &&
        localPosition.dx <= size.width &&
        localPosition.dy >= 0 &&
        localPosition.dy <= size.height) {
      setState(() {
        _startNormalizedOffset = Offset(
          localPosition.dx / size.width,
          localPosition.dy / size.height,
        );
        _currentNormalizedOffset = _startNormalizedOffset;
      });
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final RenderBox? renderBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || _startNormalizedOffset == null) return;

    final localPosition = renderBox.globalToLocal(details.globalPosition);
    final size = renderBox.size;

    // Clamp values between 0.0 and 1.0
    final dx = (localPosition.dx / size.width).clamp(0.0, 1.0);
    final dy = (localPosition.dy / size.height).clamp(0.0, 1.0);

    setState(() {
      _currentNormalizedOffset = Offset(dx, dy);
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_startNormalizedOffset != null && _currentNormalizedOffset != null) {
      final x = double.parse((_startNormalizedOffset!.dx < _currentNormalizedOffset!.dx
              ? _startNormalizedOffset!.dx
              : _currentNormalizedOffset!.dx)
          .toStringAsFixed(4));
      final y = double.parse((_startNormalizedOffset!.dy < _currentNormalizedOffset!.dy
              ? _startNormalizedOffset!.dy
              : _currentNormalizedOffset!.dy)
          .toStringAsFixed(4));
      final w = double.parse((_startNormalizedOffset!.dx - _currentNormalizedOffset!.dx).abs().toStringAsFixed(4));
      final h = double.parse((_startNormalizedOffset!.dy - _currentNormalizedOffset!.dy).abs().toStringAsFixed(4));

      // Don't add tiny click noise boxes
      if (w > 0.01 && h > 0.01) {
        setState(() {
          _regions.add(OcclusionRegion(x: x, y: y, width: w, height: h));
        });
        widget.onChanged(_imageFilePath, _regions);
      }
    }

    setState(() {
      _startNormalizedOffset = null;
      _currentNormalizedOffset = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryGold = Color(0xFFE3C36C);
    const surfaceContainer = Color(0xFF21201B);
    const onSurface = Color(0xFFE7E2DA);
    const onSurfaceVariant = Color(0xFFCFC5B3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Image Occlusion',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: onSurface,
              ),
            ),
            Row(
              children: [
                if (_imageFilePath != null)
                  TextButton(
                    onPressed: _clearRegions,
                    child: const Text(
                      'Clear Masks',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        color: Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGold,
                    foregroundColor: const Color(0xFF15130F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.image_outlined, size: 18),
                  label: Text(
                    _imageFilePath == null ? 'Upload Image' : 'Change Image',
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_imageFilePath == null)
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: onSurface.withOpacity(0.05)),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 48,
                    color: onSurfaceVariant.withOpacity(0.4),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Upload an image to start masking',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      color: onSurfaceVariant.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Drag/Draw rectangles on the image to create masks.',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  color: onSurfaceVariant.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: onSurface.withOpacity(0.1)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      GestureDetector(
                        onPanStart: _handlePanStart,
                        onPanUpdate: _handlePanUpdate,
                        onPanEnd: _handlePanEnd,
                        child: Stack(
                          key: _imageKey,
                          children: [
                            Image.file(
                              File(_imageFilePath!),
                              fit: BoxFit.contain,
                            ),
                            // Draw existing regions
                            ..._regions.asMap().entries.map((entry) {
                              final index = entry.key;
                              final region = entry.value;
                              return Positioned.fill(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return Stack(
                                      children: [
                                        Positioned(
                                          left: region.x * constraints.maxWidth,
                                          top: region.y * constraints.maxHeight,
                                          width: region.width * constraints.maxWidth,
                                          height: region.height * constraints.maxHeight,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: primaryGold.withOpacity(0.3),
                                              border: Border.all(color: primaryGold, width: 1.5),
                                            ),
                                            child: Align(
                                              alignment: Alignment.topRight,
                                              child: GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    _regions.removeAt(index);
                                                  });
                                                  widget.onChanged(_imageFilePath, _regions);
                                                },
                                                child: Container(
                                                  color: Colors.red,
                                                  child: const Icon(
                                                    Icons.close,
                                                    size: 14,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              );
                            }).toList(),
                            // Draw active drawing box
                            if (_startNormalizedOffset != null && _currentNormalizedOffset != null)
                              Positioned.fill(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final startX = _startNormalizedOffset!.dx * constraints.maxWidth;
                                    final startY = _startNormalizedOffset!.dy * constraints.maxHeight;
                                    final currentX = _currentNormalizedOffset!.dx * constraints.maxWidth;
                                    final currentY = _currentNormalizedOffset!.dy * constraints.maxHeight;

                                    final left = startX < currentX ? startX : currentX;
                                    final top = startY < currentY ? startY : currentY;
                                    final width = (startX - currentX).abs();
                                    final height = (startY - currentY).abs();

                                    return Stack(
                                      children: [
                                        Positioned(
                                          left: left,
                                          top: top,
                                          width: width,
                                          height: height,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: primaryGold.withOpacity(0.15),
                                              border: Border.all(color: primaryGold, width: 1.5, style: BorderStyle.solid),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
