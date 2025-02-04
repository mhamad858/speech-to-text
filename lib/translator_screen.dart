import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mh_app/home_screen.dart';
import 'package:translator/translator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // For JSON encoding/decoding

class TranslatorScreen extends StatefulWidget {
  const TranslatorScreen({super.key});

  @override
  State<TranslatorScreen> createState() => _TranslatorScreen();
}

class _TranslatorScreen extends State<TranslatorScreen> {
  final outputController = TextEditingController(text: "Result here...");
  final inputController = TextEditingController();
  final translator = GoogleTranslator();

  String inputText = '';
  String inputLanguage = 'en';
  String outputLanguage = 'fr';

  // List to store translation history
  List<TranslationHistory> translationHistory = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
    // Load history on app start
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyData = prefs.getString('translationHistory');
    if (historyData != null) {
      setState(() {
        // Decode JSON and load into history
        translationHistory = (jsonDecode(historyData) as List)
            .map((item) => TranslationHistory.fromJson(item))
            .toList();
      });
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyData =
        jsonEncode(translationHistory.map((item) => item.toJson()).toList());
    await prefs.setString('translationHistory', historyData);
  }

  Future<void> translatorText() async {
    final translated = await translator.translate(
      inputText,
      from: inputLanguage,
      to: outputLanguage,
    );
    setState(() {
      outputController.text = translated.text;
    });
  }

  void _copyText() {
    if (inputController.text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: inputController.text));
      _showSnackBar("Text copied!");
    }
  }

  void _deleteText() {
    setState(() {
      inputController.clear();
      outputController.clear();
      inputText = "";
    });
    _showSnackBar("Text deleted!");
  }

  void _saveToHistory() {
    if (inputText.isNotEmpty && outputController.text.isNotEmpty) {
      bool exists = translationHistory.any((entry) =>
          entry.originalText == inputText &&
          entry.translatedText == outputController.text);

      if (!exists) {
        setState(() {
          translationHistory.add(TranslationHistory(
            originalText: inputText,
            translatedText: outputController.text,
          ));
        });
        _saveHistory(); // Save history to SharedPreferences
        _showSnackBar("Text saved to history!");
      } else {
        _showSnackBar("This text is already saved in history.");
      }
    } else {
      _showSnackBar("No text to save!");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 1),
    ));
  }

  void _navigateToHistory() async {
    final selectedTexts = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistoryScreen(
          history: translationHistory,
          onDelete: (selectedIndexes) {
            setState(() {
              selectedIndexes
                  .sort((a, b) => b.compareTo(a)); // Delete in reverse order
              for (int index in selectedIndexes) {
                translationHistory.removeAt(index);
              }
              _saveHistory(); // Save history after deletion
            });
          },
        ),
      ),
    );

    if (selectedTexts != null && selectedTexts.isNotEmpty) {
      setState(() {
        // Append selected texts to the existing input text with spaces between them
        inputController.text =
            "${inputController.text} ${selectedTexts.join(" ")}".trim();
        inputText = inputController.text; // Update the inputText variable
      });

      // Trigger translation for the updated input text
      await translatorText();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 117, 210, 226),
      appBar: AppBar(
        title: const Text(
          "Translator",
          style: TextStyle(
            color: Colors.yellow,
            fontWeight: FontWeight.bold,
            fontSize: 35,
          ),
        ),
        backgroundColor: Colors.pink,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _navigateToHistory,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.pink,
              ),
              child: Text(
                'Select a service',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.mic),
              title: const Text('Speech to Text'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HomeScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.volume_up),
              title: const Text('Text to Speech'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TextToSpeechScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.translate),
              title: const Text('Translation'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TranslatorScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: inputController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    fillColor: const Color.fromARGB(255, 9, 231, 142),
                    filled: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(17),
                        borderSide:
                            const BorderSide(color: Colors.black, width: 4)),
                    hintText: "Enter text to translate",
                  ),
                  onChanged: (value) {
                    setState(() {
                      inputText = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    DropdownButton<String>(
                      value: inputLanguage,
                      onChanged: (newValue) {
                        setState(() {
                          inputLanguage = newValue!;
                        });
                      },
                      items: <String>[
                        'en',
                        'fr',
                        'es',
                        'de',
                        'ur',
                        'hi',
                        'ar',
                        'ku',
                        'ru',
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    const Icon(Icons.arrow_forward_rounded),
                    DropdownButton<String>(
                      value: outputLanguage,
                      onChanged: (newValue) {
                        setState(() {
                          outputLanguage = newValue!;
                        });
                      },
                      items: <String>[
                        'en',
                        'fr',
                        'es',
                        'de',
                        'ur',
                        'hi',
                        'ar',
                        'ku',
                        'ru',
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: translatorText,
                      icon: const Icon(Icons.swap_horiz_sharp,
                          color: Colors.white, size: 25),
                      label: const Text("Translate",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: outputController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    fillColor: const Color.fromARGB(255, 9, 231, 142),
                    filled: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(17),
                        borderSide: const BorderSide(
                            color: Color.fromARGB(255, 0, 0, 0), width: 4)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _copyText,
                      icon: const Icon(Icons.copy, color: Colors.white),
                      label: const Text("Copy",
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton.icon(
                      onPressed: _saveToHistory,
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text("Save To History",
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton.icon(
                      onPressed: _deleteText,
                      icon: const Icon(Icons.delete, color: Colors.white),
                      label: const Text("Delete",
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TranslationHistory {
  final String originalText;
  final String translatedText;

  TranslationHistory(
      {required this.originalText,
      required this.translatedText}); // Convert object to JSON
  Map<String, dynamic> toJson() => {
        'originalText': originalText,
        'translatedText': translatedText,
      };

  // Create object from JSON
  factory TranslationHistory.fromJson(Map<String, dynamic> json) {
    return TranslationHistory(
      originalText: json['originalText'],
      translatedText: json['translatedText'],
    );
  }
}

class HistoryScreen extends StatefulWidget {
  final List<TranslationHistory> history;
  final Function(List<int>) onDelete;

  const HistoryScreen({
    super.key,
    required this.history,
    required this.onDelete,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final Set<int> selectedIndexes = {};

  void _deleteSelectedTexts() {
    widget.onDelete(selectedIndexes.toList());
    setState(() {
      selectedIndexes.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("History"),
        backgroundColor: Colors.pink,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: _deleteSelectedTexts,
          ),
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            onPressed: () {
              final selectedTexts = selectedIndexes
                  .map((index) => widget.history[index].originalText)
                  .toList();
              Navigator.pop(context, selectedTexts);
            },
          ),
        ],
      ),
      body: widget.history.isEmpty
          ? const Center(child: Text("No history available"))
          : ListView.builder(
              itemCount: widget.history.length,
              itemBuilder: (context, index) {
                final historyItem = widget.history[index];
                return ListTile(
                  title: Text('Original: ${historyItem.originalText}'),
                  subtitle: Text('Translated: ${historyItem.translatedText}'),
                  leading: Checkbox(
                    value: selectedIndexes.contains(index),
                    onChanged: (isSelected) {
                      setState(() {
                        if (isSelected == true) {
                          selectedIndexes.add(index);
                        } else {
                          selectedIndexes.remove(index);
                        }
                      });
                    },
                  ),
                );
              },
            ),
    );
  }
}
