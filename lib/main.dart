import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ───────────────────────── Theme / helpers ─────────────────────────
const kRed = Color(0xFFD9141E);
const kInk = Color(0xFF1B2A4A);
const kGrey = Color(0xFF7B8494);
const kLine = Color(0xFFE9EDF2);
const kBg = Color(0xFFF7F8FB);
const kChip = Color(0xFFF1F3F7);
const kGreen = Color(0xFF2EAD5C);
const kGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFFE0161F), Color(0xFFB30B15)],
);
const kShadow = [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 6))];

TextStyle t(double s, {FontWeight w = FontWeight.w700, Color c = kInk, double? h}) =>
    GoogleFonts.cairo(fontSize: s, fontWeight: w, color: c, height: h);

void go(BuildContext c, Widget w) => Navigator.push(c, MaterialPageRoute(builder: (_) => w));

/// "‹" arrow (points left even in RTL).
Icon chev([Color c = kRed, double s = 24]) =>
    Icon(Icons.chevron_left_rounded, color: c, size: s, textDirection: TextDirection.ltr);

/// "›" arrow (points right even in RTL).
Icon chevR([Color c = kRed, double s = 24]) =>
    Icon(Icons.chevron_right_rounded, color: c, size: s, textDirection: TextDirection.ltr);

void main() => runApp(const TabibakApp());

class TabibakApp extends StatelessWidget {
  const TabibakApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'طبيبك',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: kRed,
          scaffoldBackgroundColor: Colors.white,
          textTheme: GoogleFonts.cairoTextTheme(ThemeData.light().textTheme),
        ),
        builder: (c, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
        home: const SplashScreen(),
      );
}

// ───────────────────────── Data ─────────────────────────
class Doctor {
  const Doctor(this.name, this.spec, this.rating, this.reviews, this.price, this.img);
  final String name, spec, price, img;
  final String rating;
  final int reviews;
}

const doctors = [
  Doctor('د. أحمد محمد علي', 'استشاري باطنية', '4.8', 245, '10,000', 'assets/images/doctor1.jpg'),
  Doctor('د. سارة عبد الله', 'أخصائية نساء وتوليد', '4.6', 180, '8,000', 'assets/images/doctor2.jpg'),
  Doctor('د. حسن محمود', 'أخصائي أطفال', '4.5', 120, '7,500', 'assets/images/doctor3.jpg'),
  Doctor('د. علي محمد', 'استشاري جراحة عامة', '4.4', 98, '9,000', 'assets/images/doctor4.jpg'),
];

// ───────────────────────── Painters (icons / logo) ─────────────────────────
class HeartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final heart = Path()
      ..moveTo(w * .5, h * .93)
      ..cubicTo(w * -.1, h * .52, w * .1, h * -.04, w * .5, h * .27)
      ..cubicTo(w * .9, h * -.04, w * 1.1, h * .52, w * .5, h * .93)
      ..close();
    canvas.drawPath(heart, Paint()..shader = kGradient.createShader(Offset.zero & s));
    final ecg = Path()
      ..moveTo(w * .1, h * .5)
      ..lineTo(w * .36, h * .5)
      ..lineTo(w * .43, h * .32)
      ..lineTo(w * .54, h * .68)
      ..lineTo(w * .61, h * .45)
      ..lineTo(w * .66, h * .5)
      ..lineTo(w * .9, h * .5);
    canvas.drawPath(ecg, Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .04
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class EcgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final p = Path()
      ..moveTo(0, h * .5)
      ..lineTo(w * .3, h * .5)
      ..lineTo(w * .4, h * .15)
      ..lineTo(w * .52, h * .9)
      ..lineTo(w * .62, h * .35)
      ..lineTo(w * .68, h * .5)
      ..lineTo(w, h * .5);
    canvas.drawPath(p, Paint()
      ..color = const Color(0xFFD5DAE2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class DoctorPainter extends CustomPainter {
  DoctorPainter({this.cap = false});
  final bool cap;
  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final white = Paint()..color = Colors.white;
    final red = Paint()..color = kRed;
    c.drawCircle(Offset(w * .5, w * .31), w * .16, white);
    c.drawRRect(
        RRect.fromRectAndCorners(Rect.fromLTWH(w * .15, w * .54, w * .7, w * .4),
            topLeft: Radius.circular(w * .26), topRight: Radius.circular(w * .26)),
        white);
    c.drawPath(Path()..moveTo(w * .39, w * .54)..lineTo(w * .5, w * .72)..lineTo(w * .61, w * .54)..close(), red);
    c.drawPath(
        Path()..moveTo(w * .3, w * .58)..quadraticBezierTo(w * .28, w * .82, w * .48, w * .84),
        Paint()
          ..color = kRed
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * .03
          ..strokeCap = StrokeCap.round);
    if (cap) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * .33, w * .07, w * .34, w * .11), Radius.circular(w * .04)), white);
      c.drawRect(Rect.fromCenter(center: Offset(w * .5, w * .125), width: w * .03, height: w * .07), red);
      c.drawRect(Rect.fromCenter(center: Offset(w * .5, w * .125), width: w * .07, height: w * .03), red);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class AmbulancePainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final white = Paint()..color = Colors.white;
    final red = Paint()..color = kRed;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * .05, w * .24, w * .9, w * .48), Radius.circular(w * .09)), white);
    c.drawRect(Rect.fromCenter(center: Offset(w * .33, w * .48), width: w * .08, height: w * .24), red);
    c.drawRect(Rect.fromCenter(center: Offset(w * .33, w * .48), width: w * .24, height: w * .08), red);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * .62, w * .32, w * .22, w * .16), Radius.circular(w * .03)), red);
    for (final x in [.28, .74]) {
      c.drawCircle(Offset(w * x, w * .74), w * .11, red);
      c.drawCircle(Offset(w * x, w * .74), w * .08, white);
      c.drawCircle(Offset(w * x, w * .74), w * .03, red);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

Widget paintIcon(CustomPainter p, double size) => CustomPaint(size: Size(size, size), painter: p);

// ───────────────────────── Shared widgets ─────────────────────────
/// Image from assets with a graceful placeholder (drop real photos in assets/images/).
class Pic extends StatelessWidget {
  const Pic(this.asset, {super.key, this.size = 64, this.height, this.radius = 999, this.icon = Icons.person_rounded, this.quiet = false});
  final String asset;
  final double size, radius;
  final double? height;
  final IconData icon;
  final bool quiet;
  @override
  Widget build(BuildContext context) {
    final h = height ?? size;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(asset, width: size, height: h, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => quiet
              ? SizedBox(width: size, height: h)
              : Container(width: size, height: h, color: const Color(0xFFE6EBF2),
                  child: Icon(icon, size: size * .55, color: const Color(0xFF9AA6B8)))),
    );
  }
}

class SWaveClipper extends CustomClipper<Path> {
  const SWaveClipper();
  @override
  Path getClip(Size s) => Path()
    ..lineTo(0, s.height - 34)
    ..cubicTo(s.width * .3, s.height + 8, s.width * .62, s.height - 78, s.width, s.height - 22)
    ..lineTo(s.width, 0)
    ..close();
  @override
  bool shouldReclip(covariant CustomClipper<Path> o) => false;
}

class SplashWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size s) => Path()
    ..moveTo(0, s.height * .64)
    ..cubicTo(s.width * .35, s.height * .76, s.width * .6, s.height * .15, s.width, 0)
    ..lineTo(s.width, s.height)
    ..lineTo(0, s.height)
    ..close();
  @override
  bool shouldReclip(covariant CustomClipper<Path> o) => false;
}

/// Red header (back arrow on the left, optional action on the right) + white sheet with rounded top.
class RedPage extends StatelessWidget {
  const RedPage({super.key, required this.title, required this.body, this.nav, this.action, this.bottomBar});
  final String title;
  final Widget body;
  final Widget? nav, action, bottomBar;
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: kGradient),
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
                    child: IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 36, textDirection: TextDirection.ltr),
                    ),
                  ),
                ]),
              ),
            ),
            Expanded(
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(color: kBg, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
                child: Column(children: [
                  Expanded(child: body),
                  if (bottomBar != null) bottomBar!,
                  if (nav != null) nav!,
                ]),
              ),
            ),
          ]),
        ),
      );
}

class RedButton extends StatelessWidget {
  const RedButton(this.text, {super.key, required this.onTap, this.edgeIcon, this.height = 52, this.white = false});
  final String text;
  final VoidCallback onTap;
  final Widget? edgeIcon;
  final double height;
  final bool white;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: kGradient,
            borderRadius: BorderRadius.circular(height / 2),
            border: white ? Border.all(color: Colors.white, width: 2) : null,
            boxShadow: const [BoxShadow(color: Color(0x4DD9141E), blurRadius: 14, offset: Offset(0, 7))],
          ),
          child: Stack(alignment: Alignment.center, children: [
            Text(text, style: t(17, w: FontWeight.w800, c: Colors.white)),
            if (edgeIcon != null) Positioned(right: 18, child: edgeIcon!),
          ]),
        ),
      );
}

class AppNav extends StatelessWidget {
  const AppNav({super.key, this.active = const {0}, this.apptLabel = 'مواعيدي'});
  final Set<int> active;
  final String apptLabel;
  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_rounded, Icons.home_outlined, 'الرئيسية'),
      apptLabel == 'حجوزاتي'
          ? (Icons.assignment_rounded, Icons.assignment_outlined, 'حجوزاتي')
          : (Icons.event_available_rounded, Icons.event_available_outlined, 'مواعيدي'),
      (Icons.notifications_rounded, Icons.notifications_none_rounded, 'إشعارات'),
      (Icons.more_horiz_rounded, Icons.more_horiz_rounded, 'المزيد'),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Directionality(
          textDirection: TextDirection.ltr, // reference shows الرئيسية on the left
          child: Row(children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: InkWell(
                  onTap: () {
                    if (i == 0 && !active.contains(0)) {
                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (r) => false);
                    } else if (i == 1 && !active.contains(1)) {
                      go(context, const AppointmentsScreen());
                    } else if (i == 2 && !active.contains(2)) {
                      go(context, const NotificationsScreen());
                    } else if (i == 3 && !active.contains(3)) {
                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const ProfileScreen()), (r) => false);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(active.contains(i) ? items[i].$1 : items[i].$2, size: 24, color: active.contains(i) ? kRed : kGrey),
                      const SizedBox(height: 2),
                      Text(items[i].$3, style: t(10.5, w: active.contains(i) ? FontWeight.w800 : FontWeight.w500, c: active.contains(i) ? kRed : kGrey)),
                    ]),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

class AppSearch extends StatelessWidget {
  const AppSearch(this.hint, {super.key, this.suffix});
  final String hint;
  final Widget? suffix;
  @override
  Widget build(BuildContext context) => Container(
        height: 50,
        decoration: BoxDecoration(color: const Color(0xFFF3F5F9), borderRadius: BorderRadius.circular(24), border: Border.all(color: kLine)),
        child: TextField(
          style: t(14, w: FontWeight.w500),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: hint,
            hintStyle: t(13.5, w: FontWeight.w500, c: kGrey),
            prefixIcon: const Icon(Icons.search_rounded, color: kInk),
            suffixIcon: suffix,
            contentPadding: const EdgeInsets.symmetric(vertical: 13),
          ),
        ),
      );
}

class FilterChips extends StatefulWidget {
  const FilterChips(this.items, {super.key, this.more = false, this.onChanged});
  final List<String> items;
  final bool more;
  final ValueChanged<int>? onChanged;
  @override
  State<FilterChips> createState() => _FilterChipsState();
}

