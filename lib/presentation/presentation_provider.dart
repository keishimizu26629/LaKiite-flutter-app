import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userNameControllerStateProvider = StateProvider<TextEditingController>(
    (_) => TextEditingController(text: ''));

final emailAddressControllerStateProvider = StateProvider<TextEditingController>(
    (_) => TextEditingController(text: ''));

final dateOfBirthControllerStateProvider = StateProvider<TextEditingController>(
    (_) => TextEditingController(text: ''));

final passwordControllerStateProvider = StateProvider<TextEditingController>(
    (_) => TextEditingController(text: ''));
