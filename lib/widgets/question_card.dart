// lib/widgets/question_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/models/question.dart';
import 'package:mgw_tutorial/widgets/choice_card.dart';
import 'package:mgw_tutorial/provider/question_provider.dart';

class QuestionCard extends StatefulWidget {
  final Question question;
  final int questionNumber;
  final bool hasSubmitted;
  final bool isAnswerBeforeExam;

  const QuestionCard({
    super.key,
    required this.question,
    required this.questionNumber,
    required this.hasSubmitted,
    required this.isAnswerBeforeExam,
  });

  @override
  State<QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard> {
  // State to toggle explanation visibility for THIS card.
  // Reset this state when the question data or context changes significantly (like refresh).
  bool _showExplanations = false;

  // If the question or exam setting changes, hide explanation initially
  @override
  void didUpdateWidget(covariant QuestionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Hide explanation if the question ID or the exam's explanation setting changes
    if (widget.question.id != oldWidget.question.id || widget.isAnswerBeforeExam != oldWidget.isAnswerBeforeExam) {
      _showExplanations = false;
    }
     // If the user just submitted, and explanations are shown AFTER submit,
     // you *might* want to auto-show the explanation here.
     // Currently, we rely on the user clicking the button, which is often better UX.
     // If (!oldWidget.hasSubmitted && widget.hasSubmitted && !widget.isAnswerBeforeExam) {
     //   // Check if explanation exists before trying to show it
     //   if (widget.question.explanation != null && widget.question.explanation!.isNotEmpty) {
     //      setState(() { _showExplanations = true; });
     //   }
     // }
  }


  @override
  Widget build(BuildContext context) {
    final questionProvider = Provider.of<QuestionProvider>(context); // Listen to redraw if answer changes
    final bool hasAnswered = questionProvider.selectedAnswers.containsKey(widget.question.id);

    // Logic to determine if the "Show Explanation" button should be visible:
    // 1. Visible AFTER submit if exam explanations are after submit (isAnswerBeforeExam is false).
    // 2. Visible BEFORE submit if exam explanations are before submit (isAnswerBeforeExam is true) AND user has answered this question.
    final bool canShowExplanationButton =
        (widget.hasSubmitted && !widget.isAnswerBeforeExam) ||
        (!widget.hasSubmitted && widget.isAnswerBeforeExam && hasAnswered);

    // Ensure _showExplanations is false if the button isn't supposed to be visible
    // This prevents explanation content from showing if the condition to show the button isn't met.
    if (!canShowExplanationButton && _showExplanations) {
        // Don't use setState here as it would cause infinite loops.
        // Just update the local state for this build cycle.
        // A better pattern would be to derive visibility completely, or use didUpdateWidget.
        // Let's stick to didUpdateWidget for state resets and button tap for toggling.
    }


    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.circular(10.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Text with Number
            HtmlWidget(
              '${widget.questionNumber}: ${widget.question.questionText}',
              textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),

            // Image if available
            if (widget.question.imageUrl != null && widget.question.imageUrl!.isNotEmpty) ...[
               Image.network(
                 widget.question.imageUrl!,
                 errorBuilder: (context, error, stackTrace) =>
                     const Center(child: Text('Failed to load image')),
               ),
               const SizedBox(height: 12),
             ],

             // Passage text if available
             if (widget.question.passage != null && widget.question.passage!.isNotEmpty) ...[
               Card(
                 margin: const EdgeInsets.symmetric(vertical: 8.0),
                 elevation: 0.5,
                 color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                 child: Padding(
                   padding: const EdgeInsets.all(12.0),
                   child: HtmlWidget(
                     widget.question.passage!,
                     textStyle: TextStyle(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                   ),
                 ),
               ),
               const SizedBox(height: 12),
             ],

            // Choices - Pass isAnswerBeforeExam down
            ChoiceCard(
              label: 'A',
              choiceText: widget.question.optionA,
              question: widget.question,
              hasSubmitted: widget.hasSubmitted,
              isAnswerBeforeExam: widget.isAnswerBeforeExam,
            ),
            ChoiceCard(
              label: 'B',
              choiceText: widget.question.optionB,
              question: widget.question,
              hasSubmitted: widget.hasSubmitted,
              isAnswerBeforeExam: widget.isAnswerBeforeExam,
            ),
            ChoiceCard(
              label: 'C',
              choiceText: widget.question.optionC,
              question: widget.question,
              hasSubmitted: widget.hasSubmitted,
              isAnswerBeforeExam: widget.isAnswerBeforeExam,
            ),
            ChoiceCard(
              label: 'D',
              choiceText: widget.question.optionD,
              question: widget.question,
              hasSubmitted: widget.hasSubmitted,
              isAnswerBeforeExam: widget.isAnswerBeforeExam,
            ),

            // Explanation Button - Show only if allowed based on exam setting and submission state
            if (widget.question.explanation != null && widget.question.explanation!.isNotEmpty && canShowExplanationButton) ...[
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showExplanations = !_showExplanations;
                    });
                  },
                   style: ElevatedButton.styleFrom(
                       backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                       foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                   ),
                  child: Text(
                    _showExplanations ? 'Hide Explanation' : 'Show Explanation', // TODO: Localize
                  ),
                ),
              ),
            ],

            // Explanation Content - Show only if the button can be shown AND it's toggled on (_showExplanations is true)
            if (_showExplanations && canShowExplanationButton && widget.question.explanation != null && widget.question.explanation!.isNotEmpty) ...[
               const SizedBox(height: 12),
               Card(
                 elevation: 0.5,
                 color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                 margin: EdgeInsets.zero,
                 child: Padding(
                   padding: const EdgeInsets.all(12.0),
                   child: HtmlWidget(
                     'Explanation: ${widget.question.explanation!}', // TODO: Localize "Explanation"
                      textStyle: TextStyle(
                         fontSize: 15,
                         fontStyle: FontStyle.italic,
                         color: Theme.of(context).colorScheme.onPrimaryContainer,
                       ),
                   ),
                 ),
               ),
               // TODO: Add Explanation Image/Video logic if needed
               if (widget.question.explanationImageUrl != null && widget.question.explanationImageUrl!.isNotEmpty) ...[
                 const SizedBox(height: 8),
                 Image.network(widget.question.explanationImageUrl!, errorBuilder: (context, error, stackTrace) => const Center(child: Text('Failed to load explanation image'))), // TODO: Localize
               ],
               if (widget.question.explanationVideoUrl != null && widget.question.explanationVideoUrl!.isNotEmpty) ...[
                 const SizedBox(height: 8),
                 Text('Explanation Video: ${widget.question.explanationVideoUrl!}'), // TODO: Implement video player, Localize
               ],

            ],
          ],
        ),
      ),
    );
  }
}