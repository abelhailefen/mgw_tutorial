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

        // --- Logic for Colors and Icons ---

        if (hasSubmitted) {
          // After Submission Logic: Always show correctness
          if (isSelected) {
            cardColor = isCorrectAnswer
                ? Colors.green.withOpacity(0.3) // User selected correctly
                : Colors.red.withOpacity(0.3); // User selected incorrectly
            textColor = isCorrectAnswer ? Colors.green.shade800 : Colors.red.shade800;
             trailingIcon = isCorrectAnswer
                ? Icon(Icons.check_circle, color: Colors.green.shade800)
                : Icon(Icons.cancel, color: Colors.red.shade800);
          } else if (isCorrectAnswer) {
            cardColor = Colors.green.withOpacity(0.3); // Correct answer was not selected by user
            textColor = Colors.green.shade800;
            trailingIcon = Icon(Icons.check_circle_outline, color: Colors.green.shade800);
          }
           borderSide = BorderSide.none; // No border after submit
        } else {
          // Before Submission Logic
          if (isSelected) {
            // Always highlight the selected answer
            cardColor = Theme.of(context).colorScheme.primary.withOpacity(0.1);
            textColor = Theme.of(context).colorScheme.primary;
            borderSide = BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5);

            // If explanations are before submit, show correctness FOR THE SELECTED ANSWER
            if (isAnswerBeforeExam) {
              cardColor = isCorrectAnswer
                  ? Colors.green.withOpacity(0.3) // User selected correctly before submit
                  : Colors.red.withOpacity(0.3); // User selected incorrectly before submit
              textColor = isCorrectAnswer ? Colors.green.shade800 : Colors.red.shade800;
              trailingIcon = isCorrectAnswer
                  ? Icon(Icons.check_circle, color: Colors.green.shade800)
                  : Icon(Icons.cancel, color: Colors.red.shade800);
              borderSide = isCorrectAnswer
                ? BorderSide(color: Colors.green.shade800, width: 1.5)
                : BorderSide(color: Colors.red.shade800, width: 1.5);
            }
          }
          // If not selected, no special color/icon before submit, regardless of isAnswerBeforeExam
          // Correct answer is NOT revealed before submit unless selected and isAnswerBeforeExam is true.
        }

        // --- End Logic for Colors and Icons ---


        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          color: cardColor ?? Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
             borderRadius: BorderRadius.circular(8.0),
             side: borderSide,
          ),
          elevation: isSelected ? 2.0 : 1.0,
          child: InkWell(
             // Disable tap if submitted
             // OR if explanations are before submit AND this card shows correctness (meaning it's the selected/correct one)
             onTap: hasSubmitted || (isAnswerBeforeExam && isSelected) // Disable if submitted OR if showing correctness before submit (which only happens for selected)
                 ? null
                 : () { // Allow tap if not submitted AND not showing correctness before submit for this card
                     provider.selectAnswer(question.id, label);
                   },
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