class _FilterChipsState extends State<FilterChips> {
  int sel = 0;
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 42,
        child: Row(children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => GestureDetector(
                onTap: () {
                  setState(() => sel = i);
                  widget.onChanged?.call(i);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: i == sel ? kGradient : null,
                    color: i == sel ? null : kChip,
                    borderRadius: BorderRadius.circular(21),
                    boxShadow: i == sel ? const [BoxShadow(color: Color(0x4DD9141E), blurRadius: 10, offset: Offset(0, 4))] : null,
                  ),
                  child: Text(widget.items[i], style: t(13.5, w: FontWeight.w700, c: i == sel ? Colors.white : const Color(0xFF4B5873))),
                ),
              ),
            ),
          ),
          if (widget.more) Padding(padding: const EdgeInsets.only(left: 10), child: chev(kRed, 20)),
        ]),
      );
}

Widget iconTile(Widget child, {double size = 100, double r = 30}) => Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: kGradient,
        borderRadius: BorderRadius.circular(r),
        boxShadow: const [BoxShadow(color: Color(0x4DD9141E), blurRadius: 14, offset: Offset(0, 7))],
      ),
      child: child,
    );

Widget pill(String text, Color bg, Color fg) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: t(12, w: FontWeight.w700, c: fg)),
    );

BoxDecoration cardBox([double r = 20]) =>
    BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(r), boxShadow: kShadow, border: Border.all(color: const Color(0xFFF0F2F6)));

// ───────────────────────── 1. Splash ─────────────────────────
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Stack(children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white, Color(0xFFF1F3F6)]),
            ),
          ),
        ),
        const Positioned(left: -10, bottom: 120, child: Pic('assets/images/stethoscope.png', size: 240, radius: 0, quiet: true)),
        Positioned(
          bottom: 0, left: 0, right: 0, height: h * .32,
          child: ClipPath(clipper: SplashWaveClipper(), child: Container(decoration: const BoxDecoration(gradient: kGradient))),
        ),
        Positioned.fill(
          child: SafeArea(
            child: Column(children: [
              SizedBox(height: h * .17),
              SizedBox(width: 150, height: 135, child: CustomPaint(painter: HeartPainter())),
              Text('طبيبك', style: t(78, w: FontWeight.w900, c: kRed, h: 1.15)),
              Text('صحتك .. أولويتنا', style: t(19, w: FontWeight.w600, c: const Color(0xFF5B6B86))),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                child: RedButton('ابدأ الآن', white: true, height: 58, edgeIcon: chevR(Colors.white, 22),
                    onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OnboardingScreen()))),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ───────────────────────── 2. Home ─────────────────────────
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    Widget card(Widget icon, String title, String sub, Widget? screen) => GestureDetector(
          onTap: screen == null ? null : () => go(context, screen),
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
            decoration: cardBox(26),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              iconTile(icon),
              const SizedBox(height: 10),
              Text(title, style: t(17.5, w: FontWeight.w800, c: kRed)),
              const SizedBox(height: 2),
              Text(sub, textAlign: TextAlign.center, style: t(11, w: FontWeight.w500, c: kGrey, h: 1.35)),
            ]),
          ),
        );
    return Scaffold(
      backgroundColor: kBg,
      body: Column(children: [
        Container(
          decoration: const BoxDecoration(gradient: kGradient, borderRadius: BorderRadius.vertical(bottom: Radius.circular(40))),
          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 10, 20, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              GestureDetector(onTap: () => go(context, const NotificationsScreen()), child: const Icon(Icons.notifications_rounded, color: Colors.white, size: 28)),
              Expanded(child: Text('طبيبك', textAlign: TextAlign.center, style: t(30, w: FontWeight.w900, c: Colors.white))),
              const CircleAvatar(radius: 18, backgroundColor: Colors.white, child: Icon(Icons.person_rounded, color: Color(0xFF5B7FA6), size: 24)),
            ]),
            const SizedBox(height: 14),
            Text('مرحباً بك', style: t(24, w: FontWeight.w800, c: Colors.white)),
            Text('نحن هنا من أجلك', style: t(15, w: FontWeight.w500, c: Colors.white)),
            const SizedBox(height: 14),
            Container(
              height: 54,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
              child: TextField(
                readOnly: true,
                onTap: () => go(context, const DoctorListScreen()),
                style: t(14, w: FontWeight.w500),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'ابحث عن طبيب، مركز، أو خدمة...',
                  hintStyle: t(13, w: FontWeight.w500, c: kGrey),
                  prefixIcon: const Icon(Icons.search_rounded, color: kInk),
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ]),
        ),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
            mainAxisSpacing: 18,
            crossAxisSpacing: 18,
            childAspectRatio: .8,
            children: [
              // visual order in the reference: bed (right) / doctor (left), ambulance (right) / home (left)
              card(paintIcon(_BedIcon(), 54), 'حجز سرير', 'ICU - HDU - CCU\nوغيرها', const BedScreen()),
              card(paintIcon(DoctorPainter(), 62), 'حجز طبيب', 'احجز موعدك مع أفضل\nالأطباء', const DoctorListScreen()),
              card(paintIcon(AmbulancePainter(), 62), 'إسعاف', 'طلب إسعاف سريع', const AmbulanceScreen()),
              card(const Icon(Icons.home_rounded, color: Colors.white, size: 62), 'خدمة منزلية', 'طبيب - ممرض - معمل', const HomeServicesScreen()),
            ],
          ),
        ),
        const AppNav(),
      ]),
    );
  }
}

class _BedIcon extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final p = Paint()..color = Colors.white;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * .04, w * .12, w * .1, w * .76), Radius.circular(w * .04)), p);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * .04, w * .56, w * .92, w * .14), Radius.circular(w * .03)), p);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * .86, w * .56, w * .1, w * .32), Radius.circular(w * .04)), p);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * .2, w * .32, w * .22, w * .18), Radius.circular(w * .05)), p);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * .48, w * .36, w * .48, w * .15), Radius.circular(w * .05)), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

// ───────────────────────── 3. Doctors list ─────────────────────────
class DoctorCard extends StatelessWidget {
  const DoctorCard(this.d, {super.key});
  final Doctor d;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => go(context, DoctorProfileScreen(d)),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: cardBox(),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: kLine, width: 2)),
              child: Pic(d.img, size: 70),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d.name, style: t(15.5, w: FontWeight.w800)),
                Text(d.spec, style: t(12.5, w: FontWeight.w500, c: kGrey)),
                Row(children: [
                  const Icon(Icons.star_rounded, color: Color(0xFFFFB400), size: 20),
                  const SizedBox(width: 4),
                  Text(d.rating, style: t(12.5, w: FontWeight.w600, c: const Color(0xFF4B5873))),
                  const SizedBox(width: 8),
                  Text('(${d.reviews})', style: t(11.5, w: FontWeight.w500, c: kGrey)),
                ]),
                Row(children: [
                  Text(d.price, style: t(14.5, w: FontWeight.w800)),
                  const SizedBox(width: 4),
                  Text('ج.س', style: t(12, w: FontWeight.w500, c: kGrey)),
                ]),
              ]),
            ),
            SizedBox(
              height: 78,
              child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Icon(Icons.favorite_border_rounded, color: kGrey, size: 20),
                chev(kRed, 20),
              ]),
            ),
          ]),
        ),
      );
}

class DoctorListScreen extends StatelessWidget {
  const DoctorListScreen({super.key});
  @override
  Widget build(BuildContext context) => RedPage(
        title: 'حجز طبيب',
        action: IconButton(onPressed: () => go(context, const FilterScreen()), icon: const Icon(Icons.filter_list_rounded, color: Colors.white, size: 28)),
        nav: const AppNav(),
        body: Column(children: [
          const Padding(padding: EdgeInsets.fromLTRB(16, 18, 16, 14), child: AppSearch('ابحث عن طبيب، أو تخصص...')),
          const FilterChips(['الكل', 'باطنية', 'أطفال', 'نساء وتوليد'], more: true),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: doctors.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (_, i) => DoctorCard(doctors[i]),
            ),
          ),
        ]),
      );
}

// ───────────────────────── 4. Doctor profile ─────────────────────────
class DoctorProfileScreen extends StatelessWidget {
  const DoctorProfileScreen(this.d, {super.key});
  final Doctor d;

  Widget stat(String label, String value) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          decoration: cardBox(16),
          child: Column(children: [
            Text(label, style: t(10.5, w: FontWeight.w600, c: kGrey)),
            const SizedBox(height: 8),
            Text(value, textAlign: TextAlign.center, style: t(12, w: FontWeight.w800)),
          ]),
        ),
      );

  Widget center(String name, String place, String days, String price, String hours) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: cardBox(16),
        child: Column(children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.location_on_rounded, color: kRed, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: t(15, w: FontWeight.w800)),
                Text(place, style: t(12, w: FontWeight.w500, c: kGrey)),
              ]),
            ),
            const Icon(Icons.apartment_rounded, color: kInk, size: 44),
          ]),
          const SizedBox(height: 4),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 14), child: Text(days, style: t(12.5, w: FontWeight.w600, c: const Color(0xFF4B5873))))),
            const Padding(padding: EdgeInsets.only(bottom: 16), child: Icon(Icons.calendar_today_outlined, color: kGrey, size: 13)),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$price ج.س', style: t(13.5, w: FontWeight.w800)),
              Text(hours, style: t(11, w: FontWeight.w500, c: kGrey)),
            ]),
          ]),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(children: [
        Expanded(
          child: ListView(padding: EdgeInsets.zero, children: [
            SizedBox(
              height: 300,
              child: Stack(children: [
                Positioned.fill(child: Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFEDEFF3), Colors.white])))),
                Positioned(left: 10, top: 130, child: SizedBox(width: 120, height: 70, child: CustomPaint(painter: EcgPainter()))),
                Positioned(top: 0, left: 0, right: 0, height: 150 + top * .4, child: ClipPath(clipper: const SWaveClipper(), child: Container(decoration: const BoxDecoration(gradient: kGradient)))),
                Positioned(
                  top: top + 6, left: 6,
                  child: IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 36, textDirection: TextDirection.ltr),
                  ),
                ),
                Positioned(
                  top: top + 12, right: 16,
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.favorite_rounded, color: kRed, size: 22),
                  ),
                ),
                Positioned(left: 0, right: 0, top: top + 24, child: Center(child: Pic(d.img, size: 190, height: 220, radius: 28, icon: Icons.person_rounded))),
              ]),
            ),
            Center(child: Text(d.name, style: t(22, w: FontWeight.w800))),
            const SizedBox(height: 4),
            Center(child: pill(d.spec, kChip, const Color(0xFF4B5873))),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.star_rounded, color: Color(0xFFFFB400), size: 22),
              const SizedBox(width: 6),
              Text(d.rating, style: t(14, w: FontWeight.w800, c: const Color(0xFF4B5873))),
              const SizedBox(width: 10),
              GestureDetector(onTap: () => go(context, ReviewsScreen(d)), child: Text('(${d.reviews} تقييم)', style: t(12.5, w: FontWeight.w700, c: kRed))),
            ]),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 16, 11, 0),
              child: Row(children: [
                stat('رقم التسجيل', '12345'),
                stat('المؤهلات', 'ماجستير + دكتوراه'),
                stat('سنوات الخبرة', '10 سنوات'),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('المراكز التي يعمل بها', style: t(16, w: FontWeight.w800)),
                const SizedBox(height: 10),
                center('مركز المسباح', 'الخرطوم - بحري', 'السبت - الخميس', '10,000', '8:00 - 6:00 م'),
                center('مركز الشرق', 'الخرطوم - أم درمان', 'الأحد - الخميس', '8,000', '9:00 - 5:00 م'),
              ]),
            ),
          ]),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 6, 16, MediaQuery.of(context).padding.bottom + 12),
          child: RedButton('احجز موعد', onTap: () => go(context, ConfirmBookingScreen(d))),
        ),
      ]),
    );
  }
}

