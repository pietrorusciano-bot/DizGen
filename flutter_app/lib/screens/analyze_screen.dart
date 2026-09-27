import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';

import '../api_service.dart';
import '../models.dart';
import 'word_detail_screen.dart';

const _primary = Color(0xFF630ED4);
const _primaryContainer = Color(0xFF7C3AED);
const _surface = Color(0xFFFBF8FF);
const _onSurface = Color(0xFF171B2D);
const _onSurfaceVariant = Color(0xFF4A4455);

const List<List<Color>> _accents = [
  [Color(0xFFF3E8FF), Color(0xFF6B21A8)],
  [Color(0xFFFEF3C7), Color(0xFFB45309)],
  [Color(0xFFFCE7F3), Color(0xFFBE185D)],
];

const _chunkSeconds = 4;

class AnalyzeScreen extends StatefulWidget {
  const AnalyzeScreen({super.key});

  @override
  State<AnalyzeScreen> createState() => _AnalyzeScreenState();
}

class _AnalyzeScreenState extends State<AnalyzeScreen> {
  final _textController = TextEditingController();
  final _recorder = AudioRecorder();
  final ScrollController _listController = ScrollController();

  List<TermMatch> _matches = [];
  bool _recording = false;
  bool _showBackToTop = false;

  StreamSubscription<Uint8List>? _streamSub;
  final List<int> _audioBuffer = [];
  Timer? _flushTimer;
  bool _sending = false;
  String _baseText = '';
  String _liveTranscript = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _listController.addListener(() {
      final show = _listController.hasClients && _listController.offset > 200;
      if (show != _showBackToTop && mounted) {
        setState(() => _showBackToTop = show);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _flushTimer?.cancel();
    _streamSub?.cancel();
    _textController.dispose();
    _listController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _toggleMic() async {
    if (_recording) {
      await _stopRecording();
      return;
    }

    final ok = await _recorder.hasPermission();
    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permesso microfono negato')),
        );
      }
      return;
    }

    try {
      final pcmStream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
          noiseSuppress: true,
          echoCancel: true,
        ),
      );

      _baseText = _textController.text.trim();
      _liveTranscript = '';
      _audioBuffer.clear();

      _streamSub = pcmStream.listen((chunk) {
        _audioBuffer.addAll(chunk);
      });

      _flushTimer = Timer.periodic(
        const Duration(seconds: _chunkSeconds),
        (_) => _flush(),
      );

