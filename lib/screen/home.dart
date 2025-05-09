import 'package:call/components/filter_menu.dart';
import 'package:call/core/config.dart';
import 'package:call/screen/UserDetailPage.dart';
import 'package:direct_call_plus/direct_call_plus.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:phone_state/phone_state.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Timer? _debounce;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  List<String> sectors = [];
  List<String> aanganwadis = [];
  List<Map<String, dynamic>> users = [];
  bool noData = false;
  bool isLoading = false;
  int currentPage = 0;
  final int pageSize = 15;
  bool hasMore = true;
  ScrollController _scrollController = ScrollController();

  StreamSubscription? _phoneStateSubscription;

  void _callNumber(String number) async {
    bool? res = await DirectCallPlus.makeCall(number);
  }

  void fetchUsers({
    List<String>? sectors,
    List<String>? aanganwadis,
    String? searchQuery,
  }) async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      var url = "${ApiConstants.baseUrl}/lead/getAll";
      final uri = Uri.parse(url);

      // Create request body
      final requestBody = {
        "pageNumber": currentPage,
        "pageSize": pageSize,
        "sortBy": "id",
        "sortDirection": "ASC",
        if (sectors != null && sectors.isNotEmpty) "sectors": sectors,
        if (aanganwadis != null && aanganwadis.isNotEmpty)
          "aanganwadis": aanganwadis,
        if (searchQuery != null && searchQuery.isNotEmpty)
          "searchQuery": searchQuery,
      };

      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        final data = jsonDecode(body);

        final responseBody = data["responseBody"];
        final content = responseBody["content"] as List;
        final isLast = responseBody["last"] as bool;

        setState(() {
          users.addAll(List<Map<String, dynamic>>.from(content));
          currentPage++;
          hasMore = !isLast;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        debugPrint(
            'Failed to fetch users. Status code: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint('Error fetching users: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    fetchUsers();
    fetchUsers();
    _scrollController.addListener(_scrollListener);
    _initPhoneStateListener();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _phoneStateSubscription?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _isSearching = query.isNotEmpty;
        currentPage = 0;
        users.clear();
      });
      fetchUsers(
          sectors: sectors, aanganwadis: aanganwadis, searchQuery: query);
    });
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (!isLoading && hasMore) {
        fetchUsers();
      }
    }
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
      (user) =>
          _normalizePhoneNumber(user['number'].toString()) == normalizedNumber,
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

  Future<void> _pickAndUploadFile() async {
    try {
      // Open file picker
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null) {
        // Create form data
        FormData formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(
            result.files.single.path!,
            filename: result.files.single.name,
          ),
        });

        // Make the API call
        final dio = Dio();
        final response = await dio.post(
          '${ApiConstants.baseUrl}/lead/upload',
          data: formData,
        );

        // Show response in dialog
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Upload Response'),
              content: Text(response.data.toString()),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      // Show error dialog
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to upload file: ${e.toString()}'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: _isSearching ? _buildSearchField() : Text(widget.title),
          actions: [
            // Search toggle button
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) {
                    _searchController.clear();
                    // Reset search - fetch all data
                    fetchUsers(
                        aanganwadis: aanganwadis,
                        sectors: sectors,
                        searchQuery: '');
                  }
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return FilterMenu(
                      selectedSectors: sectors,
                      selectedAanganwadis: aanganwadis,
                      onApplyFilters: (sectors, aanganwadis) {
                        // Reset pagination
                        setState(() {
                          users.clear();
                          currentPage = 0;
                          hasMore = true;
                        });

                        // Apply filters and fetch data
                        this.sectors = sectors;
                        this.aanganwadis = aanganwadis;
                        fetchUsers(sectors: sectors, aanganwadis: aanganwadis);
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
        body: Center(
          child: users.isEmpty
              ? const Text("No Data Found")
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: users.length + (hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == users.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    final name = users[index]["name"]; // Get the user data
                    final no = users[index]["number"]; // Get the number
                    final sector = users[index]["sector"]; // Get the number
                    final aanganwadi =
                        users[index]["aanganwadi"]; // Get the number
                    final id = users[index]["id"];
                    final daysSinceLastCall = users[index]["daysSinceLastCall"];
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
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12.0, horizontal: 16.0),
                                title: Text(
                                  name, // Concatenate name and number
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text("$aanganwadi ($sector)"),
                                      Text(no)
                                    ]),
                                trailing: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                          child: IconButton(
                                        icon: const Icon(Icons.call,
                                            color: Colors.blue),
                                        onPressed: () => _callNumber(no),
                                        // Pass the correct number
                                        tooltip: 'Call User',
                                      )),
                                      buildCallInfo(daysSinceLastCall)
                                    ])),
                          ),
                        ));
                  },
                ),
        ),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              onPressed: () {
                setState(() {
                  users = [];
                });
                fetchUsers();
              },
              child: const Icon(Icons.refresh),
            ),
            const SizedBox(width: 10),
            FloatingActionButton(
              onPressed: _pickAndUploadFile,
              tooltip: 'Upload Excel',
              child: const Icon(Icons.upload_file),
            ),
          ],
        ));
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: const InputDecoration(
        hintText: 'Search...',
        hintStyle: TextStyle(color: Colors.white70),
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
      ),
      style: const TextStyle(color: Colors.white),
      onChanged: _onSearchChanged,
    );
  }

  Widget buildCallInfo(int? daysSinceLastCall) {
    String callText;
    if (daysSinceLastCall == null || daysSinceLastCall < 0) {
      callText = 'No calls yet';
    } else if (daysSinceLastCall == 0) {
      callText = 'Called today';
    } else if (daysSinceLastCall == 1) {
      callText = 'Called yesterday';
    } else {
      callText = 'Called $daysSinceLastCall days ago';
    }

    return Text(
      callText,
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey[600],
      ),
      textAlign: TextAlign.center,
    );
  }
}
