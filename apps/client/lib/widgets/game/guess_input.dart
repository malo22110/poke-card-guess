import 'package:flutter/material.dart';

class GuessInput extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onGuessSubmitted;
  final VoidCallback onGiveUp;

  const GuessInput({
    super.key,
    required this.controller,
    required this.onGuessSubmitted,
    required this.onGiveUp,
  });

  @override
  State<GuessInput> createState() => _GuessInputState();
}

class _GuessInputState extends State<GuessInput> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    // Request focus immediately when the widget is built/shown (e.g. start of round)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            autofocus: true,
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: 'Who\'s that Pokemon?',
              hintStyle: const TextStyle(color: Colors.black54),
              filled: true,
              fillColor: Colors.white.withOpacity(0.9), // Lighter background
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF3B4CCA), width: 3),
              ),
              prefixIcon: const Icon(Icons.search, color: Colors.black54),
              suffixIcon: IconButton(
                icon: const Icon(Icons.send, color: Color(0xFF3B4CCA)),
                onPressed: widget.onGuessSubmitted,
              ),
            ),
            onSubmitted: (_) => widget.onGuessSubmitted(),
            textInputAction: TextInputAction.send,
            cursorColor: const Color(0xFF3B4CCA),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            TextButton(
              onPressed: widget.onGiveUp,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.black.withOpacity(0.3),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
              ),
              child: const Text('Give Up'),
            ),
          ],
        ),
      ],
    );
  }
}
