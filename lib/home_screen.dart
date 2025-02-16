import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mh_app/translator_screen.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  String _recognizedText = "";
  List<String> _history = [];
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initSpeechState();
    _loadRecognizedText();  // Load the saved text
    _loadHistory();
  }

  // Initialize speech recognition
  void _initSpeechState() async {
    bool available = await _speech.initialize();
    if (!mounted) return;
    setState(() {
      _isListening = available;
    });
  }

  // Load recognized text from SharedPreferences
  void _loadRecognizedText() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _recognizedText = prefs.getString('recognized_text') ?? "";
    });
  }

  // Save recognized text to SharedPreferences
  void _saveRecognizedText() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('recognized_text', _recognizedText);
  }

  // Load history from SharedPreferences
  void _loadHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _history = prefs.getStringList('history') ?? [];
    });
  }

  // Save history to SharedPreferences
  void _saveHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList('history', _history);
  }

  // Start speech recognition
  void _startListening() {
    _speech.listen(onResult: (result) {
      setState(() {
        _recognizedText = result.recognizedWords;
        _saveRecognizedText();  // Save text whenever it updates
      });
    });
    setState(() {
      _isListening = false;
    });
  }

  // Stop speech recognition
  void _stopListening() {
    _speech.stop();
    setState(() {
      _isListening = true;
    });
  }

  // Copy recognized text to clipboard
  void _copyText() {
    Clipboard.setData(ClipboardData(text: _recognizedText));
    _showSnackBar("Text Copied");
  }

  // Delete recognized text
  void _deleteText() {
    setState(() {
      _recognizedText = "";
    });
    _speech.stop();
    _saveRecognizedText();  // Clear saved text when deleted
    _showSnackBar("Text Deleted");
  }

  // Save recognized text to history
  void _saveToHistory() {
    if (_recognizedText.isNotEmpty) {
      setState(() {
        _history.add(_recognizedText);
        _recognizedText = "";
      });
      _saveHistory();
      _saveRecognizedText();  // Save the empty text after saving history
      _showSnackBar("Text Saved to History");
    }
  }
//(Speech To Text)،(Text To Speech)،(Translation)
  // Show a Snackbar with a message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 1),
    ));
  }

  // Navigate to history and return selected text
  void _navigateToHistory() async {
    final selectedTexts = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistoryScreen(history: _history,
          onDelete: (selectedIndexes) {
            setState(() {
              selectedIndexes.sort((a, b) => b.compareTo(a));
              for (int index in selectedIndexes) {
                _history.removeAt(index);
              }
              _saveHistory();
            });
          }, storageKey: '',
        ),
      ),
    );

    if (selectedTexts != null && selectedTexts.isNotEmpty) {
      setState(() {
        _recognizedText += " ${selectedTexts.join("")}"; 
        _saveRecognizedText();  // Save the updated text
        
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pink,
        title: const Text(
          "Speech To Text",
          style: TextStyle(
            color: Colors.yellowAccent,
            fontWeight: FontWeight.bold,
            fontSize: 35,
          ),
        ),
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
                  color: Color.fromARGB(255, 255, 255, 255),
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.mic),
              title: const Text('Speech to Text'),
              onTap: () {
                Navigator.pop(context);
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
      backgroundColor: const Color.fromARGB(255, 117, 210, 226),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Speech Recognition",
              style: TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _isListening ? _startListening : _stopListening,
              icon: Icon(
                _isListening ? Icons.mic : Icons.mic_off,
                color: Colors.black,
                size: 25,
              ),
              label: Text(
                _isListening ? "Speech" : "Stop",
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 232, 60, 141),
              ),),
            const SizedBox(height: 20),
            Container(
              height: MediaQuery.of(context).size.height / 4,
              width: 1000,
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 9, 231, 142),
                border: Border.all(
                  color: Colors.black,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(17),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _recognizedText.isNotEmpty
                      ? _recognizedText
                      : "Result Here....",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 19,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _copyText,
                  icon: const Icon(Icons.copy, color: Colors.white),
                  label:
                      const Text("Copy", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  onPressed: _saveToHistory,
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text("Save",
                      style: TextStyle(color: Colors.white)),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
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
    );
  }
}

class TextToSpeechScreen extends StatefulWidget {
  const TextToSpeechScreen({super.key});

  @override
  State<TextToSpeechScreen> createState() => _TextToSpeechScreenState();
}

