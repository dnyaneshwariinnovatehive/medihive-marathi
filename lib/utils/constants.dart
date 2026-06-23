import 'package:flutter/material.dart';

/// App-wide constants
class AppConstants {
  // ─── Doctor / Clinic Info ─────────────────────────────────
  static const String doctorName = 'Dr. Rajas Gavas';
  static const String clinicName = 'Shree Clinic';
  static const String clinicAddress =
      'Nirman bhavan, near Milagris school, Sawantwadi';
  static const String clinicPhone = '9067251670';
  static const String licenseNo = 'I-107200-A';
  static const String doctorInitials = 'RG';

  // ─── Developer / Help Info ────────────────────────────────
  static const String devEmail = 'ashwin.innovatehive@gmail.com';
  static const String devPhone = '8767555945';
  static const String appVersion = 'v1.0.7';

  // ─── Blood Groups ────────────────────────────────────────
  static const List<String> bloodGroups = [
    'O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'
  ];

  // ─── Gender Options ───────────────────────────────────────
  static const List<String> genders = ['Male', 'Female', 'Other'];

  // ─── OPD Types ────────────────────────────────────────────
  static const List<String> opdTypes = ['Consultation', 'Follow-up'];

  // ─── Payment Modes ────────────────────────────────────────
  static const List<String> paymentModes = ['Cash', 'Online', 'Card'];

  // ─── Charge Types ─────────────────────────────────────────
  static const List<String> chargeTypes = ['Cash', 'Credit'];

  // ─── Medicine Suggestions ──────────────────────────────────
  static const List<String> medicineSuggestions = [
    'Maharasnadi yog', 'Raktapachak', 'Madhuyog', 'Avipattikar', 'Ashmarihar',
    'Janusandhi Shoolhar', 'Vatarakta Rujahar', 'Talisadi churna',
    'Sitopaladi churna', 'Hingvashtak Churna', 'Bhaskar Lavan Churna',
    'Haridrakhand', 'Mahasudarshan', 'Menses Formula', 'Ansashoolhar',
    'Bilvadi Churna', 'Raktadab Yog', 'Triphala Churna', 'Triphala Guggul',
    'Sukh + Arsh', 'Raktarth Formula', 'Karpuradi', 'RTI', 'Numo',
    'Mansapachak', 'Eladi Churna', 'Madhukhwath', 'Aargwadh Kapila',
    'Arogyavardhini', 'Allerco', 'Asthiposhak Vati', 'Brahmi Vati',
    'Chandrakala Ras', 'Chitrakadi Vati', 'Crustone', 'Dhatri Loha',
    'Diarid', 'Eladi Vati', 'Gandhak Rasayan', 'Gandharva Haritaki',
    'Gudmar Ghan', 'Rasapachak vati', 'Kamdudha', 'Kamdudha (M.Yu.)',
    'Kanaksundar vati', 'Krumighn Vati', 'Kumari Asava', 'Kutaj Ghan',
    'Laghu Sutshekhar', 'Laghu Malini Vasant', 'Laxmi Vilas Ras',
    'Mansapachak Vati', 'Medopachak', 'Navayas Loha Vati', 'Pcyst-o-tab',
    'Pachak Vati', 'Rasapachak', 'Patolnimbadi Yog', 'Pathyadi Vati',
    'Pravala Panchamrut', 'Pravala Panchamrut (M.Yu.)', 'Punarnava Mandur',
    'Rajni Yog', 'Rajapravartini Vati', 'Raktastambhak Vati', 'Rasgandha',
    'Sanshmani Vati', 'Sariva Manjishta Vati', 'Sarivadi Vati', 'Shankh Vati',
    'Shephali Vati', 'Shwas Kuthar Ras', 'Sukshma Triphala', 'Sutagandha',
    'Sutshekhar Ras', 'Tapyadi Loha', 'Tribhuvan Kirti', 'Vatagajankush Ras',
    'Amrutadi Guggul', 'Gokshuradi Guggul', 'Kaishor Guggul',
    'Kanchanar Guggul', 'Kukkutankhi Guggul', 'Lakshadi Guggul',
    'Mahayograj Guggul', 'Yograj Guggul', 'Medohar Guggul',
    'Panchatikta Ghrit Guggul', 'Punarnavadi Guggul', 'Rasnadi Guggul',
    'Singhnad Guggul', 'Trayodashang Guggul',
  ];

  // ─── Symptom Suggestions ──────────────────────────────────
  static const List<String> symptomSuggestions = [
    'Radiating pain', 'Tingling numbness', 'Sciatica - radiating leg pain',
    'Joint pain', 'Stiffness', 'Crepitus', 'Swelling',
    'Chills and shivering', 'Sweating', 'Headache', 'Muscle aches',
    'Fatigue', 'Dehydration', 'Loss of appetite',
    'Sore throat', 'Difficulty swallowing', 'Constipation',
    'Lower back pain', 'Neck pain', 'Neck stiffness',
    'Radiating pain and numbness', 'Weight gain', 'Dryness',
    'Weight loss', 'Anxiety', 'Irritability', 'Excessive thirst',
    'Frequent urination', 'Outer elbow pain', 'Radiating discomfort',
    'Shoulder pain and stiffness', 'Irregular periods',
    'Abnormal heavy bleeding', 'Infertility', 'Heel pain',
    'Loose motion', 'Vomiting', 'Burning micturation',
    'Flank or back pain', 'Blood in urine', 'Painful urination',
    'Nausea', 'Dry eyes', 'Burning eyes', 'Chest pain',
    'Burning sensation in chest', 'Difficulty in breathing',
    'Dizziness', 'Anemia',
  ];

  // ─── Backup Periods ───────────────────────────────────────
  static const List<String> backupPeriods = [
    '1 Month', '3 Months', '6 Months', '12 Months', 'Complete Backup'
  ];

  // ─── Month Names ──────────────────────────────────────────
  static const List<String> monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  // ─── Day Abbreviations ────────────────────────────────────
  static const List<String> dayAbbreviations = [
    'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'
  ];

  // ─── Colors ───────────────────────────────────────────────
  static const Color primary = Color(0xFF1A506C);
  static const Color primaryLight = Color(0xFF2A6E90);
  static const Color success = Color(0xFF1A8C5B);
  static const Color whatsapp = Color(0xFF25D366);
}
