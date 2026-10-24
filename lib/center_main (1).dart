import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ═══════════════ طبيبك — تطبيق المركز (Center app) ═══════════════
// يستخدم نفس تصميم تطبيق المستخدمين. البيانات في الذاكرة (Db) وتتحدّث لحظياً بين الشاشات.
// للربط بالسيرفر: استبدل دوال Db (set / add / remove) بنداءات API.

const kRed = Color(0xFFD9141E), kInk = Color(0xFF1B2A4A), kGrey = Color(0xFF7B8494), kLine = Color(0xFFE9EDF2);
const kBg = Color(0xFFF7F8FB), kChip = Color(0xFFF1F3F7), kGreen = Color(0xFF2A8F4F), kAmber = Color(0xFFB7791F);
const kGrad = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE0161F), Color(0xFFB30B15)]);

TextStyle t(double s, {FontWeight w = FontWeight.w700, Color c = kInk, double? h}) => GoogleFonts.cairo(fontSize: s, fontWeight: w, color: c, height: h);
void go(BuildContext c, Widget w) => Navigator.push(c, MaterialPageRoute(builder: (_) => w));
Icon chev([Color c = kRed, double s = 24]) => Icon(Icons.chevron_left_rounded, color: c, size: s, textDirection: TextDirection.ltr);
BoxDecoration card([double r = 18]) => BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(r), border: Border.all(color: const Color(0xFFF0F2F6)), boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 6))]);
Widget gap([double h = 12]) => SizedBox(height: h);
Widget pill(String s, Color bg, Color fg) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)), child: Text(s, style: t(11.5, c: fg)));
Widget sec(String s) => Padding(padding: const EdgeInsets.only(top: 18, bottom: 10), child: Text(s, style: t(15.5, w: FontWeight.w800)));
String money(int n) => n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
int num(String s) => int.tryParse(s.replaceAll(',', '')) ?? 0;
void snack(BuildContext c, String m) => ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m, style: t(13, c: Colors.white))));

Widget badge(String s) {
  const m = {'جديد': (Color(0xFFFDE8EA), kRed), 'مؤكد': (Color(0xFFD9F3E1), kGreen), 'مكتمل': (kChip, kInk), 'مرفوض': (Color(0xFFFFF1D6), kAmber)};
  final x = m[s] ?? (kChip, kGrey);
  return pill(s, x.$1, x.$2);
}

Widget tile(IconData i, {double size = 44, bool dark = false}) => Container(
      width: size, height: size, alignment: Alignment.center,
      decoration: BoxDecoration(gradient: dark ? kGrad : null, color: dark ? null : const Color(0xFFFDE8EA), borderRadius: BorderRadius.circular(size / 3.2)),
      child: Icon(i, color: dark ? Colors.white : kRed, size: size * .52),
    );

Widget btn(String text, VoidCallback onTap, {bool outline = false, double h = 50}) => GestureDetector(
      onTap: onTap,
      child: Container(
        height: h, width: double.infinity, alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: outline ? null : kGrad, color: outline ? Colors.white : null, borderRadius: BorderRadius.circular(h / 2),
          border: outline ? Border.all(color: kRed, width: 1.6) : null,
          boxShadow: outline ? null : const [BoxShadow(color: Color(0x4DD9141E), blurRadius: 14, offset: Offset(0, 7))],
        ),
        child: Text(text, style: t(16, w: FontWeight.w800, c: outline ? kRed : Colors.white)),
      ),
    );

Widget bar(BuildContext c, List<Widget> ch) => Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(c).padding.bottom + 12),
      child: Column(mainAxisSize: MainAxisSize.min, children: [for (final w in ch) Padding(padding: const EdgeInsets.only(top: 8), child: w)]),
    );

Widget panel(List<Widget> ch) => Container(width: double.infinity, margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14), decoration: card(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: ch));
Widget kv(String k, String v, {bool bold = false}) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [Expanded(child: Text(k, style: t(13, w: FontWeight.w500, c: kGrey))), Flexible(child: Text(v, textAlign: TextAlign.end, style: t(13.5, c: bold ? kRed : kInk)))]));
Widget two(String a, String b) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(a, style: t(14.5, w: FontWeight.w800)), Text(b, style: t(12, w: FontWeight.w500, c: kGrey))]);

Widget fld(String l, TextEditingController c, {String? hint, int lines = 1, TextInputType? kb}) => Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l, style: t(12.5)),
        gap(6),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
          child: TextField(controller: c, maxLines: lines, keyboardType: kb, style: t(14, w: FontWeight.w600), decoration: InputDecoration(border: InputBorder.none, hintText: hint, hintStyle: t(13, w: FontWeight.w500, c: kGrey), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13))),
        ),
      ]),
    );

/// Chips bound to a Set<int> owned by the parent State (call setState via [refresh]).
Widget chips(List<String> items, Set<int> sel, VoidCallback refresh, {bool multi = false}) => Wrap(spacing: 8, runSpacing: 8, children: [
      for (var i = 0; i < items.length; i++)
        GestureDetector(
          onTap: () {
            if (multi) {
              sel.contains(i) ? sel.remove(i) : sel.add(i);
            } else {
              sel..clear()..add(i);
            }
            refresh();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(gradient: sel.contains(i) ? kGrad : null, color: sel.contains(i) ? null : kChip, borderRadius: BorderRadius.circular(20)),
            child: Text(items[i], style: t(13, c: sel.contains(i) ? Colors.white : const Color(0xFF4B5873))),
          ),
        ),
    ]);

