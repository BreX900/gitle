import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mek/mek.dart';

extension BuildAsyncValueExtensions<T> on AsyncValue<T> {
  Widget buildView({required Widget Function(T data) data}) {
    return buildWhen(
      loading: () => const Center(child: CircularProgressIcon()),
      error: (exception, _) => ErrorWidget(exception),
      data: data,
    );
  }
}
