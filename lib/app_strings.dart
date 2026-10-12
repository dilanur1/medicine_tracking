// lib/app_strings.dart
import 'package:flutter/material.dart';

class AppStrings {
  final Locale locale;
  AppStrings(this.locale);

  String get _lang {
    final langCode = locale.languageCode;
    return langCode;
  }



  String get appTitle {
    switch (_lang) {
      case 'tr': return 'İlaç Takibi';
      case 'es': return 'Control de Medicamentos';
      case 'de': return 'Medikamenten-Tracker';
      case 'fr': return 'Suivi des Médicaments';
      case 'it': return 'Monitoraggio Farmaci';
      case 'ru': return 'Контроль лекарств';
      case 'zh': return '服药提醒';
      case 'ja': return '服薬管理';
      case 'ar': return 'متابعة الأدوية';
      default: return 'Medicine Tracker';
    }
  }

  String get dailyDoses {
    switch (_lang) {
      case 'tr': return 'Günlük Dozlar';
      case 'es': return 'Dosis Diarias';
      case 'de': return 'Tägliche Dosen';
      case 'fr': return 'Doses Quotidiennes';
      case 'it': return 'Dosi Giornaliere';
      case 'ru': return 'Ежедневные дозы';
      case 'zh': return '每日剂量';
      case 'ja': return '毎日の服用量';
      case 'ar': return 'الجرعات اليومية';
      default: return 'Daily Doses';
    }
  }

  String get myMedicines {
    switch (_lang) {
      case 'tr': return 'İlaçlarım';
      case 'es': return 'Mis Medicamentos';
      case 'de': return 'Meine Medikamente';
      case 'fr': return 'Mes Médicaments';
      case 'it': return 'I Miei Farmaci';
      case 'ru': return 'Мои лекарства';
      case 'zh': return '我的药物';
      case 'ja': return 'マイ薬';
      case 'ar': return 'أدويتي';
      default: return 'My Medicines';
    }
  }

  String get intervalDaysText {
    switch (_lang) {
      case 'tr': return 'Kaç günde bir içilecek? (Örn: 1 = Her gün, 2 = 2 günde bir)';
      case 'es': return '¿Cada cuántos días? (Ej: 1 = Diario, 2 = Cada 2 días)';
      case 'de': return 'Alle wie viele Tage? (Z.B. 1 = Täglich)';
      case 'fr': return '¿Cada cuántos días? (Ej: 1 = Diario, 2 = Cada 2 días)';
      case 'it': return 'Con quale frequenza deve essere assunto? (es. 1 = Ogni giorno, 2 = A giorni alterni)';
      case 'ru': return 'Как часто следует его принимать? (например, 1 = ежедневно, 2 = через день)';
      case 'zh': return '多久服用一次？ （例如：1 = 每天，2 = 隔天）';
      case 'ja': return 'どのくらいの頻度で服用すべきですか？（例：1 = 毎日、2 = 1日おき）';
      case 'ar': return 'كم مرة يجب تناوله؟ (مثلاً: 1 = يومياً، 2 = يوماً بعد يوم)';
      default: return 'Every X days (e.g., 1 = Daily)';
    }
  }

  // AppStrings sınıfına eklenecekler:
  String get everyDay {
    switch (_lang) {
      case 'tr': return 'Her Gün';
      case 'es': return 'Todos los días';
      case 'de': return 'Jeden Tag';
      case 'fr': return 'Tous les jours';
      case 'it': return 'Ogni giorno';
      case 'ru': return 'Каждый день';
      case 'zh': return '每天';
      case 'ja': return '毎日';
      case 'ar': return 'كل يوم';
      default: return 'Every Day';
    }
  }

  String get customInterval {
    switch (_lang) {
      case 'tr': return 'Belirli Aralıklarla (X günde bir)';
      case 'es': return 'Intervalo personalizado (Cada X días)';
      case 'de': return 'Benutzerdefiniertes Intervall (Alle X Tage)';
      case 'fr': return 'Intervalle personnalisé (Tous les X jours)';
      case 'it': return 'Intervallo personalizzato (Ogni X giorni)';
      case 'ru': return 'Каждые X дней';
      case 'zh': return '自定义间隔（每隔X天）';
      case 'ja': return 'カスタム間隔（X日ごと）';
      case 'ar': return 'فترة مخصصة (كل X أيام)';
      default: return 'Custom Interval (Every X days)';
    }
  }

