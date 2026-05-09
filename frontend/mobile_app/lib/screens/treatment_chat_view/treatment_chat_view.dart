import 'dart:ui';
import 'package:flutter/material.dart';
import '../../common/brand_color.dart';
import '../../common/glass_container.dart';

class TreatmentChatView extends StatefulWidget {
  const TreatmentChatView({super.key});

  @override
  State<TreatmentChatView> createState() => _TreatmentChatViewState();
}

class _TreatmentChatViewState extends State<TreatmentChatView> {
  // ── Logic unchanged ────────────────────────────────────────
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

  // ── UI ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColor.background,
      extendBodyBehindAppBar: true,
      appBar: const DarkAppBar(title: 'Treatment Chat'),
      body: Stack(
        children: [
          const DarkBackground(),
          Column(
            children: [
              // Compensate for AppBar
              SizedBox(
                height: kToolbarHeight + MediaQuery.of(context).padding.top,
              ),

              // ── Quick chips ──────────────────────────────
              _QuickChipBar(
                onChipTap: (disease) {
                  _controller.text = disease;
                  _sendMessage();
                },
              ),

              // ── Messages ─────────────────────────────────
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final isUser = msg['sender'] == 'user';
                    return _ChatBubble(text: msg['text']!, isUser: isUser);
                  },
                ),
              ),

              // ── Input bar ─────────────────────────────────
              _GlassInputBar(controller: _controller, onSend: _sendMessage),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Quick Chip Bar ─────────────────────────────────────────────
class _QuickChipBar extends StatelessWidget {
  final ValueChanged<String> onChipTap;
  const _QuickChipBar({required this.onChipTap});

  static const _diseases = [
    'Anthracnose',
    'Alternaria',
    'Cercospora',
    'Bacterial Blight',
    'Healthy',
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          color: BrandColor.bgDeep.withOpacity(0.85),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _diseases.map((disease) {
                return GestureDetector(
                  onTap: () => onChipTap(disease),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: BrandColor.primary.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: BrandColor.primary.withOpacity(0.28),
                      ),
                    ),
                    child: Text(
                      disease,
                      style: TextStyle(
                        color: BrandColor.accent,
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
      ),
    );
  }
}

// ── Chat Bubble ────────────────────────────────────────────────
class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  const _ChatBubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: isUser ? _UserBubble(text: text) : _BotBubble(text: text),
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  final String text;
  const _UserBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [BrandColor.primary, BrandColor.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(4),
        ),
        boxShadow: [
          BoxShadow(
            color: BrandColor.primary.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
      ),
    );
  }
}

class _BotBubble extends StatelessWidget {
  final String text;
  const _BotBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(18),
        topRight: Radius.circular(18),
        bottomLeft: Radius.circular(4),
        bottomRight: Radius.circular(18),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: BrandColor.glassFill,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(18),
            ),
            border: Border.all(color: BrandColor.glassBorder),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: BrandColor.lightText,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Glass Input Bar ────────────────────────────────────────────
class _GlassInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _GlassInputBar({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            14,
            12,
            14,
            12 + MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: BrandColor.bgDeep.withOpacity(0.88),
            border: Border(top: BorderSide(color: BrandColor.glassBorder)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  style: const TextStyle(
                    color: BrandColor.darkText,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ask about a disease...',
                    hintStyle: TextStyle(
                      color: BrandColor.softText,
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: BrandColor.glassFill,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: BrandColor.glassBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: BrandColor.primary.withOpacity(0.55),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onSend,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [BrandColor.primary, BrandColor.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: BrandColor.primary.withOpacity(0.45),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
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
      ),
    );
  }
}
