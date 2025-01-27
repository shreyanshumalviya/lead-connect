import 'package:call/screen/UserDetailPage.dart';
import 'package:direct_call_plus/direct_call_plus.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:phone_state/phone_state.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Map<String, dynamic>> users = [];
  StreamSubscription? _phoneStateSubscription;

  void _callNumber(String number) async {
    bool? res = await DirectCallPlus.makeCall(number);
  }

  void fetchUsers() async {
    const url = "http://52.66.145.64:8080/mandi-dev/lead/getAll";
    final uri = Uri.parse(url);
    final response = await http.post(uri);

    if (response.statusCode == 200) {
      final body = response.body;
      final data = jsonDecode(body);

      // Update the users list with data from the responseBody
      setState(() {
        users = List<Map<String, dynamic>>.from(data["responseBody"]);
      });
    } else {
      debugPrint('Failed to fetch users. Status code: ${response.statusCode}');
    }
  }

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    fetchUsers();
    _initPhoneStateListener();
  }

  @override
  void dispose() {
    _phoneStateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      await Permission.phone.request();
    }
  }

  Future<void> _initPhoneStateListener() async {
    try {
      if (await Permission.phone.isGranted) {
        print("phonestate length ${PhoneState.stream.length}");
        PhoneState.stream.forEach((status) {
          print('Initial phone state: ${status.toString()}');
          if (status.number != null && status.number!.isNotEmpty) {
            _handleOngoingCall(status.number!);
          }
        });
      } else {
        print('Phone permission not granted');
        await Permission.phone.request();
      }
    } catch (e) {
      print('Error initializing phone state listener: $e');
    }
  }

  void _handleOngoingCall(String phoneNumber) {
    if (phoneNumber.isEmpty) return;

    // Normalize the phone number for comparison
    String normalizedNumber = _normalizePhoneNumber(phoneNumber);

    // Find matching user
    final matchingUser = users.firstWhere(
          (user) => _normalizePhoneNumber(user['number'].toString()) == normalizedNumber,
      orElse: () => {},
    );

    // If matching user found, navigate to details page
    if (matchingUser.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserDetailsPage(userId: matchingUser['id']),
        ),
      );
    }
  }

  String _normalizePhoneNumber(String number) {
    // Remove all non-digit characters
    String normalized = number.replaceAll(RegExp(r'[^\d]'), '');

    // Remove country code if present (assuming Indian numbers)
    if (normalized.startsWith('91') && normalized.length > 10) {
      normalized = normalized.substring(2);
    }
    // Take last 10 digits if number is longer
    if (normalized.length > 10) {
      normalized = normalized.substring(normalized.length - 10);
    }
    return normalized;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: users.isEmpty
            ? CircularProgressIndicator() // Show loading if users list is empty
            : ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final name = users[index]["name"]; // Get the user data
                  final no = users[index]["number"]; // Get the number
                  final id = users[index]["id"];
                  return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserDetailsPage(
                                  userId:
                                      id), // Replace with your page and parameter
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 5,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 12.0, horizontal: 16.0),
                            title: Text(
                              name, // Concatenate name and number
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            subtitle: Text(no),
                            trailing: IconButton(
                              icon: Icon(Icons.call, color: Colors.blue),
                              onPressed: () => _callNumber(no),
                              // Pass the correct number
                              tooltip: 'Call User',
                            ),
                          ),
                        ),
                      ));
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: fetchUsers,
        tooltip: 'Fetch Users',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
