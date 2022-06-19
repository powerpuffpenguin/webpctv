import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:webpctv/db/data/account.dart';
import 'package:webpctv/environment.dart';
import 'package:webpctv/pages/dev/dev.dart';
import 'package:webpctv/pages/load/add.dart';
import 'package:webpctv/rpc/webapi/client.dart';
import 'package:webpctv/widget/state.dart';

class _FocusID {
  _FocusID._();
  static const account = 'account';
  static const help = 'help';
  static const about = 'about';
}

class MyDrawerView extends StatefulWidget {
  const MyDrawerView({
    Key? key,
    this.disabled = false,
    required this.client,
  }) : super(key: key);

  /// 是否禁用 功能按鈕
  final bool disabled;

  final Client client;
  @override
  _MyDrawerViewState createState() => _MyDrawerViewState();
}

abstract class _State extends MyState<MyDrawerView> {
  final _recognizer = <String, TapGestureRecognizer>{};
  TapGestureRecognizer createRecognizer(String id) {
    var recognizer = _recognizer[id];
    if (recognizer == null) {
      recognizer = TapGestureRecognizer();
      _recognizer[id] = recognizer;
    }
    return recognizer;
  }

  @override
  void dispose() {
    _recognizer.forEach((key, value) {
      value.dispose();
    });
    super.dispose();
  }

  Widget _richTextUrl(String tag, String url, TextStyle? style) {
    return RichText(
      text: TextSpan(
        children: <TextSpan>[
          TextSpan(style: style, text: '$tag '),
          TextSpan(
            style: style?.copyWith(
              color: Theme.of(context).colorScheme.secondary,
            ),
            text: url,
            recognizer: createRecognizer(url)
              ..onTap = () async {
                try {
                  debugPrint('launch $url');
                  await launchUrlString(url,
                      mode: LaunchMode.externalApplication);
                } catch (e) {
                  BotToast.showText(text: '$e');
                }
              },
          ),
          TextSpan(style: style, text: ' .'),
        ],
      ),
    );
  }

  void _openAbout() {
    final TextStyle? textStyle = Theme.of(context).textTheme.bodyText1;
    final children = <Widget>[
      _richTextUrl(
        'Source code at',
        'https://github.com/powerpuffpenguin/webpctv',
        textStyle,
      ),
      _richTextUrl(
        'LICENSE at',
        'https://raw.githubusercontent.com/powerpuffpenguin/webpctv/main/LICENSE',
        textStyle,
      ),
    ];
    if (Platform.isAndroid) {
      children.add(
          _richTextUrl('Play Store at', MyEnvironment.playStore, textStyle));
    }
    showAboutDialog(
      context: context,
      applicationName: 'Webpc TV',
      applicationVersion: MyEnvironment.version,
      applicationLegalese: MyEnvironment.applicationLegalese,
      children: children,
    );
  }

  void _openHelp() async {
    try {
      const url = 'https://github.com/powerpuffpenguin/webpctv/issues';
      debugPrint('launch $url');
      await launchUrlString(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (isNotClosed) {
        BotToast.showText(text: '$e');
      }
    }
  }

  void _openAccount() {
    final client = widget.client;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MyAddPage(
          account: Account(
            id: 1,
            url: client.url,
            name: client.name,
            password: client.password,
            devices: client.devices,
          ),
        ),
      ),
    );
  }
}

class _MyDrawerViewState extends _State with _KeyboardComponent {
  Client get client => widget.client;
  @override
  void initState() {
    super.initState();
    listenKeyUp(onKeyUp);
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      DrawerHeader(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Image.asset(
              "assets/webpctv.png",
            ),
            Text(client.name),
            Text(client.url),
          ],
        ),
      ),
    ];

    children.addAll(<Widget>[
      FocusScope(
        node: focusScopeNode,
        child: ListTile(
          focusNode: createFocusNode(_FocusID.account),
          leading: const Icon(Icons.account_box),
          title: const Text('account'),
          onTap: widget.disabled ? null : _openAccount,
        ),
      ),
      const Divider(),
      FocusScope(
        autofocus: true,
        node: focusScopeNode,
        child: ListTile(
          focusNode: createFocusNode(_FocusID.help),
          leading: const Icon(Icons.help),
          title: const Text('help'),
          onTap: widget.disabled ? null : _openHelp,
        ),
      ),
      const Divider(),
      FocusScope(
        autofocus: true,
        node: focusScopeNode,
        child: ListTile(
          focusNode: createFocusNode(_FocusID.about),
          leading: const Icon(Icons.info),
          title: Text(
            MaterialLocalizations.of(context)
                .aboutListTileTitle(MyEnvironment.appName),
          ),
          onTap: widget.disabled ? null : _openAbout,
        ),
      ),
    ]);
    if (MyEnvironment.isDebug) {
      children.addAll(<Widget>[
        const Divider(),
        ListTile(
          leading: const Icon(Icons.adb),
          title: const Text("測試"),
          onTap: widget.disabled
              ? null
              : () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MyDevPage(
                        client: widget.client,
                      ),
                    ),
                  );
                },
        ),
      ]);
    }
    return Drawer(
      child: ListView(
        children: children,
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
    }
  }

  _selectFocused(MyFocusNode focused) {
    switch (focused.id) {
      case _FocusID.account:
        _openAccount();
        break;
      case _FocusID.help:
        _openHelp();
        break;
      case _FocusID.about:
        _openAbout();
        break;
    }
  }
}