// ───────────────────────── 5. Confirm booking ─────────────────────────
class ConfirmBookingScreen extends StatefulWidget {
  const ConfirmBookingScreen(this.d, {super.key});
  final Doctor d;
  @override
  State<ConfirmBookingScreen> createState() => _ConfirmBookingScreenState();
}

class _ConfirmBookingScreenState extends State<ConfirmBookingScreen> {
  int day = 0, time = 1;
  static const days = [('السبت', '18'), ('الأحد', '19'), ('الاثنين', '20'), ('الثلاثاء', '21')];
  static const times = ['5:00 م', '4:30 م', '4:00 م', '6:00 م', '6:00 م', '5:30 م', '2:00 م', '7:30 م', '8:00 م'];

  Widget title(String s) => Padding(padding: const EdgeInsets.only(top: 20, bottom: 12), child: Text(s, style: t(16.5, w: FontWeight.w800)));

  BoxDecoration tile(bool on) => BoxDecoration(
        gradient: on ? kGradient : null,
        color: on ? null : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: on ? null : Border.all(color: kLine),
        boxShadow: on ? const [BoxShadow(color: Color(0x4DD9141E), blurRadius: 12, offset: Offset(0, 6))] : kShadow,
      );

  @override
  Widget build(BuildContext context) {
    final d = widget.d;
    return RedPage(
      title: 'تأكيد الحجز',
      bottomBar: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 14),
        child: RedButton('تأكيد الحجز', onTap: () => go(context, PaymentScreen(d))),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 8), children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: kLine)),
          child: Row(children: [
            Pic(d.img, size: 68),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d.name, style: t(15.5, w: FontWeight.w800)),
                Text(d.spec, style: t(12.5, w: FontWeight.w500, c: kGrey)),
                Text('مركز المسباح - الخرطوم', style: t(12.5, w: FontWeight.w500, c: const Color(0xFF4B5873))),
                Row(children: [
                  Text('10,000', style: t(14, w: FontWeight.w800)),
                  const SizedBox(width: 4),
                  Text('ج.س', style: t(12, w: FontWeight.w500, c: kGrey)),
                ]),
              ]),
            ),
          ]),
        ),
        title('اختر التاريخ'),
        Row(children: [
          for (var i = 0; i < days.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => day = i),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: tile(i == day),
                  child: Column(children: [
                    Text(days[i].$1, style: t(11.5, w: FontWeight.w600, c: i == day ? Colors.white : kGrey)),
                    Text(days[i].$2, style: t(24, w: FontWeight.w800, c: i == day ? Colors.white : kInk, h: 1.3)),
                  ]),
                ),
              ),
            ),
        ]),
        title('اختر الوقت'),
        GridView.count(
          crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 2.2,
          children: [
            for (var i = 0; i < times.length; i++)
              GestureDetector(
                onTap: () => setState(() => time = i),
                child: Container(
                  alignment: Alignment.center,
                  decoration: tile(i == time),
                  child: Text(times[i], style: t(14, w: FontWeight.w700, c: i == time ? Colors.white : kInk)),
                ),
              ),
          ],
        ),
      ]),
    );
  }
}

// ───────────────────────── 6. Success ─────────────────────────
class SuccessScreen extends StatelessWidget {
  const SuccessScreen(this.d, {super.key});
  final Doctor d;

  Widget row(IconData i, String s, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Icon(i, color: kRed, size: 22),
          const SizedBox(width: 12),
          Text(s, style: t(14, w: bold ? FontWeight.w800 : FontWeight.w600, c: const Color(0xFF3B4A68))),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    const bits = [
      (-74.0, -70.0, Color(0xFF2EAD5C), .8), (74.0, -64.0, Color(0xFF2EAD5C), -.7), (92.0, -4.0, Color(0xFFE8559A), -.2),
      (-92.0, -12.0, Color(0xFFF5A623), .1), (-74.0, 50.0, Color(0xFFE8559A), -.6), (76.0, 56.0, Color(0xFF2EAD5C), .8),
    ];
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(children: [
            const SizedBox(height: 44),
            SizedBox(
              width: 230, height: 170,
              child: Stack(alignment: Alignment.center, children: [
                for (final b in bits)
                  Transform.translate(offset: Offset(b.$1, b.$2), child: Transform.rotate(angle: b.$4, child: Container(width: 12, height: 6, decoration: BoxDecoration(color: b.$3, borderRadius: BorderRadius.circular(1.5))))),
                Container(
                  width: 104, height: 104,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3DBB6B), Color(0xFF1F9A4C)]),
                    boxShadow: [BoxShadow(color: Color(0x332EAD5C), blurRadius: 16, offset: Offset(0, 8))],
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 70),
                ),
              ]),
            ),
            Text('تم إرسال طلب الحجز بنجاح', style: t(21, w: FontWeight.w800)),
            const SizedBox(height: 10),
            Text('سيتم مراجعة طلبك من قبل المركز،\nوسيتم إشعارك بمجرد التأكيد.', textAlign: TextAlign.center, style: t(13, w: FontWeight.w500, c: const Color(0xFF6B7794), h: 1.7)),
            const SizedBox(height: 26),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: cardBox(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: kLine, width: 2)),
                    child: Pic(d.img, size: 56),
                  ),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(d.name, style: t(15, w: FontWeight.w800)),
                    Text(d.spec, style: t(12.5, w: FontWeight.w500, c: kGrey)),
                  ]),
                ]),
                const SizedBox(height: 8),
                row(Icons.location_on_outlined, 'مركز المسباح', bold: true),
                row(Icons.calendar_month_outlined, 'السبت 18 أكتوبر 2025'),
                row(Icons.access_time_rounded, 'الساعة 4:30 م'),
                row(Icons.access_time_rounded, '${d.price} ج.س', bold: true),
              ]),
            ),
            const Spacer(),
            RedButton('العودة إلى الرئيسية', height: 50, onTap: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (r) => false)),
          ]),
        ),
      ),
    );
  }
}

// ───────────────────────── 7. Bed booking ─────────────────────────
class BedScreen extends StatelessWidget {
  const BedScreen({super.key});

  Widget hospital(BuildContext c, String name, String place, String type, bool ok, String price, String img) => GestureDetector(
        onTap: () => go(c, HospitalScreen(name, place)),
        child: Container(
        padding: const EdgeInsets.all(14),
        decoration: cardBox(18),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: t(16, w: FontWeight.w800)),
              Text(place, style: t(12, w: FontWeight.w500, c: kGrey)),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.location_on_rounded, color: kRed, size: 22),
                const SizedBox(width: 8),
                pill(type, kChip, kInk),
                const SizedBox(width: 8),
                ok ? pill('متاح', const Color(0xFFD9F3E1), const Color(0xFF2A8F4F)) : pill('غير متاح', kRed, Colors.white),
              ]),
              const SizedBox(height: 8),
              Text('$price ج.س / يوم', style: t(14, w: FontWeight.w800)),
            ]),
          ),
          const SizedBox(width: 10),
          Pic(img, size: 112, height: 118, radius: 12, icon: Icons.apartment_rounded),
        ]),
      ));

  @override
  Widget build(BuildContext context) => RedPage(
        title: 'حجز سرير',
        nav: const AppNav(active: {1}, apptLabel: 'حجوزاتي'),
        body: Column(children: [
          const SizedBox(height: 16),
          const FilterChips(['الكل', 'CCU', 'HDU', 'ICU', 'عادية']),
          Expanded(
            child: ListView(padding: const EdgeInsets.all(16), children: [
              hospital(context, 'مستشفى السلام', 'الخرطوم - أم درمان', 'ICU', true, '15,000', 'assets/images/hospital1.jpg'),
              const SizedBox(height: 14),
              hospital(context, 'مستشفى النيل', 'الخرطوم - بحري', 'HDU', true, '12,000', 'assets/images/hospital2.jpg'),
              const SizedBox(height: 14),
              hospital(context, 'مستشفى المدينة', 'الخرطوم - شرق النيل', 'CCU', false, '18,000', 'assets/images/hospital3.jpg'),
            ]),
          ),
        ]),
      );
}

// ───────────────────────── 8. Home services ─────────────────────────
class HomeServicesScreen extends StatelessWidget {
  const HomeServicesScreen({super.key});

  Widget service(BuildContext c, Widget icon, String title, String sub, {Widget? to}) => GestureDetector(
        onTap: to == null ? null : () => go(c, to),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white, Color(0xFFF1F3F7)]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEDEFF4)),
            boxShadow: kShadow,
          ),
          child: Row(children: [
            chevR(kRed, 26),
            const SizedBox(width: 6),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: t(17, w: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(sub, style: t(12, w: FontWeight.w500, c: kGrey, h: 1.5)),
              ]),
            ),
            const SizedBox(width: 10),
            Container(
              width: 100, height: 100, alignment: Alignment.center,
              decoration: const BoxDecoration(gradient: kGradient, shape: BoxShape.circle),
              child: icon,
            ),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) => RedPage(
        title: 'خدمة منزلية',
        nav: const AppNav(),
        body: ListView(padding: const EdgeInsets.fromLTRB(16, 20, 16, 8), children: [
          service(context, paintIcon(DoctorPainter(), 64), 'زيارة طبيب للمنزل', 'استشارة وفحص في منزلك', to: const HomeRequestScreen(true)),
          service(context, paintIcon(DoctorPainter(cap: true), 64), 'تمريض منزلي', 'ممرض أو ممرضة لرعايتك في\nالمنزل', to: const HomeRequestScreen(false)),
          service(context, const Icon(Icons.science_rounded, color: Colors.white, size: 58), 'خدمة معمل', 'سحب عينات وإجراء التحاليل', to: const LabScreen()),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            decoration: BoxDecoration(color: const Color(0xFFFBE3E3), borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              const Icon(Icons.cottage_rounded, size: 64, color: Color(0xFFE08A5B)),
              const SizedBox(width: 10),
              Expanded(child: Text('رعايتك في منزلك .. بكل راحة', style: t(13.5, w: FontWeight.w800))),
            ]),
          ),
        ]),
      );
}

// ───────────────────────── 9. Home lab ─────────────────────────
class LabScreen extends StatefulWidget {
  const LabScreen({super.key});
  @override
  State<LabScreen> createState() => _LabScreenState();
}

class _LabScreenState extends State<LabScreen> {
  final Set<int> sel = {0, 1};
  static const tests = [('صورة دم كاملة', '150'), ('تحليل السكر', '80'), ('وظائف الكلى', '250'), ('وظائف الكبد', '250')];