  String get intervalDaysLabel {
    switch (_lang) {
      case 'tr': return 'Kaç günde bir içilecek?';
      case 'es': return '¿Cada cuántos días se tomará?';
      case 'de': return 'Alle wie viele Tage einzunehmen?';
      case 'fr': return "Quel est l'intervalle de combien de jours ?";
      case 'it': return "Qual è l'intervallo di giorni?";
      case 'ru': return 'Какой интервал в днях?';
      case 'zh': return '間隔多少天？';
      case 'ja': return '何日おきですか？';
      case 'ar': return 'ما هي الفترة الفاصلة بالأيام؟';
      default: return 'How many days interval?';
    }
  }

  String get today {
    switch (_lang) {
      case 'tr': return 'Bugün';
      case 'es': return 'Hoy';
      case 'de': return 'Heute';
      case 'fr': return 'Aujourd\'hui';
      case 'it': return 'Oggi';
      case 'ru': return 'Сегодня';
      case 'zh': return '今天';
      case 'ja': return '今日';
      case 'ar': return 'اليوم';
      default: return 'Today';
    }
  }

  String get yesterday {
    switch (_lang) {
      case 'tr': return 'Dün';
      case 'es': return 'Ayer';
      case 'de': return 'Gestern';
      case 'fr': return 'Hier';
      case 'it': return 'Ieri';
      case 'ru': return 'Вчера';
      case 'zh': return '昨天';
      case 'ja': return '昨日';
      case 'ar': return 'أمس';
      default: return 'Yesterday';
    }
  }

  String get tomorrow {
    switch (_lang) {
      case 'tr': return 'Yarın';
      case 'es': return 'Mañana';
      case 'de': return 'Morgen';
      case 'fr': return 'Demain';
      case 'it': return 'Domani';
      case 'ru': return 'Завтра';
      case 'zh': return '明天';
      case 'ja': return '明日';
      case 'ar': return 'غدا';
      default: return 'Tomorrow';
    }
  }

  String get addMedicine {
    switch (_lang) {
      case 'tr': return 'İlaç Ekle';
      case 'es': return 'Añadir Medicamento';
      case 'de': return 'Medikament hinzufügen';
      case 'fr': return 'Ajouter un Médicament';
      case 'it': return 'Aggiungi Farmaco';
      case 'ru': return 'Добавить лекарство';
      case 'zh': return '添加药物';
      case 'ja': return '薬を追加';
      case 'ar': return 'إضافة دواء';
      default: return 'Add Medicine';
    }
  }

  String get navDaily {
    switch (_lang) {
      case 'tr': return 'Günlük';
      case 'es': return 'Diario';
      case 'de': return 'Täglich';
      case 'fr': return 'Quotidien';
      case 'it': return 'Giornaliero';
      case 'ru': return 'Ежедневно';
      case 'zh': return '日常';
      case 'ja': return 'デイリー';
      case 'ar': return 'يومي';
      default: return 'Daily';
    }
  }

  String get delete {
    switch (_lang) {
      case 'tr': return 'Sil';
      case 'es': return 'Eliminar';
      case 'de': return 'Löschen';
      case 'fr': return 'Supprimer';
      case 'it': return 'Elimina';
      case 'ru': return 'Удалить';
      case 'zh': return '删除';
      case 'ja': return '削除';
      case 'ar': return 'حذف';
      default: return 'Delete';
    }
  }

  String get deleteConfirmation {
    switch (_lang) {
      case 'tr': return 'Bu ilacı silmek istediğinize emin misiniz?';
      case 'es': return '¿Estás seguro de que deseas eliminar este medicamento?';
      case 'de': return 'Möchten Sie dieses Medikament wirklich löschen?';
      case 'fr': return 'Êtes-vous sûr de vouloir supprimer ce médicament ?';
      case 'it': return 'Sei sicuro di voler eliminare questo medicinale?';
      case 'ru': return 'Вы уверены, что хотите удалить это лекарство?';
      case 'zh': return '您確定要刪除這種藥物嗎？';
      case 'ja': return 'この薬を削除してもよろしいですか？';
      case 'ar': return 'هل أنت متأكد من أنك تريد حذف هذا الدواء؟';
      default: return 'Are you sure you want to delete this medicine?';
    }
  }

  String get navMedicines {
    switch (_lang) {
      case 'tr': return 'İlaçlar';
      case 'es': return 'Medicamentos';
      case 'de': return 'Medikamente';
      case 'fr': return 'Médicaments';
      case 'it': return 'Farmaci';
      case 'ru': return 'Лекарства';
      case 'zh': return '药物';
      case 'ja': return '薬';
      case 'ar': return 'الأدوية';
      default: return 'Medicines';
    }
  }

