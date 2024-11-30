import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:time_picker_spinner_pop_up/time_picker_spinner_pop_up.dart';

import 'package:awn/services/entity_management_services.dart'
    as entity_services;
import 'package:awn/widgets/custom_dropdown_button.dart';
import 'package:awn/widgets/custom_text_field.dart';
import 'package:awn/widgets/location_input.dart';

class HelpForm extends StatefulWidget {
  const HelpForm({super.key});

  @override
  State<HelpForm> createState() => _HelpFormState();
}

class _HelpFormState extends State<HelpForm> {
  final FocusScopeNode _focusScopeNode = FocusScopeNode();
  final _formKey = GlobalKey<FormState>();
  String? _selectedDropDownValue;
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  double? latitude;
  double? longitude;
  double? currentLatitude;
  double? currentLongitude;
  final GlobalKey<LocationInputState> _locationInputKey = GlobalKey();
  bool _isLoading = false;

  void _unfocusTextFields() {
    _focusScopeNode.unfocus();
  }

  void _onDropdownValueChanged(String? newValue) {
    setState(() {
      _selectedDropDownValue = newValue;
    });
  }

  void _onCurrentLocationLoaded(
      double currentLatitude, double currentLongitude) {
    setState(() {
      this.currentLatitude = currentLatitude;
      this.currentLongitude = currentLongitude;
    });
  }

  void _onLocationChanged(double latitude, double longitude) {
    setState(() {
      this.latitude = latitude;
      this.longitude = longitude;
    });
  }

  void _clearForm() {
    _locationInputKey.currentState?.refreshLocation();
    setState(() {
      _formKey.currentState!.reset();
      _selectedDropDownValue = null;
      _descriptionController.clear();
      _selectedDate = DateTime.now();
      latitude = currentLatitude;
      longitude = currentLongitude;
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate() &&
        _selectedDropDownValue != null &&
        latitude != null &&
        longitude != null) {
      setState(() {
        _isLoading = true;
      });
      entity_services.submitHelpRequest(
        _selectedDropDownValue!,
        _descriptionController.text,
        latitude!,
        longitude!,
        _selectedDate,
        context,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill the required fields"),
        ),
      );
    }
  }

  @override
  void dispose() {
    _focusScopeNode.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _unfocusTextFields,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("AWN"), // Changed from translate("appName")
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
        body: FocusScope(
          node: _focusScopeNode,
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Card(
                color: Colors.white,
                borderOnForeground: false,
                elevation: 30,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                     child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomDropdownButton(
                            controller: _searchController,
                            selectedDropDownValue: _selectedDropDownValue,
                            onChanged: _onDropdownValueChanged,
                          ),
                          const SizedBox(height: 16),
                          CustomTextFormField(
                            controller: _descriptionController,
                            labelText: "Description",
                            hintText: "describe what have you lost", 
                            prefixIcon: Icons.description_outlined,
                            isUser: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "describe what have you lost"; // Changed from translate("DescriptionHint")
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(5),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2.0,
                              ),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: SizedBox(
                              height: 100,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TimePickerSpinnerPopUp(
                                    mode: CupertinoDatePickerMode.dateAndTime,
                                    timeWidgetBuilder: (time) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withOpacity(0.8),
                                              width: 1.75),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        padding: const EdgeInsets.fromLTRB(
                                            12, 10, 12, 10),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Image.asset(
                                              'assets/images/time_picker_calendar_icon.png',
                                              height: 26,
                                              width: 26,
                                              color: Theme.of(context)
                                                  .iconTheme
                                                  .color,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              "${_selectedDate.day.toString()}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year.toString()}  ${_selectedDate.hour.toString().padLeft(2, '0')}:${_selectedDate.minute.toString().padLeft(2, '0')}",
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontStyle: FontStyle.normal,
                                                fontWeight: FontWeight.w700,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    initTime: _selectedDate,
                                    minTime: DateTime.now(),
                                    barrierColor: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.1),
                                    onChange: (dateTime) {
                                      setState(() {
                                        _selectedDate = dateTime;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(5),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2.0,
                              ),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: SizedBox(
                              height: 200,
                              child: LocationInput(
                                key: _locationInputKey,
                                onLoaded: _onCurrentLocationLoaded,
                                onChanged: _onLocationChanged,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () async {
                                  await _submit();
                                },
                                child: _isLoading
                                    ? const CircularProgressIndicator()
                                    : Text("Submit"), // Changed from translate("Submit")
                              ),
                              const SizedBox(width: 32),
                              ElevatedButton(
                                onPressed: _clearForm,
                                child: Text("Clear"), // Changed from translate("Clear")
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}