Widget empty(IconData i, String s) => Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [tile(i, size: 84), gap(14), Text(s, textAlign: TextAlign.center, style: t(14, c: kGrey))])));

// ═══════════════ Data ═══════════════
class Booking {
  Booking(this.id, this.type, this.patient, this.phone, this.title, this.when, this.price, this.extra, {this.status = 'جديد'});
  final int id, type; // 0 طبيب · 1 سرير · 2 خدمة منزلية
  final String patient, phone, title, when, price, extra;
  String status, note = '', assigned = '';
}

class Doc {
  Doc(this.name, this.spec, this.quals, this.lic, this.exp, this.price, this.days, this.hours, {this.on = true});
  String name, spec, quals, lic, exp, price, days, hours;
  bool on;
}

class Bed {
  Bed(this.type, this.no, this.floor, this.price, this.equip, {this.free = true});
  String type, no, floor, price, equip;
  bool free;
}

class Svc {
  Svc(this.name, this.price, {this.on = true});
  String name, price;
  bool on;
}

class Db extends ChangeNotifier {
  final bookings = <Booking>[
    Booking(1, 0, 'محمد عبد الرحيم', '+249 912 345 678', 'كشف · د. أحمد محمد علي (باطنية)', 'السبت 18 أكتوبر · 4:30 م', '10,000', ''),
    Booking(2, 0, 'آمنة إبراهيم', '+249 923 111 222', 'كشف · د. سارة عبد الله (نساء وتوليد)', 'الأحد 19 أكتوبر · 6:00 م', '8,000', ''),
    Booking(3, 1, 'خالد يوسف', '+249 91 555 0101', 'حجز سرير ICU · 3 أيام', 'دخول السبت 18 أكتوبر', '45,000', 'ICU'),
    Booking(4, 2, 'فاطمة أحمد', '+249 99 888 7766', 'تمريض منزلي · حقن وريدي', 'الاثنين 20 أكتوبر · 9:00 ص', '3,000', 'الخرطوم - بحري - المسبح'),
    Booking(5, 2, 'عمر حسن', '+249 90 321 4455', 'سحب عينات · صورة دم + سكر', 'الثلاثاء 21 أكتوبر · 8:00 ص', '730', 'أم درمان - الثورة', status: 'مؤكد'),
    Booking(6, 0, 'ليلى محمود', '+249 92 444 3322', 'كشف · د. حسن محمود (أطفال)', 'الأحد 19 أكتوبر · 5:00 م', '7,500', '', status: 'مؤكد'),
    Booking(7, 1, 'سمير علي', '+249 91 777 6655', 'حجز سرير HDU · 2 أيام', 'دخول 12 أكتوبر', '24,000', 'HDU', status: 'مكتمل'),
  ];
  final docs = <Doc>[
    Doc('د. أحمد محمد علي', 'باطنية', 'ماجستير + دكتوراه باطنية - جامعة الخرطوم', '12345', '10', '10,000', 'السبت - الخميس', '8:00 ص - 6:00 م'),
    Doc('د. سارة عبد الله', 'نساء وتوليد', 'بكالوريوس الطب + دبلوم نساء وتوليد', '23456', '7', '8,000', 'الأحد - الخميس', '9:00 ص - 5:00 م'),
    Doc('د. حسن محمود', 'أطفال', 'ماجستير طب الأطفال', '34567', '9', '7,500', 'السبت - الأربعاء', '10:00 ص - 6:00 م', on: false),
  ];
  final beds = <Bed>[
    Bed('ICU', '101', '1', '15,000', 'جهاز تنفس · مونيتور'), Bed('ICU', '102', '1', '15,000', 'جهاز تنفس · مونيتور', free: false), Bed('ICU', '103', '1', '15,000', 'مونيتور'),
    Bed('HDU', '201', '2', '12,000', 'مونيتور · أكسجين'), Bed('HDU', '202', '2', '12,000', 'أكسجين'), Bed('CCU', '301', '3', '18,000', 'مونيتور قلب', free: false),
    Bed('عادية', '401', '4', '6,000', 'تكييف'), Bed('عادية', '402', '4', '6,000', 'تكييف'), Bed('عادية', '403', '4', '6,000', '', free: false),
  ];
  final svcs = <Svc>[Svc('زيارة طبيب للمنزل', '8,000'), Svc('تمريض منزلي', '3,000'), Svc('سحب عينات المعمل', '500', on: false)];
  final staff = <String>['أحمد عثمان · ممرض', 'هالة محمد · ممرضة', 'معتز علي · فني مختبر'];

  void set(Booking b, String s, {String note = '', String who = ''}) {
    b.status = s;
    b.note = note;
    b.assigned = who;
    notifyListeners();
  }

  void ping() => notifyListeners();
  int get fresh => bookings.where((b) => b.status == 'جديد').length;
  int get freeBeds => beds.where((b) => b.free).length;
  int get revenue => bookings.where((b) => b.status == 'مؤكد' || b.status == 'مكتمل').fold<int>(0, (a, b) => a + num(b.price));
}

final db = Db();
const kTypes = ['حجز طبيب', 'حجز سرير', 'خدمة منزلية'];
const kTypeIcons = [Icons.medical_services_rounded, Icons.bed_rounded, Icons.home_rounded];
const kBedTypes = ['ICU', 'HDU', 'CCU', 'عادية'];

