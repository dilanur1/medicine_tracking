import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'app_strings.dart';
import 'ad_service.dart';
import 'premium_service.dart';

// ───────────────── Yayın ayarları (YAYINLAMADAN ÖNCE DEĞİŞTİR) ─────────────────

/// Gizlilik politikası sayfanızın herkese açık adresi (Play Console'a da aynısını girin).
const kPrivacyPolicyUrl = 'https://dilanur1.github.io/medicine_tracking/privacy-policy.html';

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

/// Eski kayıtlardaki "tedavi süresi (ay)" değerini bitiş tarihine çevirir.
String? _legacyEndDate(Map<String, dynamic> j) {
  final months = j['treatmentMonths'];
  if (months is! int || months <= 0) return null;
  final start = DateTime.parse(j['startDate']);
  return dateKey(DateTime(start.year, start.month + months, start.day));
}

class Medicine {
  final int id;
  String name;
  String dose;
  List<int> times; 
  bool enabled;
  final String startDate; 
  int? stockCount; // Kalan toplam hap sayısı
  String? endDate; // yyyy-MM-dd, null = süresiz
  int meal; // 0: aç veya tok, 1: aç, 2: tok
  int intervalDays;

  Medicine({
    required this.id,
    required this.name,
    required this.dose,
    required this.times,
    required this.startDate,
    this.enabled = true,
    this.stockCount,
    this.endDate,
    this.intervalDays = 1,
    this.meal = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'dose': dose,
        'times': times,
        'enabled': enabled,
        'startDate': startDate,
        'stockCount': stockCount,
        'endDate': endDate,
        'intervalDays': intervalDays,
        'meal': meal,
      };

  DateTime? get endDay => endDate == null ? null : DateTime.parse(endDate!);

  /// Kalan hap, bu kadar dozun altına düşünce "bitmek üzere" sayılır (3 doz günü).
  int get lowStockThreshold => times.length * 3;

  bool get isStockLow =>
      stockCount != null && times.isNotEmpty && stockCount! <= lowStockThreshold;

  /// Bu ilaç [day] gününde alınmalı mı? (başlangıç tarihinden itibaren N günde bir)
  bool isDueOn(DateTime day) {
    final diff = daysBetween(DateTime.parse(startDate), day);
    if (diff < 0) return false;
    final end = endDay;
    if (end != null && daysBetween(end, day) > 0) return false;
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
        endDate: j['endDate'] ?? _legacyEndDate(j),
        intervalDays: j['intervalDays'] ?? 1,
        meal: j['meal'] ?? 0,
      );
}

class Dose {
  final Medicine med;
  final int minutes;
  Dose(this.med, this.minutes);
}

// ───────────────────── Interval (days) picker ─────────────────────

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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<bool>(
          value: _custom,
          isExpanded: true, // Metin uzunsa alta kaymasını veya sığmasını sağlar
          decoration: InputDecoration(
            labelText: s.intervalDaysLabel,
            labelStyle: const TextStyle(fontSize: 13), // Almanca uzunluklar için yazı boyutunu biraz küçültebiliriz
          ),
          items: [
            DropdownMenuItem(value: false, child: Text(s.everyDay, overflow: TextOverflow.ellipsis)),
            DropdownMenuItem(value: true, child: Text(s.customInterval, overflow: TextOverflow.ellipsis)),
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
            decoration: InputDecoration(
              labelText: s.intervalDaysLabel,
              labelStyle: const TextStyle(fontSize: 13),
            ),
            onChanged: (_) => widget.onChanged(_parsed),
          ),
        ],
      ],
    );
  }
}

/// Aç / tok / fark etmez seçimi.
class MealPicker extends StatelessWidget {
  final int value; // 0: aç veya tok, 1: aç, 2: tok
  final ValueChanged<int> onChanged;

