import 'dart:js_interop';
import 'package:web/web.dart' as web;

final JSFunction _handler =
    ((web.BeforeUnloadEvent event) {
  event.preventDefault();
  event.returnValue = '';
}).toJS;

void enableLeaveConfirmation() {
  web.window.addEventListener('beforeunload', _handler);
}

void disableLeaveConfirmation() {
  web.window.removeEventListener('beforeunload', _handler);
}
