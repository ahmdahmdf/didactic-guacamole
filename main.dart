import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const TawheedApp());
}

class TawheedApp extends StatefulWidget {
  const TawheedApp({super.key});

  @override
  State<TawheedApp> createState() => _TawheedAppState();
}

class _TawheedAppState extends State<TawheedApp> {
  bool darkMode = false;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF145A45);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'كتاب التوحيد',
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: green),
        scaffoldBackgroundColor: const Color(0xFFF7F6F0),
        appBarTheme: const AppBarTheme(
          backgroundColor: green,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF68B69A),
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(centerTitle: true),
        useMaterial3: true,
      ),
      home: HomePage(
        darkMode: darkMode,
        onThemeChanged: (value) => setState(() => darkMode = value),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final bool darkMode;
  final ValueChanged<bool> onThemeChanged;

  const HomePage({
    super.key,
    required this.darkMode,
    required this.onThemeChanged,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int lastPage = 0;
  List<int> favorites = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      lastPage = prefs.getInt('last_page') ?? 0;
      favorites = prefs.getStringList('favorites')?.map(int.parse).toList() ?? [];
      loading = false;
    });
  }

  Future<void> _openReader({int page = 0}) async {
    final result = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (_) => ReaderPage(initialPage: page)),
    );
    if (result != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_page', result);
      if (mounted) setState(() => lastPage = result);
    }
    await _loadSavedData();
  }

  Future<void> _showFavorites() async {
    if (favorites.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لم تضف صفحات إلى المفضلة بعد')),
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('الصفحات المفضلة',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              ...favorites.map((p) => ListTile(
                    leading: const Icon(Icons.bookmark),
                    title: Text('الصفحة ${p + 1}'),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () {
                      Navigator.pop(ctx);
                      _openReader(page: p);
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('كتاب التوحيد'),
          actions: [
            IconButton(
              tooltip: 'الوضع الليلي',
              onPressed: () => widget.onThemeChanged(!widget.darkMode),
              icon: Icon(widget.darkMode ? Icons.light_mode : Icons.dark_mode),
            ),
          ],
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF145A45), Color(0xFF24775C)],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.menu_book_rounded,
                            size: 74, color: Color(0xFFFFD980)),
                        SizedBox(height: 16),
                        Text(
                          'كتاب التوحيد',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'الذي هو حق الله على العبيد',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'للشيخ محمد بن عبد الوهاب رحمه الله',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _ActionCard(
                    icon: Icons.menu_book,
                    title: 'ابدأ قراءة الكتاب',
                    subtitle: 'افتح الكتاب من الصفحة الأولى',
                    onTap: () => _openReader(),
                  ),
                  _ActionCard(
                    icon: Icons.history,
                    title: 'متابعة القراءة',
                    subtitle: 'آخر موضع محفوظ: الصفحة ${lastPage + 1}',
                    onTap: () => _openReader(page: lastPage),
                  ),
                  _ActionCard(
                    icon: Icons.bookmark,
                    title: 'الصفحات المفضلة',
                    subtitle: '${favorites.length} صفحة محفوظة',
                    onTap: _showFavorites,
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'ملاحظة: هذه النسخة تعرض صفحات PDF الأصلية. البحث النصي والفهرس التفصيلي يحتاجان إلى استخراج النص من النسخة المصوّرة ومراجعته.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'يعمل الكتاب من داخل التطبيق دون الحاجة إلى اتصال بالإنترنت.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_left),
        onTap: onTap,
      ),
    );
  }
}

class ReaderPage extends StatefulWidget {
  final int initialPage;
  const ReaderPage({super.key, required this.initialPage});

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  PDFViewController? controller;
  String? pdfPath;
  int currentPage = 0;
  int totalPages = 0;
  bool loading = true;
  bool isFavorite = false;
  List<int> favorites = [];

  @override
  void initState() {
    super.initState();
    currentPage = widget.initialPage;
    _preparePdf();
    _loadFavorites();
  }

  Future<void> _preparePdf() async {
    try {
      final data = await rootBundle.load('assets/kitab_at_tawheed.pdf');
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/kitab_at_tawheed.pdf');
      if (!await file.exists()) {
        await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
      }
      if (!mounted) return;
      setState(() {
        pdfPath = file.path;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر فتح الكتاب: $e')),
      );
    }
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      favorites = prefs.getStringList('favorites')?.map(int.parse).toList() ?? [];
      isFavorite = favorites.contains(currentPage);
    });
  }

  Future<void> _toggleFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (favorites.contains(currentPage)) {
        favorites.remove(currentPage);
        isFavorite = false;
      } else {
        favorites.add(currentPage);
        favorites.sort();
        isFavorite = true;
      }
    });
    await prefs.setStringList('favorites', favorites.map((e) => e.toString()).toList());
  }

  Future<void> _saveAndExit() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_page', currentPage);
    if (mounted) Navigator.pop(context, currentPage);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(totalPages > 0
              ? 'الصفحة ${currentPage + 1} من $totalPages'
              : 'قراءة الكتاب'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: _saveAndExit,
          ),
          actions: [
            IconButton(
              tooltip: isFavorite ? 'إزالة من المفضلة' : 'إضافة للمفضلة',
              onPressed: _toggleFavorite,
              icon: Icon(isFavorite ? Icons.bookmark : Icons.bookmark_border),
            ),
          ],
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : pdfPath == null
                ? const Center(child: Text('تعذر تحميل ملف الكتاب'))
                : PDFView(
                    filePath: pdfPath!,
                    defaultPage: widget.initialPage,
                    enableSwipe: true,
                    swipeHorizontal: false,
                    autoSpacing: true,
                    pageFling: true,
                    pageSnap: true,
                    fitPolicy: FitPolicy.BOTH,
                    onViewCreated: (c) => controller = c,
                    onRender: (pages) {
                      if (!mounted) return;
                      setState(() => totalPages = pages ?? 0);
                    },
                    onPageChanged: (page, pages) {
                      if (!mounted || page == null) return;
                      setState(() {
                        currentPage = page;
                        totalPages = pages ?? totalPages;
                        isFavorite = favorites.contains(page);
                      });
                    },
                    onError: (error) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('خطأ في عرض PDF: $error')),
                        );
                      }
                    },
                  ),
        bottomNavigationBar: pdfPath == null
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        tooltip: 'الصفحة السابقة',
                        onPressed: currentPage > 0
                            ? () => controller?.setPage(currentPage - 1)
                            : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                      Text('${currentPage + 1} / ${totalPages == 0 ? '…' : totalPages}'),
                      IconButton(
                        tooltip: 'الصفحة التالية',
                        onPressed: totalPages == 0 || currentPage >= totalPages - 1
                            ? null
                            : () => controller?.setPage(currentPage + 1),
                        icon: const Icon(Icons.chevron_left),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
