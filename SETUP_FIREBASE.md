# ربط تطبيقات طبيبك الثلاثة بـ Firebase

الملفات: `user_main.dart` (المريض) · `doctor_main.dart` (الطبيب) · `center_main.dart` (المركز) · `tabibak_firebase.dart` (الطبقة المشتركة) · `firestore.rules` · `storage.rules` · `firebase.json`.

> لم يُشغَّل الكود في بيئة Flutter عند كتابته. شغّل `flutter analyze` أولاً في كل مشروع وأصلح أي ملاحظة قبل التجربة.

## 1) مشروع Firebase (مرة واحدة للثلاثة)
1. أنشئ **مشروعاً واحداً** في Firebase Console، وسجّل فيه **ثلاثة تطبيقات Android** بثلاثة `applicationId` مختلفة (مثلاً `app.tabibak.user` و`app.tabibak.doctor` و`app.tabibak.center`). المشروع الواحد هو ما يجعل البيانات مشتركة بينها.
2. **Authentication → Sign-in method → Phone**: فعّله.
   - أضف بصمة SHA-1 وSHA-256 لكل تطبيق (Project settings → Your apps) وإلا يفشل التحقق بالهاتف على أندرويد.
   - **Authentication → Settings → SMS region policy**: تأكد من السماح بالسودان (+249).
   - للتجربة بلا رسائل حقيقية: Phone → *Phone numbers for testing*: أضف رقماً ورمزاً (مثل `+249912345678` ← `123456`).
3. **Firestore Database**: أنشئها (Production mode) ثم انشر القواعد (الخطوة 4).
4. **Storage**: فعّله (يحتاج خطة Blaze). تُرفع إليه إشعارات التحويل وتراخيص المراكز.

## 2) كل مشروع Flutter
```bash
flutter pub add firebase_core firebase_auth cloud_firestore firebase_storage image_picker google_fonts
```
- انسخ `tabibak_firebase.dart` إلى `lib/` في **كل** مشروع، وانسخ ملف التطبيق إلى `lib/main.dart`.
- ضع `google-services.json` الخاص بكل تطبيق في `android/app/` وأضف إضافة Gradle الخاصة بـ Google Services (التعليمات تظهر في Console عند تسجيل التطبيق).
- `minSdkVersion` لا يقل عن 23 في `android/app/build.gradle`.
- iOS (إن لزم): `GoogleService-Info.plist` + مفتاحا `NSPhotoLibraryUsageDescription` و`NSCameraUsageDescription` في Info.plist، وإعداد APNs ومخطط URL للتحقق بالهاتف.
- إن لم تُضَف إعدادات Firebase يعمل التطبيق **بالوضع التجريبي المحلي** تلقائياً (`Fb.on == false`). لإيقاف Firebase عمداً: `--dart-define=FIREBASE=false`.

## 3) تشغيل بلا بيانات تجريبية
`--dart-define=DEMO_DATA=false --dart-define=DEMO_OTP=false --dart-define=SIMULATE=false` (مع Firebase تُمسح البيانات التجريبية تلقائياً).

## 4) نشر القواعد
```bash
firebase deploy --only firestore:rules,storage
```

## 5) ما تفعله أنت من لوحة Firebase (الاعتماد)
- **اعتماد مركز:** Firestore ← `centers/{id}` ← غيّر `status` إلى `1` (معلّق 0 · معتمد 1 · مرفوض 2 مع `reason`). يظهر الاعتماد في تطبيق المركز تلقائياً.
- **توثيق طبيب:** Firestore ← `doctors/{رقم المجلس}` ← `verified = true` بعد مراجعة بطاقة المجلس. لا يظهر الطبيب للمرضى قبل ذلك.
- ترخيص المركز المرفوع يوجد في Storage ← `licenses/{centerId}.jpg` (لا يقرؤه إلا فريقك).

