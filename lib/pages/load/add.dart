import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:king011_icons/king011_icons.dart';
import 'package:webpctv/db/data/account.dart';
import 'package:webpctv/environment.dart';
import 'package:webpctv/rpc/webapi/client.dart';
import 'package:webpctv/widget/spin.dart';
import 'package:webpctv/widget/state.dart';

class _FocusID {
  _FocusID._();
  static const url = 'url';
  static const name = 'name';
  static const password = 'password';
  static const submit = 'submit';
}

class MyAddPage extends StatefulWidget {
  const MyAddPage({
    Key? key,
    this.account,
  }) : super(key: key);
  final Account? account;
  @override
  _MyAddPageState createState() => _MyAddPageState();
}

abstract class _State extends MyState<MyAddPage> {
  final _urlController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();

  final _form = GlobalKey<FormState>();

  dynamic _error;
  final _cancelToken = CancelToken();

  _submit() async {
    final url = _urlController.text;
    final name = _nameController.text;
    final password = _passwordController.text;

    if (widget.account != null) {
      final account = widget.account!;
      if (account.url == url &&
          account.name == name &&
          account.password == password) {
        Navigator.of(context).pop();
        return;
      }
    }
    setState(() {
      disabled = true;
      _error = null;
    });
    try {
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        throw Exception('invalid url');
      }

      // verify
      final client = Client(
        baseUrl: url,
        name: name,
        password: password,
      );
      await client.sigin(cancelToken: _cancelToken);
      checkAlive();

      //     final status = await client.getStatus(cancelToken: _cancelToken);
      //     checkAlive();
      //     client.status = status;
      //     // save db
      //     final helper = (await DB.helpers).account;
      //     checkAlive();
      //     final account = Account(id: 0, url: url, name: name, password: password);
      //     if (widget.account == null) {
      //       // add
      //       final id = await helper.add(account);
      //       debugPrint('insert id: $id');
      //       checkAlive();
      //       account.id = id;
      //       client.account = id;
      //     } else {
      //       // edit
      //       account.id = widget.account!.id;
      //       await helper.updateById(
      //         account.id,
      //         account.toMap()..remove(AccountHelper.columnID),
      //       );
      //       checkAlive();
      //     }
      //     if (widget.push) {
      //       MySettings.instance.setAccount(account.id);
      //       Navigator.of(context).pushReplacement(
      //         MaterialPageRoute(
      //           builder: (_) => MyHomePage(
      //             client: client,
      //           ),
      //         ),
      //       );
      //     } else {
      //       Navigator.of(context).pop(account);
      //     }
      aliveSetState(() {
        disabled = false;
      });
    } catch (e) {
      aliveSetState(() {
        disabled = false;
        _error = e;
      });
    }
  }
}

class _MyAddPageState extends _State with _KeyboardComponent {
  @override
  void initState() {
    super.initState();
    final account = widget.account;
    if (account != null) {
      _urlController.text = account.url;
      _nameController.text = account.name;
      _passwordController.text = account.password;
    }
    if (!_urlController.text.startsWith('http://') &&
        !_urlController.text.startsWith('https://')) {
      final focus = createFocusNode(_FocusID.url);
      if (focus.canRequestFocus) {
        focus.requestFocus();
      }
    } else if (_nameController.text.isEmpty) {
      final focus = createFocusNode(_FocusID.name);
      if (focus.canRequestFocus) {
        focus.requestFocus();
      }
    } else if (_passwordController.text.isEmpty) {
      final focus = createFocusNode(_FocusID.password);
      if (focus.canRequestFocus) {
        focus.requestFocus();
      }
    }
    listenKeyUp(onKeyUp);
  }

  @override
  void dispose() {
    _cancelToken.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: _build(context),
      onWillPop: () => Future.value(enabled),
    );
  }

  Widget _build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: backOfAppBar(context, disabled: disabled),
        title: const Text('Server Metadata '),
      ),
      body: Form(
        key: _form,
        child: ListView(
          children: [
            FocusScope(
              node: focusScopeNode,
              child: TextFormField(
                enabled: enabled,
                controller: _urlController,
                focusNode: createFocusNode(_FocusID.url),
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  prefixIcon: Icon(MaterialCommunityIcons.server),
                  label: Text('URL'),
                ),
                onEditingComplete: () => setFocus(_FocusID.name),
              ),
            ),
            FocusScope(
              node: focusScopeNode,
              child: TextFormField(
                enabled: enabled,
                controller: _nameController,
                focusNode: createFocusNode(_FocusID.name),
                keyboardType: TextInputType.name,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.account_circle),
                  label: Text('Username'),
                ),
                onEditingComplete: () => setFocus(_FocusID.password),
              ),
            ),
            FocusScope(
              node: focusScopeNode,
              child: TextFormField(
                enabled: enabled,
                controller: _passwordController,
                focusNode: createFocusNode(_FocusID.password),
                keyboardType: TextInputType.visiblePassword,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.password),
                  label: Text('Password'),
                ),
                onEditingComplete: () => setFocus(_FocusID.submit),
              ),
            ),
            _error == null
                ? Container()
                : Container(
                    padding: const EdgeInsets.all(MyEnvironment.viewPadding),
                    child: Text(
                      '$_error',
                      style: TextStyle(color: Theme.of(context).errorColor),
                    ),
                  ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  Widget? _buildFloatingActionButton(BuildContext context) {
    if (disabled) {
      return createSpinFloating();
    }
    return FocusScope(
      node: focusScopeNode,
      child: FloatingActionButton(
        focusColor: Theme.of(context).focusColor.withOpacity(0.5),
        focusNode: createFocusNode(_FocusID.submit),
        child: const Icon(Icons.send),
        tooltip: 'Submit',
        onPressed: disabled ? null : _submit,
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
    } else if (evt.logicalKey == LogicalKeyboardKey.arrowDown) {
      final focused = focusedNode();
      if (focused != null) {
        _nextFocus(focused);
      }
    }
  }

  _nextFocus(MyFocusNode focused) {
    switch (focused.id) {
      case _FocusID.url:
        setFocus(_FocusID.name, focused: focused.focusNode);
        break;
      case _FocusID.name:
        setFocus(_FocusID.password, focused: focused.focusNode);
        break;
      case _FocusID.password:
        setFocus(_FocusID.submit, focused: focused.focusNode);
        break;
      case _FocusID.submit:
        setFocus(_FocusID.url, focused: focused.focusNode);
        break;
    }
  }

  _selectFocused(MyFocusNode focused) {
    switch (focused.id) {
      case _FocusID.url:
      case _FocusID.name:
      case _FocusID.password:
        _nextFocus(focused);
        break;
      case _FocusID.submit:
        _submit();
        break;
    }
  }
}
