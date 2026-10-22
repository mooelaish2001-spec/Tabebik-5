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
const kShadow = [
  BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 6))
];

TextStyle t(
  double s, {
  FontWeight w = FontWeight.w700,
  Color c = kInk,
  double? h,
}) =>
    GoogleFonts.cairo(fontSize: s, fontWeight: w, color: c, height: h);

void go(BuildContext c, Widget w) =>
    Navigator.push(c, MaterialPageRoute(builder: (_) => w));

/// "‹" arrow (points left even in RTL).
Icon chev([Color c = kRed, double s = 24]) => Icon(
      Icons.chevron_left_rounded,
      color: c,
      size: s,
      textDirection: TextDirection.ltr,
    );

/// "›" arrow (points right even in RTL).
Icon chevR([Color c = kRed, double s = 24]) => Icon(
      Icons.chevron_right_rounded,
      color: c,
      size: s,
      textDirection: TextDirection.ltr,
    );

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
        // FIX #2: guard against null child from TransitionBuilder.
        builder: (c, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        ),
        home: const SplashScreen(),
      );
}

// ───────────────────────── Data ─────────────────────────
class Doctor {
  const Doctor(
      this.name, this.spec, this.rating, this.reviews, this.price, this.img);
  final String name, spec, price, img;
  final String rating;
  final int reviews;
}

const doctors = [
  Doctor('د. أحمد محمد علي', 'استشاري باطنية', '4.8', 245, '10,000',
      'assets/images/doctor1.jpg'),
  Doctor('د. سارة عبد الله', 'أخصائية نساء وتوليد', '4.6', 180, '8,000',
      'assets/images/doctor2.jpg'),
  Doctor('د. حسن محمود', 'أخصائي أطفال', '4.5', 120, '7,500',
      'assets/images/doctor3.jpg'),
  Doctor('د. علي محمد', 'استشاري جراحة عامة', '4.4', 98, '9,000',
      'assets/images/doctor4.jpg'),
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
    canvas.drawPath(
        ecg,
        Paint()
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
    canvas.drawPath(
        p,
        Paint()
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
            topLeft: Radius.circular(w * .26),
            topRight: Radius.circular(w * .26)),
        white);
    c.drawPath(
        Path()
          ..moveTo(w * .39, w * .54)
          ..lineTo(w * .5, w * .72)
          ..lineTo(w * .61, w * .54)
          ..close(),
        red);
    c.drawPath(
        Path()
          ..moveTo(w * .3, w * .58)
          ..quadraticBezierTo(w * .28, w * .82, w * .48, w * .84),
        Paint()
          ..color = kRed
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * .03
          ..strokeCap = StrokeCap.round);
    if (cap) {
      c.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(w * .33, w * .07, w * .34, w * .11),
              Radius.circular(w * .04)),
          white);
      c.drawRect(
          Rect.fromCenter(
              center: Offset(w * .5, w * .125),
              width: w * .03,
              height: w * .07),
          red);
      c.drawRect(
          Rect.fromCenter(
              center: Offset(w * .5, w * .125),
              width: w * .07,
              height: w * .03),
          red);
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
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * .05, w * .24, w * .9, w * .48),
            Radius.circular(w * .09)),
        white);
    c.drawRect(
        Rect.fromCenter(
            center: Offset(w * .33, w * .48), width: w * .08, height: w * .24),
        red);
    c.drawRect(
        Rect.fromCenter(
            center: Offset(w * .33, w * .48), width: w * .24, height: w * .08),
        red);
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * .62, w * .32, w * .22, w * .16),
            Radius.circular(w * .03)),
        red);
    for (final x in [.28, .74]) {
      c.drawCircle(Offset(w * x, w * .74), w * .11, red);
      c.drawCircle(Offset(w * x, w * .74), w * .08, white);
      c.drawCircle(Offset(w * x, w * .74), w * .03, red);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

Widget paintIcon(CustomPainter p, double size) =>
    CustomPaint(size: Size(size, size), painter: p);

// ───────────────────────── Shared widgets ─────────────────────────
/// Image from assets with a graceful placeholder (drop real photos in assets/images/).
class Pic extends StatelessWidget {
  const Pic(this.asset,
      {super.key,
      this.size = 64,
      this.height,
      this.radius = 999,
      this.icon = Icons.person_rounded,
      this.quiet = false});
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
      child: Image.asset(asset,
          width: size,
          height: h,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => quiet
              ? SizedBox(width: size, height: h)
              : Container(
                  width: size,
                  height: h,
                  color: const Color(0xFFE6EBF2),
                  child: Icon(icon,
                      size: size * .55, color: const Color(0xFF9AA6B8)))),
    );
  }
}

