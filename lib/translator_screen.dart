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
    _loadSavedText(); // Load saved input and output text when screen is opened
  }

  // Load translation history
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

  // Load saved text (input and output)
  Future<void> _loadSavedText() async {
    final prefs = await SharedPreferences.getInstance();
    final savedInputText = prefs.getString('inputText') ?? '';
    final savedOutputText = prefs.getString('outputText') ?? 'Result here...';

    if (mounted) {
      setState(() {
        inputText = savedInputText;
        inputController.text =
            savedInputText; // Ensure the text is restored in the field
        outputController.text = savedOutputText;
      });
    }
  }

  // Save text to SharedPreferences
  Future<void> _saveText() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('inputText', inputText); // Save input text
    await prefs.setString(
        'outputText', outputController.text); // Save output text
  }

  // Translator function
  // Translator function (Does not add to history automatically)
Future<void> translatorText() async {
  final translated = await translator.translate(
    inputText,
    from: inputLanguage,
    to: outputLanguage,
  );

  setState(() {
    outputController.text = translated.text;
  });

  _saveText(); // Save output text after translation
}

  // Copy input text
  void _copyText() {
    if (inputController.text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: inputController.text));
      _showSnackBar("Text copied!");
    }else {
        _showSnackBar("This text is already saved in history.");
      }
  }

  // Delete input and output text
  void _deleteText() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('inputText'); // Remove saved input text
    await prefs.remove('outputText'); // Remove saved output text

    setState(() {
      inputController.clear();
      outputController.clear();
      inputText = "";
    });

    _showSnackBar("Text deleted!");
  }

  // Save translation history
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

  // Save history to SharedPreferences
  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyData =
        jsonEncode(translationHistory.map((item) => item.toJson()).toList());
    await prefs.setString('translationHistory', historyData);
  } // Show Snackbar

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 1),
    ));
  }

  // Navigate to History Screen
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
        inputText = inputController.text;
      });

      // Trigger translation for the updated input text
      await translatorText();
    }
  }

  // Custom onChanged function to save input text
  void _onInputChanged(String value) {
    setState(() {
      inputText = value;
    });
    _saveText(); // Save whenever input text changes
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
            fontSize: 25,
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
                  onChanged:
                      _onInputChanged, // Call the custom onChanged function
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
                          color: Colors.black, size: 25),
                      label: const Text("Translate",
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 232, 60, 141)),
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
                      label: const Text("Save",
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
  final DateTime timestamp;  // Add this line

  TranslationHistory({
    required this.originalText,
    required this.translatedText,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();  // Default to current time

  // Convert object to JSON
  Map<String, dynamic> toJson() => {
    'originalText': originalText,
    'translatedText': translatedText,
    'timestamp': timestamp.toIso8601String(),  // Store timestamp
  };

  // Create object from JSON
  factory TranslationHistory.fromJson(Map<String, dynamic> json) {
    return TranslationHistory(
      originalText: json['originalText'],
      translatedText: json['translatedText'],
      timestamp: json.containsKey('timestamp')
          ? DateTime.tryParse(json['timestamp']) ?? DateTime.now()
          : DateTime.now(),
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
  bool isAllSelected = false; // Tracks "Select All" state

  void _toggleSelectAll() {
    setState(() {
      if (isAllSelected) {
        selectedIndexes.clear();
      } else {
        selectedIndexes
            .addAll(List.generate(widget.history.length, (index) => index));
      }
      isAllSelected = !isAllSelected;
    });
  }

  void _deleteSelectedTexts() {
    widget.onDelete(selectedIndexes.toList());
    setState(() {
      selectedIndexes.clear();
      isAllSelected = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("History",
          style: TextStyle(
            color: Colors.yellowAccent,
            fontWeight: FontWeight.bold,
            fontSize: 25,
          ),
        ),
        backgroundColor: Colors.pink,
        actions: [
          // "Select All" Checkbox
          Checkbox(
            checkColor: Colors.grey,
            value: isAllSelected,
            onChanged: (value) => _toggleSelectAll(),
          ),
          // Delete Icon
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: _deleteSelectedTexts,
          ),
          // Checkmark Icon
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            onPressed: () {
              Navigator.pop(
                  context,
                  widget.history
                      .where((item) => selectedIndexes
                          .contains(widget.history.indexOf(item)))
                      .map((item) => item.originalText)
                      .toList());
            },
          ),
        ],
      ),
      body: widget.history.isEmpty
          ? const Center(child: Text("No history available"))
          : ListView.builder(
              itemCount: widget.history.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Checkbox(
                    value: selectedIndexes.contains(index),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value!) {
                          selectedIndexes.add(index);
                        } else {
                          selectedIndexes.remove(index);
                        }
                      });
                    },
                  ),
                  title: Row(
                    children: [
                      const Text(
                        "Original: ",
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      Expanded(
                        child: Text(widget.history[index].originalText),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            "Translated: ",
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                          Expanded(
                            child: Text(widget.history[index].translatedText),
                          ),],
                      ),
                      const SizedBox(height: 4),
                      // Display timestamp if available
                      Align(
                        alignment: Alignment.centerRight,
                     child:  Text(
  'Date: ${widget.history[index].timestamp != null ? 
  "${widget.history[index].timestamp.toLocal()
  .day}/${widget.history[index].timestamp.toLocal().month}/${widget.history[index]
  .timestamp.toLocal().year} - ${TimeOfDay.fromDateTime(widget.history[index].timestamp)
  .format(context)}" : "Unknown"}',
  style: const TextStyle(fontSize: 10, color: Colors.grey),
),
                      )
                    ],
                  ),
                );
              },
            ),
    );
  }
}