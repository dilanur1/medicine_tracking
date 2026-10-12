import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'app_strings.dart';

// ───────────────────────── Helpers ─────────────────────────

String _two(int n) => n.toString().padLeft(2, '0');

String dateKey(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

String timeLabel(int minutes) => '${_two(minutes ~/ 60)}:${_two(minutes % 60)}';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

int daysBetween(DateTime a, DateTime b) =>
    DateTime.utc(b.year, b.month, b.day)
        .difference(DateTime.utc(a.year, a.month, a.day))
        .inDays;

// ───────────────────────── Model ─────────────────────────

class Medicine {
  final int id;
  String name;
  String dose;
  List<int> times; 
  bool enabled;
  final String startDate; 
  int? stockCount; // Kalan toplam hap sayısı
  int? treatmentMonths;
  int intervalDays;

  Medicine({
    required this.id,
    required this.name,
    required this.dose,
    required this.times,
    required this.startDate,
    this.enabled = true,
    this.stockCount,
    this.treatmentMonths,
    this.intervalDays = 1,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'dose': dose,
        'times': times,
        'enabled': enabled,
        'startDate': startDate,
        'stockCount': stockCount,
        'treatmentMonths': treatmentMonths,
        'intervalDays': intervalDays,
      };

  /// Bu ilaç [day] gününde alınmalı mı? (başlangıç tarihinden itibaren N günde bir)
  bool isDueOn(DateTime day) {
    final diff = daysBetween(DateTime.parse(startDate), day);
    if (diff < 0) return false;
    return intervalDays <= 1 || diff % intervalDays == 0;
  }

  /// [from] gününden (dahil) itibaren ilk [count] doz gününü döndürür.
  List<DateTime> nextDueDays(DateTime from, int count) {
    final step = intervalDays < 1 ? 1 : intervalDays;
    final start = dateOnly(DateTime.parse(startDate));
    final diff = daysBetween(start, from);
    final offset = diff <= 0 ? 0 : ((diff + step - 1) ~/ step) * step;
    return [
      for (var k = 0; k < count; k++)
        DateTime(start.year, start.month, start.day + offset + k * step),
    ];
  }
  factory Medicine.fromJson(Map<String, dynamic> j) => Medicine(
        id: j['id'],
        name: j['name'],
        dose: j['dose'],
        times: List<int>.from(j['times']),
        enabled: j['enabled'] ?? true,
        startDate: j['startDate'],
        stockCount: j['stockCount'],
        treatmentMonths: j['treatmentMonths'],
        intervalDays: j['intervalDays'] ?? 1,
        
      );
}

class Dose {
  final Medicine med;
  final int minutes;
  Dose(this.med, this.minutes);
}

// ───────────────────── Interval (days) picker ─────────────────────

/// "Her gün" / "N günde bir" seçimi. Ekleme ve düzenleme dialoglarında ortak.
class IntervalDaysPicker extends StatefulWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const IntervalDaysPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<IntervalDaysPicker> createState() => _IntervalDaysPickerState();
}

class _IntervalDaysPickerState extends State<IntervalDaysPicker> {
  late bool _custom = widget.value > 1;
  late final TextEditingController _controller = TextEditingController(
    text: widget.value > 1 ? widget.value.toString() : '2',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _parsed => (int.tryParse(_controller.text) ?? 1).clamp(1, 365).toInt();

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Column(
      children: [
        DropdownButtonFormField<bool>(
          value: _custom,
          decoration: InputDecoration(labelText: s.intervalDaysLabel),
          items: [
            DropdownMenuItem(value: false, child: Text(s.everyDay)),
            DropdownMenuItem(value: true, child: Text(s.customInterval)),
          ],
          onChanged: (val) {
            setState(() => _custom = val ?? false);
            widget.onChanged(_custom ? _parsed : 1);
          },
        ),
        if (_custom) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: s.intervalDaysLabel),
            onChanged: (_) => widget.onChanged(_parsed),
          ),
        ],
      ],
    );
  }
}
class MedicineDialog extends StatefulWidget {
  final Medicine? existingMedicine; // Eğer düzenleme yapılacaksa dolu gelir

  const MedicineDialog({super.key, this.existingMedicine});