  Widget step(int n, String label, bool on) => SizedBox(
        width: 56,
        child: Column(children: [
          Container(
            width: 36, height: 36, alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? kRed : const Color(0xFFEDF0F5), shape: BoxShape.circle,
              boxShadow: on ? const [BoxShadow(color: Color(0x4DD9141E), blurRadius: 8, offset: Offset(0, 4))] : null,
            ),
            child: Text('$n', style: t(14, w: FontWeight.w800, c: on ? Colors.white : kInk)),
          ),
          const SizedBox(height: 6),
          Text(label, style: t(12, w: on ? FontWeight.w800 : FontWeight.w600, c: on ? kInk : const Color(0xFF4B5873))),
        ]),
      );

  Widget line() => Expanded(child: Padding(padding: const EdgeInsets.only(top: 18), child: Container(height: 2, color: const Color(0xFFE3E7EE))));

  @override
  Widget build(BuildContext context) => RedPage(
        title: 'خدمة المعمل المنزلي',
        bottomBar: Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 14),
          child: RedButton('التالي', onTap: () => go(context, LabScheduleScreen(sel.map((i) => tests[i]).toList()))),
        ),
        body: ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 8), children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              step(1, 'التحاليل', true), line(), step(2, 'الموعد', false), line(), step(3, 'التأكيد', false),
            ]),
          ),
          const SizedBox(height: 22),
          Row(children: [
            Text('اختر التحاليل المطلوبة', style: t(15.5, w: FontWeight.w800)),
            const SizedBox(width: 6),
            chev(kGrey, 20),
          ]),
          const SizedBox(height: 12),
          const AppSearch('ابحث عن تحليل...', suffix: Icon(Icons.close_rounded, color: kInk, size: 20)),
          const SizedBox(height: 14),
          Container(
            decoration: cardBox(16),
            child: Column(children: [
              for (var i = 0; i < tests.length; i++)
                GestureDetector(
                  onTap: () => setState(() => sel.contains(i) ? sel.remove(i) : sel.add(i)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(border: i == tests.length - 1 ? null : const Border(bottom: BorderSide(color: Color(0xFFF1F3F6)))),
                    child: Row(children: [
                      Container(
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                          color: sel.contains(i) ? kRed : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: sel.contains(i) ? null : Border.all(color: const Color(0xFFD5DAE2), width: 1.5),
                        ),
                        child: sel.contains(i) ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(tests[i].$1, style: t(13.5, w: FontWeight.w800)),
                          Text('${tests[i].$2} ج.س', style: t(12.5, w: FontWeight.w500, c: kGrey)),
                        ]),
                      ),
                      chev(kInk, 20),
                    ]),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 16),
          Center(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.add_rounded, color: kRed, size: 16),
              const SizedBox(width: 4),
              Text('المزيد من التحاليل', style: t(11.5, w: FontWeight.w700)),
            ]),
          ),
        ]),
      );
}

// ───────────────────────── 10. Profile / More ─────────────────────────
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Widget item(IconData i, String s, {int badge = 0, Widget? to}) => Builder(
        builder: (c) => InkWell(
          onTap: to == null ? null : () => go(c, to),
          child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F3F6)))),
        child: Row(children: [
          Icon(i, color: kRed, size: 26),
          const SizedBox(width: 14),
          Expanded(child: Text(s, style: t(14, w: FontWeight.w700, c: const Color(0xFF3B4A68)))),
          if (badge > 0)
            Container(
              width: 20, height: 20, alignment: Alignment.center, margin: const EdgeInsets.only(left: 4),
              decoration: const BoxDecoration(color: kRed, shape: BoxShape.circle),
              child: Text('$badge', style: t(11, w: FontWeight.w800, c: Colors.white)),
            ),
          chev(kInk, 20),
        ]),
      )));

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        body: Column(children: [
          SizedBox(
            height: 150 + MediaQuery.of(context).padding.top,
            child: ClipPath(clipper: const SWaveClipper(), child: Container(decoration: const BoxDecoration(gradient: kGradient))),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Row(children: [
              chevR(kGrey, 26),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('أحمد محمد علي', style: t(16.5, w: FontWeight.w800)),
                  Text('مريض', style: t(13, w: FontWeight.w500, c: kGrey)),
                ]),
              ),
              Container(
                width: 84, height: 84,
                decoration: const BoxDecoration(color: Color(0xFFE3E7EE), shape: BoxShape.circle, boxShadow: kShadow),
                child: const Icon(Icons.person_rounded, color: Color(0xFF6B7788), size: 56),
              ),
            ]),
          ),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 8), children: [
              Container(
                decoration: cardBox(18),
                clipBehavior: Clip.antiAlias,
                child: Column(children: [
                  item(Icons.event_available_outlined, 'مواعيدي', to: const AppointmentsScreen()),
                  item(Icons.home_rounded, 'طلبات الخدمة المنزلية', to: const HomeOrdersScreen()),
                  item(Icons.notifications_none_rounded, 'إشعارات', badge: 3, to: const NotificationsScreen()),
                  item(Icons.folder_shared_outlined, 'السجل الطبي', to: const RecordsScreen()),
                  item(Icons.favorite_border_rounded, 'المفضلة', to: const FavoritesScreen()),
                  item(Icons.family_restroom_rounded, 'أفراد العائلة', to: const FamilyScreen()),
                  item(Icons.person_outline_rounded, 'المعلومات الشخصية', to: const PersonalInfoScreen()),
                  item(Icons.settings_outlined, 'الإعدادات', to: const SettingsScreen()),
                  item(Icons.headset_mic_outlined, 'مساعدة ودعم', to: const HelpScreen()),
                ]),
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(children: [
                    const Icon(Icons.logout_rounded, color: kRed, size: 24),
                    const SizedBox(width: 12),
                    Text('تسجيل الخروج', style: t(13.5, w: FontWeight.w800, c: kRed)),
                  ]),
                ),
              ),
            ]),
          ),
          const AppNav(active: {0, 3}),
        ]),
      );
}

// ═════════════════════════════════════════════════════════════════════════
// ░░░ الصفحات المضافة (Added pages) ░░░
// ═════════════════════════════════════════════════════════════════════════

// ───────────────────────── Added helpers ─────────────────────────
const kSlot = 'السبت 18 أكتوبر · 4:30 م';
String money(int n) => n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
int toInt(String s) => int.parse(s.replaceAll(',', ''));
Widget gap([double h = 12]) => SizedBox(height: h);
Widget sec(String s) => Padding(padding: const EdgeInsets.only(top: 18, bottom: 10), child: Text(s, style: t(15.5, w: FontWeight.w800)));
void home(BuildContext c) => Navigator.pushAndRemoveUntil(c, MaterialPageRoute(builder: (_) => const HomeScreen()), (r) => false);
Widget pillOk(String s) => pill(s, const Color(0xFFD9F3E1), const Color(0xFF2A8F4F));
Widget pillWarn(String s) => pill(s, const Color(0xFFFFF1D6), const Color(0xFFB7791F));

Widget tileIcon(IconData i, {double size = 44}) => Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: const Color(0xFFFDE8EA), borderRadius: BorderRadius.circular(size / 3.2)),
      child: Icon(i, color: kRed, size: size * .52),
    );

Widget panel(List<Widget> ch) => Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: cardBox(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: ch),
    );

Widget group(List<Widget> ch) => Container(margin: const EdgeInsets.only(bottom: 4), decoration: cardBox(18), child: Column(children: ch));

Widget kv(String k, String v, {bool bold = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Expanded(child: Text(k, style: t(13, w: FontWeight.w500, c: kGrey))),
        Text(v, style: t(13.5, w: bold ? FontWeight.w800 : FontWeight.w700, c: bold ? kRed : kInk)),
      ]),
    );

Widget two(String a, String b) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(a, style: t(15, w: FontWeight.w800)),
      Text(b, style: t(12, w: FontWeight.w500, c: kGrey)),
    ]);

Widget docRow(Doctor d) => Row(children: [
      Pic(d.img, size: 56),
      const SizedBox(width: 12),
      Expanded(child: two(d.name, '${d.spec} · مركز المسباح')),
    ]);

Widget menuRow(IconData i, String s, {Widget? trailing, Widget? to, Color c = kInk}) => Builder(
      builder: (ctx) => InkWell(
        onTap: to == null ? null : () => go(ctx, to),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(children: [
            Icon(i, color: kRed, size: 24),
            const SizedBox(width: 14),
            Expanded(child: Text(s, style: t(14, c: c))),
            trailing ?? chev(kInk, 20),
          ]),
        ),
      ),
    );

Widget cnt(String n) => Row(mainAxisSize: MainAxisSize.min, children: [pill(n, kChip, kInk), const SizedBox(width: 6), chev(kInk, 20)]);

Widget btnBar(BuildContext c, String text, VoidCallback onTap, {String? alt, VoidCallback? onAlt}) => Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(c).padding.bottom + 14),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        RedButton(text, onTap: onTap),
        if (alt != null) ...[const SizedBox(height: 10), OutBtn(alt, onTap: onAlt ?? () {})],
      ]),
    );

Widget addressCard() => panel([
      Row(children: [
        tileIcon(Icons.location_on_rounded),
        const SizedBox(width: 12),
        Expanded(child: two('الخرطوم - بحري - المسبح', 'شارع 15، بجوار الصيدلية')),
        Text('تغيير', style: t(12.5, c: kRed)),
      ]),
    ]);

Widget timeline(List<(String, String, int)> steps) => Column(children: [
      for (var i = 0; i < steps.length; i++)
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Column(children: [
              Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: steps[i].$3 == 1 ? kRed : (steps[i].$3 == 2 ? Colors.white : const Color(0xFFE3E7EE)),
                  border: steps[i].$3 == 2 ? Border.all(color: kRed, width: 3) : null,
                ),
                child: steps[i].$3 == 1 ? const Icon(Icons.check_rounded, color: Colors.white, size: 15) : null,
              ),
              if (i < steps.length - 1) Expanded(child: Container(width: 2, color: steps[i].$3 == 1 ? kRed : const Color(0xFFE3E7EE))),
            ]),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(steps[i].$1, style: t(13.5, c: steps[i].$3 == 0 ? kGrey : kInk)),
                Text(steps[i].$2, style: t(11.5, w: FontWeight.w500, c: kGrey)),
              ]),
            ),
          ]),
        ),
    ]);

Widget labSteps(int a) {
  Widget s(int n, String l) => SizedBox(
        width: 56,
        child: Column(children: [
          Container(
            width: 36, height: 36, alignment: Alignment.center,
            decoration: BoxDecoration(color: n <= a ? kRed : const Color(0xFFEDF0F5), shape: BoxShape.circle),
            child: n < a ? const Icon(Icons.check_rounded, color: Colors.white, size: 20) : Text('$n', style: t(14, w: FontWeight.w800, c: n <= a ? Colors.white : kInk)),
          ),
          const SizedBox(height: 6),
          Text(l, style: t(12, w: n == a ? FontWeight.w800 : FontWeight.w600)),
        ]),
      );
  Widget ln(bool on) => Expanded(child: Padding(padding: const EdgeInsets.only(top: 18), child: Container(height: 2, color: on ? kRed : const Color(0xFFE3E7EE))));
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [s(1, 'التحاليل'), ln(a > 1), s(2, 'الموعد'), ln(a > 2), s(3, 'التأكيد')]),
  );
}

// ───────────────────────── Added shared widgets ─────────────────────────
class OutBtn extends StatelessWidget {
  const OutBtn(this.text, {super.key, required this.onTap, this.height = 46});
  final String text;
  final VoidCallback onTap;
  final double height;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: height, width: double.infinity, alignment: Alignment.center,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(height / 2), border: Border.all(color: kRed, width: 1.6)),
          child: Text(text, style: t(15, w: FontWeight.w800, c: kRed)),
        ),
      );
}

class AppField extends StatelessWidget {
  const AppField(this.label, {super.key, this.value, this.hint, this.icon, this.type, this.lines = 1, this.ltr = false});
  final String label;
  final String? value, hint;
  final IconData? icon;
  final TextInputType? type;
  final int lines;
  final bool ltr;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(top: 14, bottom: 6), child: Text(label, style: t(12.5))),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
          child: TextFormField(
            initialValue: value,
            keyboardType: type,
            maxLines: lines,
            textDirection: ltr ? TextDirection.ltr : null,
            textAlign: ltr ? TextAlign.left : TextAlign.start,
            style: t(14, w: FontWeight.w600),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
              hintStyle: t(13, w: FontWeight.w500, c: kGrey),
              prefixIcon: icon == null ? null : Icon(icon, color: kGrey, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            ),
          ),
        ),
      ]);
}

class ChipWrap extends StatefulWidget {
  const ChipWrap(this.items, {super.key, this.sel = const {0}, this.multi = false});
  final List<String> items;
  final Set<int> sel;
  final bool multi;
  @override
  State<ChipWrap> createState() => _ChipWrapState();
}

