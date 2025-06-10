import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/models/question.dart';
import 'package:mgw_tutorial/widgets/choice_card.dart';
import 'package:mgw_tutorial/provider/question_provider.dart';
// import 'package:mgw_tutorial/widgets/explanation_widget.dart'; // Commented out as ExplanationWidget is not used

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
  void didUpdateWidget(covariant QuestionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.question.id != oldWidget.question.id ||
        widget.isAnswerBeforeExam != oldWidget.isAnswerBeforeExam) {
      _showExplanations = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final questionProvider = Provider.of<QuestionProvider>(context);
    final bool hasAnswered =
        questionProvider.selectedAnswers.containsKey(widget.question.id);
    final selectedAnswer = questionProvider.getSelectedAnswer(widget.question.id);

    final bool canShowExplanationButton =
        (widget.hasSubmitted && !widget.isAnswerBeforeExam) ||
        (!widget.hasSubmitted && widget.isAnswerBeforeExam && hasAnswered);

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
            if (widget.question.imageUrl != null &&
                widget.question.imageUrl!.isNotEmpty) ...[
              Image.network(
                widget.question.imageUrl!,
                errorBuilder: (context, error, stackTrace) =>
                    const Center(child: Text('Failed to load image')),
              ),
              const SizedBox(height: 12),
            ],
            // Passage text if available
            if (widget.question.passage != null &&
                widget.question.passage!.isNotEmpty) ...[
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
            // Choices
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
            // Explanation Button
            if ((widget.question.explanation != null &&
                    widget.question.explanation!.isNotEmpty) &&
                canShowExplanationButton) ...[
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
                    foregroundColor:
                        Theme.of(context).colorScheme.onSecondaryContainer,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(
                    _showExplanations ? "Hide Explanation" : "Show Explanation",
                  ),
                ),
              ),
            ],
            // Explanation Content
            if (_showExplanations &&
                canShowExplanationButton &&
                (widget.question.explanation != null ||
                    widget.question.answer.isNotEmpty))
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Correct Answer
                    Text(
                      "Correct Answer: ${widget.question.answer}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Explanation Text
                    if (widget.question.explanation != null &&
                        widget.question.explanation!.isNotEmpty)
                      HtmlWidget(
                        widget.question.explanation!,
                        textStyle: TextStyle(
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    // Commented out ExplanationWidget
                    /*
                    ExplanationWidget(
                      question: widget.question,
                      selectedAnswer: selectedAnswer,
                    ),
                    */
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}