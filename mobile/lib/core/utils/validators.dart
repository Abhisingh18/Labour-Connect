class Validators {
  Validators._();

  static String? phone(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Phone number is required';
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v)) {
      return 'Enter a valid 10-digit mobile number';
    }
    return null;
  }

  static String? required(String? value, [String field = 'This field']) {
    if ((value ?? '').trim().isEmpty) return '$field is required';
    return null;
  }

  static String? name(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Name is required';
    if (v.length < 2) return 'Name is too short';
    return null;
  }
}