  String get noDoses {
    switch (_lang) {
      case 'tr': return 'Bu gün için doz bulunmuyor.';
      case 'es': return 'No hay dosis para este día.';
      case 'de': return 'Keine Dosen für diesen Tag.';
      case 'fr': return 'Aucune dose pour ce jour.';
      case 'it': return 'Nessuna dose per questo giorno.';
      case 'ru': return 'На этот день доз нет.';
      case 'zh': return '今天没有剂量。';
      case 'ja': return 'この日の用量はありません。';
      case 'ar': return 'لا توجد جرعات لهذا اليوم.';
      default: return 'No doses for this day.';
    }
  }

  String get noMedicine {
    switch (_lang) {
      case 'tr': return 'Henüz kayıtlı ilaç yok.';
      case 'es': return 'No hay medicamentos añadidos.';
      case 'de': return 'Keine Medikamente hinzugefügt.';
      case 'fr': return 'Aucun médicament ajouté.';
      case 'it': return 'Nessun farmaco aggiunto.';
      case 'ru': return 'Лекарства не добавлены.';
      case 'zh': return '尚未添加药物。';
      case 'ja': return '薬が追加されていません。';
      case 'ar': return 'لم تتم إضافة أدوية بعد.';
      default: return 'No medicines added yet.';
    }
  }

  String get missed {
    switch (_lang) {
      case 'tr': return 'Kaçırıldı';
      case 'es': return 'Perdido';
      case 'de': return 'Verpasst';
      case 'fr': return 'Manqué';
      case 'it': return 'Saltato';
      case 'ru': return 'Пропущено';
      case 'zh': return '已错过';
      case 'ja': return '逃した';
      case 'ar': return 'فائتة';
      default: return 'Missed';
    }
  }

  String get notTakenYet {
    switch (_lang) {
      case 'tr': return 'Henüz alınmadı';
      case 'es': return 'No tomado aún';
      case 'de': return 'Noch nicht eingenommen';
      case 'fr': return 'Pas encore pris';
      case 'it': return 'Non ancora preso';
      case 'ru': return 'Еще не принято';
      case 'zh': return '尚未服用';
      case 'ja': return 'まだ服用していません';
      case 'ar': return 'لم يُؤخذ بعد';
      default: return 'Not taken yet';
    }
  }

  String takenOf(int taken, int total) {
    switch (_lang) {
      case 'tr': return 'Alınan: $taken / $total';
      case 'es': return 'Tomado: $taken / $total';
      case 'de': return 'Eingenommen: $taken / $total';
      case 'fr': return 'Pris : $taken / $total';
      case 'it': return 'Presi: $taken / $total';
      case 'ru': return 'Принято: $taken / $total';
      case 'zh': return '已服用: $taken / $total';
      case 'ja': return '服用済み: $taken / $total';
      case 'ar': return 'المأخوذ: $taken / $total';
      default: return 'Taken: $taken / $total';
    }
  }

  String get newMedicine {
    switch (_lang) {
      case 'tr': return 'Yeni İlaç';
      case 'es': return 'Nuevo Medicamento';
      case 'de': return 'Neues Medikament';
      case 'fr': return 'Nouveau Médicament';
      case 'it': return 'Nuovo Farmaco';
      case 'ru': return 'Новое лекарство';
      case 'zh': return '新药物';
      case 'ja': return '新しい薬';
      case 'ar': return 'دواء جديد';
      default: return 'New Medicine';
    }
  }

  String get medicineName {
    switch (_lang) {
      case 'tr': return 'İlaç Adı';
      case 'es': return 'Nombre del Medicamento';
      case 'de': return 'Medikamentenname';
      case 'fr': return 'Nom du Médicament';
      case 'it': return 'Nome del Farmaco';
      case 'ru': return 'Название лекарства';
      case 'zh': return '药物名称';
      case 'ja': return '薬の名前';
      case 'ar': return 'اسم الدواء';
      default: return 'Medicine Name';
    }
  }

String get settings {
    switch (_lang) {
      case 'tr': return 'Ayarlar';
      case 'es': return 'Ajustes';
      case 'de': return 'Einstellungen';
      case 'fr': return 'Paramètres';
      case 'it': return 'Impostazioni';
      case 'ru': return 'Настройки';
      case 'zh': return '设置';
      case 'ja': return '設定';
      case 'ar': return 'الإعدادات';
      default: return 'Settings';
    }
  }

  String get language {
    switch (_lang) {
      case 'tr': return 'Dil';
      case 'es': return 'Idioma';
      case 'de': return 'Sprache';
      case 'fr': return 'Langue';
      case 'it': return 'Lingua';
      case 'ru': return 'Язык';
      case 'zh': return '语言';
      case 'ja': return '言語';
      case 'ar': return 'اللغة';
      default: return 'Language';
    }
  }