class SWaveClipper extends CustomClipper<Path> {
  const SWaveClipper();
  @override
  Path getClip(Size s) => Path()
    ..lineTo(0, s.height - 34)
    ..cubicTo(s.width * .3, s.height + 8, s.width * .62, s.height - 78,
        s.width, s.height - 22)
    ..lineTo(s.width, 0)
    ..close();
  @override
  bool shouldReclip(covariant CustomClipper<Path> o) => false;
}

class SplashWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size s) => Path()
    ..moveTo(0, s.height * .64)
    ..cubicTo(s.width * .35, s.height * .76, s.width * .6, s.height * .15,
        s.width, 0)
    ..lineTo(s.width, s.height)
    ..lineTo(0, s.height)
    ..close();
  @override
  bool shouldReclip(covariant CustomClipper<Path> o) => false;
}

/// Red header (back arrow on the left, optional action on the right) + white sheet with rounded top.
class RedPage extends StatelessWidget {
  const RedPage(
      {super.key,
      required this.title,
      required this.body,
      this.nav,
      this.action,
      this.bottomBar});
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
                  Expanded(
                      child: Text(title,
                          textAlign: TextAlign.center,
                          style: t(20, w: FontWeight.w800, c: Colors.white))),
                  SizedBox(
                    width: 56,
                    child: IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.chevron_left_rounded,
                          color: Colors.white,
                          size: 36,
                          textDirection: TextDirection.ltr),
                    ),
                  ),
                ]),
              ),
            ),
            Expanded(
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(
                    color: kBg,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(28))),
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
  const RedButton(this.text,
      {super.key,
      required this.onTap,
      this.edgeIcon,
      this.height = 52,
      this.white = false});
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
            boxShadow: const [
              BoxShadow(
                  color: Color(0x4DD9141E),
                  blurRadius: 14,
                  offset: Offset(0, 7))
            ],
          ),
          child: Stack(alignment: Alignment.center, children: [
            Text(text,
                style: t(17, w: FontWeight.w800, c: Colors.white)),
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
          : (
              Icons.event_available_rounded,
              Icons.event_available_outlined,
              'مواعيدي'
            ),
      (Icons.notifications_rounded, Icons.notifications_none_rounded, 'إشعارات'),
      (Icons.more_horiz_rounded, Icons.more_horiz_rounded, 'المزيد'),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
              color: Color(0x14000000),
              blurRadius: 18,
              offset: Offset(0, -4))
        ],
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
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const HomeScreen()),
                          (r) => false);
                    } else if (i == 3 && !active.contains(3)) {
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ProfileScreen()),
                          (r) => false);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(
                          active.contains(i) ? items[i].$1 : items[i].$2,
                          size: 24,
                          color: active.contains(i) ? kRed : kGrey),
                      const SizedBox(height: 2),
                      Text(items[i].$3,
                          style: t(10.5,
                              w: active.contains(i)
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              c: active.contains(i) ? kRed : kGrey)),
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
        decoration: BoxDecoration(
            color: const Color(0xFFF3F5F9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: kLine)),
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
  const FilterChips(this.items, {super.key, this.more = false});
  final List<String> items;
  final bool more;
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
                onTap: () => setState(() => sel = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: i == sel ? kGradient : null,
                    color: i == sel ? null : kChip,
                    borderRadius: BorderRadius.circular(21),
                    boxShadow: i == sel
                        ? const [
                            BoxShadow(
                                color: Color(0x4DD9141E),
                                blurRadius: 10,
                                offset: Offset(0, 4))
                          ]
                        : null,
                  ),
                  child: Text(widget.items[i],
                      style: t(13.5,
                          w: FontWeight.w700,
                          c: i == sel
                              ? Colors.white
                              : const Color(0xFF4B5873))),
                ),
              ),
            ),
          ),
          if (widget.more)
            Padding(
                padding: const EdgeInsets.only(left: 10), child: chev(kRed, 20)),
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
        boxShadow: const [
          BoxShadow(
              color: Color(0x4DD9141E), blurRadius: 14, offset: Offset(0, 7))
        ],
      ),
      child: child,
    );