// ═══════════════ Shell ═══════════════
void main() => runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'طبيبك للمراكز',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: kRed, scaffoldBackgroundColor: Colors.white, textTheme: GoogleFonts.cairoTextTheme(ThemeData.light().textTheme)),
      builder: (c, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
      home: const LoginScreen(),
    ));

const roots = <Widget>[HomeScreen(), BookingsScreen(), ManageScreen(), AccountScreen()];

class Nav extends StatelessWidget {
  const Nav(this.i, {super.key});
  final int i;
  static const items = [(Icons.dashboard_rounded, 'الرئيسية'), (Icons.event_note_rounded, 'الحجوزات'), (Icons.apps_rounded, 'الإدارة'), (Icons.person_rounded, 'حسابي')];
  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(26)), boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, -4))]),
        child: SafeArea(
          top: false,
          child: Row(children: [
            for (var k = 0; k < items.length; k++)
              Expanded(
                child: InkWell(
                  onTap: () {
                    if (k != i) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => roots[k]), (r) => false);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(items[k].$1, color: k == i ? kRed : kGrey),
                      Text(items[k].$2, style: t(10.5, w: k == i ? FontWeight.w800 : FontWeight.w500, c: k == i ? kRed : kGrey)),
                    ]),
                  ),
                ),
              ),
          ]),
        ),
      );
}

/// Red header + rounded sheet. [nav] != null => root page (no back arrow, bottom nav).
class RPage extends StatelessWidget {
  const RPage(this.title, {super.key, required this.body, this.nav, this.action, this.bottom});
  final String title;
  final Widget body;
  final int? nav;
  final Widget? action, bottom;
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: kGrad),
          child: Column(children: [
            SafeArea(
              bottom: false,
              child: SizedBox(
                height: 60,
                child: Row(children: [
                  SizedBox(width: 56, child: action),
                  Expanded(child: Text(title, textAlign: TextAlign.center, style: t(20, w: FontWeight.w800, c: Colors.white))),
                  SizedBox(
                    width: 56,
                    child: nav != null ? null : IconButton(onPressed: () => Navigator.maybePop(context), icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 36, textDirection: TextDirection.ltr)),
                  ),
                ]),
              ),
            ),
            Expanded(
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(color: kBg, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
                child: Column(children: [Expanded(child: body), if (bottom != null) bottom!, if (nav != null) Nav(nav!)]),
              ),
            ),
          ]),
        ),
      );
}

// ═══════════════ 1. Login ═══════════════
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final u = TextEditingController(), p = TextEditingController();
    return Scaffold(
      body: Column(children: [
        Container(
          height: 250, width: double.infinity,
          decoration: const BoxDecoration(gradient: kGrad, borderRadius: BorderRadius.vertical(bottom: Radius.circular(80))),
          child: SafeArea(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 60),
              Text('طبيبك', style: t(34, w: FontWeight.w900, c: Colors.white)),
              Text('بوابة المراكز الطبية', style: t(13, w: FontWeight.w500, c: Colors.white)),
            ]),
          ),
        ),
        Expanded(
          child: ListView(padding: const EdgeInsets.fromLTRB(24, 24, 24, 16), children: [
            Center(child: Text('تسجيل دخول المركز', style: t(21, w: FontWeight.w800))),
            fld('البريد الإلكتروني أو رقم الهاتف', u, hint: 'center@example.com', kb: TextInputType.emailAddress),
            Padding(padding: const EdgeInsets.only(top: 0), child: fld('كلمة المرور', p, hint: '••••••••')),
            gap(8),
            Text('نسيت كلمة المرور؟', style: t(12.5, c: kRed)),
            gap(18),
            btn('دخول', () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()))),
            gap(14),
            Center(child: Text('حساب المركز يُفعَّل بعد مراجعة الترخيص من إدارة طبيبك', textAlign: TextAlign.center, style: t(11.5, w: FontWeight.w500, c: kGrey, h: 1.6))),
          ]),
        ),
      ]),
    );
  }
}