  const MealPicker({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final options = {1: s.mealEmpty, 2: s.mealFull, 0: s.mealAny};
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.meal, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: [
              for (final e in options.entries)
                ChoiceChip(
                  label: Text(e.value),
                  selected: value == e.key,
                  onSelected: (_) => onChanged(e.key),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// İsteğe bağlı tedavi bitiş tarihi seçici.
class TreatmentEndPicker extends StatelessWidget {
  final String? value; // yyyy-MM-dd
  final ValueChanged<String?> onChanged;

  const TreatmentEndPicker(
      {super.key, required this.value, required this.onChanged});

  Future<void> _pick(BuildContext context) async {
    final today = dateOnly(DateTime.now());
    final current = value == null ? null : DateTime.parse(value!);
    final picked = await showDatePicker(
      context: context,
      initialDate: (current != null && !current.isBefore(today))
          ? current
          : today.add(const Duration(days: 7)),
      firstDate: today,
      lastDate: DateTime(today.year + 5, today.month, today.day),
    );
    if (picked != null) onChanged(dateKey(picked));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final text = value == null
        ? s.endNone
        : MaterialLocalizations.of(context)
            .formatMediumDate(DateTime.parse(value!));
    return InkWell(
      onTap: () => _pick(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: s.endLabel,
          suffixIcon: value == null
              ? const Icon(Icons.calendar_today)
              : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => onChanged(null),
                ),
        ),
        child: Text(text),
      ),
    );
  }
}

class MedicineDialog extends StatefulWidget {
  final Medicine? existingMedicine;

  const MedicineDialog({super.key, this.existingMedicine});

  @override
  State<MedicineDialog> createState() => _MedicineDialogState();
}

class _MedicineDialogState extends State<MedicineDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _doseController;
  late final TextEditingController _stockController;

  late int _intervalDays;
  String? _endDate;
  late int _meal;
  late List<int> _times;

  @override
  void initState() {
    super.initState();
    final m = widget.existingMedicine;
    _nameController = TextEditingController(text: m?.name ?? '');
    _doseController = TextEditingController(text: m?.dose ?? '');
    _stockController = TextEditingController(text: m?.stockCount?.toString() ?? '');
    _endDate = m?.endDate;
    _meal = m?.meal ?? 0;
    _intervalDays = m?.intervalDays ?? 1;
    _times = m != null ? List<int>.from(m.times) : [8 * 60];
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
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: s.stockLabel,
                helperText: s.stockHelp,
                helperMaxLines: 2,
              ),
            ),
            const SizedBox(height: 8),
            TreatmentEndPicker(
              value: _endDate,
              onChanged: (v) => setState(() => _endDate = v),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(s.addTime, style: const TextStyle(fontWeight: FontWeight.bold)),
                ElevatedButton(
                  onPressed: _pickTime,
                  style: ElevatedButton.styleFrom(
                    
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // Hafif yuvarlatılmış köşeler
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1), // İç boşluk
                  ),
                  child: const Icon(Icons.add_alarm),
                )
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
            const SizedBox(height: 12),
            MealPicker(
              value: _meal,
              onChanged: (v) => setState(() => _meal = v),
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
            final updatedMedicine = Medicine(
              id: widget.existingMedicine?.id ?? DateTime.now().millisecondsSinceEpoch,
              name: _nameController.text.trim(),
              dose: _doseController.text.trim(),
              times: _times,
              startDate: widget.existingMedicine?.startDate ?? DateTime.now().toIso8601String(),
              stockCount: int.tryParse(_stockController.text),
              endDate: _endDate,
              meal: _meal,
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

  static const actionTaken = 'action_taken';

  static void Function(String actionId, int medId, int minutes, int occurrence)? onNotificationAction;

  AppStrings get _strings =>
      AppStrings.forLocale(
          appLocaleNotifier.value ?? ui.PlatformDispatcher.instance.locale);

  Future<void> init() async {
    tzdata.initializeTimeZones();
    final localName =
        (await FlutterTimezone.getLocalTimezone()).identifier;
    tz.setLocalLocation(tz.getLocation(localName));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final s = _strings;
    final ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          'medicine_category',
          actions: [
            DarwinNotificationAction.plain(actionTaken, s.take),
          ],
        )
      ],
    );
    await _plugin.initialize(
      InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: backgroundNotificationResponseHandler,
    );
  }

