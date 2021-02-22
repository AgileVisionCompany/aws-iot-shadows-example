

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:shadows/const/colors.dart';
import 'package:shadows/const/dimens.dart';
import 'package:shadows/const/images.dart';
import 'package:shadows/widgets/common.dart';

enum HintMode {

  /// hint is displayed inside the field and is show only if the field is empty
  text,

  /// hint is displayed above the field
  hint,

  /// 2 hints are displayed, one -> above the input, another -> in the input
  both

}

enum PasswordMode {

  /// input value is displayed to the user
  noPassword,

  /// input value is not displayed to the user
  simplePassword,

  /// input value is not visible by default but the user can make it visible
  revealablePassword

}

/// Default text input
class FineInput extends StatefulWidget {

  final GlobalKey inputKey;

  /// Hint to be displayed near the text input
  final String hint;

  /// Displayed only if [hintMode] = both
  final String secondHint;

  /// The type of text input action (e.g. done, next, search).
  ///
  /// Depending on the value the corresponding button is displayed in the virtual keyboard.
  final TextInputAction inputAction;

  /// How the hint should be displayed. See [HintMode] for details.
  final HintMode hintMode;

  /// Whether the chars should be displayed to the user or they should be hidden.
  ///
  /// See [PasswordMode] for details
  final PasswordMode passwordMode;

  /// Text controller which is used to handle the text input state (usually used
  /// for getting/setting input value)
  final TextEditingController controller;

  /// Focus controller which allows setting/clearing focus
  final FocusNode focusNode;

  /// Whether the field is required or not. If required, an asterisk char is added to the hint.
  final bool required;

  /// The type of virtual keyboard & text input look to be displayed.
  final TextInputType textInputType;

  /// An image to be shown to the left side of the input
  final AssetImage prefixImage;

  /// This callback is called when the user confirms the enetered value (e.g. he
  /// presses 'Done' button on the virtual keyboard)
  final Function(String) onSubmitted;

  /// Pass [true] to decrease the height of the input
  final bool isSmall;

  /// Error message to be displayed near the input field (may be NULL or empty)
  final String errorMessage;

  FineInput({
    this.hint,
    this.secondHint,
    this.inputAction = TextInputAction.done,
    this.passwordMode = PasswordMode.noPassword,
    this.hintMode = HintMode.text,
    this.required = false,
    this.controller,
    this.focusNode,
    this.textInputType,
    this.prefixImage,
    this.onSubmitted,
    this.isSmall = false,
    this.inputKey,
    this.errorMessage
  });

  @override
  State createState() {
    return _FineInputState();
  }

}

class _FineInputState extends State<FineInput> with SingleTickerProviderStateMixin {

  bool _isRevealed = false;
  FocusedBackgroundController _focusedBackgroundController;

  bool _hasErrorMessage() => widget.errorMessage != null && widget.errorMessage.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _focusedBackgroundController = FocusedBackgroundController(widget.focusNode);
    _focusedBackgroundController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
    _focusedBackgroundController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    TextField inputWidget = _buildInputWidget();
    Widget containerChild;

    containerChild = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (widget.hintMode == HintMode.hint || widget.hintMode == HintMode.both) ...[
          Text(
            hintText(),
            key: widget.inputKey,
            style: TextStyle(
                fontSize: AppDimens.defaultTextSize,
                color: AppColors.lightHintText
            ),
          ),
          Widgets.verticalSpace(height: AppDimens.smallSpace),
        ],
        inputWidget,
        if (_hasErrorMessage()) _buildErrorMessage()
      ],
    );

    return AnimatedSize(
        duration: AppDimens.animationDuration,
        vsync: this,
        child: Container(
            width: double.infinity,
            child: containerChild
        ),
    );
  }

  Widget _buildInputWidget() {
    String hint;
    if (widget.hintMode == HintMode.both) {
      hint = widget.secondHint;
    } else if (widget.hintMode == HintMode.text) {
      hint = hintText();
    } else {
      hint = null;
    }

    return TextField(
      key: widget.hintMode == HintMode.text ? widget.inputKey : null,
      controller: widget.controller,
      textInputAction: widget.inputAction,
      keyboardType: widget.textInputType,
      focusNode: _focusedBackgroundController.focusNode,
      obscureText: widget.passwordMode != PasswordMode.noPassword && !_isRevealed,
      onSubmitted: widget.onSubmitted,
      style: _hasErrorMessage() ? TextStyle(color: AppColors.errorText) : null,
      decoration: InputDecoration(
        filled: true,
        fillColor: _focusedBackgroundController.inputBackgroundColor,
        hintText: hint,
        hintStyle: TextStyle(
          color: AppColors.inputHint
        ),
        contentPadding: EdgeInsets.symmetric(vertical: widget.isSmall ? 10 : 20, horizontal: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppDimens.inputRadius)),
          borderSide: _hasErrorMessage() ? BorderSide(color: AppColors.errorAccent, width: 1) : BorderSide.none
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.inputActiveBorder),
          borderRadius: BorderRadius.all(Radius.circular(AppDimens.inputRadius)),
        ),
        suffixIcon: _buildRevealPasswordButton(),
        prefixIcon: _buildPrefix(),
      ),
    );
  }

  Widget _buildRevealPasswordButton() {
    if (widget.passwordMode == PasswordMode.revealablePassword) {
      return GestureDetector(
          onTap: () {
            setState(() {
              _isRevealed = !_isRevealed;
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 11),
            child: ImageIcon(
              AssetImage(_isRevealed ? AppImages.iconHidePassword : AppImages.iconShowPassword),
              color: AppColors.primaryAction,
            ),
          ),
        );
    } else {
      return null;
    }
  }

  Widget _buildPrefix() {
    if (widget.prefixImage == null) {
      return null;
    } else {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 11),
        child: ImageIcon(
          widget.prefixImage,
          color: AppColors.primaryAction,
        ),
      );
    }
  }

  Widget _buildErrorMessage() {
    return Widgets.hint(
      widget.errorMessage,
      color: AppColors.errorText
    );
  }

  String hintText() {
    return "${widget.hint}${widget.required ? " *" : ""}";
  }
}

class FocusedBackgroundController extends ChangeNotifier {
  bool _isFocused = false;
  bool _shouldRelease = false;

  FocusNode focusNode;

  FocusedBackgroundController(FocusNode focusNode) {
    if (focusNode == null) {
      this.focusNode = FocusNode();
      _shouldRelease = true;
    } else {
      this.focusNode = focusNode;
      _shouldRelease = false;
    }
    this.focusNode.addListener(() {
      _isFocused = this.focusNode.hasFocus;
      notifyListeners();
    });
  }

  Color get inputBackgroundColor => _isFocused ? AppColors.inputBackgroundFocused : AppColors.inputBackground;

  @override
  void dispose() {
    super.dispose();
    if (_shouldRelease) focusNode?.dispose();
  }

}