class _ChipWrapState extends State<ChipWrap> {
  late Set<int> s = {...widget.sel};
  @override
  Widget build(BuildContext context) => Wrap(spacing: 8, runSpacing: 8, children: [
        for (var i = 0; i < widget.items.length; i++)
          GestureDetector(
            onTap: () => setState(() {
              if (widget.multi) {
                s.contains(i) ? s.remove(i) : s.add(i);
              } else {
                s = {i};
              }
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(gradient: s.contains(i) ? kGradient : null, color: s.contains(i) ? null : kChip, borderRadius: BorderRadius.circular(20)),
              child: Text(widget.items[i], style: t(13, c: s.contains(i) ? Colors.white : const Color(0xFF4B5873))),
            ),
          ),
      ]);
}

class RadioPick extends StatefulWidget {
  const RadioPick(this.items, {super.key, this.sel = 0});
  final List<(String, String)> items;
  final int sel;
  @override
  State<RadioPick> createState() => _RadioPickState();
}

class _RadioPickState extends State<RadioPick> {
  late int s = widget.sel;
  @override
  Widget build(BuildContext context) => Column(children: [
        for (var i = 0; i < widget.items.length; i++)
          GestureDetector(
            onTap: () => setState(() => s = i),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: s == i ? const Color(0xFFFFF5F6) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: s == i ? kRed : kLine, width: 1.5),
              ),
              child: Row(children: [
                Icon(s == i ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: s == i ? kRed : kGrey),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.items[i].$1, style: t(14)),
                    if (widget.items[i].$2.isNotEmpty) Text(widget.items[i].$2, style: t(11.5, w: FontWeight.w500, c: kGrey)),
                  ]),
                ),
              ]),
            ),
          ),
      ]);
}

class SchedulePicker extends StatefulWidget {
  const SchedulePicker({super.key, this.onChanged});
  final ValueChanged<String>? onChanged;
  @override
  State<SchedulePicker> createState() => _SchedulePickerState();
}

class _SchedulePickerState extends State<SchedulePicker> {
  int day = 0, time = 1;
  static const days = [('السبت', '18'), ('الأحد', '19'), ('الاثنين', '20'), ('الثلاثاء', '21')];
  static const times = ['5:00 م', '4:30 م', '4:00 م', '6:00 م', '5:30 م', '7:30 م'];
  void pick(int d, int tm) {
    setState(() {
      day = d;
      time = tm;
    });
    widget.onChanged?.call('${days[d].$1} ${days[d].$2} أكتوبر · ${times[tm]}');
  }

  BoxDecoration box(bool on) => BoxDecoration(
        gradient: on ? kGradient : null,
        color: on ? null : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: on ? null : Border.all(color: kLine),
      );

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        sec('اختر اليوم'),
        Row(children: [
          for (var i = 0; i < days.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => pick(i, time),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: box(i == day),
                  child: Column(children: [
                    Text(days[i].$1, style: t(11.5, w: FontWeight.w600, c: i == day ? Colors.white : kGrey)),
                    Text(days[i].$2, style: t(22, w: FontWeight.w800, c: i == day ? Colors.white : kInk, h: 1.3)),
                  ]),
                ),
              ),
            ),
        ]),
        sec('اختر الوقت'),
        GridView.count(
          crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 2.4,
          children: [
            for (var i = 0; i < times.length; i++)
              GestureDetector(
                onTap: () => pick(day, i),
                child: Container(alignment: Alignment.center, decoration: box(i == time), child: Text(times[i], style: t(13.5, c: i == time ? Colors.white : kInk))),
              ),
          ],
        ),
      ]);
}

class EmptyState extends StatelessWidget {
  const EmptyState(this.icon, this.title, this.sub, {super.key, this.btn, this.onTap});
  final IconData icon;
  final String title, sub;
  final String? btn;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            tileIcon(icon, size: 96),
            gap(16),
            Text(title, style: t(17)),
            gap(6),
            Text(sub, textAlign: TextAlign.center, style: t(13, w: FontWeight.w500, c: kGrey, h: 1.6)),
            if (btn != null) ...[gap(20), SizedBox(width: 220, child: RedButton(btn!, height: 46, onTap: onTap ?? () {}))],
          ]),
        ),
      );
}

/// Generic green "done" page used after booking / payment / cancel / request.
class DoneScreen extends StatelessWidget {
  const DoneScreen(this.title, this.sub, this.rows, {super.key, this.btn = 'العودة إلى الرئيسية', this.to});
  final String title, sub, btn;
  final List<(String, String)> rows;
  final Widget? to;
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: kBg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(children: [
              const SizedBox(height: 56),
              Container(
                width: 104, height: 104,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3DBB6B), Color(0xFF1F9A4C)]),
                  boxShadow: [BoxShadow(color: Color(0x332EAD5C), blurRadius: 16, offset: Offset(0, 8))],
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 70),
              ),
              const SizedBox(height: 22),
              Text(title, textAlign: TextAlign.center, style: t(21, w: FontWeight.w800)),
              const SizedBox(height: 10),
              Text(sub, textAlign: TextAlign.center, style: t(13, w: FontWeight.w500, c: const Color(0xFF6B7794), h: 1.7)),
              const SizedBox(height: 26),
              panel([for (final r in rows) kv(r.$1, r.$2)]),
              const Spacer(),
              RedButton(btn, height: 50, onTap: () {
                if (to == null) {
                  home(context);
                } else {
                  go(context, to!);
                }
              }),
            ]),
          ),
        ),
      );
}

class MapPainter extends CustomPainter {
  const MapPainter(this.route);
  final bool route;
  @override
  void paint(Canvas c, Size s) {
    c.drawRect(Offset.zero & s, Paint()..color = const Color(0xFFE9EEE6));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(s.width * .3, s.height * .35, s.width * .35, s.height * .3), const Radius.circular(10)), Paint()..color = const Color(0xFFD5E4CF));
    final w = Paint()..color = Colors.white..strokeCap = StrokeCap.round;
    c.drawLine(Offset(0, s.height * .3), Offset(s.width, s.height * .3), w..strokeWidth = 12);
    c.drawLine(Offset(0, s.height * .72), Offset(s.width, s.height * .72), w..strokeWidth = 9);
    c.drawLine(Offset(s.width * .22, 0), Offset(s.width * .22, s.height), w..strokeWidth = 12);
    c.drawLine(Offset(s.width * .72, 0), Offset(s.width * .72, s.height), w..strokeWidth = 9);
    if (route) c.drawLine(Offset(s.width * .22, s.height * .72), Offset(s.width * .5, s.height * .5), Paint()..color = kRed..strokeWidth = 4..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

/// Map placeholder on top + white sheet below (ambulance request / tracking).
class MapPage extends StatelessWidget {
  const MapPage(this.title, this.sheet, {super.key, this.route = false});
  final String title;
  final Widget sheet;
  final bool route;
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: kBg,
        body: Column(children: [
          SizedBox(
            height: 300,
            child: Stack(children: [
              Positioned.fill(child: CustomPaint(painter: MapPainter(route))),
              const Center(child: Icon(Icons.location_on_rounded, color: kRed, size: 54)),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), decoration: BoxDecoration(color: kRed, borderRadius: BorderRadius.circular(20)), child: Text(title, style: t(16, w: FontWeight.w800, c: Colors.white))),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.maybePop(context),
                      child: Container(width: 38, height: 38, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: chev(kRed, 26)),
                    ),
                  ]),
                ),
              ),
            ]),
          ),
          Expanded(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), child: sheet)),
        ]),
      );
}

// ───────────────────────── 11. Onboarding ─────────────────────────
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingState();
}

class _OnboardingState extends State<OnboardingScreen> {
  final pc = PageController();
  int i = 0;
  static const pages = [
    (Icons.event_available_rounded, 'احجز طبيبك بسهولة', 'اختر الطبيب والموعد المناسب لك، وأكّد حجزك في دقائق.'),
    (Icons.home_rounded, 'خدمات طبية في منزلك', 'زيارة طبيب أو ممرض وسحب عينات المعمل دون عناء الانتقال.'),
    (Icons.local_hospital_rounded, 'إسعاف سريع وتتبّع مباشر', 'اطلب الإسعاف وتابع وصوله على الخريطة لحظة بلحظة.'),
  ];
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(children: [
          Expanded(
            child: PageView.builder(
              controller: pc,
              itemCount: pages.length,
              onPageChanged: (v) => setState(() => i = v),
              itemBuilder: (_, k) => Column(children: [
                Container(
                  height: 340, width: double.infinity, alignment: Alignment.center,
                  decoration: const BoxDecoration(gradient: kGradient, borderRadius: BorderRadius.vertical(bottom: Radius.circular(90))),
                  child: Container(width: 140, height: 140, decoration: const BoxDecoration(color: Color(0x29FFFFFF), shape: BoxShape.circle), child: Icon(pages[k].$1, color: Colors.white, size: 70)),
                ),
                const SizedBox(height: 30),
                Text(pages[k].$2, style: t(22, w: FontWeight.w800)),
                Padding(padding: const EdgeInsets.fromLTRB(32, 10, 32, 0), child: Text(pages[k].$3, textAlign: TextAlign.center, style: t(14, w: FontWeight.w500, c: kGrey, h: 1.7))),
              ]),
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var k = 0; k < pages.length; k++)
              AnimatedContainer(duration: const Duration(milliseconds: 200), margin: const EdgeInsets.all(3), width: k == i ? 24 : 8, height: 8, decoration: BoxDecoration(color: k == i ? kRed : kLine, borderRadius: BorderRadius.circular(4))),
          ]),
          Padding(
            padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).padding.bottom + 20),
            child: RedButton(i == pages.length - 1 ? 'ابدأ الآن' : 'التالي', onTap: () {
              if (i == pages.length - 1) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              } else {
                pc.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
              }
            }),
          ),
        ]),
      );
}

// ───────────────────────── 12. Login / OTP / Register ─────────────────────────
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(children: [
          Container(
            height: 250, width: double.infinity,
            decoration: const BoxDecoration(gradient: kGradient, borderRadius: BorderRadius.vertical(bottom: Radius.circular(80))),
            child: SafeArea(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.favorite_rounded, color: Colors.white, size: 64),
                Text('طبيبك', style: t(34, w: FontWeight.w900, c: Colors.white)),
                Text('صحتك .. أولويتنا', style: t(13, w: FontWeight.w500, c: Colors.white)),
              ]),
            ),
          ),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(24, 24, 24, 16), children: [
              Center(child: Text('تسجيل الدخول', style: t(22, w: FontWeight.w800))),
              Center(child: Text('أدخل رقم هاتفك وسنرسل لك رمز التحقق', style: t(13, w: FontWeight.w500, c: kGrey))),
              const AppField('رقم الهاتف', hint: '+249 9XX XXX XXX', icon: Icons.phone_outlined, type: TextInputType.phone, ltr: true),
              gap(20),
              RedButton('إرسال الرمز', onTap: () => go(context, const OtpScreen())),
              gap(14),
              OutBtn('المتابعة كزائر', onTap: () => home(context)),
              gap(18),
              GestureDetector(
                onTap: () => go(context, const RegisterScreen()),
                child: Center(child: Text.rich(TextSpan(text: 'ليس لديك حساب؟ ', style: t(13, w: FontWeight.w500, c: kGrey), children: [TextSpan(text: 'إنشاء حساب', style: t(13, w: FontWeight.w800, c: kRed))]))),
              ),
            ]),
          ),
        ]),
      );
}

