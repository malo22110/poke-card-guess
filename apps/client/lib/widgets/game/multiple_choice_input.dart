import 'package:flutter/material.dart';

class MultipleChoiceInput extends StatelessWidget {
  final List<String> choices;
  final ValueChanged<String> onChoiceSelected;
  final VoidCallback onGiveUp;
  final bool isSubmitting;

  const MultipleChoiceInput({
    super.key,
    required this.choices,
    required this.onChoiceSelected,
    required this.onGiveUp,
    this.isSubmitting = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: choices.map((choice) => SizedBox(
            width: MediaQuery.of(context).size.width > 400 ? 180 : MediaQuery.of(context).size.width * 0.4,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : () => onChoiceSelected(choice),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                backgroundColor: Colors.white.withOpacity(0.9),
                foregroundColor: const Color(0xFF3B4CCA),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                choice,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )).toList(),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: isSubmitting ? null : onGiveUp,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white30,
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
    );
  }
}
