import 'package:flutter/material.dart';

class LanguageController {
  static final ValueNotifier<bool> isTamil = ValueNotifier(false);

  static void toggleLanguage() {
    isTamil.value = !isTamil.value;
  }

  static void setTamil(bool value) {
    isTamil.value = value;
  }
}
