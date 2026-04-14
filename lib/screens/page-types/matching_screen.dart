import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class Matching extends StatefulWidget {
  final String question;
  final List<dynamic> leftItems;
  final List<dynamic> rightItems;
  final VoidCallback onNext;

  const Matching({
    super.key,
    required this.question,
    required this.leftItems,
    required this.rightItems,
    required this.onNext,
  });

  @override
  State<Matching> createState() => _MatchingState();
}

class _MatchingState extends State<Matching> {
  int? firstIndex;
  int? secondIndex;
  List<int> matchedIndexes = [];

  // bool oneSelected = false; // If the user has submitted the answer
  bool showResult = false;
  bool isMatch = false;

  late List<Map<String, dynamic>> items; // Stores flattened list

  List<Map<String, dynamic>> _flattenLists() {
    // Flatten lists
    List<Map<String, dynamic>> items = [
      ...widget.leftItems.map((e) => {...e, 'side': 'left'}),
      ...widget.rightItems.map((e) => {...e, 'side': 'right'}),
    ];
    items.shuffle();
    return items;
  }

  @override
  void initState() {
    super.initState();
    items = _flattenLists();
  }

  bool get _isCorrect{
    if (isMatch && firstIndex == secondIndex){
      return true;
    }
    return false;
  }

  // Method to return option ui color
  Color _optionColor(int index) {
    // If option is already matched
    if (matchedIndexes.contains(index)){
      return Colors.green.shade100;
    }

    // On selection
    if (!showResult){
      if (index == firstIndex){
        return AppColors.primaryLight;
      }
      return Colors.transparent;
    }

    // Show result for current selection
    if (index == firstIndex || index == secondIndex){
      return isMatch ? Colors.green.shade100 : Colors.red.shade100;
    }

    return Colors.transparent;
  }

  // Method to return option ui border colour
  Color _optionBorderColor(int index) {
    if (matchedIndexes.contains(index)){
      return Colors.green;
    }

    if (!showResult){
      if (index == firstIndex){
        return AppColors.primary;
      }
      return AppColors.primaryLight;
    }

    if (index == firstIndex || index == secondIndex){
      return isMatch ? Colors.green : Colors.red;
    }

    return AppColors.primaryLight;
  }

  void _handleTap(int index){
    // Prevents spam clicking and tapping matched items
    if (matchedIndexes.contains(index) || showResult) return;

    setState(() {
      if (firstIndex == null) {
        firstIndex = index;
      } else if (secondIndex == null && index != firstIndex) {
        secondIndex = index;

        final firstItem = items[firstIndex!];
        final secondItem = items[secondIndex!];

        // check match (same id but different side)
        isMatch = firstItem['id'] == secondItem['id'] &&
            firstItem['side'] != secondItem['side'];

        showResult = true;
      }
    });

    // Reset after delay
    if (firstIndex != null && secondIndex != null) {
      // Only delay if the answer is incorrect
      if (!isMatch){
        Future.delayed(const Duration(milliseconds: 800), () {
          setState(() {
            firstIndex = null;
            secondIndex = null;
            showResult = false;
          });
        });
      }
      else{
        setState(() {
          // Save matched index
          matchedIndexes.add(firstIndex!);
          matchedIndexes.add(secondIndex!);
          firstIndex = null;
          secondIndex = null;
          showResult = false;
        });
      }

    }
  }

  bool get _isComplete {
    return matchedIndexes.length == items.length;
  }

  @override
  Widget build(BuildContext context) {

    return Padding(
        padding: const EdgeInsets.all(24),
        // Use LayoutBuilder or simply ensure the Column doesn't fight the Spacer
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Top icon
                      Center(
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.quiz_rounded,
                            size: 60,
                            color: AppColors.primary,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 2.5, // tweak this!
                        ),

                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GestureDetector(
                              onTap: matchedIndexes.contains(index) ? null : () => _handleTap(index),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 20),
                                decoration: BoxDecoration(
                                  color: _optionColor(index),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _optionBorderColor(index),
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  item['content']!,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontSize: 18,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      if (_isComplete) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.emoji_emotions_outlined, color: Colors.green,),
                            const SizedBox(width: 8),
                            Text( "You have match all options!",
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ]),
              ),

            ),
            // Keep the button at the bottom (outside the scroll view)
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isComplete ? widget.onNext: null,
                child: Text('Continue'),
              ),
            ),
            const SizedBox(height: 12),
          ],
        )

    );
  }
}