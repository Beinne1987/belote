/// بلدٌ للاختيار: رمز ISO-2 · رمز الاتّصال الدوليّ · الاسم العربيّ · علمٌ (إيموجي).
/// يُستعمل في اختيار بادئة الهاتف (E.164) وفي دولة الملف الشخصيّ (للتصنيف).
class Country {
  final String code; // ISO-3166 alpha-2 (يُخزَّن في countryCode)
  final String dial; // رمز الاتّصال بلا +
  final String ar; // الاسم العربيّ
  final String flag; // علمٌ إيموجي

  const Country(this.code, this.dial, this.ar, this.flag);

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
  Country('MR', '222', 'موريتانيا', '🇲🇷'),
  Country('MA', '212', 'المغرب', '🇲🇦'),
  Country('DZ', '213', 'الجزائر', '🇩🇿'),
  Country('TN', '216', 'تونس', '🇹🇳'),
  Country('LY', '218', 'ليبيا', '🇱🇾'),
  Country('EG', '20', 'مصر', '🇪🇬'),
  Country('SD', '249', 'السودان', '🇸🇩'),
  Country('SA', '966', 'السعودية', '🇸🇦'),
  Country('AE', '971', 'الإمارات', '🇦🇪'),
  Country('QA', '974', 'قطر', '🇶🇦'),
  Country('KW', '965', 'الكويت', '🇰🇼'),
  Country('BH', '973', 'البحرين', '🇧🇭'),
  Country('OM', '968', 'عُمان', '🇴🇲'),
  Country('YE', '967', 'اليمن', '🇾🇪'),
  Country('JO', '962', 'الأردن', '🇯🇴'),
  Country('LB', '961', 'لبنان', '🇱🇧'),
  Country('SY', '963', 'سوريا', '🇸🇾'),
  Country('IQ', '964', 'العراق', '🇮🇶'),
  Country('PS', '970', 'فلسطين', '🇵🇸'),
  Country('SN', '221', 'السنغال', '🇸🇳'),
  Country('ML', '223', 'مالي', '🇲🇱'),
  Country('NE', '227', 'النيجر', '🇳🇪'),
  Country('CI', '225', 'ساحل العاج', '🇨🇮'),
  Country('GN', '224', 'غينيا', '🇬🇳'),
  Country('GM', '220', 'غامبيا', '🇬🇲'),
  Country('NG', '234', 'نيجيريا', '🇳🇬'),
  Country('TD', '235', 'تشاد', '🇹🇩'),
  Country('DJ', '253', 'جيبوتي', '🇩🇯'),
  Country('SO', '252', 'الصومال', '🇸🇴'),
  Country('KM', '269', 'جزر القمر', '🇰🇲'),
  Country('TR', '90', 'تركيا', '🇹🇷'),
  Country('FR', '33', 'فرنسا', '🇫🇷'),
  Country('ES', '34', 'إسبانيا', '🇪🇸'),
  Country('IT', '39', 'إيطاليا', '🇮🇹'),
  Country('DE', '49', 'ألمانيا', '🇩🇪'),
  Country('GB', '44', 'بريطانيا', '🇬🇧'),
  Country('BE', '32', 'بلجيكا', '🇧🇪'),
  Country('NL', '31', 'هولندا', '🇳🇱'),
  Country('US', '1', 'الولايات المتحدة', '🇺🇸'),
  Country('CA', '1', 'كندا', '🇨🇦'),
];

/// البلد الافتراضيّ (موريتانيا).
const Country kDefaultCountry = Country('MR', '222', 'موريتانيا', '🇲🇷');

/// يجد بلدًا برمز ISO-2، أو الافتراضيّ.
Country countryByCode(String code) => kCountries.firstWhere(
      (c) => c.code == code.toUpperCase(),
      orElse: () => kDefaultCountry,
    );
