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
  final bool isAnswerBeforeExam; // <-- New parameter

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


        if (hasSubmitted) {
          // After Submission Logic
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
            cardColor = Theme.of(context).colorScheme.primary.withOpacity(0.1); // Highlight selected
            textColor = Theme.of(context).colorScheme.primary;
            borderSide = BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5); // Add border
          }

           // Show icons/colors before submit ONLY if isAnswerBeforeExam is true
          if (isSelected && isAnswerBeforeExam) {
             trailingIcon = isCorrectAnswer
                ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary) // Or green theme color
                : Icon(Icons.cancel, color: Theme.of(context).colorScheme.error); // Or red theme color
             // Color logic is handled above by isSelected
          } else if (!isSelected && isCorrectAnswer && isAnswerBeforeExam) {
             cardColor = Colors.green.withOpacity(0.3); // Correct answer not selected, but revealed before submit
             textColor = Colors.green.shade800; // Green text color
             trailingIcon = Icon(Icons.check_circle_outline, color: Colors.green.shade800);
          }
          // Note: If isAnswerBeforeExam is false, no special coloring/icons appear before submit, only selection highlight.
        }

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          color: cardColor ?? Theme.of(context).cardColor, // Use default card color if no specific color
          shape: RoundedRectangleBorder(
             borderRadius: BorderRadius.circular(8.0),
             side: borderSide, // Apply border side
          ),
          elevation: isSelected ? 2.0 : 1.0, // Slightly more elevation when selected
          child: InkWell(
            // Disable tap after submission OR if explanations are shown before submit
            // Tapping should also be disabled if explanations are before submit AND this is the correct answer
             onTap: hasSubmitted || (isAnswerBeforeExam && (isSelected || isCorrectAnswer))
                 ? null // Disable if submitted or if explanation is shown before submit (selected or correct)
                 : () { // Only selectable if not submitted AND (not showing explanations before submit OR not selected/correct)
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
                      color: textColor, // Apply text color
                    ),
                  ),
                  Expanded(
                    child: HtmlWidget(
                      choiceText,
                       textStyle: TextStyle(fontSize: 16, color: textColor), // Apply text color
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