Widget pill(String text, Color bg, Color fg) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: t(12, w: FontWeight.w700, c: fg)),
    );

BoxDecoration cardBox([double r = 20]) => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(r),
    boxShadow: kShadow,
    border: Border.all(color: const Color(0xFFF0F2F6)));

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
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Color(0xFFF1F3F6)]),
            ),
          ),
        ),
        const Positioned(
            left: -10,
            bottom: 120,
            child: Pic('assets/images/stethoscope.png',
                size: 240, radius: 0, quiet: true)),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: h * .32,
          child: ClipPath(
              clipper: SplashWaveClipper(),
              child:
                  Container(decoration: const BoxDecoration(gradient: kGradient))),
        ),
        Positioned.fill(
          child: SafeArea(
            child: Column(children: [
              SizedBox(height: h * .17),
              SizedBox(
                  width: 150,
                  height: 135,
                  child: CustomPaint(painter: HeartPainter())),
              Text('طبيبك', style: t(78, w: FontWeight.w900, c: kRed, h: 1.15)),
              Text('صحتك .. أولويتنا',
                  style: t(19,
                      w: FontWeight.w600, c: const Color(0xFF5B6B86))),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                child: RedButton('ابدأ الآن',
                    white: true,
                    height: 58,
                    edgeIcon: chevR(Colors.white, 22),
                    onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const HomeScreen()))),
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
    Widget card(Widget icon, String title, String sub, Widget? screen) =>
        GestureDetector(
          onTap: screen == null ? null : () => go(context, screen),
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
            decoration: cardBox(26),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              iconTile(icon),
              const SizedBox(height: 10),
              Text(title, style: t(17.5, w: FontWeight.w800, c: kRed)),
              const SizedBox(height: 2),
              Text(sub,
                  textAlign: TextAlign.center,
                  style: t(11, w: FontWeight.w500, c: kGrey, h: 1.35)),
            ]),
          ),
        );
    return Scaffold(
      backgroundColor: kBg,
      body: Column(children: [
        Container(
          decoration: const BoxDecoration(
              gradient: kGradient,
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(40))),
          padding: EdgeInsets.fromLTRB(
              20, MediaQuery.of(context).padding.top + 10, 20, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.notifications_rounded,
                  color: Colors.white, size: 28),
              Expanded(
                  child: Text('طبيبك',
                      textAlign: TextAlign.center,
                      style: t(30, w: FontWeight.w900, c: Colors.white))),
              const CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person_rounded,
                      color: Color(0xFF5B7FA6), size: 24)),
            ]),
            const SizedBox(height: 14),
            Text('مرحباً بك', style: t(24, w: FontWeight.w800, c: Colors.white)),
            Text('نحن هنا من أجلك',
                style: t(15, w: FontWeight.w500, c: Colors.white)),
            const SizedBox(height: 14),
            Container(
              height: 54,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28)),
              child: TextField(
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
              card(paintIcon(_BedIcon(), 54), 'حجز سرير',
                  'ICU - HDU - CCU\nوغيرها', const BedScreen()),
              card(paintIcon(DoctorPainter(), 62), 'حجز طبيب',
                  'احجز موعدك مع أفضل\nالأطباء', const DoctorListScreen()),
              card(paintIcon(AmbulancePainter(), 62), 'إسعاف',
                  'طلب إسعاف سريع', null),
              card(const Icon(Icons.home_rounded, color: Colors.white, size: 62),
                  'خدمة منزلية', 'طبيب - ممرض - معمل',
                  const HomeServicesScreen()),
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
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * .04, w * .12, w * .1, w * .76),
            Radius.circular(w * .04)),
        p);
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * .04, w * .56, w * .92, w * .14),
            Radius.circular(w * .03)),
        p);
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * .86, w * .56, w * .1, w * .32),
            Radius.circular(w * .04)),
        p);
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * .2, w * .32, w * .22, w * .18),
            Radius.circular(w * .05)),
        p);
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * .48, w * .36, w * .48, w * .15),
            Radius.circular(w * .05)),
        p);
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
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: kLine, width: 2)),
              child: Pic(d.img, size: 70),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d.name, style: t(15.5, w: FontWeight.w800)),
                Text(d.spec, style: t(12.5, w: FontWeight.w500, c: kGrey)),
                Row(children: [
                  const Icon(Icons.star_rounded,
                      color: Color(0xFFFFB400), size: 20),
                  const SizedBox(width: 4),
                  Text(d.rating,
                      style: t(12.5,
                          w: FontWeight.w600, c: const Color(0xFF4B5873))),
                  const SizedBox(width: 8),
                  Text('(${d.reviews})',
                      style: t(11.5, w: FontWeight.w500, c: kGrey)),
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
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.favorite_border_rounded,
                        color: kGrey, size: 20),
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
        action: const Icon(Icons.filter_list_rounded,
            color: Colors.white, size: 28),
        nav: const AppNav(),
        body: Column(children: [
          const Padding(
              padding: EdgeInsets.fromLTRB(16, 18, 16, 14),
              child: AppSearch('ابحث عن طبيب، أو تخصص...')),
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

  Widget center(
          String name, String place, String days, String price, String hours) =>
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: cardBox(16),
        child: Column(children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.location_on_rounded, color: kRed, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child:
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: t(15, w: FontWeight.w800)),
                Text(place, style: t(12, w: FontWeight.w500, c: kGrey)),
              ]),
            ),
            const Icon(Icons.apartment_rounded, color: kInk, size: 44),
          ]),
          const SizedBox(height: 4),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
                child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(days,
                        style: t(12.5,
                            w: FontWeight.w600,
                            c: const Color(0xFF4B5873))))),
            const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child:
                    Icon(Icons.calendar_today_outlined, color: kGrey, size: 13)),
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
                Positioned.fill(
                    child: Container(
                        decoration: const BoxDecoration(
                            gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFFEDEFF3), Colors.white])))),
                Positioned(
                    left: 10,
                    top: 130,
                    child: SizedBox(
                        width: 120,
                        height: 70,
                        child: CustomPaint(painter: EcgPainter()))),
                Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 150 + top * .4,
                    child: ClipPath(
                        clipper: const SWaveClipper(),
                        child: Container(
                            decoration:
                                const BoxDecoration(gradient: kGradient)))),
                Positioned(
                  top: top + 6,
                  left: 6,
                  child: IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.chevron_left_rounded,
                        color: Colors.white,
                        size: 36,
                        textDirection: TextDirection.ltr),
                  ),
                ),
                Positioned(
                  top: top + 12,
                  right: 16,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12)),
                    child:
                        const Icon(Icons.favorite_rounded, color: kRed, size: 22),
                  ),
                ),
                Positioned(
                    left: 0,
                    right: 0,
                    top: top + 24,
                    child: Center(
                        child: Pic(d.img,
                            size: 190,
                            height: 220,
                            radius: 28,
                            icon: Icons.person_rounded))),
              ]),
            ),
            Center(child: Text(d.name, style: t(22, w: FontWeight.w800))),
            const SizedBox(height: 4),
            Center(
                child: pill(d.spec, kChip, const Color(0xFF4B5873))),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.star_rounded, color: Color(0xFFFFB400), size: 22),
              const SizedBox(width: 6),
              Text(d.rating,
                  style: t(14,
                      w: FontWeight.w800, c: const Color(0xFF4B5873))),
              const SizedBox(width: 10),
              Text('(${d.reviews} تقييم)',
                  style: t(12.5, w: FontWeight.w500, c: kGrey)),
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
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('المراكز التي يعمل بها',
                        style: t(16, w: FontWeight.w800)),
                    const SizedBox(height: 10),
                    center('مركز المسباح', 'الخرطوم - بحري', 'السبت - الخميس',
                        '10,000', '8:00 - 6:00 م'),
                    center('مركز الشرق', 'الخرطوم - أم درمان', 'الأحد - الخميس',
                        '8,000', '9:00 - 5:00 م'),
                  ]),
            ),
          ]),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
              16, 6, 16, MediaQuery.of(context).padding.bottom + 12),
          child: RedButton('احجز موعد',
              onTap: () => go(context, ConfirmBookingScreen(d))),
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
  static const days = [
    ('السبت', '18'),
    ('الأحد', '19'),
    ('الاثنين', '20'),
    ('الثلاثاء', '21')
  ];
  static const times = [
    '5:00 م', '4:30 م', '4:00 م', '6:00 م', '6:00 م',
    '5:30 م', '2:00 م', '7:30 م', '8:00 م'
  ];

  Widget title(String s) => Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 12),
      child: Text(s, style: t(16.5, w: FontWeight.w800)));

  BoxDecoration tile(bool on) => BoxDecoration(
        gradient: on ? kGradient : null,
        color: on ? null : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: on ? null : Border.all(color: kLine),
        boxShadow: on
            ? const [
                BoxShadow(
                    color: Color(0x4DD9141E),
                    blurRadius: 12,
                    offset: Offset(0, 6))
              ]
            : kShadow,
      );

  @override
  Widget build(BuildContext context) {
    final d = widget.d;
    return RedPage(
      title: 'تأكيد الحجز',
      bottomBar: Padding(
        padding: EdgeInsets.fromLTRB(
            16, 8, 16, MediaQuery.of(context).padding.bottom + 14),
        child: RedButton('تأكيد الحجز', onTap: () {
          // FIX #3: pass the actual picked day/time to SuccessScreen.
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => SuccessScreen(
                        d,
                        dayName: days[day].$1,
                        dayNum: days[day].$2,
                        time: times[time],
                      )));
        }),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 8), children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kLine)),
          child: Row(children: [
            Pic(d.img, size: 68),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d.name, style: t(15.5, w: FontWeight.w800)),
                Text(d.spec, style: t(12.5, w: FontWeight.w500, c: kGrey)),
                Text('مركز المسباح - الخرطوم',
                    style: t(12.5, w: FontWeight.w500, c: const Color(0xFF4B5873))),
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
                    Text(days[i].$1,
                        style: t(11.5,
                            w: FontWeight.w600,
                            c: i == day ? Colors.white : kGrey)),
                    Text(days[i].$2,
                        style: t(24,
                            w: FontWeight.w800,
                            c: i == day ? Colors.white : kInk,
                            h: 1.3)),
                  ]),
                ),
              ),
            ),
        ]),
        title('اختر الوقت'),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.2,
          children: [
            for (var i = 0; i < times.length; i++)
              GestureDetector(
                onTap: () => setState(() => time = i),
                child: Container(
                  alignment: Alignment.center,
                  decoration: tile(i == time),
                  child: Text(times[i],
                      style: t(14,
                          w: FontWeight.w700,
                          c: i == time ? Colors.white : kInk)),
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
  const SuccessScreen(this.d,
      {super.key, this.dayName = 'السبت', this.dayNum = '18', this.time = '4:30 م'});
  final Doctor d;
  final String dayName, dayNum, time;

  Widget row(IconData i, String s, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Icon(i, color: kRed, size: 22),
          const SizedBox(width: 12),
          Text(s,
              style: t(14,
                  w: bold ? FontWeight.w800 : FontWeight.w600,
                  c: const Color(0xFF3B4A68))),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    const bits = [
      (-74.0, -70.0, Color(0xFF2EAD5C), .8),
      (74.0, -64.0, Color(0xFF2EAD5C), -.7),
      (92.0, -4.0, Color(0xFFE8559A), -.2),
      (-92.0, -12.0, Color(0xFFF5A623), .1),
      (-74.0, 50.0, Color(0xFFE8559A), -.6),
      (76.0, 56.0, Color(0xFF2EAD5C), .8),
    ];
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(children: [
            const SizedBox(height: 44),
            SizedBox(
              width: 230,
              height: 170,
              child: Stack(alignment: Alignment.center, children: [
                for (final b in bits)
                  Transform.translate(
                      offset: Offset(b.$1, b.$2),
                      child: Transform.rotate(
                          angle: b.$4,
                          child: Container(
                              width: 12,
                              height: 6,
                              decoration: BoxDecoration(
                                  color: b.$3,
                                  borderRadius: BorderRadius.circular(1.5))))),
                Container(
                  width: 104,
                  height: 104,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF3DBB6B), Color(0xFF1F9A4C)]),
                    boxShadow: [
                      BoxShadow(
                          color: Color(0x332EAD5C),
                          blurRadius: 16,
                          offset: Offset(0, 8))
                    ],
                  ),
                  child:
                      const Icon(Icons.check_rounded, color: Colors.white, size: 70),
                ),
              ]),
            ),
            Text('تم إرسال طلب الحجز بنجاح', style: t(21, w: FontWeight.w800)),
            const SizedBox(height: 10),
            Text(
              'سيتم مراجعة طلبك من قبل المركز،\nوسيتم إشعارك بمجرد التأكيد.',
              textAlign: TextAlign.center,
              style: t(13,
                  w: FontWeight.w500, c: const Color(0xFF6B7794), h: 1.7),
            ),
            const SizedBox(height: 26),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: cardBox(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: kLine, width: 2)),
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
                row(Icons.calendar_month_outlined, '$dayName $dayNum أكتوبر 2025'),
                row(Icons.access_time_rounded, 'الساعة $time'),
                row(Icons.access_time_rounded, '${d.price} ج.س', bold: true),
              ]),
            ),
            const Spacer(),
            RedButton('العودة إلى الرئيسية',
                height: 50,
                onTap: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (r) => false)),
          ]),
        ),
      ),
    );
  }
}

