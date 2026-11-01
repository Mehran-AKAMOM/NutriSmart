import 'package:flutter/material.dart';

import '../services/assistant.dart';
import '../state/app_state.dart';
import '../theme.dart';

class _Message {
  final bool fromUser;
  final String text;
  const _Message(this.fromUser, this.text);
}

/// Chat with NutriSmart's offline coach.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_Message> _messages = [];
  List<String> _suggestions = NutriAssistant.defaultSuggestions;
  bool _typing = false;
  NutriAssistant? _assistant;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_assistant == null) {
      _assistant = NutriAssistant(AppScope.read(context));
      final hello = _assistant!.greeting();
      _messages.add(_Message(false, hello.text));
      _suggestions = hello.suggestions;
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    final q = text.trim();
    if (q.isEmpty || _typing) return;
    _input.clear();
    setState(() {
      _messages.add(_Message(true, q));
      _typing = true;
      _suggestions = const [];
    });
    _scrollToEnd();
    // A short pause so the reply feels like a conversation.
    await Future.delayed(const Duration(milliseconds: 700));
    final reply = _assistant!.reply(q);
    if (!mounted) return;
    setState(() {
      _typing = false;
      _messages.add(_Message(false, reply.text));
      _suggestions = reply.suggestions;
    });
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ---- Header ----
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(children: [
                if (canPop) ...[
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 4),
                ],
                const _BotAvatar(size: 46),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Coach', style: AppText.h1),
                      Row(children: [
                        Icon(Icons.circle, size: 8, color: AppColors.limeDark),
                        SizedBox(width: 5),
                        Text('Offline · uses your food log', style: AppText.small),
                      ]),
                    ],
                  ),
                ),
              ]),
            ),

            // ---- Messages ----
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                itemCount: _messages.length + (_typing ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i == _messages.length) return const _TypingBubble();
                  return _Bubble(message: _messages[i]);
                },
              ),
            ),

            // ---- Suggestions ----
            if (_suggestions.isNotEmpty)
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: _suggestions
                      .map((s) => Padding(
                            padding: const EdgeInsets.only(right: 8, bottom: 6),
                            child: Material(
                              color: AppColors.surface,
                              shape: const StadiumBorder(
                                  side: BorderSide(color: AppColors.line)),
                              child: InkWell(
                                customBorder: const StadiumBorder(),
                                onTap: () => _send(s),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 9),
                                  child: Text(s,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),

            // ---- Input ----
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _send,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Ask about food, nutrients, your day…',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide:
                            const BorderSide(color: AppColors.violet, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Material(
                  color: AppColors.lime,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _send(_input.text),
                    child: const SizedBox(
                      width: 52,
                      height: 52,
                      child: Icon(Icons.arrow_upward_rounded,
                          color: AppColors.ink, size: 24),
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _BotAvatar extends StatelessWidget {
  final double size;
  const _BotAvatar({this.size = 30});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppColors.ink,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.auto_awesome_rounded,
            color: AppColors.lime, size: size * 0.5),
      );
}

class _Bubble extends StatelessWidget {
  final _Message message;
  const _Bubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final user = message.fromUser;
    final bubble = Container(
      constraints:
          BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.74),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: user ? AppColors.violet : AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(user ? 20 : 6),
          bottomRight: Radius.circular(user ? 6 : 20),
        ),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            color: user ? Colors.white : AppColors.ink,
            fontSize: 14.5,
            height: 1.4,
          ),
          children: _rich(message.text),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: user ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!user) ...[const _BotAvatar(), const SizedBox(width: 8)],
          bubble,
        ],
      ),
    );
  }

  /// Turns **bold** markers into bold text spans.
  static List<TextSpan> _rich(String text) {
    final parts = text.split('**');
    return [
      for (var i = 0; i < parts.length; i++)
        TextSpan(
          text: parts[i],
          style: i.isOdd ? const TextStyle(fontWeight: FontWeight.w800) : null,
        ),
    ];
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          const _BotAvatar(),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, __) => Row(
                children: List.generate(3, (i) {
                  final phase = ((_c.value * 3) - i).clamp(0.0, 1.0);
                  final up = phase < 0.5 ? phase * 2 : (1 - phase) * 2;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: Color.lerp(AppColors.line, AppColors.violet, up),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
            ),
          ),
        ]),
      );
}
