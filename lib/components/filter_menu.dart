
import 'dart:convert';

import 'package:call/core/config.dart';
import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:http/http.dart' as http;


class FilterMenu extends StatefulWidget {
  final Function(List<String>, List<String>) onApplyFilters;
  final List<String> selectedSectors;
  final List<String> selectedAanganwadis;

  const FilterMenu({
    Key? key,
    required this.onApplyFilters,
    this.selectedSectors = const [],
    this.selectedAanganwadis = const [],
  }) : super(key: key);

  @override
  State<FilterMenu> createState() => _FilterMenuState();
}

class _FilterMenuState extends State<FilterMenu> {
  List<String> selectedSectors = [];
  List<String> selectedAanganwadis = [];
  // Example data - replace with your actual data
  List<String> sectors = [];
  List<String> aanganwadis = [];
  bool isLoading = true;
  String? error;

  TextEditingController aanganwadiSearchController = TextEditingController();
  TextEditingController sectorSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedSectors = List.from(widget.selectedSectors);
    selectedAanganwadis = List.from(widget.selectedAanganwadis);
    fetchFilters();
    aanganwadiSearchController.addListener(() {
      aanganwadiSearchController.text = aanganwadiSearchController.text.trim();
    });
    sectorSearchController.addListener(() {
      sectorSearchController.text = sectorSearchController.text.trim();
    });
  }

  Future<void> fetchFilters() async {
    try {
      final url = Uri.parse("${ApiConstants.baseUrl}/lead/filters");
      final response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes); // Handle UTF-8 encoding
        final data = jsonDecode(body);
        final responseBody = data["responseBody"];

        setState(() {
          sectors = List<String>.from(responseBody["sectors"]);
          aanganwadis = List<String>.from(responseBody["aanganwadis"]);
          isLoading = false;
          error = null;
        });
      } else {
        setState(() {
          error = 'Failed to load filters';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading filters...'),
            ],
          ),
        ),
      );
    }

    if (error != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error!),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  isLoading = true;
                  error = null;
                });
                fetchFilters();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filters',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).primaryColor,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sectors Section
                  _buildSectionTitle('Select Sectors'),
                  const SizedBox(height: 8),
                  _buildDropdown(
                    items: sectors,
                    searchController: sectorSearchController,
                    selectedItems: selectedSectors,
                    onChanged: (value) {
                      setState(() => selectedSectors = value);
                    },
                    hint: "Search sectors...",
                  ),
                  const SizedBox(height: 20),

                  // Aanganwadis Section
                  _buildSectionTitle('Select Aanganwadis'),
                  const SizedBox(height: 8),
                  _buildDropdown(
                    items: aanganwadis,
                    searchController: aanganwadiSearchController,
                    selectedItems: selectedAanganwadis,
                    onChanged: (value) {
                      setState(() => selectedAanganwadis = value);
                    },
                    hint: "Search aanganwadis...",
                  ),
                ],
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        selectedSectors = [];
                        selectedAanganwadis = [];
                      });
                      widget.onApplyFilters([], []);
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                    ),
                    child: const Text('Clear'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      widget.onApplyFilters(
                        selectedSectors,
                        selectedAanganwadis,
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: Colors.grey[800],
      ),
    );
  }

  Widget _buildDropdown({
    required List<String> items,
    required List<String> selectedItems,
    required Function(List<String>) onChanged,
    TextEditingController? searchController,
    required String hint,
  }) {
  return DropdownSearch<String>.multiSelection(
      items: items,
      selectedItems: selectedItems,
      onChanged: onChanged,
      popupProps: PopupPropsMultiSelection.menu(
        showSearchBox: true,
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
          ),
        ),
        containerBuilder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: child,
          );
        },
        showSelectedItems: true,
      ),
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
        ),
      ),
    );
  }
}