// ───────────────────────── 7. Bed booking ─────────────────────────
class BedScreen extends StatelessWidget {
  const BedScreen({super.key});

  Widget hospital(String name, String place, String type, bool ok, String price,
          String img) =>
      Container(
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
                ok
                    ? pill('متاح', const Color(0xFFD9F3E1), const Color(0xFF2A8F4F))
                    : pill('غير متاح', kRed, Colors.white),
              ]),
              const SizedBox(height: 8),
              Text('$price ج.س / يوم', style: t(14, w: FontWeight.w800)),
            ]),
          ),
          const SizedBox(width: 10),
          Pic(img, size: 112, height: 118, radius: 12, icon: Icons.apartment_rounded),
        ]),
      );

  @override
  Widget build(BuildContext context) => RedPage(
        title: 'حجز سرير',
        nav: const AppNav(active: {1}, apptLabel: 'حجوزاتي'),
        body: Column(children: [
          const SizedBox(height: 16),
          const FilterChips(['الكل', 'CCU', 'HDU', 'ICU', 'عادية']),
          Expanded(
            child: ListView(padding: const EdgeInsets.all(16), children: [
              hospital('مستشفى السلام', 'الخرطوم - أم درمان', 'ICU', true,
                  '15,000', 'assets/images/hospital1.jpg'),
              const SizedBox(height: 14),
              hospital('مستشفى النيل', 'الخرطوم - بحري', 'HDU', true, '12,000',
                  'assets/images/hospital2.jpg'),
              const SizedBox(height: 14),
              hospital('مستشفى المدينة', 'الخرطوم - شرق النيل', 'CCU', false,
                  '18,000', 'assets/images/hospital3.jpg'),
            ]),
          ),
        ]),
      );
}

