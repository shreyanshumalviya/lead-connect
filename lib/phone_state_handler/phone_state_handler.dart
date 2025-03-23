// import 'package:call/service/api_service.dart';
// import 'package:phone_state_background/phone_state_background.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// import 'package:shared_preferences/shared_preferences.dart';
//
// @pragma('vm:entry-point')
// Future<void> phoneStateBackgroundCallbackHandler(
//   PhoneStateBackgroundEvent event,
//   String number,
//   int duration,
// ) async {
//   try {
//     // Get userId from SharedPreferences
//     final prefs = await SharedPreferences.getInstance();
//     final phoneNumber = prefs.getString('phoneNumber');
//
//     if (phoneNumber == null) {
//       print('User not logged in');
//       return;
//     }
//
//     // Convert the event to API action string
//     String action = _getActionFromEvent(event);
//
//     // Only send data for relevant events
//     if (action.isNotEmpty) {
//       await _sendToApi(
//         phoneNumber: phoneNumber,
//         action: action,
//         callerNumber: number,
//         duration: duration,
//       );
//     }
//   } catch (e) {
//     print('Error in phone state handler: $e');
//   }
// }
//
// String _getActionFromEvent(PhoneStateBackgroundEvent event) {
//   switch (event) {
//     case PhoneStateBackgroundEvent.incomingstart:
//       return 'INCOMING_START';
//     case PhoneStateBackgroundEvent.incomingmissed:
//       return 'INCOMING_MISSED';
//     case PhoneStateBackgroundEvent.incomingreceived:
//       return 'INCOMING_RECEIVED';
//     case PhoneStateBackgroundEvent.incomingend:
//       return 'INCOMING_END';
//     case PhoneStateBackgroundEvent.outgoingstart:
//       return 'OUTGOING_START';
//     case PhoneStateBackgroundEvent.outgoingend:
//       return 'OUTGOING_END';
//     default:
//       return '';
//   }
// }
//
// Future<void> _sendToApi({
//   required String phoneNumber,
//   required String action,
//   required String callerNumber,
//   required int duration,
// }) async {
//   try {
//     // Get headers with user_id
//     final headers = await ApiService.getHeaders();
//
//     final response = await http.post(
//       Uri.parse('https://mandi-3.make73.com/mandi/api/call-logs'),
//       headers: headers,
//       body: json.encode({
//         'userId': phoneNumber, // Using phone number as userId
//         'action': action,
//         'phoneNumber': callerNumber,
//         'duration': duration,
//       }),
//     );
//
//     if (response.statusCode != 200) {
//       print('Failed to send call log. Status code: ${response.statusCode}');
//       print('Response body: ${response.body}');
//     }
//   } catch (e) {
//     print('Error sending call log to API: $e');
//     // Store failed requests locally for retry later
//     await _storeFailedRequest({
//       'userId': phoneNumber,
//       'action': action,
//       'phoneNumber': callerNumber,
//       'duration': duration,
//       'timestamp': DateTime.now().toIso8601String(),
//     });
//   }
// }
//
// Future<void> _storeFailedRequest(Map<String, dynamic> request) async {
//   try {
//     final prefs = await SharedPreferences.getInstance();
//     List<String> failedRequests = prefs.getStringList('failedCallLogs') ?? [];
//     failedRequests.add(json.encode(request));
//     await prefs.setStringList('failedCallLogs', failedRequests);
//   } catch (e) {
//     print('Error storing failed request: $e');
//   }
// }
//
// // Utility function to retry failed requests (can be called when app starts or when network is available)
// Future<void> retryFailedRequests() async {
//   try {
//     final prefs = await SharedPreferences.getInstance();
//     List<String> failedRequests = prefs.getStringList('failedCallLogs') ?? [];
//
//     if (failedRequests.isEmpty) return;
//
//     List<String> remainingFailedRequests = [];
//
//     for (String requestStr in failedRequests) {
//       try {
//         Map<String, dynamic> request = json.decode(requestStr);
//         final response = await http.post(
//           Uri.parse('http://localhost:8080/api/call-logs'),
//           headers: {'Content-Type': 'application/json'},
//           body: json.encode(request),
//         );
//
//         if (response.statusCode != 200) {
//           remainingFailedRequests.add(requestStr);
//         }
//       } catch (e) {
//         remainingFailedRequests.add(requestStr);
//       }
//     }
//
//     await prefs.setStringList('failedCallLogs', remainingFailedRequests);
//   } catch (e) {
//     print('Error retrying failed requests: $e');
//   }
// }
