// lib/widgets/choice_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/provider/question_provider.dart';
import 'package:mgw_tutorial/models/question.dart';

class ChoiceCard extends StatelessWidget {
  final String label; // 'A', 'B', 'C', 'D'
  final String choiceText; // The actual text for the choice
  final Question question; // The question object this choice belongs to
  final bool hasSubmitted; // Whether the user has submitted the exam
  final bool isAnswerBeforeExam; // <-- Receive the parameter

  const ChoiceCard({
    super.key,
    required this.label,
    required this.choiceText,
    required this.question,
    required this.hasSubmitted,
    required this.isAnswerBeforeExam, // <-- Receive the parameter
  });

  @override
  Widget build(BuildContext context) {
    // Use Consumer to react to changes in selected answers
    return Consumer<QuestionProvider>(
      builder: (context, provider, child) {
        final selectedAnswer = provider.getSelectedAnswer(question.id);
        final bool isSelected = selectedAnswer == label;
        final bool isCorrectAnswer = question.answer == label;

        Color? cardColor;
        Color? textColor = Theme.of(context).colorScheme.onSurface; // Default text color
        Icon? trailingIcon;
        BorderSide borderSide = BorderSide.none;

        // Determine if correctness feedback should be shown
        // This happens AFTER submit, OR BEFORE submit if isAnswerBeforeExam is true AND the user has selected an answer for this question.
        final bool showCorrectnessFeedback = hasSubmitted || (isAnswerBeforeExam && selectedAnswer != null);


        if (showCorrectnessFeedback) {
          // --- Show correctness logic ---
          if (isSelected) {
             // User selected this answer
             cardColor = isCorrectAnswer
                 ? Colors.green.withOpacity(0.3) // Selected AND Correct
                 : Colors.red.withOpacity(0.3); // Selected AND Wrong
             textColor = isCorrectAnswer ? Colors.green.shade800 : Colors.red.shade800;
             trailingIcon = isCorrectAnswer
                 ? Icon(Icons.check_circle, color: Colors.green.shade800)
                 : Icon(Icons.cancel, color: Colors.red.shade800);
             borderSide = isCorrectAnswer
                ? BorderSide(color: Colors.green.shade800, width: 1.5)
                : BorderSide(color: Colors.red.shade800, width: 1.5);

          } else if (isCorrectAnswer) {
             // This is the correct answer, but the user didn't select it
             cardColor = Colors.green.withOpacity(0.3);
             textColor = Colors.green.shade800;
             trailingIcon = Icon(Icons.check_circle_outline, color: Colors.green.shade800);
             borderSide = BorderSide(color: Colors.green.shade800, width: 1.5);
          } else {
            // This is a wrong answer and the user didn't select it
            cardColor = null; // Default card color
            textColor = Theme.of(context).colorScheme.onSurface; // Default text color
            trailingIcon = null;
            borderSide = BorderSide.none;
          }
        } else {
           // --- Before submission, no correctness feedback ---
           if (isSelected) {
             // User selected this answer, but no correctness feedback yet
             cardColor = Theme.of(context).colorScheme.primary.withOpacity(0.1); // Highlight selected
             textColor = Theme.of(context).colorScheme.primary;
             borderSide = BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5);
           } else {
             // Not selected, not showing feedback
             cardColor = null;
             textColor = Theme.of(context).colorScheme.onSurface;
             borderSide = BorderSide.none;
           }
            trailingIcon = null; // No icon before feedback is shown
        }


        // Determine if the card should be tappable
        // It should NOT be tappable if:
        // 1. The exam has been submitted (hasSubmitted is true).
        // 2. Explanations are shown before submit (isAnswerBeforeExam is true) AND the user has already selected an answer for this question (selectedAnswer != null).
        final bool isTappable = !(hasSubmitted || (isAnswerBeforeExam && selectedAnswer != null));


        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          color: cardColor ?? Theme.of(context).cardColor, // Use default card color if no specific color
          shape: RoundedRectangleBorder(
             borderRadius: BorderRadius.circular(8.0),
             side: borderSide, // Apply border side
          ),
          elevation: isSelected ? 2.0 : 1.0, // Slightly more elevation when selected
          child: InkWell(
            onTap: isTappable
                ? () { provider.selectAnswer(question.id, label); }
                : null, // Disable tap if not tappable
            borderRadius: BorderRadius.circular(8.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$label. ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Expanded(
                    child: HtmlWidget(
                      choiceText,
                       textStyle: TextStyle(fontSize: 16, color: textColor),
                    ),
                  ),
                  if (trailingIcon != null) ...[
                     const SizedBox(width: 8),
                     trailingIcon,
                   ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}