import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:webpctv/db/db.dart';
import 'package:webpctv/environment.dart';
import 'package:webpctv/pages/load/add.dart';
import 'package:webpctv/widget/state.dart';

class _FocusID {
  _FocusID._();
  static const refish = 'refish';
}

class MyLoadPage extends StatefulWidget {
  const MyLoadPage({
    Key? key,
  }) : super(key: key);
  @override
  _MyLoadPageState createState() => _MyLoadPageState();
}

abstract class _State extends MyState<MyLoadPage> {
  dynamic _error;
  _refish() async {
    aliveSetState(() {
      disabled = true;
      _error = null;
    });
    try {
      // get account
      final helper = (await DB.helpers).account;
      checkAlive();
      var account = await helper.getById(1);
      checkAlive();
      if (account == null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const MyAddPage(),
          ),
        );
      } else {}
      // Navigator.of(context).pushReplacement(
      //   MaterialPageRoute(
      //     builder: (_) => MyHomePage(
      //       client: Client(
      //         account: account!.id,
      //         baseUrl: account.url,
      //         name: account.name,
      //         password: account.password,
      //       ),
      //     ),
      //   ),
      // );
      // return;

      // Navigator.of(context).pushReplacementNamed(MyRoutes.firstAdd);
    } catch (e) {
      aliveSetState(() {
        _error = e;
        disabled = false;
      });
    }
  }
}

class _MyLoadPageState extends _State with _KeyboardComponent {
  @override
  void initState() {
    super.initState();
    Future.value().then((value) => _refish());
    listenKeyUp(onKeyUp);
  }

  @override
  Widget build(BuildContext context) {
    if (disabled) {
      return const Scaffold(
        body: Center(
          child: SizedBox(
            height: 60,
            child: FittedBox(
              child: CupertinoActivityIndicator(),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(MyEnvironment.viewPadding),
        child: Text(
          '$_error',
          style: TextStyle(color: Theme.of(context).errorColor),
        ),
      ),
      floatingActionButton: FocusScope(
        node: focusScopeNode,
        child: FloatingActionButton(
          focusColor: Theme.of(context).focusColor.withOpacity(0.5),
          focusNode: createFocusNode(_FocusID.refish),
          child: const Icon(Icons.refresh),
          tooltip: 'Refish',
          onPressed: disabled ? null : _refish,
        ),
      ),
    );
  }
}

mixin _KeyboardComponent on _State {
  void onKeyUp(KeyEvent evt) {
    if (evt.logicalKey == LogicalKeyboardKey.select) {
      if (enabled) {
        final focused = focusedNode();
        if (focused != null) {
          _selectFocused(focused);
        }
      }
    } else if (evt.logicalKey == LogicalKeyboardKey.arrowDown ||
        evt.logicalKey == LogicalKeyboardKey.arrowUp ||
        evt.logicalKey == LogicalKeyboardKey.arrowLeft ||
        evt.logicalKey == LogicalKeyboardKey.arrowRight) {
      final focused = focusedNode();
      if (focused?.id != _FocusID.refish) {
        setFocus(_FocusID.refish);
      }
    }
  }

  _selectFocused(MyFocusNode focused) {
    switch (focused.id) {
      case _FocusID.refish:
        _refish();
        break;
    }
  }
}