class _TextToSpeechScreenState extends State<TextToSpeechScreen> {
  final FlutterTts flutterTts = FlutterTts();
  final TextEditingController textController = TextEditingController();
  final List<String> _history = [];
  bool _isSpeaking = false; // Track if the speaker is talking

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  Future<void> speak(String text) async {
    if (text.isEmpty || _isSpeaking) {
      return; // Prevent speaking if text is empty or speaking is already happening
    }

    setState(() {
      _isSpeaking = true;
    });

    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(1.0);

    flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false; // Re-enable button after speaking is done
      });
    });

    await flutterTts.speak(text);
  }

  Future<void> stopSpeaking() async {
    await flutterTts.stop();
    setState(() {
      _isSpeaking = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadText();
    _loadHistoryFromStorage();
  }

  Future<void> _loadText() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      textController.text = prefs.getString('textToSpeechText') ?? "";
    });
  }

  Future<void> _saveText() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('textToSpeechText', textController.text);
  }

  Future<void> _loadHistoryFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final storedHistory = prefs.getString('textToSpeechHistory');
    if (storedHistory != null) {
      setState(() {
        _history.addAll(List<String>.from(jsonDecode(storedHistory)));
      });
    }
  }

  Future<void> _saveHistoryToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('textToSpeechHistory', jsonEncode(_history));
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 1),
    ));
  }

  void _deleteText() {
    setState(() {
      textController.clear();
    });
    _saveText();
  }

  void _copyText() {
    if (textController.text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: textController.text));
      _showSnackBar("Text copied");
    }
  }

  void _saveToHistory() async {
    if (textController.text.isNotEmpty) {
      setState(() {
        if (!_history.contains(textController.text)) {
          _history.add(textController.text);
        }
      });
      await _saveHistoryToStorage();
      _showSnackBar("Text Saved to History");
    }
  }

  void _navigateToHistory() async {
    final List<String>? selectedTexts = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistoryScreen(
          history: _history,
          onDelete: (selectedIndexes) {
            setState(() {
              selectedIndexes.sort((a, b) => b.compareTo(a));
              for (int index in selectedIndexes) {
                _history.removeAt(index);
              }
            });
            _saveHistoryToStorage();
          },
          storageKey: 'textToSpeechHistory', // Unique key for Text to Speech history
        ),
      ),
    );
    if (selectedTexts != null && selectedTexts.isNotEmpty) {
      setState(() {
        textController.text += (textController.text.isNotEmpty ? " " : "") + selectedTexts.join(" ");
      });
      _saveText();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 117, 210, 226),
        appBar: AppBar(
          title: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              "Text To Speech",
              style: TextStyle(
                color: Colors.yellow,
                fontWeight: FontWeight.bold,
                fontSize: 35,
              ),
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
                  Navigator.pop(context);
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                const Text(
                  "Volume Listening",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: _isSpeaking || textController.text.isEmpty
                      ? stopSpeaking
                      : () => speak(textController.text),
                  icon: Icon(
                    _isSpeaking ? Icons.volume_off : Icons.volume_up,
                    color: Colors.black,
                    size: 25,
                  ),
                  label: Text(
                    _isSpeaking ? "Stop" : "Listen",
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 232, 60, 141),
                  ),
                ),
                const SizedBox(height: 50),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                    controller: textController,
                    decoration: InputDecoration(
                      fillColor: const Color.fromARGB(255, 9, 231, 142),
                      filled: true,
                      hintStyle: const TextStyle(color: Colors.white),
                      hintText: "Enter Text",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(17),
                        borderSide:
                            const BorderSide(color: Colors.black, width: 4),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(17),
                        borderSide:
                            const BorderSide(color: Colors.black, width: 2),
                      ),
                    ),
                    maxLines: 5,
                    onChanged: (text) {
                      _saveText();
                    },
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
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton.icon(
                      onPressed: _saveToHistory,
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text("Save ggg",
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton.icon(
                      onPressed: _deleteText,
                      icon: const Icon(Icons.delete, color: Colors.white),
                      label: const Text("Delete",
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}



class HistoryScreen extends StatefulWidget {
  final List<String> history;
  final Function(List<int>) onDelete;
  final String storageKey;

  const HistoryScreen({
    super.key,
    required this.history,
    required this.onDelete,
    required this.storageKey,
  });

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isSelectAll = false;
  Set<int> _selectedIndexes = {};

  void _toggleSelectAll() {
    setState(() {
      if (_isSelectAll) {
        _selectedIndexes.clear();
      } else {
        _selectedIndexes.addAll(List.generate(widget.history.length, (index) => index));
      }
      _isSelectAll = !_isSelectAll;
    });
  }

  void _deleteSelected() async {
    if (_selectedIndexes.isNotEmpty) {
      List<int> sortedIndexes = _selectedIndexes.toList()..sort((a, b) => b.compareTo(a));
      setState(() {
        widget.onDelete(sortedIndexes); // Delete items from parent
        _selectedIndexes.clear();
        _isSelectAll = false;
      });

      // Save updated history to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(widget.storageKey, jsonEncode(widget.history));
    }
  }

  void _returnSelected() {
    if (_selectedIndexes.isNotEmpty) {
      List<String> selectedTexts = _selectedIndexes.map((index) => widget.history[index]).toList();
      Navigator.pop(context, selectedTexts);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'History',
          style: TextStyle(
            color: Colors.yellowAccent,
            fontWeight: FontWeight.bold,
            fontSize: 25,
          ),
        ),
        backgroundColor: Colors.pink,
        actions: [
          IconButton(
            icon: Icon(
              _isSelectAll ? Icons.check_box : Icons.check_box_outline_blank,
              color: const Color.fromARGB(255, 88, 86, 86),
            ),
            onPressed: _toggleSelectAll,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: _deleteSelected,
          ),
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            onPressed: _returnSelected,
          ),
        ],
      ),
      body: widget.history.isEmpty
          ? const Center(child: Text("No history available"))
          : ListView.builder(
              itemCount: widget.history.length,
              itemBuilder: (context, index) {
                return HistoryListItem(
                  text: widget.history[index],
                  index: index,
                  isSelected: _selectedIndexes.contains(index),
                  onSelect: _toggleItemSelection,
                );
              },
            ),
    );
  }

  void _toggleItemSelection(int index) {
    setState(() {
      if (_selectedIndexes.contains(index)) {
        _selectedIndexes.remove(index);
      } else {
        _selectedIndexes.add(index);
      }
      _isSelectAll = _selectedIndexes.length == widget.history.length;
    });
  }
}

class HistoryListItem extends StatelessWidget {
  final String text;
  final int index;
  final bool isSelected;
  final Function(int) onSelect;

  const HistoryListItem({
    super.key,
    required this.text,
    required this.index,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(text),
      leading: Checkbox(
        value: isSelected,
        onChanged: (bool? checked) {
          onSelect(index);
        },
      ),
      onTap: () {
        onSelect(index);
      },
    );
  }
}