  String get stockCount {
    switch (_lang) {
      case 'tr': return 'Kalan Hap / Doz Miktarı';
      case 'es': return 'Cantidad de pastillas restantes';
      case 'de': return 'Verbleibende Tabletten / Dosis';
      case 'fr': return 'Quantité de pilules restantes';
      case 'it': return 'Quantità di pillole rimanenti';
      case 'ru': return 'Остаток таблеток / доз';
      case 'zh': return '剩余药片/剂量';
      case 'ja': return '残りの錠剤/用量';
      case 'ar': return 'الكمية المتبقية من الحبوب';
      default: return 'Remaining Stock';
    }
  }

  String get treatmentDuration {
    switch (_lang) {
      case 'tr': return 'Tedavi Süresi (Ay)';
      case 'es': return 'Duración del tratamiento (Meses)';
      case 'de': return 'Behandlungsdauer (Monate)';
      case 'fr': return 'Durée du traitement (Mois)';
      case 'it': return 'Durata del trattamento (Mesi)';
      case 'ru': return 'Длительность лечения (месяцев)';
      case 'zh': return '治疗周期（个月）';
      case 'ja': return '治療期間（月）';
      case 'ar': return 'مدة العلاج (بالشهور)';
      default: return 'Treatment Duration (Months)';
    }
  }

  String get stockWarningTitle {
    switch (_lang) {
      case 'tr': return 'İlaç Bitmek Üzere! ⚠️';
      case 'es': return '¡Medicamento agotándose! ⚠️';
      case 'de': return 'Medikament geht zur Neige! ⚠️';
      case 'fr': return 'Médicament bientôt épuisé ! ⚠️';
      case 'it': return 'Farmaco in esaurimento! ⚠️';
      case 'ru': return 'Лекарство заканчивается! ⚠️';
      case 'zh': return '药物快用完了！⚠️';
      case 'ja': return '薬が残り少なくなっています！ ⚠️';
      case 'ar': return 'الدواء على وشك النفاد! ⚠️';
      default: return 'Medicine Running Low! ⚠️';
    }
  }

  String stockWarningBody(String name) {
    switch (_lang) {
      case 'tr': return '$name ilacınızın süresi veya stoğu bitmek üzere.';
      case 'es': return 'Su medicamento $name se está agotando.';
      case 'de': return 'Ihr Medikament $name geht zur Neige.';
      case 'fr': return 'Votre médicament $name est presque épuisé.';
      case 'it': return 'Il tuo farmaco $name sta per finire.';
      case 'ru': return 'Ваше лекарство $name заканчивается.';
      case 'zh': return '您的药物 $name 快用完了。';
      case 'ja': return '薬「$name」の残り少なくなっています。';
      case 'ar': return 'دواؤك $name على وشك النفاد.';
      default: return 'Your medicine $name is running out.';
    }
  }

  String get snooze15 {
    switch (_lang) {
      case 'tr': return '15 Dk Ertele';
      case 'es': return 'Posponer 15m';
      case 'de': return '15 Min. verschieben';
      case 'fr': return 'Reporter de 15 min';
      case 'it': return 'Posticipa di 15m';
      case 'ru': return 'Отложить на 15 мин';
      case 'zh': return '推迟15分钟';
      case 'ja': return '15分スヌーズ';
      case 'ar': return 'تأجيل لمدة 15 دقيقة';
      default: return 'Snooze 15m';
    }
  }

  String get take {
    switch (_lang) {
      case 'tr': return 'İçtim';
      case 'es': return 'Tomar';
      case 'de': return 'Eingenommen';
      case 'fr': return 'Prendre';
      case 'it': return 'Prendi';
      case 'ru': return 'Принять';
      case 'zh': return '服用';
      case 'ja': return '服用する';
      case 'ar': return 'تم الأخذ';
      default: return 'Take';
    }
  }

  String get editMedicine {
    switch (_lang) {
      case 'tr': return 'İlacı Düzenle';
      case 'es': return 'Editar Medicamento';
      case 'de': return 'Medikament bearbeiten';
      case 'fr': return 'Modifier le Médicament';
      case 'it': return 'Modifica Farmaco';
      case 'ru': return 'Редактировать лекарство';
      case 'zh': return '编辑药物';
      case 'ja': return '薬を編集';
      case 'ar': return 'تعديل الدواء';
      default: return 'Edit Medicine';
    }
  }

  String get update {
    switch (_lang) {
      case 'tr': return 'Güncelle';
      case 'es': return 'Actualizar';
      case 'de': return 'Aktualisieren';
      case 'fr': return 'Mettre à jour';
      case 'it': return 'Aggiorna';
      case 'ru': return 'Обновить';
      case 'zh': return '更新';
      case 'ja': return '更新';
      case 'ar': return 'تحديث';
      default: return 'Update';
    }
  }

