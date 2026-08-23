import 'dart:io';
import 'package:flutter/material.dart';

class ImageOcclusionWidget extends StatelessWidget {
  final String imagePath;
  final Map<String, dynamic> activeRegion;
  final List<dynamic> allRegions;
  final bool isBack;

  const ImageOcclusionWidget({
    Key? key,
    required this.imagePath,
    required this.activeRegion,
    required this.allRegions,
    required this.isBack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const primaryGold = Color(0xFFE3C36C);
    const hiddenColor = Color(0xFF15130F); // Hide using background color

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E1D9).withOpacity(0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              alignment: Alignment.center,
              children: [
                Image.file(
                  File(imagePath),
                  fit: BoxFit.contain,
                ),
                // Overlay masks
                Positioned.fill(
                  child: Stack(
                    children: allRegions.map((reg) {
                      final region = reg as Map<String, dynamic>;
                      final rx = (region['x'] as num).toDouble();
                      final ry = (region['y'] as num).toDouble();
                      final rw = (region['width'] as num).toDouble();
                      final rh = (region['height'] as num).toDouble();

                      final isActive = region['x'] == activeRegion['x'] &&
                          region['y'] == activeRegion['y'] &&
                          region['width'] == activeRegion['width'] &&
                          region['height'] == activeRegion['height'];

                      if (isActive) {
                        return Positioned(
                          left: rx * constraints.maxWidth,
                          top: ry * constraints.maxHeight,
                          width: rw * constraints.maxWidth,
                          height: rh * constraints.maxHeight,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isBack ? Colors.transparent : primaryGold.withOpacity(0.85),
                              border: Border.all(
                                color: primaryGold,
                                width: 2,
                              ),
                            ),
                          ),
                        );
                      }

                      // Non-active regions are always hidden
                      return Positioned(
                        left: rx * constraints.maxWidth,
                        top: ry * constraints.maxHeight,
                        width: rw * constraints.maxWidth,
                        height: rh * constraints.maxHeight,
                        child: Container(
                          color: hiddenColor,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