class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});
  @override
  Widget build(BuildContext context) => RedPage(
        title: 'رمز التحقق',
        bottomBar: btnBar(context, 'تأكيد', () => home(context)),
        body: ListView(padding: const EdgeInsets.all(24), children: [
          gap(10),
          Center(child: tileIcon(Icons.verified_user_rounded, size: 72)),
          gap(14),
          Center(child: Text('أدخل رمز التحقق', style: t(19, w: FontWeight.w800))),
          Center(child: Text('أرسلنا رمزاً من 4 أرقام إلى\n\u2066+249 912 345 678\u2069', textAlign: TextAlign.center, style: t(13, w: FontWeight.w500, c: kGrey, h: 1.7))),
          gap(24),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < 4; i++)
                Container(
                  width: 58, height: 64, margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: i == 3 ? kRed : kLine, width: 1.5)),
                  child: TextField(
                    textAlign: TextAlign.center, keyboardType: TextInputType.number, maxLength: 1, style: t(24),
                    decoration: const InputDecoration(border: InputBorder.none, counterText: ''),
                    onChanged: (v) {
                      if (v.isNotEmpty) FocusScope.of(context).nextFocus();
                    },
                  ),
                ),
            ]),
          ),
          gap(18),
          Center(child: Text.rich(TextSpan(text: 'إعادة إرسال الرمز بعد ', style: t(12.5, w: FontWeight.w500, c: kGrey), children: [TextSpan(text: '00:45', style: t(12.5, c: kRed))]))),
        ]),
      );
}

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});
  @override
  Widget build(BuildContext context) => RedPage(
        title: 'إنشاء حساب',
        bottomBar: btnBar(context, 'إنشاء الحساب', () => go(context, const OtpScreen())),
        body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 8), children: const [
          AppField('الاسم الكامل', hint: 'أدخل اسمك الكامل'),
          AppField('رقم الهاتف', hint: '9XX XXX XXX', type: TextInputType.phone, ltr: true),
          AppField('تاريخ الميلاد', hint: 'يوم / شهر / سنة', icon: Icons.calendar_today_outlined),
          SizedBox(height: 4),
          ChipWrap(['ذكر', 'أنثى']),
          SizedBox(height: 18),
          ChipWrap(['أوافق على الشروط والأحكام وسياسة الخصوصية'], multi: true),
        ]),
      );
}

// ───────────────────────── 13. My appointments / cancel / reschedule ─────────────────────────
class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});
  @override
  State<AppointmentsScreen> createState() => _AppointmentsState();
}

class _AppointmentsState extends State<AppointmentsScreen> {
  int tab = 0;
  Widget appt(String n, String s, Widget st, String d, String tm, {bool acts = true}) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: cardBox(),
        child: Column(children: [
          Row(children: [tileIcon(Icons.person_rounded, size: 46), const SizedBox(width: 12), Expanded(child: two(n, s)), st]),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.calendar_month_outlined, size: 16, color: kGrey),
            const SizedBox(width: 6),
            Text(d, style: t(12.5, w: FontWeight.w600, c: const Color(0xFF4B5873))),
            const SizedBox(width: 14),
            const Icon(Icons.access_time_rounded, size: 16, color: kGrey),
            const SizedBox(width: 6),
            Text(tm, style: t(12.5, w: FontWeight.w600, c: const Color(0xFF4B5873))),
          ]),
          if (acts) ...[
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: OutBtn('إعادة جدولة', height: 38, onTap: () => go(context, const RescheduleScreen()))),
              const SizedBox(width: 10),
              Expanded(child: OutBtn('إلغاء الحجز', height: 38, onTap: () => go(context, const CancelScreen()))),
            ]),
          ],
        ]),
      );

  @override
  Widget build(BuildContext context) => RedPage(
        title: 'مواعيدي',
        nav: const AppNav(active: {1}),
        body: Column(children: [
          const SizedBox(height: 16),
          FilterChips(const ['القادمة', 'السابقة', 'الملغاة'], onChanged: (v) => setState(() => tab = v)),
          Expanded(
            child: tab == 2
                ? EmptyState(Icons.event_busy_rounded, 'لا توجد حجوزات ملغاة', 'الحجوزات التي تلغيها ستظهر هنا.')
                : ListView(padding: const EdgeInsets.all(16), children: tab == 0
                    ? [
                        appt('د. أحمد محمد علي', 'استشاري باطنية · المسباح', pillOk('مؤكد'), 'السبت 18 أكتوبر', '4:30 م'),
                        appt('د. سارة عبد الله', 'نساء وتوليد · مركز الشرق', pillWarn('قيد التأكيد'), 'الأحد 19 أكتوبر', '6:00 م'),
                        appt('تحاليل منزلية', 'صورة دم + تحليل السكر', pillOk('مؤكد'), 'الثلاثاء 21 أكتوبر', '9:00 ص'),
                      ]
                    : [
                        appt('د. حسن محمود', 'أخصائي أطفال', pillOk('مكتمل'), '12 أكتوبر', '5:00 م', acts: false),
                        appt('د. علي محمد', 'استشاري جراحة عامة', pillOk('مكتمل'), '3 أكتوبر', '6:30 م', acts: false),
                      ]),
          ),
        ]),
      );
}

class CancelScreen extends StatelessWidget {
  const CancelScreen({super.key});
  @override
  Widget build(BuildContext context) => RedPage(
        title: 'إلغاء الحجز',
        bottomBar: btnBar(context, 'تأكيد الإلغاء', () => go(context, const DoneScreen('تم إلغاء الحجز', 'يمكنك حجز موعد جديد في أي وقت.', [('الحالة', 'ملغي'), ('الرسوم', 'بدون رسوم')])), alt: 'تراجع', onAlt: () => Navigator.maybePop(context)),
        body: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), children: [
          panel([docRow(doctors[0]), const SizedBox(height: 6), kv('الموعد', kSlot)]),
          sec('سبب الإلغاء'),
          const RadioPick([('ظرف طارئ', ''), ('وجدت موعداً أقرب', ''), ('تغيّرت خطتي', ''), ('سبب آخر', '')]),
          Text('الإلغاء قبل 24 ساعة من الموعد بدون أي رسوم.', style: t(11.5, w: FontWeight.w500, c: kGrey)),
        ]),
      );
}

class RescheduleScreen extends StatelessWidget {
  const RescheduleScreen({super.key});
  @override
  Widget build(BuildContext context) => RedPage(
        title: 'إعادة جدولة',
        bottomBar: btnBar(context, 'تأكيد الموعد الجديد', () => go(context, const DoneScreen('تم تغيير الموعد', 'أرسلنا لك إشعاراً بالموعد الجديد.', [('الطبيب', 'د. أحمد محمد علي'), ('الموعد الجديد', 'الأحد 19 أكتوبر · 4:30 م')]))),
        body: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), children: [
          panel([docRow(doctors[0]), const SizedBox(height: 6), kv('الموعد الحالي', kSlot)]),
          const SchedulePicker(),
        ]),
      );
}

// ───────────────────────── 14. Notifications ─────────────────────────
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  Widget item(BuildContext c, IconData i, String ti, String b, String tm, {bool un = false, Widget? to}) => GestureDetector(
        onTap: to == null ? null : () => go(c, to),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: cardBox(16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            tileIcon(i),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(ti, style: t(14)),
                Text(b, style: t(12, w: FontWeight.w500, c: kGrey, h: 1.5)),
                Text(tm, style: t(10.5, w: FontWeight.w500, c: const Color(0xFF9AA5B8))),
              ]),
            ),
            if (un) const Icon(Icons.circle, color: kRed, size: 10),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) => RedPage(
        title: 'إشعارات',
        nav: const AppNav(active: {2}),
        body: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), children: [
          sec('اليوم'),
          item(context, Icons.check_circle_rounded, 'تم تأكيد حجزك', 'موعدك مع د. أحمد محمد علي يوم السبت 4:30 م', 'منذ 5 دقائق', un: true, to: const AppointmentsScreen()),
          item(context, Icons.home_rounded, 'الممرض في الطريق إليك', 'يصل إلى منزلك خلال 15 دقيقة تقريباً', 'منذ ساعة', un: true, to: const HomeOrdersScreen()),
          sec('أمس'),
          item(context, Icons.science_rounded, 'نتيجة التحاليل جاهزة', 'صورة الدم الكاملة جاهزة للعرض والتحميل', 'أمس 6:20 م', to: const LabResultsScreen()),
          item(context, Icons.notifications_active_rounded, 'تذكير بالموعد', 'موعدك غداً الساعة 4:30 م في مركز المسباح', 'أمس 9:00 ص'),
          item(context, Icons.local_offer_rounded, 'خصم 20% على التحاليل المنزلية', 'العرض ساري حتى نهاية الشهر', 'أمس 8:00 ص'),
        ]),
      );
}

// ───────────────────────── 15. Ambulance request / tracking ─────────────────────────
class AmbulanceScreen extends StatelessWidget {
  const AmbulanceScreen({super.key});
  @override
  Widget build(BuildContext context) => MapPage(
        'طلب إسعاف',
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            tileIcon(Icons.location_on_rounded),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('موقعك الحالي', style: t(11.5, w: FontWeight.w500, c: kGrey)), Text('الخرطوم - بحري - المسبح', style: t(14))])),
            Text('تغيير', style: t(12.5, c: kRed)),
          ]),
          sec('نوع الإسعاف'),
          const ChipWrap(['إسعاف عادي', 'عناية مركزة']),
          const AppField('وصف الحالة', hint: 'وصف مختصر للحالة (اختياري)...'),
          gap(20),
          RedButton('اطلب إسعاف الآن', onTap: () => go(context, const AmbulanceTrackScreen())),
          gap(8),
          Center(child: Text('أقرب سيارة إسعاف على بعد حوالي 6 دقائق', style: t(11.5, w: FontWeight.w500, c: kGrey))),
        ]),
      );
}

class AmbulanceTrackScreen extends StatelessWidget {
  const AmbulanceTrackScreen({super.key});
  @override
  Widget build(BuildContext context) => MapPage(
        'تتبّع الإسعاف',
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('وصول الإسعاف خلال', style: t(12, w: FontWeight.w500, c: kGrey)), Text('5 دقائق', style: t(26, w: FontWeight.w800, c: kRed))])),
            pillWarn('في الطريق'),
          ]),
          gap(10),
          ClipRRect(borderRadius: BorderRadius.circular(4), child: const LinearProgressIndicator(value: .7, minHeight: 6, color: kRed, backgroundColor: kLine)),
          gap(14),
          panel([
            Row(children: [
              tileIcon(Icons.person_rounded, size: 46),
              const SizedBox(width: 12),
              Expanded(child: two('السائق: محمد حسن', 'إسعاف رقم 3 · تقييم 4.9')),
              const CircleAvatar(backgroundColor: kRed, child: Icon(Icons.phone_rounded, color: Colors.white)),
            ]),
          ]),
          panel([kv('نقطة الاستلام', 'بحري - المسبح'), kv('نوع الإسعاف', 'إسعاف عادي')]),
          OutBtn('إلغاء الطلب', onTap: () => Navigator.maybePop(context)),
        ]),
        route: true,
      );
}

// ───────────────────────── 16. Payment ─────────────────────────
class PaymentScreen extends StatelessWidget {
  const PaymentScreen(this.d, {super.key});
  final Doctor d;
  @override
  Widget build(BuildContext context) {
    final fee = toInt(d.price);
    return RedPage(
      title: 'الدفع',
      bottomBar: btnBar(context, 'ادفع ${money(fee + 500)} ج.س', () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SuccessScreen(d)))),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), children: [
        panel([docRow(d), const Divider(color: kLine, height: 24), kv('رسوم الكشف', '${d.price} ج.س'), kv('رسوم الخدمة', '500 ج.س'), kv('الإجمالي', '${money(fee + 500)} ج.س', bold: true)]),
        sec('اختر طريقة الدفع'),
        const RadioPick([('تطبيق بنكك', 'تحويل مباشر من حسابك'), ('أوكاش', 'الدفع بالمحفظة الإلكترونية'), ('فوري', 'الدفع عبر نقاط الخدمة'), ('الدفع في المركز', 'ادفع عند الوصول')]),
      ]),
    );
  }
}

