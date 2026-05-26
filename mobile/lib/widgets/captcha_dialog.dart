import 'package:flutter/material.dart';
import 'dart:math';
import '../config/theme.dart';

class SimpleCaptcha {
  final String question;
  final int correctAnswer;

  SimpleCaptcha({required this.question, required this.correctAnswer});

  factory SimpleCaptcha.generate() {
    final random = Random();
    final num1 = random.nextInt(10) + 1;  // 1-10
    final num2 = random.nextInt(10) + 1;  // 1-10
    final operation = random.nextInt(3);
    
    late int answer;
    late String op;
    
    switch (operation) {
      case 0: // Addition
        answer = num1 + num2;
        op = '+';
        break;
      case 1: // Subtraction
        answer = num1 - num2;
        op = '-';
        break;
      case 2: // Multiplication
        answer = num1 * num2;
        op = '×';
        break;
    }

    return SimpleCaptcha(
      question: '$num1 $op $num2 = ?',
      correctAnswer: answer,
    );
  }
}

class CaptchaDialog extends StatefulWidget {
  final String title;
  final String message;
  final VoidCallback onSuccess;
  
  const CaptchaDialog({
    super.key,
    this.title = 'Verify Action',
    this.message = 'Answer the security question to continue',
    required this.onSuccess,
  });

  @override
  State<CaptchaDialog> createState() => _CaptchaDialogState();
}

class _CaptchaDialogState extends State<CaptchaDialog> {
  late SimpleCaptcha _captcha;
  late TextEditingController _answerController;
  bool _answered = false;
  bool _isCorrect = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _captcha = SimpleCaptcha.generate();
    _answerController = TextEditingController();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _checkAnswer() {
    final userAnswer = int.tryParse(_answerController.text.trim());
    setState(() {
      _answered = true;
      if (userAnswer == _captcha.correctAnswer) {
        _isCorrect = true;
        _error = null;
        // Delay to show success feedback
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pop(context, true);
            widget.onSuccess();
          }
        });
      } else {
        _isCorrect = false;
        _error = 'Incorrect answer. Try again.';
      }
    });
  }

  void _retry() {
    setState(() {
      _captcha = SimpleCaptcha.generate();
      _answerController.clear();
      _answered = false;
      _isCorrect = false;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.message,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
            ),
            child: Text(
              _captcha.question,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _answerController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Your Answer',
              hintText: 'Enter the answer',
              enabled: !_isCorrect,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              prefixIcon: const Icon(Icons.check_circle),
            ),
            onSubmitted: (_) => !_isCorrect && !_answered ? _checkAnswer() : null,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_isCorrect) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: AppTheme.primary, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Verification successful',
                      style: TextStyle(color: AppTheme.primary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (!_isCorrect && _answered)
          TextButton(
            onPressed: _retry,
            child: const Text('Try Again'),
          )
        else if (!_isCorrect)
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
        if (!_isCorrect)
          FilledButton(
            onPressed: _answered ? null : _checkAnswer,
            child: const Text('Verify'),
          ),
      ],
    );
  }
}
