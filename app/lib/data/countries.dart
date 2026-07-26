/// بلدٌ للاختيار: رمز ISO-2 · رمز الاتّصال الدوليّ · الاسم العربيّ · علمٌ (إيموجي).
/// يُستعمل في اختيار بادئة الهاتف (E.164) وفي دولة الملف الشخصيّ (للتصنيف).
class Country {
  final String code; // ISO-3166 alpha-2 (يُخزَّن في countryCode)
  final String dial; // رمز الاتّصال بلا +
  final String ar; // الاسم العربيّ
  final String fr; // الاسم الفرنسيّ
  final String flag; // علمٌ إيموجي

  const Country(this.code, this.dial, this.ar, this.fr, this.flag);

  /// اسمُ البلد بلغة الواجهة. **بياناتٌ لا ARB**: قائمةٌ مغلقةٌ مرتبطةٌ برمز ISO،
  /// وإضافةُ لغةٍ عمودٌ هنا لا مئةُ مفتاحٍ هناك.
  String nameIn(String languageCode) => languageCode == 'fr' ? fr : ar;

  /// علمٌ إيموجي من رمز ISO-2 (حرفا مؤشّر إقليميّ) — احتياطًا.
  static String flagOf(String iso2) {
    if (iso2.length != 2) return '🏳️';
    const base = 0x1F1E6;
    final a = iso2.toUpperCase().codeUnitAt(0) - 0x41;
    final b = iso2.toUpperCase().codeUnitAt(1) - 0x41;
    return String.fromCharCode(base + a) + String.fromCharCode(base + b);
  }
}

/// موريتانيا أوّلًا (الجمهور الأساس)، ثمّ العالم العربيّ، ثمّ بلدانٌ رئيسة.
const List<Country> kCountries = [
  Country('MR', '222', 'موريتانيا', 'Mauritanie', '🇲🇷'),
  Country('MA', '212', 'المغرب', 'Maroc', '🇲🇦'),
  Country('DZ', '213', 'الجزائر', 'Algérie', '🇩🇿'),
  Country('TN', '216', 'تونس', 'Tunisie', '🇹🇳'),
  Country('LY', '218', 'ليبيا', 'Libye', '🇱🇾'),
  Country('EG', '20', 'مصر', 'Égypte', '🇪🇬'),
  Country('SD', '249', 'السودان', 'Soudan', '🇸🇩'),
  Country('SA', '966', 'السعودية', 'Arabie saoudite', '🇸🇦'),
  Country('AE', '971', 'الإمارات', 'Émirats arabes unis', '🇦🇪'),
  Country('QA', '974', 'قطر', 'Qatar', '🇶🇦'),
  Country('KW', '965', 'الكويت', 'Koweït', '🇰🇼'),
  Country('BH', '973', 'البحرين', 'Bahreïn', '🇧🇭'),
  Country('OM', '968', 'عُمان', 'Oman', '🇴🇲'),
  Country('YE', '967', 'اليمن', 'Yémen', '🇾🇪'),
  Country('JO', '962', 'الأردن', 'Jordanie', '🇯🇴'),
  Country('LB', '961', 'لبنان', 'Liban', '🇱🇧'),
  Country('SY', '963', 'سوريا', 'Syrie', '🇸🇾'),
  Country('IQ', '964', 'العراق', 'Irak', '🇮🇶'),
  Country('PS', '970', 'فلسطين', 'Palestine', '🇵🇸'),
  Country('SN', '221', 'السنغال', 'Sénégal', '🇸🇳'),
  Country('ML', '223', 'مالي', 'Mali', '🇲🇱'),
  Country('NE', '227', 'النيجر', 'Niger', '🇳🇪'),
  Country('CI', '225', 'ساحل العاج', "Côte d'Ivoire", '🇨🇮'),
  Country('GN', '224', 'غينيا', 'Guinée', '🇬🇳'),
  Country('GM', '220', 'غامبيا', 'Gambie', '🇬🇲'),
  Country('NG', '234', 'نيجيريا', 'Nigéria', '🇳🇬'),
  Country('TD', '235', 'تشاد', 'Tchad', '🇹🇩'),
  Country('DJ', '253', 'جيبوتي', 'Djibouti', '🇩🇯'),
  Country('SO', '252', 'الصومال', 'Somalie', '🇸🇴'),
  Country('KM', '269', 'جزر القمر', 'Comores', '🇰🇲'),
  Country('TR', '90', 'تركيا', 'Turquie', '🇹🇷'),
  Country('FR', '33', 'فرنسا', 'France', '🇫🇷'),
  Country('ES', '34', 'إسبانيا', 'Espagne', '🇪🇸'),
  Country('IT', '39', 'إيطاليا', 'Italie', '🇮🇹'),
  Country('DE', '49', 'ألمانيا', 'Allemagne', '🇩🇪'),
  Country('GB', '44', 'بريطانيا', 'Royaume-Uni', '🇬🇧'),
  Country('BE', '32', 'بلجيكا', 'Belgique', '🇧🇪'),
  Country('NL', '31', 'هولندا', 'Pays-Bas', '🇳🇱'),
  Country('US', '1', 'الولايات المتحدة', 'États-Unis', '🇺🇸'),
  Country('CA', '1', 'كندا', 'Canada', '🇨🇦'),
];

/// البلد الافتراضيّ (موريتانيا).
const Country kDefaultCountry = Country('MR', '222', 'موريتانيا', 'Mauritanie', '🇲🇷');

/// يجد بلدًا برمز ISO-2، أو الافتراضيّ.
Country countryByCode(String code) => kCountries.firstWhere(
      (c) => c.code == code.toUpperCase(),
      orElse: () => kDefaultCountry,
    );
