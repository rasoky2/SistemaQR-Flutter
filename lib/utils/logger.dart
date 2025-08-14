import 'package:flutter/foundation.dart';

const bool kDebugLogs = true; // habilita logs en debug (Windows)

void logDebug(String message) {
	if (kDebugMode && kDebugLogs) {
		debugPrint(message);
	}
}

