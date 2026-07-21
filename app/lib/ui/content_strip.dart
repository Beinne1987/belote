import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../net/api_client.dart';
import '../theme/belote_theme.dart';
import 'player_avatar.dart' show PlayerAvatar;

/// **شريط المحتوى** أعلى الرئيسيّة — لافتاتٌ دوّارة وآخرُ الأخبار، يديرهما
/// المالك من لوحة التحكّم.
///
/// **مكتفٍ بذاته وصامتُ الفشل**: يجلب `/content` مرّةً عند البناء؛ لا محتوى أو
/// تعذّرت الشبكة ⇒ لا يشغل بكسلًا واحدًا (`SizedBox.shrink`) — الرئيسيّةُ لا
/// تتعطّل على زينة.
class ContentStrip extends StatefulWidget {
  /// حقنٌ للاختبار؛ الإنتاج ينشئ عميلَه (المسار عامٌّ بلا توكن).
  final ApiClient? api;

  /// فترة تقدّم اللافتات آليًّا — تُصفَّر في الاختبارات.
  final Duration autoAdvance;

  const ContentStrip(
      {super.key, this.api, this.autoAdvance = const Duration(seconds: 5)});

  @override
  State<ContentStrip> createState() => _ContentStripState();
}

class _ContentStripState extends State<ContentStrip> {
  List<NewsView> _news = const [];
  List<BannerView> _banners = const [];
  final _page = PageController();
  Timer? _auto;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final c = await (widget.api ?? ApiClient()).content();
      if (!mounted) return;
      setState(() {
        _news = c.news;
        _banners = c.banners;
      });
      _armAuto();
    } on ApiException {
      // زينةٌ لا خبر — الصمتُ أهون من لافتةِ خطأ في وجه من فتح التطبيق.
    }
  }

  void _armAuto() {
    _auto?.cancel();
    if (_banners.length < 2 || widget.autoAdvance <= Duration.zero) return;
    _auto = Timer.periodic(widget.autoAdvance, (_) {
      if (!mounted || !_page.hasClients) return;
      _current = (_current + 1) % _banners.length;
      _page.animateToPage(_current,
          duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
    });
  }

  @override
  void dispose() {
    _auto?.cancel();
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_banners.isEmpty && _news.isEmpty) return const SizedBox.shrink();
    final t = BeloteTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_banners.isNotEmpty) _carousel(t),
        if (_news.isNotEmpty) _newsCard(t),
      ],
    );
  }

  Widget _carousel(BeloteTheme t) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              // نسبةُ لافتةٍ عريضة — تُقصّ الصورة لتملأها (المالك يرفع عريضًا).
              aspectRatio: 21 / 9,
              child: PageView.builder(
                controller: _page,
                itemCount: _banners.length,
                onPageChanged: (i) => _current = i,
                itemBuilder: (_, i) {
                  final url = PlayerAvatar.absolute(_banners[i].imageUrl);
                  if (url == null) return const SizedBox.shrink();
                  return CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    // الفشلُ صامت: مساحةٌ بلون السطح لا أيقونةُ عطبٍ حمراء.
                    errorWidget: (_, __, ___) => Container(color: t.surface2),
                    placeholder: (_, __) => Container(color: t.surface2),
                  );
                },
              ),
            ),
          ),
          if (_banners.length > 1) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _banners.length; i++)
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _current ? t.accent : t.line,
                    ),
                  ),
              ],
            ),
          ],
        ]),
      );

  Widget _newsCard(BeloteTheme t) {
    final latest = _news.first;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [t.surface2, t.surface],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openNews(t),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Icon(Icons.campaign_outlined, color: t.accentBright, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(latest.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: t.text, fontWeight: FontWeight.w800)),
                  Text(latest.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: t.text2, fontSize: 12.5)),
                ],
              ),
            ),
            Icon(Icons.chevron_left, color: t.text3),
          ]),
        ),
      ),
    );
  }

  void _openNews(BeloteTheme t) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: t.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
          children: [
            Text('آخر الأخبار',
                style: TextStyle(
                    color: t.text, fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            for (final n in _news) ...[
              const SizedBox(height: 8),
              Text(n.title,
                  style:
                      TextStyle(color: t.text, fontWeight: FontWeight.w800)),
              Text(n.body, style: TextStyle(color: t.text2, fontSize: 13.5)),
              Divider(color: t.line, height: 20),
            ],
          ],
        ),
      ),
    );
  }
}
