import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agcare_plus/core/models/ai_models.dart';

class SymptomCheckerScreen extends ConsumerStatefulWidget {
  const SymptomCheckerScreen({super.key});

  @override
  ConsumerState<SymptomCheckerScreen> createState() => _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends ConsumerState<SymptomCheckerScreen> {
  final TextEditingController _symptomController = TextEditingController();
  final List<AIMessage> _messages = [];
  bool _isLoading = false;
  InputMode _inputMode = InputMode.text;

  @override
  void dispose() {
    _symptomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Symptom Checker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[_messages.length - 1 - index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(AIMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: message.isUser ? Colors.blue[100] : Colors.grey[200],
            child: Icon(
              message.isUser ? Icons.person : Icons.medical_services,
              color: message.isUser ? Colors.blue : Colors.grey,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: message.isUser ? Colors.blue[50] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.text,
                        style: const TextStyle(fontSize: 16),
                      ),
                      if (message.imageUrl != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              message.imageUrl!,
                              width: 150,
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message.time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: () => _changeInputMode(InputMode.image),
          ),
          IconButton(
            icon: const Icon(Icons.mic),
            onPressed: () => _changeInputMode(InputMode.voice),
          ),
          Expanded(
            child: TextField(
              controller: _symptomController,
              decoration: InputDecoration(
                hintText: _inputMode == InputMode.text 
                    ? 'Describe your symptoms...' 
                    : 'Press mic to speak',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onSubmitted: (text) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    if (_symptomController.text.isEmpty) return;

    final userMessage = AIMessage(
      text: _symptomController.text,
      isUser: true,
      time: _getCurrentTime(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    _symptomController.clear();

    // Simulate AI response
    Future.delayed(const Duration(seconds: 2), () {
      final aiResponse = AIMessage(
        text: _generateAIResponse(userMessage.text),
        isUser: false,
        time: _getCurrentTime(),
      );

      setState(() {
        _messages.add(aiResponse);
        _isLoading = false;
      });
    });
  }

  String _generateAIResponse(String userInput) {
    // In a real app, this would call your Gemma 3n model
    if (userInput.toLowerCase().contains('headache')) {
      return "Based on your description of headache, I recommend:\n\n1. Rest in a quiet, dark room\n2. Drink plenty of water\n3. Consider over-the-counter pain relief like ibuprofen\n\nIf symptoms persist for more than 48 hours or worsen, please consult a doctor.";
    } else if (userInput.toLowerCase().contains('fever')) {
      return "For fever, I suggest:\n\n1. Stay hydrated\n2. Rest\n3. Monitor temperature regularly\n4. Consider fever-reducing medication if above 38°C\n\nSeek medical attention if fever exceeds 39.5°C or lasts more than 3 days.";
    } else {
      return "I've analyzed your symptoms. For $userInput, I recommend monitoring your condition and considering these general health tips:\n\n1. Get adequate rest\n2. Stay hydrated\n3. Monitor for any worsening symptoms\n\nWould you like me to ask more specific questions to better understand your condition?";
    }
  }

  void _changeInputMode(InputMode mode) {
    setState(() {
      _inputMode = mode;
      if (mode == InputMode.voice) {
        // Start voice recording
        _symptomController.text = 'Recording...';
      }
    });
  }

  void _showHistory() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Chat History'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ListTile(
                  leading: Icon(message.isUser ? Icons.person : Icons.medical_services),
                  title: Text(message.text),
                  subtitle: Text(message.time),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String _getCurrentTime() {
    return TimeOfDay.now().format(context);
  }
}

enum InputMode { text, image, voice }