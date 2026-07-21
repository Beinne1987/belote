import 'package:flutter/material.dart';

import '../net/api_client.dart';
import '../net/session_controller.dart';
import '../theme/belote_theme.dart';
import 'simple_top_bar.dart';

/// **شاشة الإشعارات (الجرس)** — كلُّ ما قيل لي: دعواتٌ وطلباتُ صداقةٍ ورسائلُ الإدارة.
///
/// لِمَ تُوجد أصلًا؟ لأنّ الإشعار المدفوع عابر: يُمسح بلمسةٍ خاطئة، ولا يصل من رفض
/// الإذن، ولا يصل والمفتاحُ غائب ([[fcm-push]]). الصندوقُ في الخادم يبقى، وهذه
/// نافذتُه.
///
/// **اللمسةُ تفعل ما يفعله الإشعار نفسُه** — الدعوةُ تفتح مقعدها، وطلبُ الصداقة يفتح
/// قائمة الأصدقاء: نفسُ الحمولة ونفسُ الوجهة ([[online-wiring]]).
class NotificationsScreen extends StatefulWidget {
  /// حقنٌ للاختبار؛ الإنتاج يقرأ من [SessionScope].
  final ApiClient? api;
  final String? token;

  /// ما يُفعَل بلمسة إشعار — يُمرَّر من `main` كي تبقى الشاشة عرضًا محضًا
  /// (نظير `HomeScreen.onOnline`). null ⇒ اللمسةُ تُعلّم مقروءًا ولا تنتقل.
  final void Function(AppNotification n)? onOpen;

  const NotificationsScreen({super.key, this.api, this.token, this.onOpen});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  ApiClient? _api;
  String? _token;
  SessionController? _session;

