import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'local_store.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  final LocalStore localStore;

  ThemeCubit(this.localStore)
      : super(localStore.darkMode ? ThemeMode.dark : ThemeMode.light);

  Future<void> setDarkMode(bool value) async {
    await localStore.saveDarkMode(value);
    emit(value ? ThemeMode.dark : ThemeMode.light);
  }
}
