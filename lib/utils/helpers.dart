class Helpers {
  /// Calculate age from date of birth string (YYYY-MM-DD)
  static int calculateAge(String dobString) {
    final dob = DateTime.tryParse(dobString);
    if (dob == null) return 0;
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  /// Format currency in Indian Rupee format
  static String formatCurrency(num amount) {
    return '₹${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{2})+(\d{3})(?!\d))'),
          (m) => '${m[1]},',
        )}';
  }
}
