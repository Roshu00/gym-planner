import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import '../tokens/spacing.dart';

InputDecoration _decoration(BuildContext context, {String? hint, Widget? prefix}) {
  final cl = context.cl;
  final c = cl.colors;
  OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(ClRadius.xs),
    borderSide: BorderSide(color: color, width: width),
  );
  return InputDecoration(
    isDense: true,
    hintText: hint,
    hintStyle: TextStyle(color: c.inkMuted),
    prefixIcon: prefix,
    prefixIconColor: c.inkMuted,
    filled: true,
    fillColor: c.surfaceRaised,
    contentPadding: const EdgeInsets.symmetric(horizontal: ClSpace.s4, vertical: ClSpace.s3 + 2),
    enabledBorder: border(Colors.transparent, 0),
    border: border(Colors.transparent, 0),
    focusedBorder: border(c.focus, ClSize.focusRing),
    errorBorder: border(c.danger, 1.5),
    focusedErrorBorder: border(c.danger, ClSize.focusRing),
    disabledBorder: border(Colors.transparent, 0),
    errorStyle: cl.text.label.copyWith(color: c.danger),
  );
}

/// Text input: filled `surface-raised`, radius 12, 2px ink focus ring, `label` above.
class ClTextField extends StatelessWidget {
  const ClTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.onChanged,
    this.error,
    this.icon,
    this.keyboardType,
    this.obscure = false,
    this.enabled = true,
    this.maxLines = 1,
  });

  /// More than 1 for creator notes and messages.
  final int maxLines;

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  /// Plain sentence: `Set nije sačuvan. Pokušaj ponovo.`
  final String? error;
  final IconData? icon;
  final TextInputType? keyboardType;
  final bool obscure;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[Text(label!, style: cl.text.label), const SizedBox(height: ClSpace.s2)],
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: ClSize.target),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            enabled: enabled,
            obscureText: obscure,
            keyboardType: maxLines > 1 ? TextInputType.multiline : keyboardType,
            minLines: 1,
            maxLines: maxLines,
            style: cl.text.body,
            cursorColor: cl.colors.ink,
            decoration: _decoration(
              context,
              hint: hint,
              prefix: icon == null ? null : Icon(icon, size: 20),
            ).copyWith(errorText: error, errorMaxLines: 2),
          ),
        ),
      ],
    );
  }
}

/// Compact numeric input for weights, reps and RIR. Uses the `data` style,
/// accepts a decimal comma. Shows [hint] (e.g. last time's value) when empty.
class ClNumberField extends StatefulWidget {
  const ClNumberField({
    super.key,
    required this.value,
    required this.onChanged,
    this.hint,
    this.decimal = false,
    this.semanticLabel,
    this.textInputAction = TextInputAction.next,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String? hint;
  final bool decimal;
  final String? semanticLabel;
  final TextInputAction textInputAction;

  @override
  State<ClNumberField> createState() => _ClNumberFieldState();
}

class _ClNumberFieldState extends State<ClNumberField> {
  late final _controller = TextEditingController(text: widget.value);
  final _focus = FocusNode();

  @override
  void didUpdateWidget(ClNumberField old) {
    super.didUpdateWidget(old);
    if (!_focus.hasFocus && widget.value != _controller.text) _controller.text = widget.value;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Semantics(
      label: widget.semanticLabel,
      child: SizedBox(
        height: 42,
        child: TextField(
          controller: _controller,
          focusNode: _focus,
          onChanged: widget.onChanged,
          expands: true,
          maxLines: null,
          textAlign: TextAlign.center,
          textAlignVertical: TextAlignVertical.center,
          textInputAction: widget.textInputAction,
          keyboardType: TextInputType.numberWithOptions(decimal: widget.decimal),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(widget.decimal ? r'[0-9.,]' : r'[0-9]')),
            LengthLimitingTextInputFormatter(widget.decimal ? 6 : 3),
          ],
          style: cl.text.data,
          cursorColor: cl.colors.ink,
          decoration: _decoration(context, hint: widget.hint).copyWith(
            contentPadding: const EdgeInsets.symmetric(horizontal: ClSpace.s1),
            hintStyle: cl.text.data.copyWith(color: cl.colors.inkMuted),
          ),
        ),
      ),
    );
  }
}