// ───────────────────────── 17. Home service orders ─────────────────────────
class HomeOrdersScreen extends StatelessWidget {
  const HomeOrdersScreen({super.key});
  @override
  Widget build(BuildContext context) => RedPage(
        title: 'طلبات الخدمة المنزلية',
        nav: const AppNav(active: {3}),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          const FilterChips(['نشطة', 'السابقة']),
          gap(14),
          panel([
            Row(children: [tileIcon(Icons.home_rounded, size: 46), const SizedBox(width: 12), Expanded(child: two('تمريض منزلي', 'طلب رقم #20418')), pillWarn('قيد التنفيذ')]),
            gap(16),
            timeline(const [('تم استلام الطلب', '4:10 م', 1), ('تم تعيين الممرض', '4:14 م', 1), ('في الطريق إليك', 'يصل خلال 15 دقيقة', 2), ('وصل إلى المنزل', '', 0)]),
          ]),
          panel([
            Row(children: [
              tileIcon(Icons.person_rounded, size: 46),
              const SizedBox(width: 12),
              Expanded(child: two('الممرض / أحمد عثمان', 'تقييم 4.8 · 120 زيارة')),
              const CircleAvatar(backgroundColor: kRed, child: Icon(Icons.phone_rounded, color: Colors.white)),
            ]),
          ]),
          panel([Row(children: [tileIcon(Icons.science_rounded, size: 46), const SizedBox(width: 12), Expanded(child: two('خدمة معمل', 'الخميس 16 أكتوبر')), pillOk('مكتمل')])]),
        ]),
      );
}

// ───────────────────────── 18. Personal info / Settings / Help ─────────────────────────
class PersonalInfoScreen extends StatelessWidget {
  const PersonalInfoScreen({super.key});
  @override
  Widget build(BuildContext context) => RedPage(
        title: 'المعلومات الشخصية',
        bottomBar: btnBar(context, 'حفظ التغييرات', () {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حفظ التغييرات', style: t(13, c: Colors.white))));
          Navigator.maybePop(context);
        }),
        body: ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 8), children: [
          Center(
            child: Stack(children: [
              const CircleAvatar(radius: 40, backgroundColor: Color(0xFFE3E7EE), child: Icon(Icons.person_rounded, size: 56, color: Color(0xFF6B7788))),
              Positioned(bottom: 0, left: 0, child: Container(padding: const EdgeInsets.all(5), decoration: const BoxDecoration(color: kRed, shape: BoxShape.circle), child: const Icon(Icons.edit_rounded, color: Colors.white, size: 14))),
            ]),
          ),
          const AppField('الاسم الكامل', value: 'أحمد محمد علي'),
          const AppField('رقم الهاتف', value: '+249 912 345 678', type: TextInputType.phone, ltr: true),
          const Row(children: [
            Expanded(child: AppField('تاريخ الميلاد', value: '12 / 05 / 1990')),
            SizedBox(width: 12),
            Expanded(child: AppField('فصيلة الدم', value: 'A+', ltr: true)),
          ]),
          sec('الجنس'),
          const ChipWrap(['ذكر', 'أنثى']),
        ]),
      );
}

class ToggleRow extends StatefulWidget {
  const ToggleRow(this.icon, this.title, {super.key, this.on = true});
  final IconData icon;
  final String title;
  final bool on;
  @override
  State<ToggleRow> createState() => _ToggleRowState();
}

class _ToggleRowState extends State<ToggleRow> {
  late bool v = widget.on;
  @override
  Widget build(BuildContext context) => menuRow(widget.icon, widget.title, trailing: Switch(value: v, onChanged: (x) => setState(() => v = x)));
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => RedPage(
        title: 'الإعدادات',
        nav: const AppNav(active: {3}),
        body: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), children: [
          sec('التنبيهات'),
          group(const [ToggleRow(Icons.notifications_none_rounded, 'إشعارات التطبيق'), ToggleRow(Icons.alarm_rounded, 'تذكير بالمواعيد')]),
          sec('عام'),
          group([
            menuRow(Icons.language_rounded, 'اللغة', trailing: Text('العربية', style: t(12.5, w: FontWeight.w500, c: kGrey))),
            const ToggleRow(Icons.dark_mode_outlined, 'الوضع الداكن', on: false),
            const ToggleRow(Icons.location_on_outlined, 'الموقع'),
          ]),
          sec('الحساب'),
          group([
            menuRow(Icons.lock_outline_rounded, 'الخصوصية والأمان'),
            menuRow(Icons.info_outline_rounded, 'عن التطبيق', trailing: Text('الإصدار 1.0.0', style: t(12.5, w: FontWeight.w500, c: kGrey))),
          ]),
          gap(24),
          Center(child: Text('حذف الحساب', style: t(13.5, c: kRed))),
        ]),
      );
}

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});
  static const faqs = [
    ('كيف ألغي حجزي؟', 'من مواعيدي اختر الموعد ثم إلغاء الحجز. الإلغاء قبل 24 ساعة بدون رسوم.'),
    ('كيف أحجز سريراً في مستشفى؟', 'اختر حجز سرير ثم المستشفى ونوع السرير وأرسل الطلب.'),
    ('متى تصل خدمة المعمل المنزلي؟', 'في الموعد الذي تحدده عند الحجز.'),
    ('كيف أسترد رسوم الدفع؟', 'تواصل مع الدعم وسنراجع طلبك خلال 24 ساعة.'),
  ];
  @override
  Widget build(BuildContext context) => RedPage(
        title: 'مساعدة ودعم',
        bottomBar: btnBar(context, 'تواصل مع الدعم', () {}),
        body: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), children: [
          const AppSearch('ابحث عن سؤال...'),
          gap(14),
          Row(children: [
            for (final c in const [(Icons.phone_rounded, 'اتصال'), (Icons.chat_rounded, 'واتساب'), (Icons.mail_rounded, 'بريد')])
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: cardBox(16),
                  child: Column(children: [tileIcon(c.$1), gap(6), Text(c.$2, style: t(12.5))]),
                ),
              ),
          ]),
          sec('الأسئلة الشائعة'),
          for (final q in faqs)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: cardBox(16),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: Text(q.$1, style: t(13.5)),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [Text(q.$2, style: t(12.5, w: FontWeight.w500, c: kGrey, h: 1.6))],
                ),
              ),
            ),
        ]),
      );
}

// ───────────────────────── 19. Hospital details / bed booking form ─────────────────────────
class HospitalScreen extends StatelessWidget {
  const HospitalScreen(this.name, this.place, {super.key});
  final String name, place;
  Widget bedRow(String type, String price, String av, bool ok) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: cardBox(16),
        child: Row(children: [tileIcon(Icons.bed_rounded), const SizedBox(width: 12), Expanded(child: two(type, '$price ج.س / يوم')), ok ? pillOk(av) : pill(av, kRed, Colors.white)]),
      );
  @override
  Widget build(BuildContext context) => RedPage(
        title: name,
        bottomBar: btnBar(context, 'احجز سرير', () => go(context, BedFormScreen(name))),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Container(height: 130, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFFDCEBFB), borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.local_hospital_rounded, size: 70, color: kRed)),
          gap(14),
          Row(children: [Expanded(child: two(name, place)), const Icon(Icons.star_rounded, color: Color(0xFFFFB400), size: 22), Text(' 4.6', style: t(13.5))]),
          sec('أنواع الأسرّة'),
          bedRow('عناية مركزة ICU', '15,000', '3 متاح', true),
          bedRow('وحدة عناية متوسطة HDU', '12,000', '5 متاح', true),
          bedRow('عناية قلب CCU', '18,000', 'غير متاح', false),
          bedRow('سرير عادي', '6,000', '12 متاح', true),
        ]),
      );
}

class BedFormScreen extends StatelessWidget {
  const BedFormScreen(this.hospital, {super.key});
  final String hospital;
  @override
  Widget build(BuildContext context) => RedPage(
        title: 'بيانات الحجز',
        bottomBar: btnBar(context, 'إرسال طلب الحجز', () => go(context, DoneScreen('تم إرسال طلب حجز السرير', 'ستتم مراجعة طلبك من المستشفى وإشعارك بالتأكيد.', [('المستشفى', hospital), ('نوع السرير', 'ICU'), ('تاريخ الدخول', 'السبت 18 أكتوبر'), ('الإجمالي', '45,000 ج.س')]))),
        body: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), children: [
          panel([Row(children: [tileIcon(Icons.bed_rounded, size: 46), const SizedBox(width: 12), Expanded(child: two('$hospital · ICU', '15,000 ج.س / يوم'))])]),
          const AppField('اسم المريض', value: 'أحمد محمد علي'),
          const AppField('تاريخ الدخول', value: 'السبت 18 أكتوبر', icon: Icons.calendar_today_outlined),
          const AppField('عدد الأيام', value: '3', type: TextInputType.number),
          const AppField('رقم التواصل', value: '+249 912 345 678', type: TextInputType.phone, ltr: true),
          gap(14),
          panel([kv('15,000 × 3 أيام', '45,000 ج.س', bold: true), Text('يتم تأكيد الحجز من المستشفى بعد المراجعة', style: t(11, w: FontWeight.w500, c: kGrey))]),
        ]),
      );
}

// ───────────────────────── 20. Lab steps 2 & 3 ─────────────────────────
class LabScheduleScreen extends StatefulWidget {
  const LabScheduleScreen(this.tests, {super.key});
  final List<(String, String)> tests;
  @override
  State<LabScheduleScreen> createState() => _LabScheduleState();
}

class _LabScheduleState extends State<LabScheduleScreen> {
  String slot = kSlot;
  @override
  Widget build(BuildContext context) => RedPage(
        title: 'خدمة المعمل المنزلي',
        bottomBar: btnBar(context, 'التالي', () => go(context, LabConfirmScreen(widget.tests, slot))),
        body: ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 8), children: [
          labSteps(2),
          SchedulePicker(onChanged: (v) => slot = v),
          sec('عنوان الزيارة'),
          addressCard(),
        ]),
      );
}

class LabConfirmScreen extends StatelessWidget {
  const LabConfirmScreen(this.tests, this.slot, {super.key});
  final List<(String, String)> tests;
  final String slot;
  @override
  Widget build(BuildContext context) {
    final sum = tests.fold<int>(0, (a, e) => a + toInt(e.$2));
    return RedPage(
      title: 'خدمة المعمل المنزلي',
      bottomBar: btnBar(context, 'تأكيد الطلب', () => go(context, DoneScreen('تم تأكيد طلب المعمل المنزلي', 'سيصلك الفني في الموعد المحدد لسحب العينات.', [('الموعد', slot), ('التحاليل', '${tests.length} تحليل'), ('الدفع', 'نقداً عند الزيارة'), ('الإجمالي', '${money(sum + 500)} ج.س')]))),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 8), children: [
        labSteps(3),
        gap(18),
        panel([Text('التحاليل المختارة', style: t(15)), for (final e in tests) kv(e.$1, '${e.$2} ج.س')]),
        panel([kv('الموعد', slot), kv('العنوان', 'الخرطوم - بحري - المسبح')]),
        panel([kv('إجمالي التحاليل', '${money(sum)} ج.س'), kv('رسوم الزيارة', '500 ج.س'), kv('الإجمالي', '${money(sum + 500)} ج.س', bold: true)]),
        Align(alignment: AlignmentDirectional.centerStart, child: pillOk('الدفع نقداً عند الزيارة')),
      ]),
    );
  }
}

