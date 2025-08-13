import 'package:flutter/foundation.dart';

const bool kDebugLogs = false;

void logDebug(String message) {
	if (kDebugMode && kDebugLogs) {
		// ignore: avoid_print
		debugPrint(message);
	}
}

