// lib/widgets/chatbot_overlay.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart'; // Import ApiService

class FoodyAIChatbot extends StatefulWidget {
  final ApiService apiService; // Added required dependency
  final VoidCallback onClose; // Added mechanism to close the chat from within

  const FoodyAIChatbot({required this.apiService, required this.onClose, super.key});

  @override
  State<FoodyAIChatbot> createState() => _FoodyAIChatbotState();
}

class _FoodyAIChatbotState extends State<FoodyAIChatbot> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, String>> _messages = [
    {'role': 'ai', 'text': 'Hello! I am Foody-AI, your digital assistant. Ask me about **total stock**, **donation items**, or **sales details**!'}
  ];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Ensure the initial welcome message is shown and scrolled
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.isEmpty || _isTyping) return;
    final userQuery = text;
    _controller.clear();

    // Add user message and AI typing indicator
    setState(() {
      _messages.add({'role': 'user', 'text': userQuery});
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      // Call the new backend-resolving method
      final response = await widget.apiService.resolveChatQuery(userQuery);

      setState(() {
        _messages.add({'role': 'ai', 'text': response});
      });

    } catch (e) {
      setState(() {
        _messages.add({'role': 'ai', 'text': 'Sorry, I couldn\'t connect to the inventory service to get that data. Error: $e'});
      });
    } finally {
      setState(() {
        _isTyping = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 380, // Fixed width for the chat box
      height: MediaQuery.of(context).size.height * 0.6, // About 60% of screen height
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 15)],
      ),
      child: Column(
        children: <Widget>[
          // Header with Close Button
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Icon(Icons.smart_toy, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(child: Text('Foody-AI Assistant', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: widget.onClose, // Use the onClose callback
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          // Chat Messages Area
          Expanded(
            child: ListView.builder(
              controller: _scrollController, // Attach controller
              padding: const EdgeInsets.all(8.0),
              // Use non-reversed order and scroll to bottom manually
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const ChatMessage(role: 'ai', text: 'Typing...', isTyping: true);
                }
                final message = _messages[index];
                return ChatMessage(role: message['role']!, text: message['text']!);
              },
            ),
          ),

          const Divider(height: 1.0),

          // Input Field
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: _handleSubmitted,
                    enabled: !_isTyping,
                    decoration: InputDecoration.collapsed(
                      hintText: _isTyping ? 'Foody-AI is thinking...' : 'Ask Foody-AI...',
                      hintStyle: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: _isTyping ? Colors.grey : Theme.of(context).colorScheme.primary),
                  onPressed: _isTyping ? null : () => _handleSubmitted(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// Reusable Chat Message Widget
class ChatMessage extends StatelessWidget {
  final String role;
  final String text;
  final bool isTyping;

  const ChatMessage({required this.role, required this.text, this.isTyping = false, super.key});

  @override
  Widget build(BuildContext context) {
    final isUser = role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isUser
              ? Colors.blue.shade800
              : isTyping
              ? Colors.grey.shade700
              : Theme.of(context).colorScheme.primary.withOpacity(0.8),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: isUser ? const Radius.circular(15) : const Radius.circular(4),
            bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(15),
          ),
        ),
        child: Text(
          isTyping ? '$text' : text,
          style: TextStyle(color: isUser ? Colors.white : Colors.black, fontSize: 13),
        ),
      ),
    );
  }
}