      setState(() {
        _recording = true;
        _matches = [];
      });
    } catch (_) {
      _showError('Impossibile avviare la registrazione');
    }
  }

  Future<void> _flush() async {
    if (_sending || _audioBuffer.isEmpty) return;
    _sending = true;
    final bytes = Uint8List.fromList(_audioBuffer);
    _audioBuffer.clear();
    try {
      final text = await ApiService.instance.transcribe(bytes);
      if (mounted && text.isNotEmpty) {
        setState(() {
          _liveTranscript = '$_liveTranscript $text'.trim();
          _textController.text =
              (_baseText.isEmpty ? '' : '$_baseText ') + _liveTranscript;
        });
        _scheduleAnalysis();
      }
    } catch (_) {
      // ignore single-chunk errors and keep going
    } finally {
      _sending = false;
    }
  }

  Future<void> _stopRecording() async {
    _flushTimer?.cancel();
    _flushTimer = null;
    try {
      await _recorder.stop();
    } catch (_) {}
    await _streamSub?.cancel();
    _streamSub = null;
    await Future.delayed(const Duration(milliseconds: 300));
    await _flush();
    if (mounted) setState(() => _recording = false);
    _debounce?.cancel();
    if (mounted) _analyze();
  }

  void _scheduleAnalysis() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), () {
      if (mounted) _analyze();
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _analyze() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    try {
      final matches = await ApiService.instance.analyze(text);
      if (mounted) setState(() => _matches = matches);
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _clearConversation() {
    setState(() {
      _textController.clear();
      _matches = [];
      _liveTranscript = '';
      _baseText = '';
    });
  }

  Future<void> _editText() async {    final controller = TextEditingController(text: _textController.text);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Testo'),
        content: TextField(
          controller: controller,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: 'Incolla o scrivi un testo...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Analizza'),
          ),
        ],
      ),
    );
    if (result != null && mounted) {
      _textController.text = result;
      _analyze();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiService.instance.user;
    final genName = user?.generation?.name;
    final unfamiliar = _matches.where((m) => !m.familiar).toList();
    final familiar = _matches.where((m) => m.familiar).toList();

    return Container(
      color: _surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              children: [
                if (genName != null) _profilePill(genName),
                const SizedBox(height: 14),
                _statusCard(),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                ListView(
                  controller: _listController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    _transcriptCard(unfamiliar.length),
                    if (unfamiliar.isNotEmpty || familiar.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _detectedWords(unfamiliar, familiar),
                    ],
                  ],
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: _backToTopButton(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _backToTopButton() {
    return AnimatedOpacity(
      opacity: _showBackToTop ? 1 : 0,
      duration: const Duration(milliseconds: 200),
      child: IgnorePointer(
        ignoring: !_showBackToTop,
        child: Material(
          color: Colors.black.withValues(alpha: 0.45),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              _listController.animateTo(
                0,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
              );
            },
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(Icons.arrow_upward, color: Colors.white, size: 22),
            ),
          ),
        ),
      ),
    );
  }

  Widget _profilePill(String genName) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF3E8FF),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE9D5FF)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.circle, size: 8, color: Colors.green),
            const SizedBox(width: 6),
            const Text('Profilo: ',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _onSurfaceVariant)),
            Text(genName,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _primary)),
          ],
        ),
      ),
    );
  }

  Widget _statusCard() {
    final listening = _recording;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE4FC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDDD0F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _listeningEmblem(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: listening ? Colors.green : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          listening ? 'Sto ascoltando...' : 'Pronto ad ascoltare',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _onSurface),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      listening
                          ? 'Trascrivo in tempo reale con Groq'
                          : 'Tocca il microfono per iniziare',
                      style: const TextStyle(
                          fontSize: 11, color: _onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    _Waveform(active: listening),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _micButton(),
          if (listening) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDDD0F0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.graphic_eq, size: 14, color: _primary),
                  const SizedBox(width: 6),
                  const Text('Ascolto in corso...',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _onSurface)),
                  const SizedBox(width: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFE9D5FF)),
                    ),
                    child: const Text('LIVE',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: _primary)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _micButton() {
    return GestureDetector(
      onTap: _toggleMic,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _recording ? Colors.red : _primaryContainer,
          boxShadow: [
            BoxShadow(
              color: (_recording ? Colors.red : _primary).withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          _recording ? Icons.stop : Icons.mic,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }

  Widget _listeningEmblem() {
    return Image.asset(
      'assets/stemma_ascolto.png',
      width: 76,
      height: 76,
      fit: BoxFit.contain,
    );
  }

  Widget _transcriptCard(int slangCount) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEDE9FE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.graphic_eq, size: 16, color: _primary),
              const SizedBox(width: 6),
              const Expanded(
                child: Text('Trascrizione in tempo reale',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: _onSurfaceVariant)),
              ),
              if (slangCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Text('$slangCount slang colti',
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF15803D))),
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: _onSurfaceVariant),
                tooltip: 'Svuota conversazione',
                onPressed: _clearConversation,
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 18, color: _onSurfaceVariant),
                tooltip: 'Incolla o modifica testo',
                onPressed: _editText,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_textController.text.trim().isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1F0F5)),
              ),
              child: const Text(
                'Parla o incolla un testo: qui apparirà la trascrizione con lo slang evidenziato.',
                style: TextStyle(
                    fontSize: 13,
                    color: _onSurfaceVariant,
                    fontStyle: FontStyle.italic),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1F0F5)),
              ),
              child: Text.rich(_highlightedTranscript()),
            ),
        ],
      ),
    );
  }

  TextSpan _highlightedTranscript() {
    final text = _textController.text;
    final unfamiliar = _matches.where((m) => !m.familiar).toList();
    if (unfamiliar.isEmpty) {
      return TextSpan(
          text: text,
          style: const TextStyle(fontSize: 14, color: _onSurface, height: 1.5));
    }

    final matches = <({int start, int end, TermMatch m})>[];
    for (final m in unfamiliar) {
      final regex = RegExp('\\b${RegExp.escape(m.term)}\\b', caseSensitive: false);
      for (final match in regex.allMatches(text)) {
        matches.add((start: match.start, end: match.end, m: m));
      }
    }
    matches.sort((a, b) => a.start.compareTo(b.start));

    final spans = <InlineSpan>[];
    int last = 0;
    int idx = 0;
    for (final entry in matches) {
      if (entry.start < last) continue;
      if (entry.start > last) {
        spans.add(TextSpan(text: text.substring(last, entry.start)));
      }
      final colors = _accents[idx % _accents.length];
      spans.add(TextSpan(
        text: text.substring(entry.start, entry.end),
        style: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: colors[1],
          backgroundColor: colors[0],
          fontWeight: FontWeight.w800,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () => _openWordDetail(entry.m),
      ));
      idx++;
      last = entry.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last)));
    }
    return TextSpan(
        children: spans,
        style: const TextStyle(fontSize: 14, color: _onSurface, height: 1.5));
  }

  void _openWordDetail(TermMatch m) {
    final term = Term(
      id: m.id,
      term: m.term,
      definition: m.definition,
      example: m.example,
      source: '',
      usingGenerations: m.usingGenerations,
    );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WordDetailScreen(term: term)),
    );
  }

  Widget _detectedWords(List<TermMatch> unfamiliar, List<TermMatch> familiar) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Vocaboli rilevati',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _onSurface)),
            const SizedBox(width: 8),
            if (unfamiliar.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text('Gen Z',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ...unfamiliar.asMap().entries.map((e) => _wordCard(e.value, e.key, true)),
        ...familiar.asMap().entries.map((e) => _wordCard(e.value, e.key, false)),
      ],
    );
  }

  Widget _wordCard(TermMatch m, int index, bool unfamiliar) {
    final colors = unfamiliar
        ? _accents[index % _accents.length]
        : const [Color(0xFFF1F5F9), Color(0xFF475569)];
    return GestureDetector(
      onTap: () => _openWordDetail(m),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors[0]),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors[0],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    m.familiar ? 'Noto' : 'Gen Z',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: colors[1]),
                  ),
                ),
                const SizedBox(width: 8),
                Text(m.term,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _onSurface)),
                const Spacer(),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ],
            ),
            const SizedBox(height: 6),
            Text.rich(
              TextSpan(children: [
                const TextSpan(
                    text: 'Significato: ',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: _onSurface)),
                TextSpan(
                    text: m.definition,
                    style: const TextStyle(
                        fontSize: 12,
                        color: _onSurfaceVariant,
                        height: 1.4)),
              ]),
            ),
            if (m.example.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(m.example,
                  style: const TextStyle(
                      fontSize: 11,
                      color: _onSurfaceVariant,
                      fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
    );
  }
}

class _Waveform extends StatefulWidget {
  final bool active;
  const _Waveform({required this.active});

  @override
  State<_Waveform> createState() => _WaveformState();
}

class _WaveformState extends State<_Waveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value * 2 * math.pi;
        return SizedBox(
          height: 24,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: List.generate(11, (i) {
              final phase = math.sin(t + i * 0.6);
              final h = widget.active ? (5 + (phase + 1) * 8) : 3.0;
              return Container(
                width: 3,
                height: h.clamp(3, 24),
                margin: const EdgeInsets.only(right: 3),
                decoration: BoxDecoration(
                  color: _barColor(i),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Color _barColor(int i) {
    const colors = [
      Color(0xFFA5B4FC),
      Color(0xFF818CF8),
      Color(0xFF8B5CF6),
      Color(0xFFC4B5FD),
      Color(0xFF6366F1),
      Color(0xFFA78BFA),
      Color(0xFF7C3AED),
    ];
    return colors[i % colors.length];
  }
}
