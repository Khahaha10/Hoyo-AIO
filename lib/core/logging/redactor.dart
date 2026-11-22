abstract final class Redactor {
  static const _mask = '***';
  static const _visibleIdDigits = 3;

  static const _secretKeys = [
    'cookie',
    'set-cookie',
    'ltoken',
    'ltoken_v2',
    'ltuid',
    'ltuid_v2',
    'ltmid_v2',
    'cookie_token',
    'cookie_token_v2',
    'account_id',
    'account_id_v2',
    'account_mid_v2',
    'mid',
    'stoken',
    'e_hkrpg_token',
    'e_lrsag',
    'e_nap_token',
    'authkey',
    'ds',
  ];

  static const _idKeys = ['uid', 'role_id', 'game_role_id'];

  static final _secretPair = RegExp(
    '(${_secretKeys.map(RegExp.escape).join('|')})(["\']?\\s*[:=]\\s*["\']?)([^;,&\\s"\']+)',
    caseSensitive: false,
  );

  static final _idPair = RegExp(
    '(${_idKeys.map(RegExp.escape).join('|')})(["\']?\\s*[:=]\\s*["\']?)(\\d+)',
    caseSensitive: false,
  );

  static String redact(String input) => input
      .replaceAllMapped(_secretPair, (m) => '${m[1]}${m[2]}$_mask')
      .replaceAllMapped(_idPair, (m) => '${m[1]}${m[2]}${maskId(m[3] ?? '')}');

  static String maskId(String id) {
    if (id.length <= _visibleIdDigits) return _mask;
    return '$_mask${id.substring(id.length - _visibleIdDigits)}';
  }

  static String redactUri(Uri uri) =>
      redact(uri.replace(fragment: '').toString().replaceAll('#', ''));
}
