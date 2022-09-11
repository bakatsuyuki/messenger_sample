import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('run開始');
  await Firebase.initializeApp();
  print('initializeApp終了');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const MyHomePage(title: 'Flutter Demo Home Page'),
      ),
    );
  }
}

class MyHomePage extends ConsumerWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: ref.watch(counterProvider).when(
              data: (data) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'ボタンを押した回数は:',
                  ),
                  Text(
                    // 更新を検知したいので `watch` で取得
                    '$data',
                    style: Theme.of(context).textTheme.headline4,
                  ),
                ],
              ),
              loading: () => Container(),
              error: (Object error, StackTrace? stackTrace) {
                return Container();
              },
            ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // ボタンタップ時に呼ばれる
          // ここでカウンターのインクリメントをしている
          ref.read(incrementProvider)();
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

final counterProvider = StreamProvider((ref) {
  return ref.watch(counterRefProvider).onValue.transform(
    StreamTransformer<DatabaseEvent, int?>.fromHandlers(
        handleData: (value, sink) {
      sink.add(value.snapshot.value as int?);
    }),
  );
});

final counterRefProvider = Provider((ref) {
  return FirebaseDatabase.instance.ref('counter');
});

final incrementProvider = Provider(
  (ref) => () {
    final currentValue = ref.read(counterProvider).value;
    ref.watch(counterRefProvider).set((currentValue ?? 0) + 1);
  },
);