// ═══════════════ 2. Dashboard ═══════════════
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  Widget stat(IconData i, String v, String l) => Expanded(
        child: Container(
          margin: const EdgeInsets.all(5), padding: const EdgeInsets.all(14), decoration: card(),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [tile(i), gap(8), Text(v, style: t(21, w: FontWeight.w800)), Text(l, style: t(11.5, w: FontWeight.w500, c: kGrey))]),
        ),
      );
  Widget quick(BuildContext c, IconData i, String s, Widget to) => Expanded(
        child: GestureDetector(
          onTap: () => go(c, to),
          child: Container(margin: const EdgeInsets.all(5), padding: const EdgeInsets.symmetric(vertical: 12), decoration: card(), child: Column(children: [tile(i, dark: true), gap(6), Text(s, textAlign: TextAlign.center, style: t(11.5))])),
        ),
      );
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: db,
        builder: (c, _) {
          final fresh = db.bookings.where((b) => b.status == 'جديد').toList();
          return RPage(
            'مركز المسباح الطبي',
            nav: 0,
            action: IconButton(onPressed: () => go(c, const NotifsScreen()), icon: const Icon(Icons.notifications_rounded, color: Colors.white, size: 28)),
            body: ListView(padding: const EdgeInsets.all(12), children: [
              Row(children: [stat(Icons.mark_email_unread_rounded, '${db.fresh}', 'طلبات جديدة'), stat(Icons.event_available_rounded, '${db.bookings.where((b) => b.status == 'مؤكد').length}', 'حجوزات مؤكدة')]),
              Row(children: [stat(Icons.bed_rounded, '${db.freeBeds}/${db.beds.length}', 'أسرّة متاحة'), stat(Icons.payments_rounded, '${money(db.revenue)} ج.س', 'الإيرادات')]),
              Row(children: [quick(c, Icons.person_add_alt_1_rounded, 'إضافة أخصائي', const DoctorForm()), quick(c, Icons.add_box_rounded, 'إضافة سرير', const BedForm()), quick(c, Icons.bar_chart_rounded, 'التقارير', const ReportsScreen())]),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 4, 6, 0),
                child: Row(children: [Expanded(child: sec('طلبات تنتظر ردّك')), GestureDetector(onTap: () => go(c, const BookingsScreen()), child: Text('عرض الكل', style: t(12.5, c: kRed)))]),
              ),
              if (fresh.isEmpty) SizedBox(height: 160, child: empty(Icons.done_all_rounded, 'لا توجد طلبات جديدة')),
              for (final b in fresh.take(4)) Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: BookingCard(b)),
            ]),
          );
        },
      );
}

// ═══════════════ 3. Bookings inbox ═══════════════
class BookingCard extends StatelessWidget {
  const BookingCard(this.b, {super.key});
  final Booking b;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => go(context, BookingDetails(b)),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14), decoration: card(),
          child: Column(children: [
            Row(children: [tile(kTypeIcons[b.type]), const SizedBox(width: 12), Expanded(child: two(b.patient, b.title)), badge(b.status)]),
            gap(8),
            Row(children: [
              const Icon(Icons.access_time_rounded, size: 16, color: kGrey),
              const SizedBox(width: 6),
              Expanded(child: Text(b.when, style: t(12, w: FontWeight.w600, c: const Color(0xFF4B5873)))),
              Text('${b.price} ج.س', style: t(13.5)),
            ]),
          ]),
        ),
      );
}

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});
  @override
  State<BookingsScreen> createState() => _BookingsState();
}

class _BookingsState extends State<BookingsScreen> {
  final type = {0}, st = {0};
  static const sts = ['الكل', 'جديد', 'مؤكد', 'مكتمل', 'مرفوض'];
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: db,
        builder: (c, _) {
          final list = db.bookings.where((b) => (type.first == 0 || b.type == type.first - 1) && (st.first == 0 || b.status == sts[st.first])).toList();
          return RPage(
            'الحجوزات',
            nav: 1,
            body: Column(children: [
              Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), child: chips(['الكل', ...kTypes], type, () => setState(() {}))),
              Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 8), child: chips(sts, st, () => setState(() {}))),
              Expanded(child: list.isEmpty ? empty(Icons.inbox_rounded, 'لا توجد حجوزات مطابقة') : ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 8), children: [for (final b in list) BookingCard(b)])),
            ]),
          );
        },
      );
}

// ═══════════════ 4. Booking details + accept / reject / complete ═══════════════
class BookingDetails extends StatefulWidget {
  const BookingDetails(this.b, {super.key});
  final Booking b;
  @override
  State<BookingDetails> createState() => _BookingDetailsState();
}

class _BookingDetailsState extends State<BookingDetails> {
  String? sel;
  Booking get b => widget.b;

  List<String> get options => b.type == 1 ? [for (final x in db.beds.where((x) => x.free && x.type == b.extra)) 'سرير ${x.no}'] : db.staff;

  void accept() {
    if (b.type != 0 && sel == null) return snack(context, b.type == 1 ? 'اختر السرير أولاً' : 'اختر الفرد المكلّف أولاً');
    if (b.type == 1) db.beds.firstWhere((x) => 'سرير ${x.no}' == sel).free = false;
    db.set(b, 'مؤكد', who: sel ?? '');
    snack(context, 'تم قبول الحجز وإشعار المريض');
    Navigator.pop(context);
  }

