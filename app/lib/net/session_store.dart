import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

/// حفظ/استعادة جلسة المصادقة محليًّا (التوكن + اللاعب) عبر `shared_preferences`.
/// التوكن صالحٌ ٣٠ يومًا خادميًّا ⇒ يبقى اللاعب داخلًا بين التشغيلات حتى يخرج أو يُرفَض.
class SessionStore {
  static const _kToken = 'belote.auth.token';
  static const _kPlayer = 'belote.auth.player';

  Future<void> save(AuthSession s) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kToken, s.token);
    await p.setString(_kPlayer, jsonEncode(s.player.toJson()));
  }

  /// يُعيد الجلسة المحفوظة أو null. `isNew` دائمًا false (استعادة، لا إنشاء).
  Future<AuthSession?> load() async {
    final p = await SharedPreferences.getInstance();
    final token = p.getString(_kToken);
    final rawPlayer = p.getString(_kPlayer);
    if (token == null || rawPlayer == null) return null;
    try {
      final player = AccountPlayer.fromJson(jsonDecode(rawPlayer) as Map<String, dynamic>);
      return AuthSession(token: token, player: player, isNew: false);
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kToken);
    await p.remove(_kPlayer);
  }
}