// ───────────────────────── 8. Home services ─────────────────────────
class HomeServicesScreen extends StatelessWidget {
  const HomeServicesScreen({super.key});

  Widget service(BuildContext c, Widget icon, String title, String sub,
          {Widget? to}) =>
      GestureDetector(
        onTap: to == null ? null : () => go(c, to),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Color(0xFFF1F3F7)]),
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
                Text(sub,
                    style: t(12, w: FontWeight.w500, c: kGrey, h: 1.5)),
              ]),
            ),
            const SizedBox(width: 10),
            Container(
              width: 100,
              height: 100,
              alignment: Alignment.center,
              decoration:
                  const BoxDecoration(gradient: kGradient, shape: BoxShape.circle),
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
          service(context, paintIcon(DoctorPainter(), 64), 'زيارة طبيب للمنزل',
              'استشارة وفحص في منزلك'),
          service(
              context,
              paintIcon(DoctorPainter(cap: true), 64),
              'تمريض منزلي',
              'ممرض أو ممرضة لرعايتك في\nالمنزل'),
          service(
              context,
              const Icon(Icons.science_rounded, color: Colors.white, size: 58),
              'خدمة معمل',
              'سحب عينات وإجراء التحاليل',
              to: const LabScreen()),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            decoration: BoxDecoration(
                color: const Color(0xFFFBE3E3),
                borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              const Icon(Icons.cottage_rounded,
                  size: 64, color: Color(0xFFE08A5B)),
              const SizedBox(width: 10),
              Expanded(
                  child: Text('رعايتك في منزلك .. بكل راحة',
                      style: t(13.5, w: FontWeight.w800))),
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
  static const tests = [
    ('صورة دم كاملة', '150'),
    ('تحليل السكر', '80'),
    ('وظائف الكلى', '250'),
    ('وظائف الكبد', '250'),
  ];

  Widget step(int n, String label, bool on) => SizedBox(
        width: 56,
        child: Column(children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? kRed : const Color(0xFFEDF0F5),
              shape: BoxShape.circle,
              boxShadow: on
                  ? const [
                      BoxShadow(
                          color: Color(0x4DD9141E),
                          blurRadius: 8,
                          offset: Offset(0, 4))
                    ]
                  : null,
            ),
            child: Text('$n',
                style: t(14, w: FontWeight.w800, c: on ? Colors.white : kInk)),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: t(12,
                  w: on ? FontWeight.w800 : FontWeight.w600,
                  c: on ? kInk : const Color(0xFF4B5873))),
        ]),
      );

  Widget line() => Expanded(
      child: Padding(
          padding: const EdgeInsets.only(top: 18),
          child: Container(height: 2, color: const Color(0xFFE3E7EE))));

  @override
  Widget build(BuildContext context) => RedPage(
        title: 'خدمة المعمل المنزلي',
        bottomBar: Padding(
          padding: EdgeInsets.fromLTRB(
              16, 8, 16, MediaQuery.of(context).padding.bottom + 14),
          child: RedButton('التالي',
              onTap: () {
                // TODO: implement next step
              }),
        ),
        body: ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 8), children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              step(1, 'التحاليل', true),
              line(),
              step(2, 'الموعد', false),
              line(),
              step(3, 'التأكيد', false),
            ]),
          ),
          const SizedBox(height: 22),
          Row(children: [
            Text('اختر التحاليل المطلوبة', style: t(15.5, w: FontWeight.w800)),
            const SizedBox(width: 6),
            chev(kGrey, 20),
          ]),
          const SizedBox(height: 12),
          const AppSearch('ابحث عن تحليل...',
              suffix: Icon(Icons.close_rounded, color: kInk, size: 20)),
          const SizedBox(height: 14),
          Container(
            decoration: cardBox(16),
            child: Column(children: [
              for (var i = 0; i < tests.length; i++)
                GestureDetector(
                  onTap: () => setState(
                      () => sel.contains(i) ? sel.remove(i) : sel.add(i)),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                        border: i == tests.length - 1
                            ? null
                            : const Border(
                                bottom:
                                    BorderSide(color: Color(0xFFF1F3F6)))),
                    child: Row(children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: sel.contains(i) ? kRed : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: sel.contains(i)
                              ? null
                              : Border.all(
                                  color: const Color(0xFFD5DAE2), width: 1.5),
                        ),
                        child: sel.contains(i)
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 16)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tests[i].$1,
                                  style: t(13.5, w: FontWeight.w800)),
                              Text('${tests[i].$2} ج.س',
                                  style: t(12.5,
                                      w: FontWeight.w500, c: kGrey)),
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
              Text('المزيد من التحاليل',
                  style: t(11.5, w: FontWeight.w700)),
            ]),
          ),
        ]),
      );
}