  String get doseHint {
    switch (_lang) {
      case 'tr': return 'Bir seferde içilecek miktar (örn: 1 hap, 5ml)';
      case 'es': return 'Cantidad a tomar por vez (ej: 1 pastilla, 5ml)';
      case 'de': return 'Menge pro Einnahme (z.B. 1 Pille, 5ml)';
      case 'fr': return 'Quantité à prendre par prise (ex: 1 pilule, 5ml)';
      case 'it': return 'Quantità da assumere a dose (es: 1 pillola, 5ml)';
      case 'ru': return 'Количество за один прием (например: 1 табл, 5мл)';
      case 'zh': return '每次服用量 (例如: 1片, 5ml)';
      case 'ja': return '1回あたりの服用量 (例: 1錠, 5ml)';
      case 'ar': return 'الكمية في المرة الواحدة (مثال: حبة واحدة، 5 مل)';
      default: return 'Amount to take at a time (e.g., 1 pill, 5ml)';
    }
  }

  String get repeatEvery {
    switch (_lang) {
      case 'tr': return '... saat ara ile';
      case 'es': return 'Cada ... horas';
      case 'de': return 'Alle ... Stunden';
      case 'fr': return 'Toutes les ... heures';
      case 'it': return 'Ogni ... ore';
      case 'ru': return 'Каждые ... ч.';
      case 'zh': return '每隔 ... 小时';
      case 'ja': return '... 時間おき';
      case 'ar': return 'كل ... ساعات';
      default: return 'Every ... hours';
    }
  }

  String firstDose(String time) {
    switch (_lang) {
      case 'tr': return 'İlk Doz: $time';
      case 'es': return 'Primera Dosis: $time';
      case 'de': return 'Erste Dosis: $time';
      case 'fr': return 'Première Dose : $time';
      case 'it': return 'Prima Dose: $time';
      case 'ru': return 'Первая доза: $time';
      case 'zh': return '首剂时间: $time';
      case 'ja': return '最初の用量: $time';
      case 'ar': return 'الجرعة الأولى: $time';
      default: return 'First Dose: $time';
    }
  }

  String get every {
    switch (_lang) {
      case 'tr': return 'Her ';
      case 'es': return 'Cada ';
      case 'de': return 'Alle ';
      case 'fr': return 'Chaque ';
      case 'it': return 'Ogni ';
      case 'ru': return 'Каждые ';
      case 'zh': return '每 ';
      case 'ja': return '毎 ';
      case 'ar': return 'كل ';
      default: return 'Every ';
    }
  }

  String get hoursSuffix {
    switch (_lang) {
      case 'tr': return ' saatte bir';
      case 'es': return ' horas';
      case 'de': return ' Stunden';
      case 'fr': return ' heures';
      case 'it': return ' ore';
      case 'ru': return ' часов';
      case 'zh': return ' 小时';
      case 'ja': return ' 時間ごと';
      case 'ar': return ' ساعات';
      default: return ' hours';
    }
  }

  String reminders(String r) {
    switch (_lang) {
      case 'tr': return 'Hatırlatıcılar: $r';
      case 'es': return 'Recordatorios: $r';
      case 'de': return 'Erinnerungen: $r';
      case 'fr': return 'Rappels : $r';
      case 'it': return 'Promemoria: $r';
      case 'ru': return 'Напоминания: $r';
      case 'zh': return '提醒时间: $r';
      case 'ja': return 'リマインダー: $r';
      case 'ar': return 'التذكيرات: $r';
      default: return 'Reminders: $r';
    }
  }

  String get addTime {
    switch (_lang) {
      case 'tr': return 'Zaman Ekle';
      case 'es': return 'Añadir Hora';
      case 'de': return 'Zeit hinzufügen';
      case 'fr': return 'Ajouter une Heure';
      case 'it': return 'Aggiungi Orario';
      case 'ru': return 'Добавить время';
      case 'zh': return '添加时间';
      case 'ja': return '時間を追加';
      case 'ar': return 'إضافة وقت';
      default: return 'Add Time';
    }
  }

  String get enterName {
    switch (_lang) {
      case 'tr': return 'Lütfen bir ilaç adı girin';
      case 'es': return 'Por favor ingrese un nombre';
      case 'de': return 'Bitte geben Sie einen Namen ein';
      case 'fr': return 'Veuillez entrer un nom';
      case 'it': return 'Inserisci un nome';
      case 'ru': return 'Введите название';
      case 'zh': return '请输入药物名称';
      case 'ja': return '薬の名前を入力してください';
      case 'ar': return 'الرجاء إدخال اسم الدواء';
      default: return 'Please enter a medicine name';
    }
  }

