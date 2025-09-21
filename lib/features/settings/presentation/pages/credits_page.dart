import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class CreditsPage extends StatefulWidget {
  const CreditsPage({super.key});

  @override
  State<CreditsPage> createState() => _CreditsPageState();
}

class _CreditsPageState extends State<CreditsPage> {
  String _markdown = 'Cargando créditos...';

  @override
  void initState() {
    super.initState();
    _loadCredits();
  }

  Future<void> _loadCredits() async {
    final text = await rootBundle.loadString('assets/legal/CREDITS.md');
    if (!mounted) return;
    setState(() => _markdown = text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créditos de audio')),
      body: Markdown(
        data: _markdown,
        onTapLink: (text, href, title) {
          if (href != null) launchUrl(Uri.parse(href), mode: LaunchMode.externalApplication);
        },
        selectable: true,
        padding: const EdgeInsets.all(16),
      ),
    );
  }
}