// ───────────────────────── 10. Profile / More ─────────────────────────
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Widget item(IconData i, String s, {int badge = 0}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFF1F3F6)))),
        child: Row(children: [
          Icon(i, color: kRed, size: 26),
          const SizedBox(width: 14),
          Expanded(
              child: Text(s,
                  style: t(14,
                      w: FontWeight.w700, c: const Color(0xFF3B4A68)))),
          if (badge > 0)
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              margin: const EdgeInsets.only(left: 4),
              decoration:
                  const BoxDecoration(color: kRed, shape: BoxShape.circle),
              child:
                  Text('$badge', style: t(11, w: FontWeight.w800, c: Colors.white)),
            ),
          chev(kInk, 20),
        ]),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        body: Column(children: [
          SizedBox(
            height: 150 + MediaQuery.of(context).padding.top,
            child: ClipPath(
                clipper: const SWaveClipper(),
                child:
                    Container(decoration: const BoxDecoration(gradient: kGradient))),
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
                width: 84,
                height: 84,
                decoration: const BoxDecoration(
                    color: Color(0xFFE3E7EE),
                    shape: BoxShape.circle,
                    boxShadow: kShadow),
                child: const Icon(Icons.person_rounded,
                    color: Color(0xFF6B7788), size: 56),
              ),
            ]),
          ),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 8), children: [
              Container(
                decoration: cardBox(18),
                clipBehavior: Clip.antiAlias,
                child: Column(children: [
                  item(Icons.event_available_outlined, 'مواعيدي'),
                  item(Icons.home_rounded, 'طلبات الخدمة المنزلية'),
                  item(Icons.notifications_none_rounded, 'إشعارات', badge: 3),
                  item(Icons.person_outline_rounded, 'المعلومات الشخصية'),
                  item(Icons.settings_outlined, 'الإعدادات'),
                  item(Icons.headset_mic_outlined, 'مساعدة ودعم'),
                ]),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(children: [
                  const Icon(Icons.logout_rounded, color: kRed, size: 24),
                  const SizedBox(width: 12),
                  Text('تسجيل الخروج',
                      style: t(13.5, w: FontWeight.w800, c: kRed)),
                ]),
              ),
            ]),
          ),
          // FIX #1: was {0, 3} which blocked both Home and More from navigating.
          const AppNav(active: {3}),
        ]),
      );
}