  void reject() {
    const reasons = ['الطبيب غير متاح في هذا الموعد', 'لا توجد أسرّة متاحة', 'خارج نطاق التغطية', 'سبب آخر'];
    var r = 0;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).padding.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('سبب الرفض', style: t(17, w: FontWeight.w800)),
            gap(8),
            for (var i = 0; i < reasons.length; i++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () => set(() => r = i),
                leading: Icon(r == i ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: r == i ? kRed : kGrey),
                title: Text(reasons[i], style: t(13.5, w: FontWeight.w600)),
              ),
            gap(8),
            btn('تأكيد الرفض', () {
              db.set(b, 'مرفوض', note: reasons[r]);
              Navigator.pop(ctx);
              Navigator.pop(context);
            }),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: db,
        builder: (c, _) => RPage(
          'تفاصيل الحجز',
          bottom: b.status == 'جديد'
              ? bar(c, [btn('قبول الحجز', accept), btn('رفض الحجز', reject, outline: true, h: 44)])
              : b.status == 'مؤكد'
                  ? bar(c, [btn('تم إنهاء الخدمة', () { db.set(b, 'مكتمل', who: b.assigned); Navigator.pop(c); })])
                  : null,
          body: ListView(padding: const EdgeInsets.all(16), children: [
            panel([
              Row(children: [
                tile(Icons.person_rounded, size: 52, dark: true),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(b.patient, style: t(16, w: FontWeight.w800)), Directionality(textDirection: TextDirection.ltr, child: Text(b.phone, style: t(12.5, w: FontWeight.w500, c: kGrey)))])),
                const CircleAvatar(backgroundColor: kRed, child: Icon(Icons.phone_rounded, color: Colors.white)),
              ]),
            ]),
            panel([
              Row(children: [Expanded(child: Text(kTypes[b.type], style: t(15))), badge(b.status)]),
              const Divider(color: kLine, height: 22),
              kv('الخدمة', b.title),
              kv('الموعد', b.when),
              if (b.type == 1) kv('نوع السرير', b.extra),
              if (b.type == 2) kv('العنوان', b.extra),
              kv('المبلغ', '${b.price} ج.س', bold: true),
              kv('طريقة الدفع', b.type == 2 ? 'نقداً عند الزيارة' : 'مدفوع عبر التطبيق'),
              if (b.assigned.isNotEmpty) kv(b.type == 1 ? 'السرير المخصص' : 'المكلّف', b.assigned),
              if (b.note.isNotEmpty) kv('سبب الرفض', b.note),
            ]),
            if (b.status == 'جديد' && b.type != 0) ...[
              sec(b.type == 1 ? 'تخصيص سرير' : 'تكليف ممرض / فني'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
                child: DropdownButton<String>(
                  value: sel, isExpanded: true, underline: const SizedBox(), hint: Text(options.isEmpty ? 'لا توجد أسرّة متاحة من هذا النوع' : 'اختر', style: t(13, w: FontWeight.w500, c: kGrey)),
                  items: [for (final o in options) DropdownMenuItem(value: o, child: Text(o, style: t(13.5, w: FontWeight.w600)))],
                  onChanged: (v) => setState(() => sel = v),
                ),
              ),
            ],
          ]),
        ),
      );
}

// ═══════════════ 5. Management hub ═══════════════
class ManageScreen extends StatelessWidget {
  const ManageScreen({super.key});
  Widget item(BuildContext c, IconData i, String s, String sub, Widget to) => GestureDetector(
        onTap: () => go(c, to),
        child: Container(padding: const EdgeInsets.all(14), decoration: card(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [tile(i, dark: true, size: 50), const Spacer(), Text(s, style: t(15, w: FontWeight.w800)), Text(sub, style: t(11.5, w: FontWeight.w500, c: kGrey))])),
      );
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: db,
        builder: (c, _) => RPage(
          'الإدارة',
          nav: 2,
          body: GridView.count(crossAxisCount: 2, padding: const EdgeInsets.all(16), mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 1.05, children: [
            item(c, Icons.medical_services_rounded, 'الأخصائيون', '${db.docs.length} أخصائي', const DoctorsScreen()),
            item(c, Icons.bed_rounded, 'الأسرّة', '${db.freeBeds} متاح من ${db.beds.length}', const BedsScreen()),
            item(c, Icons.home_rounded, 'الخدمات المنزلية', '${db.svcs.where((s) => s.on).length} خدمة مفعّلة', const HomeSvcScreen()),
            item(c, Icons.bar_chart_rounded, 'التقارير', 'الإيرادات والحجوزات', const ReportsScreen()),
            item(c, Icons.notifications_rounded, 'الإشعارات', '${db.fresh} جديد', const NotifsScreen()),
          ]),
        ),
      );
}

// ═══════════════ 6. Doctors ═══════════════
class DoctorsScreen extends StatelessWidget {
  const DoctorsScreen({super.key});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: db,
        builder: (c, _) => RPage(
          'الأخصائيون',
          bottom: bar(c, [btn('+ إضافة أخصائي', () => go(c, const DoctorForm()))]),
          body: db.docs.isEmpty
              ? empty(Icons.person_off_rounded, 'لم تضف أي أخصائي بعد')
              : ListView(padding: const EdgeInsets.all(16), children: [
                  for (final d in db.docs)
                    GestureDetector(
                      onTap: () => go(c, DoctorForm(d: d)),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14), decoration: card(),
                        child: Column(children: [
                          Row(children: [tile(Icons.person_rounded, size: 52), const SizedBox(width: 12), Expanded(child: two(d.name, '${d.spec} · ${d.exp} سنوات خبرة')), Switch(value: d.on, onChanged: (v) { d.on = v; db.ping(); })]),
                          gap(6),
                          kv('المؤهلات', d.quals),
                          kv('الدوام', '${d.days} · ${d.hours}'),
                          kv('سعر الكشف', '${d.price} ج.س', bold: true),
                        ]),
                      ),
                    ),
                ]),
        ),
      );
}

class DoctorForm extends StatefulWidget {
  const DoctorForm({super.key, this.d});
  final Doc? d;
  @override
  State<DoctorForm> createState() => _DoctorFormState();
}

