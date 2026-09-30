import 'dart:async';

import 'package:flutter/material.dart';

import '../config.dart';
import '../data/auth.dart';
import '../ui/chalkline_ui.dart';
import 'common.dart';

/// Email and a 6-digit code, no password. Also used to turn a guest into an
/// account ([saveAccount]).
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.auth, this.saveAccount = false});

  final AuthService auth;

  /// Guest → email account, keeping the same user and data.
  final bool saveAccount;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;
  String? _error;
  int _cooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _cooldown <= 1) {
        t.cancel();
        if (mounted) setState(() => _cooldown = 0);
        return;
      }
      setState(() => _cooldown--);
    });
  }

  Future<void> _send() => _run(() async {
    widget.saveAccount ? await widget.auth.saveAccount(_email.text) : await widget.auth.sendCode(_email.text);
    if (!mounted) return;
    setState(() => _codeSent = true);
    _startCooldown();
  });

  Future<void> _verify() => _run(() async {
    if (widget.saveAccount) {
      await widget.auth.verifySavedAccount(_email.text, _code.text);
      if (mounted) Navigator.of(context).pop(true);
    } else {
      await widget.auth.verifyCode(_email.text, _code.text);
    }
  });

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final emailOk = isValidEmail(_email.text);
    final codeOk = RegExp(r'^\d{6}$').hasMatch(_code.text.trim());

    final List<Widget> body;
    final Widget action;
    if (!_codeSent) {
      body = [
        ClScreenTitle(
          label: widget.saveAccount ? 'Sačuvaj nalog' : appName,
          title: widget.saveAccount ? 'Tvoj email.' : 'Prijavi se.',
        ),
        const SizedBox(height: ClSpace.s3),
        Text(
          widget.saveAccount
              ? 'Šaljemo ti kod. Tvoji treninzi, plan i pretplate ostaju isti, samo su vezani za email.'
              : 'Šaljemo ti kod od 6 cifara. Bez lozinke. Isti email radi i na drugom telefonu.',
          style: cl.text.body.copyWith(color: cl.colors.inkMuted),
        ),
        const SizedBox(height: ClSpace.s6),
        ClTextField(
          label: 'Email',
          hint: 'ana@primer.rs',
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) => setState(() {}),
        ),
      ];
      action = ClButton.block(
        label: _busy ? 'Šaljem' : 'Pošalji kod',
        onPressed: emailOk && !_busy ? _send : null,
      );
    } else {
      body = [
        ClScreenTitle(label: _email.text.trim(), title: 'Upiši kod.'),
        const SizedBox(height: ClSpace.s3),
        Text(
          'Poslali smo 6 cifara na tvoj email. Ako ga ne vidiš, pogledaj i neželjenu poštu.',
          style: cl.text.body.copyWith(color: cl.colors.inkMuted),
        ),
        const SizedBox(height: ClSpace.s6),
        ClTextField(
          label: 'Kod',
          hint: '123456',
          controller: _code,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: ClSpace.s2),
        Wrap(
          spacing: ClSpace.s4,
          children: [
            ClButton(
              label: _cooldown > 0 ? 'Pošalji ponovo za $_cooldown s' : 'Pošalji ponovo',
              variant: ClButtonVariant.text,
              onPressed: _cooldown > 0 || _busy ? null : _send,
            ),
            ClButton(
              label: 'Promeni email',
              variant: ClButtonVariant.text,
              onPressed: _busy
                  ? null
                  : () => setState(() {
                      _codeSent = false;
                      _code.clear();
                      _error = null;
                    }),
            ),
          ],
        ),
      ];
      action = ClButton.block(
        label: _busy ? 'Proveravam' : (widget.saveAccount ? 'Sačuvaj nalog' : 'Prijavi se'),
        onPressed: codeOk && !_busy ? _verify : null,
      );
    }

    return AppScreen(
      topBar: widget.saveAccount ? const ClTopBar(label: 'Nalog') : null,
      bottom: action,
      children: [
        if (!widget.saveAccount) const SizedBox(height: ClSpace.s12),
        ...body,
        if (_error != null) ...[const SizedBox(height: ClSpace.s3), ClNotice(_error!, danger: true)],
        if (!widget.saveAccount && !_codeSent) ...[
          gap,
          const ClDivider(),
          gapS,
          Text(
            'Možeš i da probaš bez naloga. Podaci ostaju na ovom telefonu dok ne sačuvaš nalog.',
            style: cl.text.body.copyWith(color: cl.colors.inkMuted),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: ClButton(
              label: 'Probaj bez naloga',
              variant: ClButtonVariant.text,
              onPressed: _busy ? null : () => _run(widget.auth.continueAsGuest),
            ),
          ),
        ],
      ],
    );
  }
}
