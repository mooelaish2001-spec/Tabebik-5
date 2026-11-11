// ═══════════════════════════════════════════════════════════════════════════
//  طبقة Firebase المشتركة بين تطبيقات طبيبك الثلاثة (المستخدم · الطبيب · المركز)
//  ضع هذا الملف نفسه في lib/ لكل مشروع، واستورده:  import 'tabibak_firebase.dart';
//
//  • كل التطبيقات تتعامل مع Firebase عبر الصنف Fb فقط (خرائط Map عادية بلا أنواع Firestore).
//  • إن لم يكن Firebase مهيّأً (لا google-services.json) تبقى Fb.on = false وتعمل التطبيقات بالوضع التجريبي المحلي.
//
//  Collections:
//    users/{uid}                      ملف المريض (الاسم، الصحة...)
//    centers/{centerId}               المركز: status 0 معلّق · 1 معتمد · 2 مرفوض  (الاعتماد من لوحة Firebase فقط)
//    centers/{centerId}/private/bank  حساب المركز البنكي (للمركز فقط؛ يُنسخ للحجز عند التأكيد)
//    centerMembers/{+249...}          مستخدمو المركز (مدير/استقبال) — المفتاح هاتفهم
//    doctors/{lic}                    الملف العام للطبيب (verified يضعه فريق طبيبك بعد مراجعة بطاقة المجلس)
//    doctorKeys/{lic}                 هاتف الطبيب المسجّل (لا يقرؤه إلا صاحبه أو المركز الذي سجّله)
//    memberships/{lic}_{centerId}     عضوية طبيب في مركز بشروطها (status: active · requestedByDoctor · invitedByCenter · offApp · removed)
//    bookings/{id}                    الحجوزات (كل الأنواع) + الدفع: pay{state, info, receiptUrl}
//    Storage: receipts/{bookingId}/*.jpg   إشعارات التحويل
// ═══════════════════════════════════════════════════════════════════════════
import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// نتيجة قراءة مفتاح الطبيب: exists = وُجد سجل برقم المجلس · denied = وُجد لكنه مسجّل بهاتف آخر.
class DoctorKey {
  const DoctorKey(this.exists, this.denied, [this.phone = '']);
  final bool exists, denied;
  final String phone;
}

class Fb {
  Fb._();

  static bool on = false;
  static String initError = '';
  static String? _vid;
  static int? _token;
  static String _lastPhone = '';

  static FirebaseFirestore get _db => FirebaseFirestore.instance;
  static FirebaseAuth get _auth => FirebaseAuth.instance;

  static User? get user => on ? _auth.currentUser : null;
  static String? get uid => user?.uid;
  static String get phone => user?.phoneNumber ?? '';

  /// يهيّئ Firebase. إن فشل (لا إعدادات) يبقى on=false ويعمل التطبيق بالوضع التجريبي.
  /// لإيقافه عمداً: --dart-define=FIREBASE=false
  static Future<void> init() async {
    if (!const bool.fromEnvironment('FIREBASE', defaultValue: true)) return;
    try {
      await Firebase.initializeApp();
      on = true;
    } catch (e) {
      initError = '$e';
      on = false;
    }
  }

  // ───────────────────────── تحويلات ─────────────────────────
  static dynamic _plain(dynamic v) {
    if (v is Timestamp) return v.millisecondsSinceEpoch;
    if (v is Map) return {for (final e in v.entries) e.key.toString(): _plain(e.value)};
    if (v is List) return [for (final x in v) _plain(x)];
    return v;
  }

  static Map<String, dynamic> _row(DocumentSnapshot<Map<String, dynamic>> d) => {...(_plain(d.data() ?? <String, dynamic>{}) as Map<String, dynamic>), 'id': d.id};

  static Stream<List<Map<String, dynamic>>> _watch(Query<Map<String, dynamic>> q) => q.snapshots().map((s) => [for (final d in s.docs) _row(d)]).handleError((_) {});