  @override
  State<MedicineDialog> createState() => _MedicineDialogState();
}

class _MedicineDialogState extends State<MedicineDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _doseController;
  late final TextEditingController _stockController;
  late final TextEditingController _monthController;
  late int _intervalDays;
  late List<int> _times;

  @override
  void initState() {
    super.initState();
    // Eğer düzenleme modundaysak alanları eski verilerle dolduruyoruz:
    final m = widget.existingMedicine;
    _nameController = TextEditingController(text: m?.name ?? '');
    _doseController = TextEditingController(text: m?.dose ?? '');
    _stockController = TextEditingController(text: m?.stockCount?.toString() ?? '');
    _monthController = TextEditingController(text: m?.treatmentMonths?.toString() ?? '');
    _intervalDays = m?.intervalDays ?? 1;
    _times = m != null ? List<int>.from(m.times) : [8 * 60]; // dakika cinsinden
  }

  void _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null) {
      final minutes = picked.hour * 60 + picked.minute;
      if (!_times.contains(minutes)) {
        setState(() {
          _times.add(minutes);
          _times.sort();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isEditing = widget.existingMedicine != null;

    return AlertDialog(
      title: Text(isEditing ? s.editMedicine : s.newMedicine),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: s.medicineName),
            ),
            TextField(
              controller: _doseController,
              decoration: InputDecoration(labelText: s.doseHint),
            ),
            TextField(
              controller: _stockController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: s.stockCount),
            ),
            TextField(
              controller: _monthController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: s.treatmentDuration),
            ),
            const SizedBox(height: 16),
            // SAATLER BÖLÜMÜ:
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(s.addTime, style: const TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add_alarm),
                  onPressed: _pickTime,
                ),
              ],
            ),
            Wrap(
              spacing: 8.0,
              children: _times.map((t) {
                return Chip(
                  label: Text(timeLabel(t)),
                  onDeleted: () {
                    setState(() {
                      _times.remove(t);
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            IntervalDaysPicker(
              value: _intervalDays,
              onChanged: (v) => _intervalDays = v,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.trim().isEmpty) return;

            // Yeni nesne oluştur veya mevcut ID'yi koruyarak güncelle
            final updatedMedicine = Medicine(
              id: widget.existingMedicine?.id ?? DateTime.now().millisecondsSinceEpoch,
              name: _nameController.text.trim(),
              dose: _doseController.text.trim(),
              times: _times,
              startDate: widget.existingMedicine?.startDate ?? DateTime.now().toIso8601String(),
              stockCount: int.tryParse(_stockController.text),
              treatmentMonths: int.tryParse(_monthController.text),
              intervalDays: _intervalDays,
              enabled: widget.existingMedicine?.enabled ?? true,
            );

            Navigator.pop(context, updatedMedicine);
          },
          child: Text(isEditing ? s.update : s.save),
        ),
      ],
    );
  }
}

// ───────────────────── Notification service ─────────────────────

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  AppStrings get _strings =>
      AppStrings.forLocale(ui.PlatformDispatcher.instance.locale);

  Future<void> init() async {
    tzdata.initializeTimeZones();
    final localName =
        (await FlutterTimezone.getLocalTimezone()).identifier;
    tz.setLocalLocation(tz.getLocation(localName));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  Future<void> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    try {
      await android?.requestExactAlarmsPermission();
    } catch (_) {}
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  // Bildirim kimliği: her ilaç için 10000'lik bir blok.
  // Blok içi: doz günü sırası * 100 + saat sırası
  static const _idBlock = 10000;

  // N günde bir alınan ilaçlar için kaç doz günü önceden kurulacak.
  // (Uygulama her açıldığında yenilenir.)
  static const _intervalOccurrences = 10;

  int _notifId(Medicine m, int occurrence, int timeIndex) =>
      m.id * _idBlock + occurrence * 100 + timeIndex;

  tz.TZDateTime _at(DateTime day, int minutes) => tz.TZDateTime(
      tz.local, day.year, day.month, day.day, minutes ~/ 60, minutes % 60);

  Future<void> scheduleMedicine(Medicine m) async {
    final s = _strings;
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'medicine_channel',
        s.channelName,
        channelDescription: s.channelDesc,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );
    final body = '${m.name}${m.dose.isNotEmpty ? ' – ${m.dose}' : ''}';
    final now = tz.TZDateTime.now(tz.local);
    final today = DateTime(now.year, now.month, now.day);

    if (m.intervalDays <= 1) {
      // Her gün: saat başına günlük tekrar eden bildirim
      for (var i = 0; i < m.times.length; i++) {
        var when = _at(today, m.times[i]);
        if (when.isBefore(now)) when = when.add(const Duration(days: 1));
        await _schedule(
          id: _notifId(m, 0, i),
          title: s.notifTitle,
          body: body,
          when: when,
          details: details,
          repeatDaily: true,
        );
      }
      return;
    }

    // N günde bir: tekrar eden bildirim yok, yaklaşan doz günleri tek tek kurulur
    final days = m.nextDueDays(today, _intervalOccurrences);
    for (var o = 0; o < days.length; o++) {
      for (var i = 0; i < m.times.length; i++) {
        final when = _at(days[o], m.times[i]);
        if (when.isBefore(now)) continue;
        await _schedule(
          id: _notifId(m, o, i),
          title: s.notifTitle,
          body: body,
          when: when,
          details: details,
        );
      }
    }
  }

  Future<void> cancelMedicine(Medicine m) async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final p in pending) {
      if (p.id ~/ _idBlock == m.id) await _plugin.cancel(p.id);
    }
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime when,
    required NotificationDetails details,
    bool repeatDaily = false,
  }) async {
    Future<void> go(AndroidScheduleMode mode) => _plugin.zonedSchedule(
          id,
          title,
          body,
          when,
          details,
          androidScheduleMode: mode,
          matchDateTimeComponents: repeatDaily ? DateTimeComponents.time : null,
        );

    try {
      await go(AndroidScheduleMode.exactAllowWhileIdle);
    } catch (_) {
      await go(AndroidScheduleMode.inexactAllowWhileIdle);
    }
  }
}