## 6) نموذج البيانات
| المسار | المحتوى | من يقرأ |
|---|---|---|
| `users/{uid}` | ملف المريض وصحته | صاحبه |
| `centers/{id}` | بيانات المركز العامة + `status` | الجميع |
| `centers/{id}/private/bank` | البنك ورقم الحساب واسم صاحبه | مستخدمو المركز |
| `centers/{id}/private/ops` | الأسرّة والكوادر | مستخدمو المركز |
| `centerMembers/{+249…}` | مستخدمو المركز (مدير/استقبال) والصلاحيات | صاحبه ومستخدمو مركزه |
| `doctors/{lic}` | الملف العام للطبيب + `verified` | الجميع |
| `doctorKeys/{lic}` | هاتف الطبيب المسجّل | صاحب الهاتف أو المركز الذي سجّله فقط |
| `memberships/{lic}_{centerId}` | شروط عمل الطبيب في المركز (سعر · أيام · ساعات) + الحالة | الجميع |
| `bookings/{id}` | الحجز + `pay{state, info, receiptUrl}` + `visit` | المريض والمركز المعني والطبيب |
| `bookings/{id}/private/health` | الملف الصحي الذي شاركه المريض | المريض والطبيب فقط (لا المركز) |

## 7) مسار الحجز والدفع
1. **المريض** يحجز ويكتب «بتشتكي من شنو» ← `bookings` بحالة `جديد` و`pay.state = later` (إن اختار التحويل).
2. **المركز** يرى الحجز فوراً ويؤكده ← `status = مؤكد`، و`pay.state = awaiting` مع `pay.info` (حسابه البنكي المحفوظ في «بيانات المركز»). إن لم يكن له حساب محفوظ يضغط «إرسال رقم الحساب» لاحقاً.
3. **المريض** يصله إشعار داخل التطبيق ورقم الحساب، فيحوّل ثم يرفق **لقطة شاشة من المعرض** ← Storage `receipts/{bookingId}` و`pay.state = sent`.
4. **المركز** يفتح الصورة ويضغط «تأكيد استلام المبلغ» (`verified`) أو «رفض الإشعار» مع السبب (`rejected` فيعيد المريض الإرسال).
5. إن لم يرد المركز على الطلب يرى المريض **رقم هاتف المركز** في صفحة الحجز ويتصل مباشرة.
6. **الطبيب** يرى الحجز المؤكَّد لليوم في «عيانين الليلة» مع الشكوى وملفه الصحي (إن شاركه)، ويُحدّث حالة الكشف؛ التشخيص لا يُرفع.

## 8) حدود معروفة (غير مُنفَّذة)
- **إشعارات الدفع (FCM):** التنبيهات تظهر داخل التطبيق أثناء فتحه فقط. للإشعارات والتطبيق مغلق أضف Firebase Cloud Messaging وCloud Functions.
- **توفّر الأسرّة والخدمات المنزلية والمعامل والإسعاف في تطبيق المريض** ما زالت قوائم ثابتة؛ حجوزاتها تصل للمركز لكن أسرّة المركز لا تُنشر للمرضى بعد.
- **التقييمات** محلية في تطبيق المريض.
- **حجز موعد مزدوج:** لا يمنع النظام حجزين في نفس الساعة للطبيب نفسه (يحتاج Transaction أو Cloud Function).
- **الشكوى** يراها المركز أيضاً (داخل وثيقة الحجز)؛ الملف الصحي وحده محجوب عنه.
- **احتلال رقم مجلس:** قد يسجّل شخص رقماً لم يسجّله غيره بعد؛ الحماية الفعلية هي أن الطبيب لا يظهر للمرضى قبل أن توثّقه أنت (`verified`).
- **سجل الأطباء ككل** يُقرأ لكل مستخدم (أسماء وتخصصات ومؤهلات فقط، بلا هواتف).
- راجع القواعد مع مختص أمان قبل الإطلاق.