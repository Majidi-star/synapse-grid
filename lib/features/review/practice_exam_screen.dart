import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall_app/core/theme/app_colors.dart';
import 'package:recall_app/models/practice_exam.dart';
import 'package:recall_app/providers/practice_exam_providers.dart';

class PracticeExamScreen extends ConsumerStatefulWidget {
  final String deckId;
  final String deckName;

  const PracticeExamScreen({
    Key? key,
    required this.deckId,
    required this.deckName,
  }) : super(key: key);

  @override
  ConsumerState<PracticeExamScreen> createState() => _PracticeExamScreenState();
}

enum ExamState { setup, generating, running, grading, results }

class _PracticeExamScreenState extends ConsumerState<PracticeExamScreen> {
  ExamState _currentState = ExamState.setup;
  
  // Setup config
  int _questionCount = 5;
  int _timeLimitMinutes = 10;
  bool _includeMC = true;
  bool _includeTF = true;
  bool _includeSA = true;

  // Running exam state
  PracticeExam? _activeExam;
  int _currentQuestionIndex = 0;
  Timer? _timer;
  int _secondsRemaining = 0;

  // Results
  ExamResult? _examResult;
  String? _errorMessage;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsRemaining = _timeLimitMinutes * 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        _submitExam();
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _generateExam() async {
    setState(() {
      _currentState = ExamState.generating;
      _errorMessage = null;
    });

    final types = <String>[];
    if (_includeMC) types.add('MC');
    if (_includeTF) types.add('TF');
    if (_includeSA) types.add('ShortAnswer');

    if (types.isEmpty) {
      setState(() {
        _currentState = ExamState.setup;
        _errorMessage = 'Please select at least one question type.';
      });
      return;
    }

    try {
      final service = ref.read(practiceExamServiceProvider);
      final exam = await service.generateExam(
        widget.deckId,
        questionCount: _questionCount,
        timeLimitMinutes: _timeLimitMinutes,
        types: types,
      );

      setState(() {
        _activeExam = exam;
        _currentQuestionIndex = 0;
        _currentState = ExamState.running;
      });
      _startTimer();
    } catch (e) {
      setState(() {
        _currentState = ExamState.setup;
        _errorMessage = 'Failed to generate exam: ${e.toString()}';
      });
    }
  }