// ───────────────────────── App ─────────────────────────

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  runApp(const MedicineApp());
}

ValueNotifier<Locale?> appLocaleNotifier = ValueNotifier<Locale?>(null);

class MedicineApp extends StatelessWidget {
  const MedicineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale?>(
      valueListenable: appLocaleNotifier,
      builder: (context, currentLocale, child) {
        return MaterialApp(
          onGenerateTitle: (context) => AppStrings.of(context).appTitle,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorSchemeSeed: Colors.teal,
            useMaterial3: true,
          ),
          locale: currentLocale, // Kullanıcının seçtiği veya sistem dili
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('tr', 'TR'),
            Locale('en', 'US'),
            Locale('de', 'DE'),
            Locale('es', 'ES'),
            Locale('fr', 'FR'),
            Locale('it', 'IT'),
            Locale('ru', 'RU'),
            Locale('zh', 'CN'),
            Locale('ja', 'JP'),
            Locale('ar', 'SA'),
          ],
          home: const HomePage(),
        );
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  static const _medsKey = 'medicines_v2';
  static const _takenKey = 'taken_v2';
  static const _nextIdKey = 'next_id_v2';

  static const _center = 10000;
  static const _pageCount = _center * 2 + 1;

  final List<Medicine> _meds = [];
  final Set<String> _taken = {}; 
  int _nextId = 1;
  bool _loading = true;
  int _tab = 0;