class _DoctorFormState extends State<DoctorForm> {
  static const specs = ['باطنية', 'أطفال', 'نساء وتوليد', 'جراحة عامة', 'قلب', 'عظام', 'جلدية', 'أنف وأذن'];
  static const days = ['السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];
  late final n = TextEditingController(text: widget.d?.name), q = TextEditingController(text: widget.d?.quals), lic = TextEditingController(text: widget.d?.lic);
  late final exp = TextEditingController(text: widget.d?.exp), price = TextEditingController(text: widget.d?.price), from = TextEditingController(text: '8:00 ص'), to = TextEditingController(text: '6:00 م');
  late final spec = {specs.indexOf(widget.d?.spec ?? '').clamp(0, specs.length - 1).toInt()};
  final gender = {0}, wd = {0, 1, 2, 3, 4};

  void save() {
    if (n.text.trim().isEmpty || price.text.trim().isEmpty) return snack(context, 'أدخل اسم الأخصائي وسعر الكشف');
    final d = widget.d ?? Doc('', '', '', '', '', '', '', '');
    d.name = n.text.trim().startsWith('د.') ? n.text.trim() : 'د. ${n.text.trim()}';
    d.spec = specs[spec.first];
    d.quals = q.text.trim();
    d.lic = lic.text.trim();
    d.exp = exp.text.trim().isEmpty ? '0' : exp.text.trim();
    d.price = price.text.trim();
    final ws = wd.toList()..sort();
    d.days = ws.isEmpty ? '—' : '${days[ws.first]} - ${days[ws.last]}';
    d.hours = '${from.text} - ${to.text}';
    if (widget.d == null) db.docs.add(d);
    db.ping();
    snack(context, 'تم حفظ بيانات الأخصائي');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => RPage(
        widget.d == null ? 'إضافة أخصائي' : 'تعديل أخصائي',
        bottom: bar(context, [btn('حفظ', save), if (widget.d != null) btn('حذف الأخصائي', () { db.docs.remove(widget.d); db.ping(); Navigator.pop(context); }, outline: true, h: 44)]),
        body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), children: [
          gap(10),
          Center(child: Stack(children: [const CircleAvatar(radius: 44, backgroundColor: Color(0xFFE3E7EE), child: Icon(Icons.person_rounded, size: 58, color: Color(0xFF6B7788))), Positioned(bottom: 0, left: 0, child: Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: kRed, shape: BoxShape.circle), child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 15)))])),
          fld('الاسم الكامل', n, hint: 'مثال: أحمد محمد علي'),
          sec('التخصص'),
          chips(specs, spec, () => setState(() {})),
          fld('المؤهلات العلمية', q, hint: 'مثال: ماجستير باطنية - جامعة الخرطوم', lines: 3),
          fld('رقم التسجيل (المجلس الطبي)', lic, kb: TextInputType.number),
          Row(children: [Expanded(child: fld('سنوات الخبرة', exp, kb: TextInputType.number)), const SizedBox(width: 12), Expanded(child: fld('سعر الكشف (ج.س)', price, kb: TextInputType.number))]),
          sec('الجنس'),
          chips(['ذكر', 'أنثى'], gender, () => setState(() {})),
          sec('أيام العمل'),
          chips(days, wd, () => setState(() {}), multi: true),
          Row(children: [Expanded(child: fld('من', from)), const SizedBox(width: 12), Expanded(child: fld('إلى', to))]),
        ]),
      );
}

// ═══════════════ 7. Beds ═══════════════
class BedsScreen extends StatelessWidget {
  const BedsScreen({super.key});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: db,
        builder: (c, _) => RPage(
          'الأسرّة',
          bottom: bar(c, [btn('+ إضافة سرير', () => go(c, const BedForm()))]),
          body: ListView(padding: const EdgeInsets.all(16), children: [
            Row(children: [
              for (final ty in kBedTypes)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4), padding: const EdgeInsets.symmetric(vertical: 10), decoration: card(14),
                    child: Column(children: [Text(ty, style: t(12, c: kGrey)), Text('${db.beds.where((b) => b.type == ty && b.free).length}/${db.beds.where((b) => b.type == ty).length}', style: t(16, c: kRed))]),
                  ),
                ),
            ]),
            gap(14),
            for (final b in db.beds)
              GestureDetector(
                onTap: () => go(c, BedForm(b: b)),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(12), decoration: card(16),
                  child: Row(children: [
                    tile(Icons.bed_rounded),
                    const SizedBox(width: 12),
                    Expanded(child: two('${b.type} · سرير ${b.no}', 'الطابق ${b.floor} · ${b.price} ج.س / يوم')),
                    pill(b.free ? 'متاح' : 'مشغول', b.free ? const Color(0xFFD9F3E1) : const Color(0xFFFDE8EA), b.free ? kGreen : kRed),
                    Switch(value: b.free, onChanged: (v) { b.free = v; db.ping(); }),
                  ]),
                ),
              ),
          ]),
        ),
      );
}

class BedForm extends StatefulWidget {
  const BedForm({super.key, this.b});
  final Bed? b;
  @override
  State<BedForm> createState() => _BedFormState();
}

class _BedFormState extends State<BedForm> {
  static const equip = ['جهاز تنفس', 'مونيتور', 'أكسجين', 'تكييف', 'حمّام خاص'];
  late final type = {kBedTypes.indexOf(widget.b?.type ?? 'ICU').clamp(0, 3).toInt()};
  late final no = TextEditingController(text: widget.b?.no), floor = TextEditingController(text: widget.b?.floor), price = TextEditingController(text: widget.b?.price);
  late final eq = {for (var i = 0; i < equip.length; i++) if ((widget.b?.equip ?? '').contains(equip[i])) i};
  late final free = {widget.b?.free == false ? 1 : 0};

