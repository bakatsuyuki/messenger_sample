import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterfire_ui/auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
      body: const _Page(),
    );
  }
}

class _TextField extends ConsumerWidget {
  const _TextField({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Theme.of(context).primaryColor,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                focusNode: ref.watch(nodeProvider),
                controller: ref.watch(textEditingController),
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                maxLines: null,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.all(
                      Radius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              ref.read(sendMessage)();
            },
            icon: Icon(
              Icons.send,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Page extends ConsumerWidget {
  const _Page({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(userProvider).when(
          data: (data) => data == null
              ? const SignInScreen(
                  providerConfigs: [
                    EmailProviderConfiguration(),
                  ],
                )
              : ref.watch(messagesProvider).when(
                    data: (data) => Column(
                      children: [
                        Expanded(
                          child: ListView(
                            children:
                                data.map((e) => Text(e.toString())).toList(),
                          ),
                        ),
                        const _TextField(),
                      ],
                    ),
                    loading: () => Container(),
                    error: (Object error, StackTrace? stackTrace) {
                      return Container();
                    },
                  ),
          error: (_, __) => Container(),
          loading: () => Container(),
        );
  }
}

final counterProvider = StreamProvider((ref) {
  return ref.watch(counterRefProvider).onValue.transform(
    StreamTransformer<DatabaseEvent, int?>.fromHandlers(
        handleData: (value, sink) {
      sink.add(value.snapshot.value as int? ?? 0);
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

final messagesProvider = StreamProvider((ref) {
  return ref.watch(messagesRefProvider).onValue.transform(
    StreamTransformer<DatabaseEvent, List<Object?>>.fromHandlers(
        handleData: (value, sink) {
      sink.add(value.snapshot.value as List<Object?>);
    }),
  );
});

final messagesRefProvider = Provider((ref) {
  return FirebaseDatabase.instance.ref('messages');
});

final sendMessage = Provider(
  (ref) => () {
    final currentValue = ref.read(messagesProvider).value;
    final message = ref.read(textEditingController).text;
    ref.read(messagesRefProvider).set((currentValue?.toList()?..add(message)));
    ref.read(textEditingController).text = '';
    ref.read(nodeProvider).unfocus();
  },
);

final userProvider = StreamProvider((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final textEditingController = Provider((_) {
  return TextEditingController();
});

final nodeProvider = Provider((_) {
  return FocusNode();
});
