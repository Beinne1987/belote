import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// من أين تُلتقَط الصورة.
enum AvatarSource { gallery, camera }

/// **يلتقط صورةً ويصغّرها** جاهزةً للرفع.
///
/// التصغير هنا لا على الخادم: صورةُ هاتفٍ حديثةٍ ٤ ميغابايت، وحدُّ nginx ميغابايتٌ
/// واحد ⇒ لولاه لقُطع الطلبُ قبل أن يبلغ الخادم أصلًا، ولرأى المستخدم فشلًا بلا سبب.
/// و`image_picker` يصغّر ويضغط **أصلًا** بمرمّز المنصّة ⇒ لا حزمةَ معالجةٍ ثانية.
///
/// **لا قصّ إلى مربّع**: نسبةُ الصورة تبقى كما التقطها، والدائرةُ تقصّها عرضًا
/// (`BoxFit.cover` في `PlayerAvatar`). القصُّ اليدويّ شاشةٌ كاملةٌ بحركاتٍ وإيماءات —
/// لا يستحقّها ما تراه في دائرةٍ قطرُها ٣٣ بكسل على الطاولة.
///
/// واجهةٌ (لا دالّة ساكنة) كي تُستبدَل في الاختبار: `image_picker` يحتاج منصّةً حيّة.
abstract class AvatarPicker {
  /// يُعيد بايتات الصورة، أو null إن ألغى المستخدم.
  Future<Uint8List?> pick(AvatarSource source);
}

/// التنفيذ الحقيقيّ فوق `image_picker`.
class DeviceAvatarPicker implements AvatarPicker {
  final ImagePicker _picker;
  DeviceAvatarPicker([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  /// أطولُ ضلعٍ بالبكسل. الصورة تُعرَض في دائرةٍ قطرُها ٨٨ بكسل في الملفّ و٣٣ على
  /// الطاولة ⇒ ٥١٢ سخيٌّ حتى لشاشةٍ بكثافة 3x، وما فوقه بايتاتٌ لا يراها أحد.
  static const maxSide = 512.0;

  /// جودة JPEG. ٨٥ حدُّ ما تراه العين في هذا الحجم؛ ما دونه يبين على الوجوه.
  static const quality = 85;

  @override
  Future<Uint8List?> pick(AvatarSource source) async {
    final file = await _picker.pickImage(
      source: source == AvatarSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: maxSide,
      maxHeight: maxSide,
      imageQuality: quality,
    );
    if (file == null) return null; // ألغى — ليس خطأً
    return file.readAsBytes();
  }
}