  String get addAtLeastOne {
    switch (_lang) {
      case 'tr': return 'En az bir zaman ekleyin';
      case 'es': return 'Añada al menos una hora';
      case 'de': return 'Fügen Sie mindestens eine Zeit hinzu';
      case 'fr': return 'Ajoutez au moins une heure';
      case 'it': return 'Aggiungi almeno un orario';
      case 'ru': return 'Добавьте хотя бы одно время';
      case 'zh': return '请至少添加一个时间';
      case 'ja': return '少なくとも1つの時間を追加してください';
      case 'ar': return 'أضف وقتاً واحداً على الأقل';
      default: return 'Add at least one time';
    }
  }

  String get cancel {
    switch (_lang) {
      case 'tr': return 'İptal';
      case 'es': return 'Cancelar';
      case 'de': return 'Abbrechen';
      case 'fr': return 'Annuler';
      case 'it': return 'Annulla';
      case 'ru': return 'Отмена';
      case 'zh': return '取消';
      case 'ja': return 'キャンセル';
      case 'ar': return 'إلغاء';
      default: return 'Cancel';
    }
  }

  String get save {
    switch (_lang) {
      case 'tr': return 'Kaydet';
      case 'es': return 'Guardar';
      case 'de': return 'Speichern';
      case 'fr': return 'Enregistrer';
      case 'it': return 'Salva';
      case 'ru': return 'Сохранить';
      case 'zh': return '保存';
      case 'ja': return '保存';
      case 'ar': return 'حفظ';
      default: return 'Save';
    }
  }

  String get channelName {
    switch (_lang) {
      case 'tr': return 'İlaç Hatırlatıcıları';
      case 'es': return 'Recordatorios de Medicamentos';
      case 'de': return 'Medikamenten-Erinnerungen';
      case 'fr': return 'Rappels de Médicaments';
      case 'it': return 'Promemoria Farmaci';
      case 'ru': return 'Напоминания о лекарствах';
      case 'zh': return '服药提醒';
      case 'ja': return '服薬リマインダー';
      case 'ar': return 'تذكيرات الأدوية';
      default: return 'Medicine Reminders';
    }
  }

  String get channelDesc {
    switch (_lang) {
      case 'tr': return 'İlaç zamanı bildirimleri';
      case 'es': return 'Notificaciones de hora de medicamentos';
      case 'de': return 'Benachrichtigungen für Medikamentenzeiten';
      case 'fr': return 'Notifications pour l\'heure des médicaments';
      case 'it': return 'Notifiche per l\'orario dei farmaci';
      case 'ru': return 'Уведомления о времени приема лекарств';
      case 'zh': return '服药时间通知';
      case 'ja': return '服薬時間の通知';
      case 'ar': return 'إشعارات أوقات الأدوية';
      default: return 'Notifications for medicine times';
    }
  }

  String get notifTitle {
    switch (_lang) {
      case 'tr': return 'İlaç Zamanı! 💊';
      case 'es': return '¡Hora de la medicina! 💊';
      case 'de': return 'Medikamentenzeit! 💊';
      case 'fr': return 'Heure du médicament ! 💊';
      case 'it': return 'È ora della medicina! 💊';
      case 'ru': return 'Время принимать лекарство! 💊';
      case 'zh': return '服药时间到！💊';
      case 'ja': return 'お薬の時間です！ 💊';
      case 'ar': return 'وقت الدواء! 💊';
      default: return 'Medicine Time! 💊';
    }
  }

  // ───── Aç/tok, kalan hap ve tedavi bitiş tarihi ─────

  // Yemekle ilişki: 0 = aç veya tok, 1 = aç, 2 = tok
  String get meal {
    switch (_lang) {
      case 'tr': return 'Yemekle ilişkisi';
      case 'es': return 'Relación con las comidas';
      case 'de': return 'Einnahme zum Essen';
      case 'fr': return 'Rapport aux repas';
      case 'it': return 'Rapporto con i pasti';
      case 'ru': return 'Связь с приёмом пищи';
      case 'zh': return '与进餐的关系';
      case 'ja': return '食事との関係';
      case 'ar': return 'العلاقة بالطعام';
      default: return 'Relation to meals';
    }
  }

  String get mealEmpty {
    switch (_lang) {
      case 'tr': return 'Aç';
      case 'es': return 'En ayunas'; // İspanyolca "Açken/Oruçlu" kısa kullanımı
      case 'de': return 'Nüchtern';  // Almanca açlık/aç karın durumunun doğrudan karşılığı
      case 'fr': return 'À jeun';    // Fransızca "Açken" kısa etiketi
      case 'it': return 'A digiuno'; // İtalyanca "Açken" kısa etiketi
      case 'ru': return 'Натощак';   // Rusça "Açken" kısa etiketi
      case 'zh': return '空腹';       // Çince "Aç karın / Açlık"
      case 'ja': return '空腹';       // Japonca "Açlık"
      case 'ar': return 'صائم';       // Arapça "Aç/Beslenmemiş"
      default: return 'Fasting';    // İngilizce "Aç/Aç karnına" kısa karşılığı
    }
  }

