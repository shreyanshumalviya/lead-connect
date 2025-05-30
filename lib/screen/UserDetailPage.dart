import 'package:call/service/api_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../core/config.dart';

class UserDetailsPage extends StatefulWidget {
  final int userId;

  const UserDetailsPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<UserDetailsPage> createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  bool isLoading = true;
  Map<String, dynamic>? leadDetails;
  String? error;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchLeadDetails();
    fetchLeadDetails();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });

  }

  final TextEditingController _summaryController = TextEditingController();

  @override
  void dispose() {
    _scrollController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  Future<void> _submitCallLog() async {
    // Show confirmation dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Submission'),
          content:
              const Text('Are you sure you want to submit this call summary?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      saveLog();
    }
  }

  Future<void> fetchLeadDetails() async {
    try {
      final response = await http.get(
        Uri.parse(
            '${ApiConstants.baseUrl}/lead/${widget.userId}/details'),
      );

      if (response.statusCode == 200) {
        setState(() {
          final body = utf8.decode(response.bodyBytes);
          final data = jsonDecode(body);

          leadDetails = data;
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to load lead details';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Lead Details'),
          elevation: 2,
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : error != null
            ? Center(child: Text(error!))
            : Column(
          children: [
            // Fixed header section
            Card(
              elevation: 4,
              margin: const EdgeInsets.all(16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lead Information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    buildLeadAccordion(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Call History',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 16),
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController, // Add this controller
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      ..._buildCallLogs(),
                      // Call summary section
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Column(
                          children: [
                            TextField(
                              controller: _summaryController,
                              decoration: const InputDecoration(
                                labelText: 'Call Summary',
                                border: OutlineInputBorder(),
                                hintText: 'Enter call summary here...',
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _submitCallLog,
                              child: const Text('Submit Call Summary'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ));

  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCallLogs() {
    final callLogs = leadDetails?['callLogs'] as List<dynamic>? ?? [];

    if (callLogs.isEmpty) {
      return [
        const Center(
          child: Text('No call logs available'),
        ),
      ];
    }

    return callLogs.map((log) {
      final DateTime creationTime = DateTime.parse(log['creationTime']);
      // final formattedDate = DateFormat('MMM dd, yyyy HH:mm').format(creationTime);
      final formattedDate = creationTime.toString();

      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    formattedDate,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                log['logText'] ?? '',
                style: const TextStyle(fontSize: 16),
              ),
              if (true) ...[
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    // Implement audio playback functionality
                    // You can use packages like just_audio or audioplayers
                    // to play the recording
                    // snack bar saying coming soon
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coming Soon')),
                    );

                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Play Recording'),
                ),
              ],
            ],
          ),
        ),
      );
    }).toList();
  }

  void saveLog() async {
    try {
      // Get headers with user_id
      final headers = await ApiService.getHeaders();

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/lead/call-log'),
        headers: headers,
        body: jsonEncode({
          'leadId': widget.userId, // Replace with actual lead ID
          'logText': _summaryController.text,
          'recordingUrl': ''
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Call log submitted successfully')),
        );
        _summaryController.clear();

        fetchLeadDetails();
      } else {
        throw Exception('Failed to submit call log');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Widget buildLeadAccordion() {
  if (isLoading) {
    return const Center(child: CircularProgressIndicator());
  }

  if (error != null) {
    return Center(child: Text(error!));
  }

  return Card(
    margin: const EdgeInsets.all(8.0),
    child: ExpansionTile(
      title: Text(
        leadDetails?['name'] ?? 'Name not available',
        style: const TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow2('Phone Number', leadDetails?['number']?.toString() ?? 'N/A'),
              const SizedBox(height: 8),
              _buildInfoRow2('Sector', leadDetails?['sector']?.toString() ?? 'N/A'),
              const SizedBox(height: 8),
              _buildInfoRow2('Anganwadi', leadDetails?['anganwadi']?.toString() ?? 'N/A'),
              const SizedBox(height: 8),
              _buildInfoRow2('Father\'s Name', leadDetails?['fatherName']?.toString() ?? 'N/A'),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildInfoRow2(String label, String value) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 120,
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
      ),
    ],
  );
}

}