  static void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;
    
    final parts = payload.split('|');
    if (parts.length < 3) return;

    final medId = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    final occurrence = int.tryParse(parts[2]) ?? 0;
    final actionId = response.actionId;

    if (actionId != null) {
      onNotificationAction?.call(actionId, medId, minutes, occurrence);
    }
  }

  // NotificationService sınıfına eklenecek metod:
  Future<void> showInstantTestNotification(Medicine m) async {
    final s = _strings;
    final details = _details(m.id, m.times.isNotEmpty ? m.times[0] : 0, 0);
    
    final body = [
      '${m.name}${m.dose.isNotEmpty ? ' – ${m.dose}' : ''}',
      if (m.meal != 0) s.mealLabel(m.meal),
    ].join(' • ');

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      s.notifTitle,
      body,
      details,
      payload: '${m.id}|${m.times.isNotEmpty ? m.times[0] : 0}|0',
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

  static const _idBlock = 10000;
  static const _intervalOccurrences = 10;

  int _notifId(Medicine m, int occurrence, int timeIndex) =>
      m.id * _idBlock + occurrence * 100 + timeIndex;

  tz.TZDateTime _at(DateTime day, int minutes) => tz.TZDateTime(
      tz.local, day.year, day.month, day.day, minutes ~/ 60, minutes % 60);

  NotificationDetails _details(int medId, int minutes, int occurrence) {
    final s = _strings;
    final androidActions = <AndroidNotificationAction>[
      AndroidNotificationAction(
        actionTaken,
        s.take,
        showsUserInterface: true,
      )
    ];

    return NotificationDetails(
      android: AndroidNotificationDetails(
        'medicine_channel',
        s.channelName,
        channelDescription: s.channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        actions: androidActions,
      ),
      iOS: const DarwinNotificationDetails(
        categoryIdentifier: 'medicine_category',
      ),
    );
  }

  Future<void> scheduleMedicine(Medicine m) async {
    final s = _strings;
    final body = [
      '${m.name}${m.dose.isNotEmpty ? ' – ${m.dose}' : ''}',
      if (m.meal != 0) s.mealLabel(m.meal),
    ].join(' • ');
    final now = tz.TZDateTime.now(tz.local);
    final today = DateTime(now.year, now.month, now.day);
    final end = m.endDay;

    await scheduleReminders(m);

    final oneOffs = m.intervalDays > 1 ||
        (end != null && daysBetween(today, end) <= _intervalOccurrences);

    if (!oneOffs) {
      for (var i = 0; i < m.times.length; i++) {
        var when = _at(today, m.times[i]);
        if (when.isBefore(now)) when = when.add(const Duration(days: 1));
        await _schedule(
          id: _notifId(m, 0, i),
          title: s.notifTitle,
          body: body,
          when: when,
          details: _details(m.id, m.times[i], 0),
          payload: '${m.id}|${m.times[i]}|0',
          repeatDaily: true,
        );
      }
      return;
    }

    final days =
        m.nextDueDays(today, _intervalOccurrences).where(m.isDueOn).toList();
    for (var o = 0; o < days.length; o++) {
      for (var i = 0; i < m.times.length; i++) {
        final when = _at(days[o], m.times[i]);
        if (when.isBefore(now)) continue;
        await _schedule(
          id: _notifId(m, o, i),
          title: s.notifTitle,
          body: body,
          when: when,
          details: _details(m.id, m.times[i], o),
          payload: '${m.id}|${m.times[i]}|$o',
        );
      }
    }
  }

  Future<void> scheduleReminders(Medicine m) async {
    final s = _strings;
    final stockId = m.id * _idBlock + 9000;
    final endId = m.id * _idBlock + 9001;
    await _plugin.cancel(stockId);
    await _plugin.cancel(endId);

    final now = tz.TZDateTime.now(tz.local);
    final today = DateTime(now.year, now.month, now.day);
    final end = m.endDay;
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

    tz.TZDateTime nextMorning() {
      final w = _at(today, 9 * 60);
      return w.isAfter(now)
          ? w
          : _at(DateTime(today.year, today.month, today.day + 1), 9 * 60);
    }

    bool afterEnd(tz.TZDateTime d) =>
        end != null && daysBetween(end, DateTime(d.year, d.month, d.day)) > 0;

    final stock = m.stockCount;
    if (stock != null && m.times.isNotEmpty) {
      var when = nextMorning();
      final surplus = stock - m.lowStockThreshold;
      if (surplus > 0) {
        final needed = (surplus + m.times.length - 1) ~/ m.times.length;
        final day = m.nextDueDays(today, needed).last;
        final planned = _at(day, 9 * 60);
        when = planned.isAfter(now) ? planned : nextMorning();
      }
      if (!afterEnd(when)) {
        await _schedule(
          id: stockId,
          title: s.stockWarningTitle,
          body: s.stockWarningBody(m.name),
          when: when,
          details: details,
          payload: '${m.id}|0|0',
        );
      }
    }

    if (end != null) {
      var when = _at(DateTime(end.year, end.month, end.day - 2), 9 * 60);
      if (!when.isAfter(now)) when = nextMorning();
      if (!afterEnd(when)) {
        await _schedule(
          id: endId,
          title: s.stockWarningTitle,
          body: s.stockWarningBody(m.name),
          when: when,
          details: details,
          payload: '${m.id}|0|0',
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
    required String payload,
    bool repeatDaily = false,
  }) async {
    Future<void> go(AndroidScheduleMode mode) => _plugin.zonedSchedule(
          id,
          title,
          body,
          when,
          details,
          payload: payload,
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

@pragma('vm:entry-point')
void backgroundNotificationResponseHandler(NotificationResponse response) {
  // Arka plan işlemleri burada yönetilebilir.
}

// ───────────────────────── App ─────────────────────────

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  unawaited(PremiumService.instance.init());
  unawaited(AdService.instance.init());
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
          locale: currentLocale,
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
    
    NotificationService.onNotificationAction = (actionId, medId, minutes, occurrence) {
      _handleNotificationAction(actionId, medId, minutes);
    };

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
    _maybeShowDisclaimer();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _medsKey, jsonEncode(_meds.map((e) => e.toJson()).toList()));
    await prefs.setStringList(_takenKey, _taken.toList());
    await prefs.setInt(_nextIdKey, _nextId);
  }

  Future<void> _rescheduleAll() async {
    await NotificationService.instance.cancelAll();
    for (final m in _meds.where((m) => m.enabled)) {
      await NotificationService.instance.scheduleMedicine(m);
    }
  }

  // ───────── Uyarı / Gizlilik / Premium / Yardım diyalogları ─────────

  static const _disclaimerKey = 'disclaimer_ok_v1';

  Future<void> _maybeShowDisclaimer() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_disclaimerKey) ?? false) return;
    if (!mounted) return;
    await _showDisclaimer(firstRun: true);
    await prefs.setBool(_disclaimerKey, true);
  }

  Future<void> _showDisclaimer({bool firstRun = false}) {
    final s = AppStrings.of(context);
    return showDialog<void>(
      context: context,
      barrierDismissible: !firstRun,
      builder: (dialogContext) => PopScope(
        canPop: !firstRun,
        child: AlertDialog(
          icon: const Icon(Icons.health_and_safety_outlined),
          title: Text(s.disclaimerTitle),
          content: SingleChildScrollView(child: Text(s.disclaimerBody)),
          actions: [
            TextButton(
              onPressed: () => _openUrl(kPrivacyPolicyUrl),
              child: Text(s.privacyPolicy),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(s.disclaimerAccept),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showNotifHelp() {
    final s = AppStrings.of(context);
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.notifications_active_outlined),
        title: Text(s.notifHelpTitle),
        content: SingleChildScrollView(child: Text(s.notifHelpBody)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(s.closeBtn),
          ),
        ],
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _showPaywall() {
    final s = AppStrings.of(context);
    final premium = PremiumService.instance;
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.workspace_premium),
        title: Text(s.paywallTitle),
        content: ValueListenableBuilder<bool>(
          valueListenable: premium.isPremium,
          builder: (_, isPremium, __) {
            if (isPremium) return Text(s.premiumActiveText);
            return ValueListenableBuilder<String?>(
              valueListenable: premium.priceText,
              builder: (_, price, __) {
                final body =
                    '${s.paywallBody(PremiumService.freeMedicineLimit)}\n\n${s.removeAdsNote}';
                return Text(price == null ? '$body\n\n${s.storeUnavailable}' : body);
              },
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => premium.restore(),
            child: Text(s.restorePurchases),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(s.closeBtn),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: premium.isPremium,
            builder: (_, isPremium, __) {
              if (isPremium) return const SizedBox.shrink();
              return ValueListenableBuilder<String?>(
                valueListenable: premium.priceText,
                builder: (_, price, __) => FilledButton(
                  onPressed: price == null ? null : () => premium.buy(),
                  child: Text(s.buyFor(price ?? '…')),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _addMedicine() async {
    if (!PremiumService.instance.isPremium.value &&
        _meds.length >= PremiumService.freeMedicineLimit) {
      await _showPaywall();
      return;
    }
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
      stockCount: draft.stockCount,
      endDate: draft.endDate,
      meal: draft.meal,
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
    final medId = int.tryParse(key.split('|')[1]);
    final matches = _meds.where((m) => m.id == medId);
    final med = matches.isEmpty ? null : matches.first;

    var changed = false;
    setState(() {
      changed = value ? _taken.add(key) : _taken.remove(key);
      if (changed && med != null && med.stockCount != null) {
        final n = med.stockCount!;
        med.stockCount = value ? (n > 0 ? n - 1 : 0) : n + 1;
      }
    });

    if (changed && med != null && med.enabled && med.stockCount != null) {
      await NotificationService.instance.scheduleReminders(med);
    }
    await _save();
  }

  void _handleNotificationAction(String actionId, int medId, int minutes) async {
    final medMatches = _meds.where((m) => m.id == medId);
    if (medMatches.isEmpty) return;
    
    final todayStr = dateKey(_today);
    final doseKeyStr = '$todayStr|$medId|$minutes';

    if (actionId == NotificationService.actionTaken) {
      if (!_taken.contains(doseKeyStr)) {
        await _setTaken(doseKeyStr, true);
      }
    }
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
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AdBanner(),
          NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            destinations: [
              NavigationDestination(icon: const Icon(Icons.today), label: s.navDaily),
              NavigationDestination(
                  icon: const Icon(Icons.medication), label: s.navMedicines),
              NavigationDestination(icon: const Icon(Icons.settings), label: s.settings),
            ],
          ),
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
        _buildAlerts(),
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
                if (d.med.meal != 0) s.mealLabel(d.med.meal),
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
            title: Text(m.name),
            subtitle: _medicineSubtitle(m),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _openEditDialog(context, m),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _completelyDeleteMedicine(context, m),
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

  Widget _medicineSubtitle(Medicine m) {
    final s = AppStrings.of(context);
    final loc = MaterialLocalizations.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    final end = m.endDay;
    final daysLeft = end == null ? null : daysBetween(_today, end);
    final ended = daysLeft != null && daysLeft < 0;

    final schedule = [
      if (m.intervalDays > 1) s.everyNDays(m.intervalDays),
      if (m.meal != 0) s.mealLabel(m.meal),
    ];
    final stockText = m.stockCount == null ? null : s.stockLeft(m.stockCount!);
    final endText = end == null
        ? null
        : (ended ? s.endedLabel : s.endsOn(loc.formatMediumDate(end)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (m.dose.isNotEmpty) Text(m.dose),
        Text(m.times.map(timeLabel).join(', ')),
        if (schedule.isNotEmpty) Text(schedule.join(' • ')),
        if (stockText != null)
          Text(stockText,
              style: (m.isStockLow && !ended)
                  ? TextStyle(color: errorColor)
                  : null),
        if (endText != null)
          Text(endText,
              style: (ended || (daysLeft ?? 99) <= 3)
                  ? TextStyle(color: errorColor)
                  : null),
      ],
    );
  }

  Widget _buildAlerts() {
    final s = AppStrings.of(context);
    final messages = <String>[];
    for (final m in _meds.where((m) => m.enabled)) {
      final end = m.endDay;
      final daysLeft = end == null ? null : daysBetween(_today, end);
      if (daysLeft != null && daysLeft < 0) continue;
      if (daysLeft != null && daysLeft <= 3) {
        messages.add(
            daysLeft == 0 ? s.endsToday(m.name) : s.endsIn(m.name, daysLeft));
      }
      if (m.isStockLow) messages.add(s.stockLow(m.name, m.stockCount!));
    }
    if (messages.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded, color: scheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                messages.join('\n'),
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTab(AppStrings s) {
    return ListView(
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
        ValueListenableBuilder<bool>(
          valueListenable: PremiumService.instance.isPremium,
          builder: (_, isPremium, __) => ListTile(
            leading: const Icon(Icons.workspace_premium),
            title: Text(s.premiumTitle),
            subtitle: Text(isPremium
                ? s.premiumActiveText
                : s.premiumInactiveSubtitle(PremiumService.freeMedicineLimit)),
            onTap: isPremium ? null : _showPaywall,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.notifications_active_outlined),
          title: Text(s.notifHelpTitle),
          onTap: _showNotifHelp,
        ),
        ListTile(
          leading: const Icon(Icons.health_and_safety_outlined),
          title: Text(s.disclaimerTitle),
          onTap: () => _showDisclaimer(),
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: Text(s.privacyPolicy),
          onTap: () => _openUrl(kPrivacyPolicyUrl),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: AdService.instance.privacyOptionsRequired,
          builder: (_, required, __) => required
              ? ListTile(
                  leading: const Icon(Icons.ads_click),
                  title: Text(s.adPrivacyOptions),
                  onTap: AdService.instance.showPrivacyOptions,
                )
              : const SizedBox.shrink(),
        ),
        /* ElevatedButton(
          onPressed: () async {
            if (_meds.isNotEmpty) {
              await NotificationService.instance.showInstantTestNotification(_meds.first);
            }
          },
          child: const Text('Test Bildirimi Gönder'),
        ), */
      ],
    );
  }
}

// ───────────────────── Add medicine dialog ─────────────────────

class _MedicineDraft {
  final String name;
  final String dose;
  final List<int> times;
  final int intervalDays;
  final int? stockCount;
  final String? endDate;
  final int meal;
  _MedicineDraft(this.name, this.dose, this.times, this.intervalDays,
      {this.stockCount, this.endDate, this.meal = 0});
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

  bool _useInterval = false;
  TimeOfDay _firstDose = const TimeOfDay(hour: 8, minute: 0);
  int _intervalHours = 8;
  int _intervalDays = 1;
  String? _endDate;
  int _meal = 0;
  final List<int> _manualTimes = [];
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _dose.dispose();
    _stockController.dispose();
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
      context,
      _MedicineDraft(
        name,
        _dose.text.trim(),
        times,
        _intervalDays,
        stockCount: int.tryParse(_stockController.text.trim()),
        endDate: _endDate,
        meal: _meal,
      ),
    );
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
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: s.stockLabel,
                helperText: s.stockHelp,
                helperMaxLines: 2,
              ),
            ),
            const SizedBox(height: 8),
            TreatmentEndPicker(
              value: _endDate,
              onChanged: (v) => setState(() => _endDate = v),
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
                      for (var h = 1; h < 24; h++)
                        if (24 % h == 0)
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
            const SizedBox(height: 12),
            MealPicker(
              value: _meal,
              onChanged: (v) => setState(() => _meal = v),
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