// Web implementation for procedural audio interop
import 'dart:js_interop';

@JS('IdemAudio.play')
external void _jsPlay(JSString type, JSNumber volume);

@JS('IdemAudio.setVolume')
external void _jsSetVolume(JSNumber volume);

@JS('IdemAudio.stop')
external void _jsStop();

void platformPlayAudio(String type, double volume) {
  try {
    _jsPlay(type.toJS, volume.toJS);
  } catch (_) {}
}

void platformSetVolume(double volume) {
  try {
    _jsSetVolume(volume.toJS);
  } catch (_) {}
}

void platformStopAudio() {
  try {
    _jsStop();
  } catch (_) {}
}