  Future<void> _submitExam() async {
    _timer?.cancel();
    setState(() {
      _currentState = ExamState.grading;
    });

    try {
      final service = ref.read(practiceExamServiceProvider);
      final result = await service.generateExamReport(_activeExam!);

      setState(() {
        _examResult = result;
        _currentState = ExamState.results;
      });
    } catch (e) {
      setState(() {
        _currentState = ExamState.results;
        _errorMessage = 'Failed to grade exam: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.onSurface),
          onPressed: () {
            if (_currentState == ExamState.running) {
              _showExitConfirmation();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          _currentState == ExamState.setup
              ? 'Setup Exam'
              : _currentState == ExamState.results
                  ? 'Exam Results'
                  : widget.deckName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.bold,
              ),
        ),
        centerTitle: true,
        actions: _currentState == ExamState.running
            ? [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Text(
                      _formatTime(_secondsRemaining),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: AppColors.primaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ]
            : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentState) {
      case ExamState.setup:
        return _buildSetupView();
      case ExamState.generating:
        return _buildLoadingView('Generating exam questions using AI...');
      case ExamState.running:
        return _buildRunningView();
      case ExamState.grading:
        return _buildLoadingView('AI is grading your responses...');
      case ExamState.results:
        return _buildResultsView();
    }
  }

  Widget _buildSetupView() {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Challenge your memory with a custom practice exam auto-generated by the AI tutor.',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 32),
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.error),
              ),
            ),
            const SizedBox(height: 24),
          ],
          Text('NUMBER OF QUESTIONS', style: textTheme.labelSmall?.copyWith(letterSpacing: 1.5, color: AppColors.primaryContainer)),
          Slider(
            value: _questionCount.toDouble(),
            min: 3,
            max: 15,
            divisions: 12,
            activeColor: AppColors.primaryContainer,
            inactiveColor: AppColors.surfaceContainerHighest,
            label: _questionCount.toString(),
            onChanged: (val) {
              setState(() {
                _questionCount = val.toInt();
              });
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$_questionCount Questions',
              style: textTheme.bodySmall?.copyWith(color: AppColors.onSurface.withValues(alpha: 0.7)),
            ),
          ),
          const SizedBox(height: 24),
          Text('TIME LIMIT (MINUTES)', style: textTheme.labelSmall?.copyWith(letterSpacing: 1.5, color: AppColors.primaryContainer)),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: _timeLimitMinutes,
            dropdownColor: AppColors.surfaceContainerHigh,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surfaceContainer,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: const [
              DropdownMenuItem(value: 3, child: Text('3 Minutes')),
              DropdownMenuItem(value: 5, child: Text('5 Minutes')),
              DropdownMenuItem(value: 10, child: Text('10 Minutes')),
              DropdownMenuItem(value: 15, child: Text('15 Minutes')),
              DropdownMenuItem(value: 20, child: Text('20 Minutes')),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _timeLimitMinutes = val;
                });
              }
            },
          ),
          const SizedBox(height: 24),
          Text('QUESTION TYPES', style: textTheme.labelSmall?.copyWith(letterSpacing: 1.5, color: AppColors.primaryContainer)),
          const SizedBox(height: 8),
          CheckboxListTile(
            title: const Text('Multiple Choice', style: TextStyle(color: AppColors.onSurface)),
            value: _includeMC,
            activeColor: AppColors.primaryContainer,
            checkColor: AppColors.background,
            onChanged: (val) => setState(() => _includeMC = val ?? false),
          ),
          CheckboxListTile(
            title: const Text('True / False', style: TextStyle(color: AppColors.onSurface)),
            value: _includeTF,
            activeColor: AppColors.primaryContainer,
            checkColor: AppColors.background,
            onChanged: (val) => setState(() => _includeTF = val ?? false),
          ),
          CheckboxListTile(
            title: const Text('Short Answer (AI Graded)', style: TextStyle(color: AppColors.onSurface)),
            value: _includeSA,
            activeColor: AppColors.primaryContainer,
            checkColor: AppColors.background,
            onChanged: (val) => setState(() => _includeSA = val ?? false),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _generateExam,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: AppColors.onPrimaryContainer,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              ),
              child: const Text('GENERATE EXAM', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView(String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primaryContainer),
          const SizedBox(height: 24),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.onSurface, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildRunningView() {
    final textTheme = Theme.of(context).textTheme;
    final q = _activeExam!.questions[_currentQuestionIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Question ${_currentQuestionIndex + 1} of ${_activeExam!.questions.length}',
              style: textTheme.labelLarge?.copyWith(color: AppColors.primaryContainer),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                q.type == 'MC'
                    ? 'Multiple Choice'
                    : q.type == 'TF'
                        ? 'True / False'
                        : 'Short Answer',
                style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  q.questionText,
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 32),
                _buildQuestionInput(q),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton(
              onPressed: _currentQuestionIndex > 0
                  ? () => setState(() => _currentQuestionIndex--)
                  : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.onSurface,
                side: BorderSide(color: AppColors.onSurface.withValues(alpha: 0.2)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Previous'),
            ),
            if (_currentQuestionIndex == _activeExam!.questions.length - 1)
              ElevatedButton(
                onPressed: _submitExam,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: AppColors.onPrimaryContainer,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Submit Exam', style: TextStyle(fontWeight: FontWeight.bold)),
              )
            else
              ElevatedButton(
                onPressed: () => setState(() => _currentQuestionIndex++),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceContainerHigh,
                  foregroundColor: AppColors.onSurface,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Next'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuestionInput(ExamQuestion q) {
    if (q.type == 'MC') {
      return Column(
        children: q.options!.map((opt) {
          final isSelected = q.userAnswer == opt;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: InkWell(
              onTap: () {
                setState(() {
                  q.userAnswer = opt;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryContainer.withValues(alpha: 0.1)
                      : AppColors.surfaceContainer,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryContainer
                        : AppColors.onSurface.withValues(alpha: 0.1),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: isSelected ? AppColors.primaryContainer : AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        opt,
                        style: TextStyle(
                          color: isSelected ? AppColors.primaryContainer : AppColors.onSurface,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      );
    } else if (q.type == 'TF') {
      return Row(
        children: ['True', 'False'].map((opt) {
          final isSelected = q.userAnswer == opt;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: InkWell(
                onTap: () {
                  setState(() {
                    q.userAnswer = opt;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryContainer.withValues(alpha: 0.1)
                        : AppColors.surfaceContainer,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryContainer
                          : AppColors.onSurface.withValues(alpha: 0.1),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: isSelected ? AppColors.primaryContainer : AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        opt,
                        style: TextStyle(
                          color: isSelected ? AppColors.primaryContainer : AppColors.onSurface,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );
    } else {
      // Short Answer Text Field
      return TextField(
        maxLines: 6,
        controller: TextEditingController(text: q.userAnswer)..selection = TextSelection.fromPosition(TextPosition(offset: (q.userAnswer ?? '').length)),
        onChanged: (val) {
          q.userAnswer = val;
        },
        decoration: InputDecoration(
          hintText: 'Type your explanation here...',
          hintStyle: TextStyle(color: AppColors.onSurface.withValues(alpha: 0.4)),
          filled: true,
          fillColor: AppColors.surfaceContainer,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.onSurface.withValues(alpha: 0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primaryContainer),
          ),
        ),
        style: const TextStyle(color: AppColors.onSurface),
      );
    }
  }

  Widget _buildResultsView() {
    final textTheme = Theme.of(context).textTheme;

    if (_examResult == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Unknown error occurred.',
              style: const TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => setState(() => _currentState = ExamState.setup),
              child: const Text('Back to Setup'),
            ),
          ],
        ),
      );
    }

    final result = _examResult!;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: result.score >= 80
                          ? AppColors.primaryContainer
                          : result.score >= 50
                              ? Colors.orange
                              : AppColors.error,
                      width: 4,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${result.score.toStringAsFixed(0)}%',
                    style: textTheme.headlineMedium?.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  result.score >= 80
                      ? 'Excellent Job!'
                      : result.score >= 50
                          ? 'Passed'
                          : 'Needs Review',
                  style: textTheme.titleMedium?.copyWith(
                    color: result.score >= 80
                        ? AppColors.primaryContainer
                        : result.score >= 50
                            ? Colors.orange
                            : AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text('AI REPORT CARD', style: textTheme.labelSmall?.copyWith(letterSpacing: 1.5, color: AppColors.primaryContainer)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.onSurface.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.aiFeedback,
                  style: const TextStyle(fontSize: 14, height: 1.4, color: AppColors.onSurface),
                ),
                if (result.weakTopics.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.outlineVariant),
                  const SizedBox(height: 12),
                  const Text(
                    'Recommended Review Topics:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryContainer, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: result.weakTopics.map((topic) {
                      return Chip(
                        label: Text(topic, style: const TextStyle(fontSize: 12)),
                        backgroundColor: AppColors.surfaceContainerHigh,
                        side: BorderSide(color: AppColors.onSurface.withValues(alpha: 0.1)),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text('QUESTION SUMMARY', style: textTheme.labelSmall?.copyWith(letterSpacing: 1.5, color: AppColors.primaryContainer)),
          const SizedBox(height: 12),
          ..._activeExam!.questions.asMap().entries.map((entry) {
            final idx = entry.key;
            final q = entry.value;
            final isCorrect = q.aiGrade == 'Correct';
            final isPartial = q.aiGrade == 'Partial';
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: ExpansionTile(
                collapsedBackgroundColor: AppColors.surfaceContainer,
                backgroundColor: AppColors.surfaceContainerHigh,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: Icon(
                  isCorrect
                      ? Icons.check_circle
                      : isPartial
                          ? Icons.warning
                          : Icons.cancel,
                  color: isCorrect
                      ? AppColors.primaryContainer
                      : isPartial
                          ? Colors.orange
                          : AppColors.error,
                ),
                title: Text(
                  'Question ${idx + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.onSurface),
                ),
                subtitle: Text(
                  q.questionText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.onSurface.withValues(alpha: 0.6), fontSize: 13),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(q.questionText, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Text('Your Answer: ${q.userAnswer ?? "(No Answer)"}', style: TextStyle(color: isCorrect ? AppColors.primaryContainer : AppColors.onSurfaceVariant)),
                        const SizedBox(height: 4),
                        Text('Correct Answer: ${q.correctAnswer}'),
                        if (q.aiFeedback != null && q.aiFeedback!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          Text('AI Evaluator: ${q.aiFeedback}', style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.onSurface,
                side: BorderSide(color: AppColors.onSurface.withValues(alpha: 0.2)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              ),
              child: const Text('BACK TO DECK', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ),
          ),
        ],
      ),
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: const Text('Abandon Exam?', style: TextStyle(color: AppColors.onSurface)),
        content: const Text(
          'If you leave now, your answers will not be graded and exam progress will be lost.',
          style: TextStyle(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL', style: TextStyle(color: AppColors.primaryContainer)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Dismiss dialog
              Navigator.of(context).pop(); // Pop screen
            },
            child: const Text('ABANDON', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
