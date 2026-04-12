import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../theme/app_theme.dart';
import '../../services/gemma_service.dart';
import '../../services/tts_service.dart';

class _Turn {
  final bool isUser;
  final String text;
  _Turn(this.isUser, this.text);
}

class SimulationConvoScreen extends StatefulWidget {
  const SimulationConvoScreen({super.key});

  @override
  State<SimulationConvoScreen> createState() => _SimulationConvoScreenState();
}

class _SimulationConvoScreenState extends State<SimulationConvoScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<_Turn> _turns = [];

  bool _booting = true;
  bool _thinking = false;
  String _status = "Loading Na'vi model…";
  bool _modelReady = false;
  @override
  void initState() {
    super.initState();
    _boot();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ── Boot ────────────────────────────────────────────────────────────────
  Future<void> _boot() async {
    try {
      final dir = await getExternalStorageDirectory();   // ← changed
      if (dir == null) {
        setState(() {
          _booting = false;
          _status = 'External storage unavailable.';
        });
        return;
      }
      final path = '${dir.path}/gemma-3n-E2B-it-int4.task';

      await GemmaService().init(path);

      setState(() {
        _booting = false;
        _modelReady = true;
        _turns.add(_Turn(false, "Kaltxì, ma 'eylan!\n(en) Hello, friend!"));
      });
    } catch (e) {
      setState(() {
        _booting = false;
        _status = 'Error loading model: $e';
      });
    }
  }

  // ── Send ────────────────────────────────────────────────────────────────
  Future<void> _send() async {
    if (!_modelReady) return;
    final text = _controller.text.trim();
    if (text.isEmpty || _thinking) return;
    _controller.clear();

    setState(() {
      _turns.add(_Turn(true, text));
      _turns.add(_Turn(false, ''));
      _thinking = true;
    });

    final buf = StringBuffer();
    try {
      await for (final tok in GemmaService().sendMessage(text)) {
        buf.write(tok);
        setState(() => _turns[_turns.length - 1] = _Turn(false, buf.toString()));
        _scrollToBottom();
      }

      // Speak only the Na'vi line (first line, before "(en) …").
      final naviLine = buf.toString().split('\n').first.trim();
      if (naviLine.isNotEmpty) {
        await TtsService.speak(naviLine);
      }
    } catch (e) {
      setState(() => _turns[_turns.length - 1] = _Turn(false, '⚠️ $e'));
    } finally {
      if (mounted) setState(() => _thinking = false);
    }
  }

  Future<void> _reset() async {
    await GemmaService().reset();
    setState(() {
      _turns
        ..clear()
        ..add(_Turn(false, "Kaltxì, ma 'eylan!\n(en) Hello, friend!"));
    });
  }

  void _scrollToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Restart conversation',
            onPressed: (_booting || _thinking) ? null : _reset,
          ),
        ],
      ),
      body: _booting ? _buildLoading() : _buildChat(),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(_status, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildChat() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(16),
            itemCount: _turns.length,
            itemBuilder: (_, i) => _bubble(_turns[i]),
          ),
        ),
        _buildInputBar(),
      ],
    );
  }

  Widget _bubble(_Turn t) {
    return Align(
      alignment: t.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: t.isUser ? AppColors.primary : AppColors.primaryLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          t.text.isEmpty ? '…' : t.text,
          style: TextStyle(
            color: t.isUser ? Colors.white : AppColors.textPrimary,
            fontSize: 16,
            height: 1.35,
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: !_thinking && _modelReady,
                onSubmitted: (_) => _send(),
                decoration: const InputDecoration(
                  hintText: "Reply in Na'vi or English…",
                  border: OutlineInputBorder(),
                  contentPadding:
                  EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: !_thinking && _modelReady ? null : _send,
              icon: _thinking
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}