  void save() {
    if (no.text.trim().isEmpty || price.text.trim().isEmpty) return snack(context, 'أدخل رقم السرير وسعر اليوم');
    final b = widget.b ?? Bed('', '', '', '', '');
    b.type = kBedTypes[type.first];
    b.no = no.text.trim();
    b.floor = floor.text.trim().isEmpty ? '1' : floor.text.trim();
    b.price = price.text.trim();
    b.equip = [for (final i in eq) equip[i]].join(' · ');
    b.free = free.first == 0;
    if (widget.b == null) db.beds.add(b);
    db.ping();
    snack(context, 'تم حفظ السرير');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => RPage(
        widget.b == null ? 'إضافة سرير' : 'تعديل سرير',
        bottom: bar(context, [btn('حفظ', save), if (widget.b != null) btn('حذف السرير', () { db.beds.remove(widget.b); db.ping(); Navigator.pop(context); }, outline: true, h: 44)]),
        body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), children: [
          sec('نوع السرير'),
          chips(kBedTypes, type, () => setState(() {})),
          Row(children: [Expanded(child: fld('رقم السرير', no, kb: TextInputType.number)), const SizedBox(width: 12), Expanded(child: fld('الطابق', floor, kb: TextInputType.number))]),
          fld('السعر لليوم (ج.س)', price, kb: TextInputType.number),
          sec('التجهيزات'),
          chips(equip, eq, () => setState(() {}), multi: true),
          sec('الحالة'),
          chips(['متاح', 'مشغول'], free, () => setState(() {})),
        ]),
      );
}

// ═══════════════ 8. Home services ═══════════════
class HomeSvcScreen extends StatefulWidget {
  const HomeSvcScreen({super.key});
  @override
  State<HomeSvcScreen> createState() => _HomeSvcState();
}

class _HomeSvcState extends State<HomeSvcScreen> {
  final areas = {0, 1};

  void editPrice(Svc s) {
    final c = TextEditingController(text: s.price);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.name, style: t(15)),
        content: TextField(controller: c, keyboardType: TextInputType.number, decoration: const InputDecoration(suffixText: 'ج.س')),
        actions: [TextButton(onPressed: () { s.price = c.text; db.ping(); Navigator.pop(ctx); }, child: Text('حفظ', style: t(14, c: kRed)))],
      ),
    );
  }

  void addStaff() {
    final c = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('إضافة ممرض / فني', style: t(15)),
        content: TextField(controller: c, decoration: const InputDecoration(hintText: 'الاسم · الوظيفة')),
        actions: [TextButton(onPressed: () { if (c.text.trim().isNotEmpty) db.staff.add(c.text.trim()); db.ping(); Navigator.pop(ctx); }, child: Text('إضافة', style: t(14, c: kRed)))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: db,
        builder: (c, _) => RPage(
          'الخدمات المنزلية',
          body: ListView(padding: const EdgeInsets.all(16), children: [
            for (final s in db.svcs)
              Container(
                margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14), decoration: card(16),
                child: Row(children: [
                  tile(Icons.home_rounded),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(s.name, style: t(14.5)), GestureDetector(onTap: () => editPrice(s), child: Text('${s.price} ج.س  ✎', style: t(12.5, c: kRed)))])),
                  Switch(value: s.on, onChanged: (v) { s.on = v; db.ping(); }),
                ]),
              ),
            sec('مناطق التغطية'),
            chips(['الخرطوم', 'بحري', 'أم درمان', 'شرق النيل'], areas, () => setState(() {}), multi: true),
            Row(children: [Expanded(child: sec('الطاقم المنزلي')), GestureDetector(onTap: addStaff, child: Text('+ إضافة', style: t(13, c: kRed)))]),
            for (final s in db.staff) panel([Row(children: [tile(Icons.person_rounded, size: 40), const SizedBox(width: 12), Expanded(child: Text(s, style: t(13.5))), GestureDetector(onTap: () { db.staff.remove(s); db.ping(); }, child: const Icon(Icons.delete_outline_rounded, color: kGrey))])]),
          ]),
        ),
      );
}

// ═══════════════ 9. Reports ═══════════════
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: db,
        builder: (c, _) {
          const week = [.45, .7, .55, .9, .65, .8, .5];
          const names = ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'];
          final total = db.bookings.length == 0 ? 1 : db.bookings.length;
          return RPage(
            'التقارير',
            body: ListView(padding: const EdgeInsets.all(16), children: [
              panel([Text('إجمالي الإيرادات', style: t(12.5, w: FontWeight.w500, c: kGrey)), Text('${money(db.revenue)} ج.س', style: t(26, c: kRed)), Text('من الحجوزات المؤكدة والمكتملة', style: t(11, w: FontWeight.w500, c: kGrey))]),
              panel([
                Text('الأسبوع الحالي', style: t(14)),
                gap(10),
                SizedBox(
                  height: 120,
                  child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    for (var i = 0; i < week.length; i++)
                      Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [Container(margin: const EdgeInsets.symmetric(horizontal: 6), height: 90 * week[i], decoration: BoxDecoration(gradient: kGrad, borderRadius: BorderRadius.circular(6))), gap(4), Text(names[i], style: t(11, c: kGrey))])),
                  ]),
                ),
              ]),
              panel([
                Text('الحجوزات حسب النوع', style: t(14)),
                gap(8),
                for (var i = 0; i < 3; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(children: [
                      SizedBox(width: 90, child: Text(kTypes[i], style: t(12.5, w: FontWeight.w600))),
                      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: db.bookings.where((b) => b.type == i).length / total, minHeight: 8, color: kRed, backgroundColor: kLine))),
                      const SizedBox(width: 8),
                      Text('${db.bookings.where((b) => b.type == i).length}', style: t(12.5)),
                    ]),
                  ),
              ]),
              panel([Text('الأكثر طلباً', style: t(14)), gap(6), for (final d in db.docs.take(3)) kv(d.name, '${d.price} ج.س')]),
            ]),
          );
        },
      );
}

