import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webpctv/service/key_event_service.dart';

Future<bool> showConfirmationDialog(
  BuildContext context,
  Widget title,
  Widget child,
) {
  return showDialog(
    context: context,
    builder: (context) => MyConfirmationDialog(
      title: title,
      child: child,
    ),
  ).then((ok) {
    return (ok ?? false);
  });
}

class MyConfirmationDialog extends StatefulWidget {
  const MyConfirmationDialog({
    Key? key,
    this.title,
    required this.child,
  }) : super(key: key);
  final Widget? title;
  final Widget child;
  @override
  _MyAccountPageState createState() => _MyAccountPageState();
}

class _MyAccountPageState extends State<MyConfirmationDialog> {
  final _focusScopeNode = FocusScopeNode();
  final _focusOk = FocusNode();
  final _focusCancel = FocusNode();
  @override
  void initState() {
    super.initState();
    KeyEventService.instance.addKeyUpListener(_listener);
  }

  _listener(KeyEvent evt) {
    if (!_focusScopeNode.hasFocus) {
      return;
    }
    if (evt.logicalKey == LogicalKeyboardKey.select) {
      if (_focusOk.hasFocus) {
        Navigator.of(context).pop(true);
      } else if (_focusCancel.hasFocus) {
        Navigator.of(context).pop(false);
      }
    }
  }

  @override
  void dispose() {
    KeyEventService.instance.removeKeyUpListener(_listener);
    _focusOk.dispose();
    _focusCancel.dispose();
    _focusScopeNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: widget.title,
      content: SingleChildScrollView(
        child: widget.child,
      ),
      actions: <Widget>[
        FocusScope(
          autofocus: true,
          node: _focusScopeNode,
          child: TextButton(
            focusNode: _focusOk,
            child: Text(MaterialLocalizations.of(context).okButtonLabel),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ),
        FocusScope(
          node: _focusScopeNode,
          child: TextButton(
            focusNode: _focusCancel,
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ),
      ],
    );
  }
}
