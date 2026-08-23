import 'package:flutter/material.dart';

class ClozeEditor extends StatefulWidget {
  final String initialText;
  final Function(String clozeText) onChanged;

  const ClozeEditor({
    Key? key,
    required this.initialText,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<ClozeEditor> createState() => _ClozeEditorState();
}

class _ClozeEditorState extends State<ClozeEditor> {
  late final TextEditingController _controller;
  int _clozeIndex = 1;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _controller.addListener(_onTextChanged);
    _detectNextClozeIndex();
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    widget.onChanged(_controller.text);
    _detectNextClozeIndex();
  }

  void _detectNextClozeIndex() {
    final text = _controller.text;
    final regex = RegExp(r'\{\{c(\d+)::');
    final matches = regex.allMatches(text);
    if (matches.isEmpty) {
      if (mounted) {
        setState(() {
          _clozeIndex = 1;
        });
      }
      return;
    }
    int maxIndex = 0;
    for (final match in matches) {
      final index = int.tryParse(match.group(1) ?? '0') ?? 0;
      if (index > maxIndex) {
        maxIndex = index;
      }
    }
    if (mounted) {
      setState(() {
        _clozeIndex = maxIndex + 1;
      });
    }
  }

  void _addClozeDeletion() {
    final text = _controller.text;
    final selection = _controller.selection;

    if (selection.isCollapsed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select some text to hide first')),
      );
      return;
    }

    final selectedText = text.substring(selection.start, selection.end);
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      '{{c$_clozeIndex::$selectedText}}',
    );

    _controller.text = newText;
    _controller.selection = TextSelection.collapsed(
      offset: selection.start + '{{c$_clozeIndex::'.length + selectedText.length + 2,
    );
  }

  String _renderPreview() {
    final text = _controller.text;
    final regex = RegExp(r'\{\{c\d+::(.*?)\}\}');
    return text.replaceAllMapped(regex, (match) => '[...]');
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
              'Cloze Text',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: onSurface,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _addClozeDeletion,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGold,
                foregroundColor: const Color(0xFF15130F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              icon: const Icon(Icons.visibility_off_outlined, size: 18),
              label: Text(
                'Hide Selection (c$_clozeIndex)',
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          maxLines: 5,
          style: const TextStyle(
            fontFamily: 'Manrope',
            color: onSurface,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: 'Enter text here, then highlight words and click the button to hide them.',
            hintStyle: TextStyle(color: onSurfaceVariant.withOpacity(0.5)),
            filled: true,
            fillColor: surfaceContainer,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: onSurface.withOpacity(0.05)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: onSurface.withOpacity(0.05)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryGold),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Live Preview (Front Side)',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: surfaceContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: onSurface.withOpacity(0.03),
            ),
          ),
          child: Text(
            _controller.text.isEmpty ? 'Preview will appear here' : _renderPreview(),
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 16,
              color: _controller.text.isEmpty ? onSurfaceVariant.withOpacity(0.5) : onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
