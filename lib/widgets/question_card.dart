// lib/widgets/question_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/models/question.dart';
import 'package:mgw_tutorial/widgets/choice_card.dart';
import 'package:mgw_tutorial/provider/question_provider.dart'; // <-- ADD THIS IMPORT


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
  bool _showExplanations = false;

  @override
  Widget build(BuildContext context) {
    final questionProvider = Provider.of<QuestionProvider>(context, listen: false);
    final bool hasAnswered = questionProvider.selectedAnswers.containsKey(widget.question.id);


    // Logic to determine if the "Show Explanation" button should be visible:
    // 1. Always visible if already submitted AND exam explanations are after submit (isAnswerBeforeExam is false).
    // 2. Visible before submit if exam explanations are before submit (isAnswerBeforeExam is true) AND user has answered this question.
    final bool canShowExplanationButton =
        (widget.hasSubmitted && !widget.isAnswerBeforeExam) ||
        (!widget.hasSubmitted && widget.isAnswerBeforeExam && hasAnswered);

    // Reset the internal _showExplanations state if the submitted state changes
    // This ensures explanations collapse when the exam is submitted, unless the exam type means they should immediately reappear.
    // A better approach might be to control _showExplanations externally or sync it.
    // For now, let's reset if submission status changes.
     if (widget.hasSubmitted && !_showExplanations && !widget.isAnswerBeforeExam && widget.question.explanation != null && widget.question.explanation!.isNotEmpty) {
        // If submitted and explanations are *after* submit, show them by default if the button is tappable
        // setState(() { _showExplanations = true; }); // Decide if you want to auto-expand on submit
     } else if (!widget.hasSubmitted && _showExplanations && widget.isAnswerBeforeExam && !hasAnswered) {
        // If not submitted, explanations before submit, but the user hasn't answered yet, hide the explanation.
        // setState(() { _showExplanations = false; }); // Ensure it's hidden if requirements aren't met
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

            // Explanation Content - Show only if button is visible (logically) AND toggled on
            // The explanation content visibility relies on the _showExplanations toggle state
            // which is only relevant if canShowExplanationButton is true.
            if (_showExplanations && widget.question.explanation != null && widget.question.explanation!.isNotEmpty) ...[
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