  late DateTime _today = dateOnly(DateTime.now());
  late final PageController _pageController =
      PageController(initialPage: _center);
  int _pageIndex = _center;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationService.instance.requestPermission();
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || _loading) return;
    final now = dateOnly(DateTime.now());
    if (now != _today) {
      setState(() => _today = now);
      if (_pageController.hasClients) _pageController.jumpToPage(_center);
    } else {
      setState(() {}); 
    }
    _rescheduleAll();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_medsKey);
    if (raw != null) {
      _meds.addAll((jsonDecode(raw) as List)
          .map((e) => Medicine.fromJson(e as Map<String, dynamic>)));
      _taken.addAll(prefs.getStringList(_takenKey) ?? []);
      _nextId = prefs.getInt(_nextIdKey) ?? 1;
    } else {
      await NotificationService.instance.cancelAll();
    }
    setState(() => _loading = false);
    _rescheduleAll();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _medsKey, jsonEncode(_meds.map((e) => e.toJson()).toList()));
    await prefs.setStringList(_takenKey, _taken.toList());
    await prefs.setInt(_nextIdKey, _nextId);
  }

  Future<void> _rescheduleAll() async {
    // Eski/yetim bildirimleri temizle, aktif ilaçlar için baştan kur.
    // (N günde bir alınan ilaçların yaklaşan bildirimleri de böylece yenilenir.)
    await NotificationService.instance.cancelAll();
    for (final m in _meds.where((m) => m.enabled)) {
      await NotificationService.instance.scheduleMedicine(m);
    }
  }

  Future<void> _addMedicine() async {
    final draft = await showDialog<_MedicineDraft>(
      context: context,
      builder: (_) => const _AddDialog(),
    );
    if (draft == null) return;

    final m = Medicine(
      id: _nextId++,
      name: draft.name,
      dose: draft.dose,
      times: draft.times,
      intervalDays: draft.intervalDays,
      startDate: dateKey(dateOnly(DateTime.now())),
    );
    setState(() => _meds.add(m));
    await NotificationService.instance.scheduleMedicine(m);
    await _save();
  }

  Future<void> _toggleEnabled(Medicine m, bool value) async {
    setState(() => m.enabled = value);
    if (value) {
      await NotificationService.instance.scheduleMedicine(m);
    } else {
      await NotificationService.instance.cancelMedicine(m);
    }
    await _save();
  }

  Future<void> _deleteMedicine(Medicine m) async {
    setState(() {
      _meds.remove(m);
      _taken.removeWhere((k) => k.split('|')[1] == m.id.toString());
    });
    await NotificationService.instance.cancelMedicine(m);
    await _save();
  }

  Future<void> _setTaken(String key, bool value) async {
    setState(() => value ? _taken.add(key) : _taken.remove(key));
    await _save();
  }

  DateTime _dayForIndex(int i) =>
      DateTime(_today.year, _today.month, _today.day + (i - _center));

  void _goTo(int index) {
    if (index < 0 || index >= _pageCount || !_pageController.hasClients) return;
    if ((index - _pageIndex).abs() > 3) {
      _pageController.jumpToPage(index);
    } else {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dayForIndex(_pageIndex),
      firstDate: _dayForIndex(0),
      lastDate: _dayForIndex(_pageCount - 1),
    );
    if (picked != null) _goTo(_center + daysBetween(_today, picked));
  }

  void _openEditDialog(BuildContext context, Medicine medicine) async {
    final result = await showDialog<Medicine>(
      context: context,
      builder: (context) => MedicineDialog(existingMedicine: medicine),
    );
    if (result == null) return;

    // Eski bildirimleri iptal et, yeni ayarlarla tekrar kur, kaydet
    await NotificationService.instance.cancelMedicine(medicine);
    setState(() {
      final index = _meds.indexWhere((m) => m.id == result.id);
      if (index != -1) _meds[index] = result;
    });
    if (result.enabled) {
      await NotificationService.instance.scheduleMedicine(result);
    }
    await _save();
  }

  void _completelyDeleteMedicine(BuildContext context, Medicine medicine) {
    final s = AppStrings.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.delete),
        content: Text(s.deleteConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () {
              _deleteMedicine(medicine);
              Navigator.pop(context);
            },
            child: Text(s.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  List<Dose> _dosesFor(DateTime day) {
    final list = <Dose>[];
    for (final m in _meds) {
      if (!m.enabled || !m.isDueOn(day)) continue;
      for (final t in m.times) {
        list.add(Dose(m, t));
      }
    }
    list.sort((a, b) => a.minutes.compareTo(b.minutes));
    return list;
  }

  String _doseKey(String day, Dose d) => '$day|${d.med.id}|${d.minutes}';

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_tab == 0 ? s.dailyDoses : s.myMedicines),
        actions: [
          if (_tab == 0 && _pageIndex != _center)
            TextButton.icon(
              onPressed: () => _goTo(_center),
              icon: const Icon(Icons.today),
              label: Text(s.today),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMedicine,
        icon: const Icon(Icons.add),
        label: Text(s.addMedicine),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.today), label: s.navDaily),
          NavigationDestination(
              icon: const Icon(Icons.medication), label: s.navMedicines),
          NavigationDestination(icon: const Icon(Icons.settings), label: s.settings),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _tab,
              children: [_buildDailyTab(s), _buildMedicinesTab(s), _buildSettingsTab(s)],
            ),
    );
  }

  Widget _buildDailyTab(AppStrings s) {
    final diff = _pageIndex - _center;
    final relative = diff == 0
        ? s.today
        : diff == -1
            ? s.yesterday
            : diff == 1
                ? s.tomorrow
                : null;

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _goTo(_pageIndex - 1),
            ),
            Expanded(
              child: InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      Text(
                        s.prettyDate(_dayForIndex(_pageIndex)),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (relative != null)
                        Text(
                          relative,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _goTo(_pageIndex + 1),
            ),
          ],
        ),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: _pageCount,
            onPageChanged: (i) => setState(() => _pageIndex = i),
            itemBuilder: (_, i) => _buildDay(s, _dayForIndex(i)),
          ),
        ),
      ],
    );
  }

  Widget _buildDay(AppStrings s, DateTime day) {
    final doses = _dosesFor(day);
    if (doses.isEmpty) {
      return Center(child: Text(s.noDoses));
    }

    final key = dateKey(day);
    final isPast = day.isBefore(_today);
    final isFuture = day.isAfter(_today);
    final isToday = !isPast && !isFuture;
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final errorColor = Theme.of(context).colorScheme.error;

    final takenCount =
        doses.where((d) => _taken.contains(_doseKey(key, d))).length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.takenOf(takenCount, doses.length)),
              const SizedBox(height: 6),
              LinearProgressIndicator(value: takenCount / doses.length),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 90),
            itemCount: doses.length,
            itemBuilder: (_, i) {
              final d = doses[i];
              final k = _doseKey(key, d);
              final taken = _taken.contains(k);
              final overdue =
                  !taken && (isPast || (isToday && d.minutes < nowMinutes));

              final parts = <String>[
                if (d.med.dose.isNotEmpty) d.med.dose,
                if (overdue) (isPast ? s.missed : s.notTakenYet),
              ];

              return CheckboxListTile(
                value: taken,
                onChanged: isFuture ? null : (v) => _setTaken(k, v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  '${timeLabel(d.minutes)}   ${d.med.name}',
                  style: TextStyle(
                    decoration: taken ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: parts.isEmpty
                    ? null
                    : Text(
                        parts.join(' • '),
                        style: overdue ? TextStyle(color: errorColor) : null,
                      ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMedicinesTab(AppStrings s) {
    if (_meds.isEmpty) {
      return Center(child: Text(s.noMedicine));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 90),
      itemCount: _meds.length,
      itemBuilder: (_, i) {
        final m = _meds[i];
        return Dismissible(
          key: ValueKey(m.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => _deleteMedicine(m),
          child: ListTile(
            onTap: () => _openEditDialog(context, m),
            title: Text(m.name),
            subtitle: Text([
              if (m.dose.isNotEmpty) m.dose,
              m.times.map(timeLabel).join(', '),
            ].join('\n')),
            isThreeLine: m.dose.isNotEmpty,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _completelyDeleteMedicine(context, m), // 👈 Silme fonksiyonu burada!
                ),
                Switch(
                  value: m.enabled,
                  onChanged: (v) => _toggleEnabled(m, v),
                ),
                
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsTab(AppStrings s) {
    final s = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.settings),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(s.language),
            trailing: DropdownButton<String>(
              value: appLocaleNotifier.value?.languageCode ?? 'tr',
              items: const [
                DropdownMenuItem(value: 'tr', child: Text('Türkçe')),
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'de', child: Text('Deutsch')),
                DropdownMenuItem(value: 'es', child: Text('Español')),
                DropdownMenuItem(value: 'fr', child: Text('Français')),
                DropdownMenuItem(value: 'it', child: Text('Italiano')),
                DropdownMenuItem(value: 'ru', child: Text('Русский')),
                DropdownMenuItem(value: 'zh', child: Text('中文')),
                DropdownMenuItem(value: 'ja', child: Text('日本語')),
                DropdownMenuItem(value: 'ar', child: Text('العربية')),
              ],
              onChanged: (langCode) {
                if (langCode != null) {
                  appLocaleNotifier.value = Locale(langCode);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────── Add medicine dialog ─────────────────────

class _MedicineDraft {
  final String name;
  final String dose;
  final List<int> times;
  final int intervalDays;
  _MedicineDraft(this.name, this.dose, this.times, this.intervalDays);
}

class _AddDialog extends StatefulWidget {
  const _AddDialog();

  @override
  State<_AddDialog> createState() => _AddDialogState();
}

class _AddDialogState extends State<_AddDialog> {
  static const _maxTimes = 24;

  final _name = TextEditingController();
  final _dose = TextEditingController();
  final _stockController = TextEditingController();
  final _monthController = TextEditingController();

  bool _useInterval = false;
  TimeOfDay _firstDose = const TimeOfDay(hour: 8, minute: 0);
  int _intervalHours = 8;
  int _intervalDays = 1;
  final List<int> _manualTimes = [];
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _dose.dispose();
    super.dispose();
  }

  List<int> _intervalTimes() {
    final result = <int>[];
    for (var t = _firstDose.hour * 60 + _firstDose.minute;
        t < 24 * 60;
        t += _intervalHours * 60) {
      result.add(t);
    }
    return result;
  }

  Future<void> _addManualTime() async {
    if (_manualTimes.length >= _maxTimes) return;
    final t = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (t == null) return;
    final minutes = t.hour * 60 + t.minute;
    if (_manualTimes.contains(minutes)) return;
    setState(() {
      _manualTimes.add(minutes);
      _manualTimes.sort();
      _error = null;
    });
  }

  Future<void> _pickFirstDose() async {
    final t = await showTimePicker(context: context, initialTime: _firstDose);
    if (t != null) setState(() => _firstDose = t);
  }

  void _save() {
    final s = AppStrings.of(context);
    final name = _name.text.trim();
    final times = _useInterval ? _intervalTimes() : List<int>.of(_manualTimes);
    if (name.isEmpty) {
      setState(() => _error = s.enterName);
      return;
    }
    if (times.isEmpty) {
      setState(() => _error = s.addAtLeastOne);
      return;
    }
    Navigator.pop(
        context, _MedicineDraft(name, _dose.text.trim(), times, _intervalDays));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return AlertDialog(
      title: Text(s.newMedicine),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _name,
              decoration: InputDecoration(labelText: s.medicineName),
              textCapitalization: TextCapitalization.sentences,
            ),
            TextField(
              controller: _dose,
              decoration: InputDecoration(labelText: s.doseHint),
            ),
            TextField(
              controller: _stockController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: s.stockCount), // Örn: 30 hap
            ),
            TextField(
              controller: _monthController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: s.treatmentDuration), // Örn: 3 ay
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(s.repeatEvery),
              value: _useInterval,
              onChanged: (v) => setState(() {
                _useInterval = v ?? false;
                _error = null;
              }),
            ),
            if (_useInterval) ...[
              OutlinedButton.icon(
                icon: const Icon(Icons.access_time),
                label: Text(s.firstDose(_firstDose.format(context))),
                onPressed: _pickFirstDose,
              ),
              Row(
                children: [
                  Text(s.every),
                  DropdownButton<int>(
                    value: _intervalHours,
                    items: [
                      for (var h = 1; h <= 24; h++)
                        DropdownMenuItem(value: h, child: Text('$h')),
                    ],
                    onChanged: (v) => setState(() => _intervalHours = v!),
                  ),
                  Text(s.hoursSuffix),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                s.reminders(_intervalTimes().map(timeLabel).join(', ')),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ] else ...[
              Wrap(
                spacing: 8,
                children: [
                  for (final t in _manualTimes)
                    InputChip(
                      label: Text(timeLabel(t)),
                      onDeleted: () => setState(() => _manualTimes.remove(t)),
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 18),
                    label: Text(s.addTime),
                    onPressed: _addManualTime,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            IntervalDaysPicker(
              value: _intervalDays,
              onChanged: (v) => _intervalDays = v,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.cancel),
        ),
        FilledButton(onPressed: _save, child: Text(s.save)),
      ],
    );
  }
}