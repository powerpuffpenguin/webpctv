import 'package:flutter/material.dart';
import 'package:ppg_ui/state/state.dart';
import 'package:webpctv/service/key_event_service.dart';

class MyFocusNode {
  final String id;
  FocusNode focusNode;
  dynamic data;
  MyFocusNode({required this.id, required this.focusNode, this.data});
  void dispose() {
    focusNode.dispose();
  }

  bool get isArrowBack => id == arrowBack;

  static const openDrawer = 'openDrawer';
  static const arrowBack = 'arrow_back';
}

abstract class MyState<T extends StatefulWidget> extends UIState<T> {
  final _keysFocusNode = <String, MyFocusNode>{};
  final _focusNodeKeys = <FocusNode, MyFocusNode>{};

  final FocusScopeNode focusScopeNode = FocusScopeNode();
  KeyUpListener? _onKeyUp;
  void listenKeyUp(KeyUpListener onKeyUp) {
    if (isClosed) {
      return;
    }
    if (_onKeyUp != null) {
      KeyEventService.instance.removeKeyUpListener(_onKeyUp!);
    }
    _onKeyUp = onKeyUp;
    KeyEventService.instance.addKeyUpListener(onKeyUp);
  }

  @protected
  MyFocusNode? getFocusNode(String id) => _keysFocusNode[id];
  @protected
  FocusNode createFocusNode(String id, {dynamic data}) {
    final focusNode = _keysFocusNode[id];
    if (focusNode != null) {
      if (focusNode.data != data) {
        focusNode.data = data;
      }

      return focusNode.focusNode;
    }
    final add = MyFocusNode(id: id, focusNode: FocusNode(), data: data);
    _keysFocusNode[id] = add;
    _focusNodeKeys[add.focusNode] = add;
    return add.focusNode;
  }

  @protected
  MyFocusNode? focusedNode() {
    if (focusScopeNode.hasFocus) {
      return _focusNodeKeys[focusScopeNode.focusedChild];
    }
    return null;
  }

  @protected
  void setFocus(String id, {FocusNode? focused}) {
    final focus = _keysFocusNode[id]?.focusNode;
    focused?.unfocus();
    if (focus?.canRequestFocus ?? false) {
      focus!.requestFocus();
    }
  }

  @protected
  void nextFocus(List<String> values, MyFocusNode? focused) {
    var i = focused == null ? 0 : values.indexOf(focused.id) + 1;
    if (i >= values.length) {
      i = 0;
    }
    setFocus(values[i], focused: focused?.focusNode);
  }

  @mustCallSuper
  @override
  void dispose() {
    if (_onKeyUp != null) {
      KeyEventService.instance.removeKeyUpListener(_onKeyUp!);
      _onKeyUp = null;
    }
    _keysFocusNode.forEach((key, value) {
      value.dispose();
    });
    focusScopeNode.dispose();
    super.dispose();
  }

  @protected
  Widget? backOfAppBar(
    BuildContext context, {
    dynamic data,
    bool disabled = false,
  }) {
    final ModalRoute<dynamic>? parentRoute = ModalRoute.of(context);
    final bool canPop = parentRoute?.canPop ?? false;
    if (!canPop) {
      return null;
    }
    return FocusScope(
      node: focusScopeNode,
      child: IconButton(
        focusNode: createFocusNode(
          MyFocusNode.arrowBack,
          data: data,
        ),
        icon: const Icon(Icons.arrow_back),
        iconSize: 24,
        onPressed: disabled ? null : () => Navigator.of(context).pop(),
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      ),
    );
  }

  BuildContext? _scaffold;
  openDrawer() {
    if (_scaffold != null) {
      Scaffold.of(_scaffold!).openDrawer();
    }
  }

  @protected
  Widget openDrawerOfAppBar(BuildContext context, {dynamic data}) {
    return FocusScope(
      node: focusScopeNode,
      child: Builder(
        builder: (context) {
          _scaffold = context;
          return IconButton(
            focusNode: createFocusNode(
              MyFocusNode.openDrawer,
              data: data,
            ),
            icon: const Icon(Icons.menu),
            iconSize: 24,
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
          );
        },
      ),
    );
  }
}