  String get mealFull {
    switch (_lang) {
      case 'tr': return 'Tok';
      case 'es': return 'Saciado';     // İspanyolca (Beslenmiş / Tok)
      case 'de': return 'Satt';        // Almanca (Karnı tok / Beslenmiş)
      case 'fr': return 'Rassasié';    // Fransızca (Tok)
      case 'it': return 'Sazio';       // İtalyanca (Tok)
      case 'ru': return 'Сытый';       // Rusça (Tok / Beslenmiş)
      case 'zh': return '饱腹';        // Çince (Karnı tok / Yemek sonrası tok durumu)
      case 'ja': return '満腹';        // Japonca (Tok / Doymuş)
      case 'ar': return 'شبعان';       // Arapça (Tok)
      default: return 'Full';         // İngilizce (Tok)
    }
  }

  String get mealAny {
    switch (_lang) {
      case 'tr': return 'Aç veya tok';
      case 'es': return 'En ayunas o con comida';
      case 'de': return 'Nüchtern oder satt';
      case 'fr': return 'Avec ou sans repas';
      case 'it': return 'A stomaco vuoto o pieno';
      case 'ru': return 'Независимо от еды';
      case 'zh': return '空腹或饱腹均可';
      case 'ja': return '空腹・食後どちらでも';
      case 'ar': return 'على معدة فارغة أو ممتلئة';
      default: return 'With or without food';
    }
  }

  String mealLabel(int m) =>
      m == 1 ? mealEmpty : (m == 2 ? mealFull : mealAny);

  String get stockLabel {
    switch (_lang) {
      case 'tr': return 'Kalan hap sayısı (isteğe bağlı)';
      case 'es': return 'Pastillas restantes (opcional)';
      case 'de': return 'Verbleibende Tabletten (optional)';
      case 'fr': return 'Comprimés restants (facultatif)';
      case 'it': return 'Pillole rimanenti (facoltativo)';
      case 'ru': return 'Осталось таблеток (необязательно)';
      case 'zh': return '剩余药量（可选）';
      case 'ja': return '残りの錠数（任意）';
      case 'ar': return 'الحبوب المتبقية (اختياري)';
      default: return 'Pills left (optional)';
    }
  }

  String get stockHelp {
    switch (_lang) {
      case 'tr': return 'Doz işaretledikçe düşer, bitmeden önce hatırlatırız';
      case 'es': return 'Disminuye al marcar dosis; te avisamos antes de que se acaben';
      case 'de': return 'Sinkt beim Abhaken von Dosen; wir erinnern vor dem Ende';
      case 'fr': return 'Diminue quand vous cochez les prises ; nous vous prévenons avant la fin';
      case 'it': return 'Diminuisce quando segni le dosi; ti avvisiamo prima che finiscano';
      case 'ru': return 'Уменьшается при отметке приёма; напомним до того, как закончатся';
      case 'zh': return '标记服药后自动减少，药快用完前会提醒你';
      case 'ja': return '服用を記録すると減ります。なくなる前にお知らせします';
      case 'ar': return 'تنقص عند تسجيل الجرعات، وسنذكّرك قبل أن تنفد';
      default: return 'Decreases as you mark doses; we remind you before it runs out';
    }
  }

  String get endLabel {
    switch (_lang) {
      case 'tr': return 'Tedavi bitiş tarihi (isteğe bağlı)';
      case 'es': return 'Fecha de fin del tratamiento (opcional)';
      case 'de': return 'Ende der Behandlung (optional)';
      case 'fr': return 'Date de fin du traitement (facultatif)';
      case 'it': return 'Data di fine terapia (facoltativo)';
      case 'ru': return 'Дата окончания курса (необязательно)';
      case 'zh': return '疗程结束日期（可选）';
      case 'ja': return '治療の終了日（任意）';
      case 'ar': return 'تاريخ انتهاء العلاج (اختياري)';
      default: return 'Treatment end date (optional)';
    }
  }

  String get endNone {
    switch (_lang) {
      case 'tr': return 'Süresiz';
      case 'es': return 'Sin fecha de fin';
      case 'de': return 'Unbefristet';
      case 'fr': return 'Sans limite';
      case 'it': return 'Senza scadenza';
      case 'ru': return 'Без срока';
      case 'zh': return '无期限';
      case 'ja': return '期限なし';
      case 'ar': return 'بدون تاريخ';
      default: return 'No end date';
    }
  }