  // ───────────────────────── التحقق بالهاتف ─────────────────────────
  static String _msg(FirebaseAuthException e) => switch (e.code) {
        'invalid-phone-number' => 'رقم الهاتف غير صالح',
        'too-many-requests' => 'محاولات كثيرة، حاول لاحقاً',
        'quota-exceeded' => 'تعذّر إرسال الرسالة الآن، حاول لاحقاً',
        'invalid-verification-code' => 'الرمز غير صحيح',
        'session-expired' || 'code-expired' => 'انتهت صلاحية الرمز، اطلب رمزاً جديداً',
        'network-request-failed' => 'لا يوجد اتصال بالإنترنت',
        'missing-client-identifier' || 'app-not-authorized' => 'التطبيق غير مهيّأ للتحقق بالهاتف (راجع إعدادات Firebase)',
        _ => 'تعذّر التحقق (${e.code})',
      };

  /// يرسل رمز SMS إلى [phone] (+249XXXXXXXXX). onAuto عند التحقق التلقائي على أندرويد.
  static Future<void> sendCode(String phone, {required void Function() onSent, required void Function(String) onError, void Function()? onAuto}) async {
    if (phone != _lastPhone) {
      _token = null;
      _lastPhone = phone;
    }
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        forceResendingToken: _token,
        verificationCompleted: (cred) async {
          try {
            await _auth.signInWithCredential(cred);
            onAuto?.call();
          } catch (_) {}
        },
        verificationFailed: (e) => onError(_msg(e)),
        codeSent: (id, token) {
          _vid = id;
          _token = token;
          onSent();
        },
        codeAutoRetrievalTimeout: (id) {
          _vid = id;
        },
      );
    } catch (_) {
      onError('تعذّر إرسال الرمز');
    }
  }

  /// يتحقق من الرمز ويسجّل الدخول. يرجع null عند النجاح، وإلا رسالة الخطأ.
  static Future<String?> verify(String code) async {
    final id = _vid;
    if (id == null) return 'اطلب رمزاً جديداً أولاً';
    try {
      await _auth.signInWithCredential(PhoneAuthProvider.credential(verificationId: id, smsCode: code));
      return null;
    } on FirebaseAuthException catch (e) {
      return _msg(e);
    } catch (_) {
      return 'تعذّر التحقق';
    }
  }

  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {}
  }

  static Future<void> deleteAuthUser() async {
    try {
      await _auth.currentUser?.delete();
    } catch (_) {
      await signOut();
    }
  }

  // ───────────────────────── المستخدمون (المرضى) ─────────────────────────
  static Future<Map<String, dynamic>?> getUser(String uid) async {
    final d = await _db.collection('users').doc(uid).get();
    return d.exists ? _row(d) : null;
  }

  static Future<void> saveUser(String uid, Map<String, dynamic> m) => _db.collection('users').doc(uid).set(m);
  static Future<void> deleteUser(String uid) => _db.collection('users').doc(uid).delete();

  // ───────────────────────── الدليل العام (مراكز · أطباء · عضويات) ─────────────────────────
  /// المراكز المعتمدة فقط (status == 1).
  static Stream<List<Map<String, dynamic>>> centers() => _watch(_db.collection('centers').where('status', isEqualTo: 1));

  /// الأطباء الموثَّقون فقط.
  static Stream<List<Map<String, dynamic>>> doctors() => _watch(_db.collection('doctors').where('verified', isEqualTo: true));

  static Stream<List<Map<String, dynamic>>> memberships() => _watch(_db.collection('memberships'));
  static Stream<List<Map<String, dynamic>>> membershipsOfCenter(String centerId) => _watch(_db.collection('memberships').where('centerId', isEqualTo: centerId));
  static Stream<List<Map<String, dynamic>>> membershipsOfDoctor(String lic) => _watch(_db.collection('memberships').where('lic', isEqualTo: lic));

  /// مراقبة ملف الطبيب العام (لمعرفة توثيقه من الإدارة).
  static Stream<Map<String, dynamic>?> watchDoctor(String lic) => _db.collection('doctors').doc(lic).snapshots().map((d) => d.exists ? _row(d) : null).handleError((_) {});

  static Future<void> setMembership(String id, Map<String, dynamic> m) => _db.collection('memberships').doc(id).set({...m, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));

  // ───────────────────────── الأطباء ─────────────────────────
  static Future<Map<String, dynamic>?> getDoctor(String lic) async {
    final d = await _db.collection('doctors').doc(lic).get();
    return d.exists ? _row(d) : null;
  }

  /// حساب الطبيب المرتبط بهذا المستخدم (بعد الدخول).
  static Future<Map<String, dynamic>?> doctorOfUid(String uid) async {
    final q = await _db.collection('doctors').where('uid', isEqualTo: uid).limit(1).get();
    return q.docs.isEmpty ? null : _row(q.docs.first);
  }

  /// يقرأ هاتف الطبيب المسجّل برقم المجلس. القواعد تسمح بالقراءة لصاحب الهاتف أو للمركز الذي سجّله فقط؛
  /// وإن كان مسجّلاً بهاتف آخر يرجع denied.
  static Future<DoctorKey> doctorKey(String lic) async {
    try {
      final d = await _db.collection('doctorKeys').doc(lic).get();
      if (!d.exists) return const DoctorKey(false, false);
      return DoctorKey(true, false, (d.data()?['phone'] ?? '') as String);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') return const DoctorKey(true, true);
      rethrow;
    }
  }

  /// يكتب الملف العام للطبيب (ومفتاحه الخاص عند الإنشاء) في دفعة واحدة.
  static Future<void> saveDoctor(String lic, Map<String, dynamic> pub, {Map<String, dynamic>? key}) async {
    final b = _db.batch();
    if (key != null) b.set(_db.collection('doctorKeys').doc(lic), key);
    b.set(_db.collection('doctors').doc(lic), {...pub, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    await b.commit();
  }

  static Future<void> deleteDoctor(String lic) async {
    final b = _db.batch();
    b.delete(_db.collection('doctors').doc(lic));
    b.delete(_db.collection('doctorKeys').doc(lic));
    await b.commit();
  }

  // ───────────────────────── المراكز ومستخدموها ─────────────────────────
  static Future<Map<String, dynamic>?> getCenter(String id) async {
    final d = await _db.collection('centers').doc(id).get();
    return d.exists ? _row(d) : null;
  }

  /// مراقبة وثيقة المركز (لمعرفة اعتماده من الإدارة وهو على شاشة الانتظار).
  static Stream<Map<String, dynamic>?> watchCenter(String id) => _db.collection('centers').doc(id).snapshots().map((d) => d.exists ? _row(d) : null).handleError((_) {});

  static Future<Map<String, dynamic>?> centerMember(String phone) async {
    final d = await _db.collection('centerMembers').doc(phone).get();
    return d.exists ? _row(d) : null;
  }

  static Stream<List<Map<String, dynamic>>> membersOfCenter(String centerId) => _watch(_db.collection('centerMembers').where('centerId', isEqualTo: centerId));

  /// تسجيل مركز جديد (status = 0 إلى أن تعتمده الإدارة) مع مديره في دفعة واحدة.
  static Future<void> createCenter(String id, Map<String, dynamic> center, String managerPhone, Map<String, dynamic> member) async {
    final b = _db.batch();
    b.set(_db.collection('centers').doc(id), {...center, 'createdAt': FieldValue.serverTimestamp()});
    b.set(_db.collection('centerMembers').doc(managerPhone), member);
    await b.commit();
  }

  static Future<void> saveCenter(String id, Map<String, dynamic> m) => _db.collection('centers').doc(id).set({...m, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  static Future<void> saveMember(String phone, Map<String, dynamic> m) => _db.collection('centerMembers').doc(phone).set(m, SetOptions(merge: true));
  static Future<void> deleteMember(String phone) => _db.collection('centerMembers').doc(phone).delete();

  /// وثائق المركز الخاصة (centers/{id}/private/{name}): bank = الحساب البنكي (يُنسخ إلى الحجز عند التأكيد ليراه المريض)،
  /// ops = الأسرّة والكوادر. لا يقرؤها إلا مستخدمو المركز.
  static Future<Map<String, dynamic>?> privateDoc(String centerId, String name) async {
    final d = await _db.collection('centers').doc(centerId).collection('private').doc(name).get();
    return d.exists ? _row(d) : null;
  }

  static Future<void> savePrivate(String centerId, String name, Map<String, dynamic> m) => _db.collection('centers').doc(centerId).collection('private').doc(name).set(m);

  /// معرّف جديد لمركز (قبل إنشائه).
  static String newCenterId() => _db.collection('centers').doc().id;

  // ───────────────────────── الحجوزات ─────────────────────────
  static String newBookingId() => _db.collection('bookings').doc().id;
  static String codeOf(String id) => 'TB-${id.substring(0, 6).toUpperCase()}';

  static Future<void> putBooking(String id, Map<String, dynamic> m) => _db.collection('bookings').doc(id).set({...m, 'code': codeOf(id), 'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp()});

  /// تعديل جزئي. المفاتيح المتداخلة بالنقطة مسموحة: {'pay.state': 'sent'}.
  static Future<void> updateBooking(String id, Map<String, dynamic> patch) => _db.collection('bookings').doc(id).update({...patch, 'updatedAt': FieldValue.serverTimestamp()});

  /// وثائق خاصة داخل الحجز (bookings/{id}/private/{name}): الملف الصحي الذي شاركه المريض — يقرؤه المريض والطبيب فقط (لا المركز).
  static Future<void> putBookingPrivate(String id, String name, Map<String, dynamic> m) => _db.collection('bookings').doc(id).collection('private').doc(name).set(m);

  static Future<Map<String, dynamic>?> bookingPrivate(String id, String name) async {
    final d = await _db.collection('bookings').doc(id).collection('private').doc(name).get();
    return d.exists ? _row(d) : null;
  }

  static Stream<List<Map<String, dynamic>>> bookingsOfPatient(String uid) => _watch(_db.collection('bookings').where('patientUid', isEqualTo: uid));
  static Stream<List<Map<String, dynamic>>> bookingsOfCenter(String centerId) => _watch(_db.collection('bookings').where('centerId', isEqualTo: centerId));
  static Stream<List<Map<String, dynamic>>> bookingsOfDoctor(String lic) => _watch(_db.collection('bookings').where('doctorLic', isEqualTo: lic));

  // ───────────────────────── الصور (إشعارات التحويل) ─────────────────────────
  static Future<String> upload(String path, Uint8List bytes) async {
    final r = FirebaseStorage.instance.ref(path);
    await r.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return r.getDownloadURL();
  }

  /// يرفع ملفاً خاصاً (مثل ترخيص المركز) ويرجع مساره فقط بلا رابط تنزيل — لا يراه إلا فريق الإدارة من لوحة Firebase.
  static Future<String> uploadPrivate(String path, Uint8List bytes) async {
    await FirebaseStorage.instance.ref(path).putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return path;
  }

  /// يفتح معرض الصور (أو الكاميرا) ويرجع بايتات الصورة، أو null عند الإلغاء.
  static Future<Uint8List?> pickImage({bool camera = false}) async {
    try {
      final f = await ImagePicker().pickImage(source: camera ? ImageSource.camera : ImageSource.gallery, maxWidth: 1400, imageQuality: 80);
      return f == null ? null : await f.readAsBytes();
    } catch (_) {
      return null;
    }
  }
}