// ───────────────────────── 21. Doctor / nurse home visit ─────────────────────────
class HomeRequestScreen extends StatelessWidget {
  const HomeRequestScreen(this.doctor, {super.key});
  final bool doctor;
  @override
  Widget build(BuildContext context) => RedPage(
        title: doctor ? 'زيارة طبيب للمنزل' : 'تمريض منزلي',
        bottomBar: btnBar(context, doctor ? 'اطلب الزيارة' : 'اطلب ممرض', () => go(context, DoneScreen('تم استلام طلبك', 'سنؤكد موعد الزيارة خلال دقائق.', [('الخدمة', doctor ? 'زيارة طبيب' : 'تمريض منزلي'), ('الموعد', kSlot), ('الرسوم', doctor ? '8,000 ج.س' : '3,000 ج.س')], btn: 'متابعة الطلب', to: const HomeOrdersScreen()))),
        body: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 8), children: [
          sec(doctor ? 'التخصص' : 'نوع الخدمة'),
          ChipWrap(doctor ? const ['باطنية', 'أطفال', 'نساء وتوليد', 'طب عام'] : const ['حقن وريدي', 'تغيير جروح', 'قياس ضغط وسكر', 'رعاية كبار السن'], multi: !doctor),
          if (!doctor) ...[sec('مدة الزيارة'), const ChipWrap(['ساعة', '4 ساعات', '12 ساعة'])],
          const SchedulePicker(),
          sec('العنوان'),
          addressCard(),
          if (doctor) const AppField('وصف الحالة', hint: 'اكتب الأعراض باختصار...', lines: 3),
          gap(12),
          panel([kv(doctor ? 'رسوم الزيارة' : 'تبدأ الأسعار من', doctor ? '8,000 ج.س' : '3,000 ج.س', bold: true)]),
        ]),
      );
}

// ───────────────────────── 22. Lab results ─────────────────────────
class LabResultsScreen extends StatelessWidget {
  const LabResultsScreen({super.key});
  Widget res(String n, String v, String r, bool ok) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(n, style: t(13.5)), Text('الطبيعي: $r', style: t(11, w: FontWeight.w500, c: kGrey))])),
          Directionality(textDirection: TextDirection.ltr, child: Text(v, style: t(13))),
          const SizedBox(width: 10),
          ok ? pillOk('طبيعي') : pillWarn('مرتفع'),
        ]),
      );
  @override
  Widget build(BuildContext context) => RedPage(
        title: 'نتائج التحاليل',
        bottomBar: btnBar(context, 'تحميل PDF', () {}, alt: 'مشاركة', onAlt: () {}),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          panel([
            Row(children: [tileIcon(Icons.science_rounded, size: 46), const SizedBox(width: 12), Expanded(child: two('صورة دم كاملة', '16 أكتوبر · معمل المسبح')), pillOk('جاهزة')]),
            const Divider(color: kLine, height: 24),
            res('الهيموجلوبين', '13.8 g/dL', '13.5 - 17.5', true),
            res('كريات الدم البيضاء', '11.8 ×10³/µL', '4 - 11', false),
            res('الصفائح الدموية', '250 ×10³/µL', '150 - 450', true),
            res('الهيماتوكريت', '42 %', '40 - 52', true),
          ]),
          panel([Row(children: [tileIcon(Icons.science_rounded, size: 46), const SizedBox(width: 12), Expanded(child: two('تحليل السكر', '16 أكتوبر · 95 mg/dL')), pillOk('طبيعي')])]),
          Center(child: Text('النتائج للاطلاع فقط، ويفسّرها الطبيب مع حالتك.', style: t(11, w: FontWeight.w500, c: kGrey))),
        ]),
      );
}

// ───────────────────────── 23. Reviews / Rate ─────────────────────────
class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen(this.d, {super.key});
  final Doctor d;
  Widget stars(int n) => Row(mainAxisSize: MainAxisSize.min, children: [for (var i = 0; i < 5; i++) Icon(Icons.star_rounded, size: 16, color: i < n ? const Color(0xFFFFB400) : const Color(0xFFD6DBE6))]);
  Widget bar(int n, double p) => Row(children: [
        Text('$n', style: t(11, c: kGrey)),
        const SizedBox(width: 6),
        Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: p, minHeight: 6, color: const Color(0xFFFFB400), backgroundColor: kLine))),
      ]);
  Widget review(String n, int s, String c, String tm) => panel([
        Row(children: [const CircleAvatar(radius: 16, backgroundColor: kChip, child: Icon(Icons.person_rounded, size: 18, color: kGrey)), const SizedBox(width: 10), Expanded(child: Text(n, style: t(13.5))), stars(s)]),
        const SizedBox(height: 6),
        Text(c, style: t(12.5, w: FontWeight.w500, c: const Color(0xFF4B5873), h: 1.5)),
        Text(tm, style: t(10.5, w: FontWeight.w500, c: const Color(0xFF9AA5B8))),
      ]);
  @override
  Widget build(BuildContext context) => RedPage(
        title: d.name,
        bottomBar: btnBar(context, 'اكتب تقييمك', () => go(context, RateScreen(d))),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          panel([
            Row(children: [
              Column(children: [Text(d.rating, style: t(34, w: FontWeight.w900)), stars(5), Text('${d.reviews} تقييم', style: t(11, w: FontWeight.w500, c: kGrey))]),
              const SizedBox(width: 20),
              Expanded(child: Column(children: [bar(5, .82), bar(4, .12), bar(3, .04), bar(2, .01), bar(1, .01)])),
            ]),
          ]),
          review('محمد عبد الرحيم', 5, 'دكتور ممتاز ومتعاون، وشرح الحالة بوضوح.', 'منذ أسبوع'),
          review('آمنة إبراهيم', 4, 'الكشف كان سريعاً والانتظار قليل.', 'منذ أسبوعين'),
          review('خالد يوسف', 5, 'تشخيص دقيق وأنصح به.', 'منذ شهر'),
        ]),
      );
}

class RateScreen extends StatefulWidget {
  const RateScreen(this.d, {super.key});
  final Doctor d;
  @override
  State<RateScreen> createState() => _RateState();
}

class _RateState extends State<RateScreen> {
  int r = 4;
  @override
  Widget build(BuildContext context) => RedPage(
        title: 'قيّم تجربتك',
        bottomBar: btnBar(context, 'إرسال التقييم', () => go(context, DoneScreen('شكراً لتقييمك', 'رأيك يساعدنا على تحسين الخدمة.', [('الطبيب', widget.d.name), ('تقييمك', '$r من 5')]))),
        body: ListView(padding: const EdgeInsets.fromLTRB(16, 20, 16, 8), children: [
          Center(child: Pic(widget.d.img, size: 76)),
          gap(8),
          Center(child: Text(widget.d.name, style: t(16, w: FontWeight.w800))),
          gap(14),
          Center(child: Text('كيف كانت تجربتك؟', style: t(15))),
          gap(8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 1; i <= 5; i++) GestureDetector(onTap: () => setState(() => r = i), child: Icon(Icons.star_rounded, size: 44, color: i <= r ? const Color(0xFFFFB400) : const Color(0xFFD6DBE6))),
          ]),
          sec('ما الذي أعجبك؟'),
          const ChipWrap(['مواعيد دقيقة', 'تعامل راقٍ', 'شرح واضح', 'سعر مناسب'], sel: {0, 2}, multi: true),
          const AppField('ملاحظات', hint: 'اكتب ملاحظاتك (اختياري)...', lines: 3),
        ]),
      );
}

// ───────────────────────── 24. Filter ─────────────────────────
class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});
  @override
  State<FilterScreen> createState() => _FilterState();
}

class _FilterState extends State<FilterScreen> {
  RangeValues v = const RangeValues(5000, 15000);
  @override
  Widget build(BuildContext context) => RedPage(
        title: 'تصفية النتائج',
        bottomBar: btnBar(context, 'تطبيق', () => Navigator.maybePop(context), alt: 'إعادة ضبط', onAlt: () => setState(() => v = const RangeValues(5000, 15000))),
        body: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 8), children: [
          sec('التخصص'),
          const ChipWrap(['الكل', 'باطنية', 'أطفال', 'نساء وتوليد', 'جراحة عامة', 'قلب'], sel: {1, 2}, multi: true),
          sec('المنطقة'),
          const ChipWrap(['الخرطوم', 'بحري', 'أم درمان'], sel: {1}),
          sec('سعر الكشف'),
          RangeSlider(values: v, min: 0, max: 30000, divisions: 30, onChanged: (x) => setState(() => v = x)),
          Row(children: [Text('${money(v.start.round())} ج.س', style: t(12, c: kGrey)), const Spacer(), Text('${money(v.end.round())} ج.س', style: t(12, c: kGrey))]),
          sec('التقييم'),
          const ChipWrap(['4 ★ فأكثر', '3 ★ فأكثر', 'الكل']),
          sec('الطبيب'),
          const ChipWrap(['الكل', 'طبيب', 'طبيبة']),
        ]),
      );
}

// ───────────────────────── 25. Medical record / Favorites / Family ─────────────────────────
class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});
  @override
  Widget build(BuildContext context) => RedPage(
        title: 'السجل الطبي',
        nav: const AppNav(active: {3}),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Row(children: [
            for (final s in const [('فصيلة الدم', 'A+'), ('العمر', '36'), ('الحساسية', 'لا يوجد')])
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: cardBox(16),
                  child: Column(children: [Text(s.$1, style: t(10.5, w: FontWeight.w600, c: kGrey)), gap(4), Text(s.$2, style: t(15, c: kRed))]),
                ),
              ),
          ]),
          gap(14),
          group([
            menuRow(Icons.event_available_outlined, 'الزيارات السابقة', trailing: cnt('8'), to: const AppointmentsScreen()),
            menuRow(Icons.science_outlined, 'نتائج التحاليل', trailing: cnt('5'), to: const LabResultsScreen()),
            menuRow(Icons.description_outlined, 'الوصفات الطبية', trailing: cnt('3')),
            menuRow(Icons.favorite_border_rounded, 'التقارير الطبية', trailing: cnt('2')),
          ]),
          gap(14),
          panel([Text('آخر زيارة', style: t(12, w: FontWeight.w500, c: kGrey)), two('د. أحمد محمد علي · باطنية', '12 أكتوبر · التشخيص: التهاب بسيط في الحلق')]),
        ]),
      );
}

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});
  @override
  Widget build(BuildContext context) => RedPage(
        title: 'المفضلة',
        nav: const AppNav(active: {3}),
        body: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: doctors.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (_, i) => DoctorCard(doctors[i]),
        ),
      );
}

class FamilyScreen extends StatelessWidget {
  const FamilyScreen({super.key});
  Widget member(String n, String rel, {bool me = false}) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: cardBox(16),
        child: Row(children: [tileIcon(Icons.person_rounded, size: 46), const SizedBox(width: 12), Expanded(child: two(n, rel)), pill(me ? 'أنا' : 'فرد', kChip, kInk), const SizedBox(width: 6), chev(kInk, 20)]),
      );
  @override
  Widget build(BuildContext context) => RedPage(
        title: 'أفراد العائلة',
        nav: const AppNav(active: {3}),
        bottomBar: btnBar(context, '+ إضافة فرد جديد', () => go(context, const AddMemberScreen())),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Text('أضف أفراد عائلتك لتحجز لهم المواعيد من حسابك.', style: t(12.5, w: FontWeight.w500, c: kGrey)),
          gap(14),
          member('أحمد محمد علي', 'الحساب الرئيسي · 36 سنة', me: true),
          member('فاطمة أحمد', 'الزوجة · 33 سنة'),
          member('يوسف أحمد', 'الابن · 6 سنوات'),
        ]),
      );
}

class AddMemberScreen extends StatelessWidget {
  const AddMemberScreen({super.key});
  @override
  Widget build(BuildContext context) => RedPage(
        title: 'إضافة فرد',
        bottomBar: btnBar(context, 'حفظ', () => Navigator.maybePop(context)),
        body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 8), children: const [
          AppField('الاسم الكامل', hint: 'اسم الفرد'),
          AppField('تاريخ الميلاد', hint: 'يوم / شهر / سنة', icon: Icons.calendar_today_outlined),
          SizedBox(height: 14),
          ChipWrap(['الزوج/ة', 'ابن', 'ابنة', 'أب', 'أم']),
        ]),
      );
}