  String get endedLabel {
    switch (_lang) {
      case 'tr': return 'Tedavi bitti';
      case 'es': return 'Tratamiento terminado';
      case 'de': return 'Behandlung beendet';
      case 'fr': return 'Traitement terminé';
      case 'it': return 'Terapia terminata';
      case 'ru': return 'Курс завершён';
      case 'zh': return '疗程已结束';
      case 'ja': return '治療終了';
      case 'ar': return 'انتهى العلاج';
      default: return 'Treatment ended';
    }
  }

  String everyNDays(int n) {
    switch (_lang) {
      case 'tr': return 'Her $n günde bir';
      case 'es': return 'Cada $n días';
      case 'de': return 'Alle $n Tage';
      case 'fr': return 'Tous les $n jours';
      case 'it': return 'Ogni $n giorni';
      case 'ru': return 'Каждые $n дн.';
      case 'zh': return '每 $n 天一次';
      case 'ja': return '$n日ごと';
      case 'ar': return 'كل $n أيام';
      default: return 'Every $n days';
    }
  }

  String stockLeft(int n) {
    switch (_lang) {
      case 'tr': return 'Kalan: $n hap';
      case 'es': return 'Quedan: $n pastillas';
      case 'de': return 'Übrig: $n Tabletten';
      case 'fr': return 'Restant : $n comprimés';
      case 'it': return 'Rimaste: $n pillole';
      case 'ru': return 'Осталось: $n шт.';
      case 'zh': return '剩余：$n 片';
      case 'ja': return '残り：$n錠';
      case 'ar': return 'المتبقي: $n حبة';
      default: return 'Left: $n pills';
    }
  }

  String stockLow(String name, int n) {
    switch (_lang) {
      case 'tr': return '$name: $n hap kaldı, bitmek üzere';
      case 'es': return '$name: quedan solo $n pastillas';
      case 'de': return '$name: nur noch $n Tabletten';
      case 'fr': return '$name : plus que $n comprimés';
      case 'it': return '$name: restano solo $n pillole';
      case 'ru': return '$name: осталось всего $n шт.';
      case 'zh': return '$name：仅剩 $n 片';
      case 'ja': return '$name：残り$n錠です';
      case 'ar': return '$name: تبقّى $n حبة فقط';
      default: return '$name: only $n pills left';
    }
  }

  String endsToday(String name) {
    switch (_lang) {
      case 'tr': return '$name: tedavi bugün bitiyor';
      case 'es': return '$name: el tratamiento termina hoy';
      case 'de': return '$name: Behandlung endet heute';
      case 'fr': return '$name : le traitement se termine aujourd\'hui';
      case 'it': return '$name: la terapia termina oggi';
      case 'ru': return '$name: курс заканчивается сегодня';
      case 'zh': return '$name：疗程今天结束';
      case 'ja': return '$name：今日で治療が終わります';
      case 'ar': return '$name: ينتهي العلاج اليوم';
      default: return '$name: treatment ends today';
    }
  }

  String endsIn(String name, int n) {
    switch (_lang) {
      case 'tr': return '$name: tedavi $n gün içinde bitiyor';
      case 'es': return '$name: el tratamiento termina en $n días';
      case 'de': return '$name: Behandlung endet in $n Tagen';
      case 'fr': return '$name : le traitement se termine dans $n jours';
      case 'it': return '$name: la terapia termina tra $n giorni';
      case 'ru': return '$name: курс заканчивается через $n дн.';
      case 'zh': return '$name：疗程将在 $n 天后结束';
      case 'ja': return '$name：治療はあと$n日で終わります';
      case 'ar': return '$name: ينتهي العلاج خلال $n أيام';
      default: return '$name: treatment ends in $n days';
    }
  }

  String endsOn(String date) {
    switch (_lang) {
      case 'tr': return 'Bitiş: $date';
      case 'es': return 'Fin: $date';
      case 'de': return 'Ende: $date';
      case 'fr': return 'Fin : $date';
      case 'it': return 'Fine: $date';
      case 'ru': return 'Окончание: $date';
      case 'zh': return '结束：$date';
      case 'ja': return '終了：$date';
      case 'ar': return 'الانتهاء: $date';
      default: return 'Ends: $date';
    }
  }

  String prettyDate(DateTime d) {
    if (_lang == 'tr') {
      const months = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } else {
      const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
      return '${months[d.month - 1]} ${d.day}, ${d.year}';
    }
  }

  static AppStrings of(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return AppStrings(locale);
  }

  static AppStrings forLocale(Locale locale) {
    return AppStrings(locale);
  }
}