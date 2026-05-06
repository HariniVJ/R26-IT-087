import 'package:flutter/material.dart';
import '../../common/brand_color.dart';

class TreatmentChatView extends StatefulWidget {
  const TreatmentChatView({super.key});

  @override
  State<TreatmentChatView> createState() => _TreatmentChatViewState();
}

class _TreatmentChatViewState extends State<TreatmentChatView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, String>> _messages = [
    {
      'sender': 'bot',
      'text':
          'Hi Farmer 👋\nAsk me about pomegranate disease treatment.\n\nExample: Anthracnose treatment',
    },
  ];

  String _getAnswer(String question) {
    final q = question.toLowerCase();
    if (q.contains('anthracnose')) {
      return '🍎 Anthracnose Treatment:\n\n• Remove infected fruits immediately\n• Avoid overhead watering\n• Apply Mancozeb or Carbendazim fungicide\n• Keep good air circulation\n• Repeat spray every 10–14 days';
    } else if (q.contains('alternaria')) {
      return '🍂 Alternaria Treatment:\n\n• Remove affected fruits\n• Avoid excess moisture\n• Apply Iprodione fungicide\n• Clean fallen fruits from the farm\n• Store in cool dry place';
    } else if (q.contains('cercospora')) {
      return '🌿 Cercospora Treatment:\n\n• Remove infected plant parts\n• Spray Carbendazim 0.1% solution\n• Improve air circulation\n• Avoid wet fruits\n• Apply every 15 days in rainy season';
    } else if (q.contains('bacterial') || q.contains('blight')) {
      return '🦠 Bacterial Blight Treatment:\n\n• Remove infected fruits\n• Use copper-based bactericide\n• Avoid working in wet fields\n• Maintain farm hygiene\n• Prune overcrowded branches';
    } else if (q.contains('healthy')) {
      return '✅ Healthy Fruit:\n\nNo treatment needed!\n\n• Continue regular monitoring\n• Maintain proper watering schedule\n• Keep farm clean\n• Monitor weekly for early signs';
    } else {
      return '❓ Please ask using a disease name:\n\n• Anthracnose\n• Alternaria\n• Cercospora\n• Bacterial Blight\n• Healthy';
    }
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': text});
      _messages.add({'sender': 'bot', 'text': _getAnswer(text)});
    });

    _controller.clear();

    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColor.background,
      appBar: AppBar(
        title: const Text('Treatment Chat'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // ── Quick Disease Chips ──────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    [
                      'Anthracnose',
                      'Alternaria',
                      'Cercospora',
                      'Bacterial Blight',
                      'Healthy',
                    ].map((disease) {
                      return GestureDetector(
                        onTap: () {
                          _controller.text = disease;
                          _sendMessage();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: BrandColor.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: BrandColor.primary.withOpacity(0.20),
                            ),
                          ),
                          child: Text(
                            disease,
                            style: const TextStyle(
                              color: BrandColor.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),

          // ── Messages ─────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['sender'] == 'user';

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.78,
                    ),
                    decoration: BoxDecoration(
                      color: isUser ? BrandColor.primary : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isUser ? 18 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: BrandColor.primary.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      msg['text']!,
                      style: TextStyle(
                        color: isUser ? Colors.white : BrandColor.darkText,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Input Bar ─────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x10000000),
                  blurRadius: 10,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Ask about a disease...',
                      hintStyle: const TextStyle(
                        color: BrandColor.lightText,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: BrandColor.background,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: BrandColor.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
