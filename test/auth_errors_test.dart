import 'dart:async';

import 'package:chalkline/data/supabase_backend.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('network problems never look like a wrong code', () {
    expect(
      authFailureFor(AuthRetryableFetchException(message: 'Failed to fetch')).message,
      contains('internet'),
    );
    expect(
      authFailureFor(AuthUnknownException(message: 'x', originalError: 'y')).message,
      contains('internet'),
    );
    expect(authFailureFor(TimeoutException('t')).message, contains('internet'));
    expect(authFailureFor(StateError('socket')).message, contains('internet'));
  });

  test('auth error codes map to actionable messages', () {
    String msg(String code, {String? status}) =>
        authFailureFor(AuthApiException('Token has expired or is invalid', code: code, statusCode: status))
            .message;
    expect(msg('otp_expired'), 'Kod nije tačan ili je istekao.');
    expect(msg('over_email_send_rate_limit'), contains('Sačekaj'));
    expect(msg('anonymous_provider_disabled'), contains('bez naloga'));
    expect(msg('email_exists'), contains('već ima nalog'));
    expect(msg('something_new', status: '429'), contains('Sačekaj'));
    expect(msg('something_new'), 'Prijava nije uspela. Pokušaj ponovo.');
  });
}
