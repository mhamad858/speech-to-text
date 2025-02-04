import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

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
  final List<String> _history = [];
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initSpeechState();
  }

  void _initSpeechState() async {
    bool available = await _speech.initialize();
    if (!mounted) return;
    setState(() {
      _isListening = available;
    });
  }

  void _startListening() {
    _speech.listen(onResult: (result) {
      setState(() {
        _recognizedText = result.recognizedWords;
      });
    });
    setState(() {
      _isListening = true;
    });
  }

  void _copyText() {
    Clipboard.setData(ClipboardData(text: _recognizedText));
    _showSnackBar("Text Copied");
  }

  void _deleteText() {
    setState(() {
      _recognizedText = "";
    });
    _speech.stop();
    _showSnackBar("Text Deleted");
  }

  void _saveToHistory() {
    if (_recognizedText.isNotEmpty) {
      setState(() {
        _history.add(_recognizedText);
        _recognizedText = "";
      });
      _showSnackBar("Text Saved to History");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 1),
    ));
  }

  void _navigateToHistory() async {
    final selectedText = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistoryScreen(
          history: _history,
          onDelete: (selectedIndexes) {
            setState(() {
              selectedIndexes.sort(
                  (a, b) => b.compareTo(a)); // Delete from last index first
              for (int index in selectedIndexes) {
                _history.removeAt(index);
              }
            });
          },
        ),
      ),
    );

    // When the user selects text, append it to the recognizedText without clearing it
    if (selectedText != null) {
      setState(() {
        _recognizedText +=
            "\n$selectedText"; // Append the selected history text
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pink,
        title: const Text(
          "STT-RE-CO",
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
            IconButton(
              onPressed: _startListening,
              icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
              iconSize: 100,
              color: _isListening ? Colors.pink : Colors.grey,
            ),
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
                  label: const Text("Save To History",
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

class HistoryScreen extends StatefulWidget {
  final List<String> history;
  final Function(List<int>) onDelete;

  const HistoryScreen(
      {super.key, required this.history, required this.onDelete});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final Set<int> selectedIndexes = {};

  void _deleteSelectedTexts() {
    widget.onDelete(selectedIndexes.toList());
    setState(() {
      selectedIndexes.clear();
    });
  }

  void _combineAndReturn() {
    String combinedText = selectedIndexes
        .map((index) => widget.history[index])
        .join("\n"); // Combine selected texts
    Navigator.pop(context, combinedText);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "History",
          style: TextStyle(
              color: Colors.yellowAccent,
              fontSize: 25,
              fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.pink,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: _deleteSelectedTexts, // Delete selected texts
          ),
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            onPressed: _combineAndReturn, // Return combined text to main screen
          ),
        ],
      ),
      body: widget.history.isEmpty
          ? const Center(child: Text("No history available"))
          : ListView.builder(
              itemCount: widget.history.length,
              itemBuilder: (context, index) {
                bool isSelected = selectedIndexes.contains(index);
                return ListTile(
                  title: Text(widget.history[index]),
                  leading: Checkbox(
                    value: isSelected,
                    onChanged: (isChecked) {
                      setState(() {
                        if (isChecked == true) {
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
