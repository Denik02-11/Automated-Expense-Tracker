import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gallery_picker/gallery_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OcrScreen extends StatefulWidget {
  const OcrScreen({Key? key});

  @override
  State<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  File? selectedMedia;
  TextEditingController _categoryController = TextEditingController();
  TextEditingController _expenseController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Text Recognition"),
      ),
      body: SingleChildScrollView(child: _buildUI()),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          List<MediaFile>? media = await GalleryPicker.pickMedia(
            context: context,
            singleMedia: true,
          );
          if (media != null && media.isNotEmpty) {
            var data = await media.first.getFile();
            setState(() {
              selectedMedia = data;
            });
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildUI() {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _imageView(),
        _extractTextView(),
      ],
    );
  }

  Widget _imageView() {
    if (selectedMedia == null) {
      return const Center(
        child: Text("Pick an image for text recognition"),
      );
    }
    return Center(
      child: Image.file(
        selectedMedia!,
        width: 200,
      ),
    );
  }

  Widget _extractTextView() {
    if (selectedMedia == null) {
      return const Center(
        child: Text("No Result"),
      );
    }

    return FutureBuilder(
      future: _extractText(selectedMedia!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else {
          String? text = snapshot.data;
          List<String> foodKeywords = [
            'restaurant',
            'food',
            'chicken',
            'drinks'
          ];
          List<String> medicineKeywords = [
            'medicine',
            'pharmacy',
            'medical',
            'hospital'
          ];
          List<String> transportationKeywords = [
            'taxi',
            'full',
            'half',
            'ticket',
            'bus',
            'uber',
            'lyft',
            'flight',
            'train',
            'rental car'
          ];
          List<String> entertainmentKeywords = [
            'movie',
            'cinema',
            'concert',
            'show',
            'performance'
          ];
          List<double> numbers = _extractNumbers(text);

          String category = _determineCategory(
            text,
            foodKeywords,
            medicineKeywords,
            transportationKeywords,
            entertainmentKeywords,
          );
          double largestNumber = _findLargestNumber(numbers);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBox("Category", category),
              const SizedBox(height: 16),
              _buildBox("Total Expense", largestNumber.toStringAsFixed(2)),
              const SizedBox(height: 16),
              _buildSaveButton(category, largestNumber),
            ],
          );
        }
      },
    );
  }

  String _determineCategory(
    String? text,
    List<String> foodKeywords,
    List<String> medicineKeywords,
    List<String> transportationKeywords,
    List<String> entertainmentKeywords,
  ) {
    String category = 'Unknown';
    if (text != null) {
      for (String keyword in foodKeywords) {
        if (text.toLowerCase().contains(keyword)) {
          category = 'Food';
          break;
        }
      }
      for (String keyword in medicineKeywords) {
        if (text.toLowerCase().contains(keyword)) {
          category = 'Medical';
          break;
        }
      }
      for (String keyword in transportationKeywords) {
        if (text.toLowerCase().contains(keyword)) {
          category = 'Transportation';
          break;
        }
      }
      for (String keyword in entertainmentKeywords) {
        if (text.toLowerCase().contains(keyword)) {
          category = 'Entertainment';
          break;
        }
      }
    }
    return category;
  }

  double _findLargestNumber(List<double> numbers) {
    return numbers.isNotEmpty ? numbers.reduce((a, b) => a > b ? a : b) : 0;
  }

  List<double> _extractNumbers(String? text) {
    // Define a regular expression pattern to match floating-point numbers with optional commas
    RegExp regex = RegExp(r"\b\d{1,5}(?:,\d{3})*(?:\.\d+)?\b");

    // Extract numbers from the text using the regular expression
    Iterable<Match> matches = regex.allMatches(text ?? "");

    // Initialize a list to store extracted numbers
    List<double> numbers = [];

    // Iterate over the matches and add them to the list
    for (Match match in matches) {
      // Remove commas from the matched substring and convert it to a double
      String matchedText = match.group(0)!.replaceAll(',', '');
      double number = double.parse(matchedText);
      numbers.add(number);
    }

    // Return only the last 5 numbers
    if (numbers.length > 5) {
      return numbers.sublist(numbers.length - 5);
    } else {
      return numbers;
    }
  }

  Future<String?> _extractText(File file) async {
    final textRecognizer = TextRecognizer(
      script: TextRecognitionScript.latin,
    );
    final InputImage inputImage = InputImage.fromFile(file);
    final RecognizedText recognizedText =
        await textRecognizer.processImage(inputImage);
    String text = recognizedText.text;
    textRecognizer.close();
    return text;
  }

  Widget _buildBox(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(String category, double expense) {
    return ElevatedButton(
      onPressed: () {
        _saveExpenseToFirestore(category, expense);
        Navigator.pop(context);
      },
      child: Text('Save'),
    );
  }

  void _saveExpenseToFirestore(String category, double expense) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('expenses')
          .where('category', isEqualTo: category)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot documentSnapshot = querySnapshot.docs.first;
        double currentExpense = documentSnapshot['expense'];
        await documentSnapshot.reference
            .update({'expense': currentExpense + expense});
      } else {
        await FirebaseFirestore.instance.collection('expenses').add({
          'category': category,
          'expense': expense,
        });
      }
      print('Expense saved to Firestore');
    } catch (e) {
      print('Error saving expense: $e');
    }
  }
}