// ═══════════════ 10. Notifications ═══════════════
class NotifsScreen extends StatelessWidget {
  const NotifsScreen({super.key});
  @override
  Widget build(BuildContext context) => RPage(
        'الإشعارات',
        body: ListView(padding: const EdgeInsets.all(16), children: [
          for (final n in const [
            (Icons.mark_email_unread_rounded, 'حجز جديد', 'محمد عبد الرحيم حجز كشفاً مع د. أحمد - السبت 4:30 م', 'منذ 5 دقائق'),
            (Icons.bed_rounded, 'طلب حجز سرير', 'خالد يوسف يطلب سرير ICU لمدة 3 أيام', 'منذ ساعة'),
            (Icons.home_rounded, 'طلب خدمة منزلية', 'فاطمة أحمد تطلب تمريضاً منزلياً', 'منذ ساعتين'),
            (Icons.cancel_rounded, 'إلغاء حجز', 'ألغت آمنة إبراهيم موعد الأحد', 'أمس'),
            (Icons.star_rounded, 'تقييم جديد', 'حصل د. أحمد على تقييم 5 نجوم', 'أمس'),
          ])
            Container(
              margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14), decoration: card(16),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                tile(n.$1), const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(n.$2, style: t(14)), Text(n.$3, style: t(12, w: FontWeight.w500, c: kGrey, h: 1.5)), Text(n.$4, style: t(10.5, w: FontWeight.w500, c: const Color(0xFF9AA5B8)))])),
              ]),
            ),
        ]),
      );
}

// ═══════════════ 11. Account / center info ═══════════════
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});
  Widget row(BuildContext c, IconData i, String s, {Widget? to, Widget? tr}) => InkWell(
        onTap: to == null ? null : () => go(c, to),
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13), child: Row(children: [Icon(i, color: kRed), const SizedBox(width: 14), Expanded(child: Text(s, style: t(14))), tr ?? chev(kInk, 20)])),
      );
  @override
  Widget build(BuildContext context) => RPage(
        'حسابي',
        nav: 3,
        body: ListView(padding: const EdgeInsets.all(16), children: [
          panel([Row(children: [tile(Icons.local_hospital_rounded, size: 60, dark: true), const SizedBox(width: 14), Expanded(child: two('مركز المسباح الطبي', 'الخرطوم - بحري · ترخيص رقم 8841')), pill('موثّق', const Color(0xFFD9F3E1), kGreen)])]),
          Container(
            decoration: card(),
            child: Column(children: [
              row(context, Icons.business_rounded, 'بيانات المركز وساعات العمل', to: const CenterInfoScreen()),
              row(context, Icons.notifications_none_rounded, 'تنبيهات الحجوزات الجديدة', tr: Switch(value: true, onChanged: (v) {})),
              row(context, Icons.group_rounded, 'مستخدمو المركز والصلاحيات'),
              row(context, Icons.headset_mic_outlined, 'المساعدة والدعم'),
            ]),
          ),
          gap(18),
          GestureDetector(
            onTap: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false),
            child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Row(children: [const Icon(Icons.logout_rounded, color: kRed), const SizedBox(width: 12), Text('تسجيل الخروج', style: t(13.5, c: kRed))])),
          ),
        ]),
      );
}

class CenterInfoScreen extends StatefulWidget {
  const CenterInfoScreen({super.key});
  @override
  State<CenterInfoScreen> createState() => _CenterInfoState();
}

class _CenterInfoState extends State<CenterInfoScreen> {
  final n = TextEditingController(text: 'مركز المسباح الطبي'), lic = TextEditingController(text: '8841'), ph = TextEditingController(text: '+249 912 000 111');
  final ad = TextEditingController(text: 'الخرطوم - بحري - المسبح، شارع 15'), from = TextEditingController(text: '8:00 ص'), to = TextEditingController(text: '10:00 م');
  final svc = {0, 1, 2};
  @override
  Widget build(BuildContext context) => RPage(
        'بيانات المركز',
        bottom: bar(context, [btn('حفظ التغييرات', () { snack(context, 'تم حفظ بيانات المركز'); Navigator.pop(context); })]),
        body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), children: [
          fld('اسم المركز', n),
          fld('رقم الترخيص', lic, kb: TextInputType.number),
          fld('هاتف المركز', ph, kb: TextInputType.phone),
          fld('العنوان', ad, lines: 2),
          Row(children: [Expanded(child: fld('بداية الدوام', from)), const SizedBox(width: 12), Expanded(child: fld('نهاية الدوام', to))]),
          sec('الخدمات التي يقدّمها المركز'),
          chips(kTypes, svc, () => setState(() {}), multi: true),
        ]),
      );
}