  List<AppNotification>? _items; // null ⇒ لم يصل بعد
  String? _error;
  bool _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loading || _items != null || _error != null) return; // مرّةً واحدة
    // بحثٌ **بلا فرض** (كـ`FriendsScreen`): الشاشة تعمل بتوكنٍ محقونٍ في الاختبار.
    _session = context.dependOnInheritedWidgetOfExactType<SessionScope>()?.notifier;
    _api = widget.api ?? _session?.api ?? ApiClient();
    _token = widget.token ?? _session?.session?.token;
    _load();
  }

  Future<void> _load() async {
    final token = _token;
    if (token == null) {
      setState(() {
        _items = const [];
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await _api!.notifications(token);
      if (!mounted) return;
      setState(() {
        _items = r.items;
        _loading = false;
      });
      _session?.setUnread(r.unread); // الشارةُ تتبع القائمةَ بلا نداءٍ ثانٍ
    } on ApiException catch (e) {
      if (!mounted) return;
      // **الفشل يُقال لا يُبتلع**: شاشةٌ فتحها اللاعب قاصدًا؛ فراغٌ كاذبٌ يقول
      // «لا شيء عندك» وهو كذبٌ عن دعوةٍ تنتظره.
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _markAll() async {
    final token = _token;
    if (token == null || _items == null) return;
    // **تفاؤليّ**: الشارةُ تختفي فورًا — والفشلُ يُعيدها عند التحديث التالي.
    // انتظارُ الشبكة لتزول نقطةٌ حمراء إبطاءٌ بلا سبب.
    setState(() {
      _items = [for (final n in _items!) n.copyWith(read: true)];
    });
    _session?.setUnread(0);
    try {
      final left = await _api!.markNotificationRead(token);
      _session?.setUnread(left);
    } catch (_) {
      // صمت: الرقمُ الصحيح يعود مع أوّل تحديث. لا شاشةَ خطأٍ لزينة.
    }
  }

  Future<void> _open(AppNotification n) async {
    if (!n.read) {
      final token = _token;
      setState(() {
        _items = [
          for (final i in _items!) i.id == n.id ? i.copyWith(read: true) : i,
        ];
      });
      if (token != null) {
        try {
          _session?.setUnread(await _api!.markNotificationRead(token, id: n.id));
        } catch (_) {
          // كسابقتها: القراءةُ تُصحَّح لاحقًا؛ الفتحُ لا ينتظرها.
        }
      }
    }
    widget.onOpen?.call(n);
  }

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    final items = _items;
    final hasUnread = items?.any((n) => !n.read) ?? false;

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: Column(
          children: [
            SimpleTopBar(
              title: 'الإشعارات',
              trailing: hasUnread
                  ? TextButton(
                      onPressed: _markAll,
                      child: Text('تعليم الكلّ',
                          style: TextStyle(color: t.accent, fontSize: 13)),
                    )
                  : null,
            ),
            Expanded(child: _body(t, items)),
          ],
        ),
      ),
    );
  }

  Widget _body(BeloteTheme t, List<AppNotification>? items) {
    if (_loading && items == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _Centered(
        icon: Icons.cloud_off,
        text: _error!,
        action: TextButton(onPressed: _load, child: const Text('إعادة المحاولة')),
        t: t,
      );
    }
    if (items == null || items.isEmpty) {
      return _Centered(
        icon: Icons.notifications_none,
        text: 'لا إشعارات بعد.\nالدعواتُ وطلباتُ الصداقة تصلك هنا.',
        t: t,
      );
    }
    // السحبُ للتحديث: أوّلُ ما تفعله يدٌ تنتظر دعوة.
    return RefreshIndicator(
      onRefresh: _load,
      color: t.accent,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _NotificationTile(
          n: items[i],
          onTap: () => _open(items[i]),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification n;
  final VoidCallback onTap;
  const _NotificationTile({required this.n, required this.onTap});

  /// أيقونةُ النوع — **المجهولُ جرسٌ عامّ** لا انهيار ([[ws-event-forward-compat]]).
  (IconData, Color) _icon(BeloteTheme t) => switch (n.kind) {
        NotificationKind.invite => (Icons.table_bar, t.accent),
        NotificationKind.friendRequest => (Icons.person_add, const Color(0xFF5BC6F0)),
        NotificationKind.system => (Icons.campaign, const Color(0xFF9B8CFF)),
        NotificationKind.unknown => (Icons.notifications, t.text3),
      };

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    final (icon, color) = _icon(t);
    return Material(
      color: n.read ? t.surface : t.surface2,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            // غيرُ المقروء يُميَّز **بالحدّ واللون** لا بالخطّ العريض وحده: أوضحُ
            // على شاشةٍ صغيرة، وأخفُّ على عينٍ تقرأ عشرة صفوف.
            border: Border.all(color: n.read ? t.line : color.withValues(alpha: .55)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            style: TextStyle(
                              color: t.text,
                              fontSize: 14.5,
                              fontWeight: n.read ? FontWeight.w600 : FontWeight.w800,
                            ),
                          ),
                        ),
                        if (!n.read)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 6),
                            decoration:
                                BoxDecoration(color: color, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(n.body,
                        style: TextStyle(color: t.text2, fontSize: 13, height: 1.5)),
                    const SizedBox(height: 6),
                    Text(_ago(n.createdAt),
                        style: TextStyle(color: t.text3, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// «منذ ٣ دقائق» — الوقتُ النسبيّ أنفعُ من تاريخٍ كامل: اللاعب يسأل «هل فاتتني
/// الطاولة؟» لا «في أيّ ساعةٍ بالضبط؟».
///
/// الأرقام **لاتينيّة** حتى في الواجهة العربيّة (عُرف المشروع) — و`Text` يرثها
/// كذلك من `MaterialApp`، فلا حاجة لعزلٍ هنا.
String _ago(DateTime at) {
  final d = DateTime.now().difference(at);
  if (d.inSeconds < 60) return 'الآن';
  if (d.inMinutes < 60) return 'منذ ${d.inMinutes} دقيقة';
  if (d.inHours < 24) return 'منذ ${d.inHours} ساعة';
  if (d.inDays < 7) return 'منذ ${d.inDays} يوم';
  return '${at.year}/${at.month}/${at.day}';
}

class _Centered extends StatelessWidget {
  final IconData icon;
  final String text;
  final Widget? action;
  final BeloteTheme t;
  const _Centered({required this.icon, required this.text, required this.t, this.action});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: t.text3, size: 44),
              const SizedBox(height: 12),
              Text(text,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: t.text2, fontSize: 14, height: 1.6)),
              if (action != null) ...[const SizedBox(height: 8), action!],
            ],
          ),
        ),
      );
}
