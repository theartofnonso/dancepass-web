import 'dart:convert';

import 'package:dancepassweb/data.dart';
import 'package:dancepassweb/datetime_container.dart';
import 'package:dancepassweb/form_field_container.dart';
import 'package:dancepassweb/http_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart' as date_formatter;
import 'package:intl/intl.dart';
import 'package:intl/intl_browser.dart';
import 'package:dancepassweb/dotos/event.dart';

import 'form_field.dart';

void main() async {
  findSystemLocale();

  await date_formatter.initializeDateFormatting();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
          // This is the theme of your application.
          //
          // Try running your application with "flutter run". You'll see the
          // application has a blue toolbar. Then, without quitting the app, try
          // changing the primarySwatch below to Colors.green and then invoke
          // "hot reload" (press "r" in the console where you ran "flutter run",
          // or simply save your changes to "hot reload" in a Flutter IDE).
          // Notice that the counter didn't reset back to zero; the application
          // is not restarted.
          useMaterial3: true,
          primarySwatch: Colors.blue,
          textButtonTheme: const TextButtonThemeData(style: ButtonStyle()),
          chipTheme: ChipThemeData(
            secondarySelectedColor: Colors.black,
            secondaryLabelStyle: const TextStyle(color: Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5.0),
              side: const BorderSide(
                color: Colors.grey,
                width: 1.0,
              ),
            ),
            side: BorderSide(
              color: Colors.grey.shade300,
              width: 1.0,
            ),
            checkmarkColor: Colors.white,
          ),
          inputDecorationTheme: InputDecorationTheme(
            contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.2),
              borderRadius: BorderRadius.circular(5),
            ),
            filled: true,
            fillColor: Colors.white,
            hintStyle: const TextStyle(color: Colors.grey),
            // Set the focused border color to blue
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.black),
              borderRadius: BorderRadius.circular(5),
            ),
            // Set the font family, weight, and size
            labelStyle: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          )),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

enum EventOperationType { create, update }

enum EventDateTimePeriod { start, end }

class _MyHomePageState extends State<MyHomePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _eventIdController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _venueController = TextEditingController();
  final TextEditingController _postcodeController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _bannerUrlController = TextEditingController();
  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _ticketPriceController = TextEditingController();
  final TextEditingController _ticketUrlController = TextEditingController();

  String _selectedCity = EventData.cities.first;
  List<String> _selectedCategories = [...EventData.eventCategories.take(1)];

  String? _selectedBannerUrl;

  List<TextEditingController> _genreFormControllers = [TextEditingController()];
  List<TextEditingController> _lineupFormControllers = [TextEditingController()];
  List<TextEditingController> _timelineDescriptionControllers = [TextEditingController()];
  List<TimeOfDay> _timelineTimes = [TimeOfDay.now()];
  List<String> _timelineSummaries = [""];

  DateTime _selectedStartDate = DateTime.now();
  TimeOfDay _selectedStartTime = TimeOfDay.now();

  DateTime _selectedEndDate = DateTime.now();
  TimeOfDay _selectedEndTime = TimeOfDay.now();

  Event? _event;

  Future<void> _selectDate({required DateTime date, required period}) async {
    DateTime? dateTime = period == EventDateTimePeriod.start ? _event?.startDateTime : _event?.endDateTime;
    var initialTime = dateTime ?? DateTime.now();

    final picked = await showDatePicker(context: context, initialDate: initialTime, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (picked != null && picked != date) {
      switch (period) {
        case EventDateTimePeriod.start:
          setState(() {
            _selectedStartDate = picked;
          });
          break;
        case EventDateTimePeriod.end:
          setState(() {
            _selectedEndDate = picked;
          });
          break;
        default:
          throw Exception("Invalid time period");
      }
    }
  }

  Future<void> _selectTime({required TimeOfDay timeOfDay, required period}) async {
    DateTime? dateTime = period == EventDateTimePeriod.start ? _event?.startDateTime : _event?.endDateTime;
    var initialTime = TimeOfDay.now();
    if (dateTime != null) {
      initialTime = TimeOfDay.fromDateTime(dateTime);
    }
    final picked = await showTimePicker(context: context, initialTime: initialTime);
    if (picked != null && picked != timeOfDay) {
      switch (period) {
        case "START":
          setState(() {
            _selectedStartTime = picked;
          });
          break;
        case "END":
          setState(() {
            _selectedEndTime = picked;
          });
          break;
        default:
          throw Exception("Invalid time period");
      }
    }
  }

  DateTime _getStartDateTime() {
    return DateTime(_selectedStartDate.year, _selectedStartDate.month, _selectedStartDate.day, _selectedStartTime.hour, _selectedStartTime.minute);
  }

  DateTime _getEndDateTime() {
    return DateTime(_selectedEndDate.year, _selectedEndDate.month, _selectedEndDate.day, _selectedEndTime.hour, _selectedEndTime.minute);
  }

  Future<void> _selectTimelinePeriod(int index) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _timelineTimes[index],
    );
    if (pickedTime != null) {
      if(pickedTime.hour >= _selectedStartTime.hour) {
        setState(() {
          _timelineTimes[index] = pickedTime;
          _setTimelineSummary(index, _timelineDescriptionControllers[index].text, _timelineTimes[index]);
        });
      } else {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Timeline can't start before event start date")));
        }
      }
    }
  }

  List<String> _getAllTimeline() {
    DateTime now = DateTime.now(); // current date and time

    final timelineDescriptions = _timelineDescriptionControllers.map((controller) => controller.text).toList();
    List<String> timeline = [];
    for (var i = 0; i < timelineDescriptions.length; i++) {
      final dateTime = DateTime(now.year, now.month, now.day, _timelineTimes[i].hour, _timelineTimes[i].minute);
      timeline.add(jsonEncode({"description": timelineDescriptions[i], "time": "${dateTime.toIso8601String()}Z"}));
    }
    return timeline;
  }

  bool _isDateValid() {
    final startDateTime = _getStartDateTime();
    final endDateTime = _getEndDateTime();
    return startDateTime.isBefore(endDateTime);
  }

  Future<void> _getEvent() async {
    if (_eventIdController.text.isNotEmpty) {
      _showProgressDialog(message: "Searching for event");
      HttpFunctions.getEvent(id: _eventIdController.text).then((event) {
        Navigator.of(context, rootNavigator: true).pop();
        if (event != null) {
          _event = event;
          _updateFormWithEvent(event);
          if (event.status == "DRAFTED") {
            _showGoLiveBanner();
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("We can't find this event")));
        }
      }).catchError((e) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Something went wrong on our end... We are fixing it")));
      });
    }
  }

  void _showProgressDialog({required String message}) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevents dialog dismissal on tap outside
      builder: (_) {
        return Dialog(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white, // Optional: Set a custom background color for the content
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(), // Display the progress bar
                  const SizedBox(height: 16.0),
                  Text(message), // Optional: Add a message
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _updateFormWithEvent(Event event) {
    setState(() {
      _nameController.text = event.name;
      _descriptionController.text = event.description;
      _selectedCategories = event.category;
      _genreFormControllers = event.genre.map((genre) => TextEditingController(text: genre)).toList();
      _selectedStartDate = event.startDateTime;
      _selectedStartTime = TimeOfDay.fromDateTime(event.startDateTime);
      _selectedEndDate = event.endDateTime;
      _selectedEndTime = TimeOfDay.fromDateTime(event.endDateTime);
      _selectedCategories = event.category;
      _venueController.text = event.venue;
      _selectedCity = event.city;
      _postcodeController.text = event.postcode;
      _addressController.text = event.address;
      _latitudeController.text = event.latitude.toString();
      _longitudeController.text = event.longitude.toString();
      _bannerUrlController.text = event.bannerUrl;
      _selectedBannerUrl = event.bannerUrl;
      _hostController.text = event.hostName;
      _ticketPriceController.text = event.ticketPrice.toString();
      _ticketUrlController.text = event.ticketsUrl.toString();
      _lineupFormControllers = event.lineup.map((artist) => TextEditingController(text: artist)).toList();

      List<TextEditingController> timelineDescriptionControllers = [];
      List<TimeOfDay> timelineTimes = [];
      List<String> timelineSummaries = [];
      for (int i = 0; i < event.timeline.length; i++) {
        final timeline = jsonDecode(event.timeline[i]);
        final description = timeline["description"];
        final datetime = DateTime.parse(timeline["time"]);
        final timeOfDay = TimeOfDay.fromDateTime(DateTime.parse(timeline["time"]));
        final controller = TextEditingController(text: description);
        timelineDescriptionControllers.add(controller);
        timelineTimes.add(timeOfDay);
        timelineSummaries.add("$description at ${DateFormat("Hm", "en").format(datetime)}");
      }
      _timelineDescriptionControllers = timelineDescriptionControllers;
      _timelineTimes = timelineTimes;
      _timelineSummaries = timelineSummaries;
    });
  }

  String _createPayload() {
    final payload = {
      "name": _nameController.text,
      "description": _descriptionController.text,
      "category": _selectedCategories.map((category) => category).toList(),
      "genre": _genreFormControllers.map((controller) => controller.text).toList(),
      "startDateTime": "${_getStartDateTime().toIso8601String()}Z",
      "endDateTime": "${_getEndDateTime().toIso8601String()}Z",
      "venue": _venueController.text,
      "city": _selectedCity,
      "country": "UK",
      "postcode": _postcodeController.text,
      "address": _addressController.text,
      "latitude": _latitudeController.text,
      "longitude": _longitudeController.text,
      "bannerUrl": _bannerUrlController.text,
      "hostName": _hostController.text,
      "lineup": _lineupFormControllers.map((controller) => controller.text).toList(),
      "timeline": _getAllTimeline(),
      "ticketPrice": _ticketPriceController.text,
      "ticketsUrl": _ticketUrlController.text
    };

    return jsonEncode(payload);
  }

  void _runCreateOperation({required String payload, required String errorMessage}) async {
    final createdEventId = await HttpFunctions.createEventDraft(payload: payload);
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    if (createdEventId != null) {
      setState(() {
        _eventIdController.text = createdEventId;
      });
      _showGoLiveBanner();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    }
  }

  void _runUpdateOperation({required String id, required String payload, required String errorMessage}) async {
    final hasBeenUpdated = await HttpFunctions.updateEvent(id: id, payload: payload);
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    if (hasBeenUpdated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${_nameController.text} has been updated")));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    }
  }

  Future<void> _submit({required String progressMessage, required String errorMessage, required EventOperationType type}) async {
    final currentState = _formKey.currentState;
    if (currentState != null) {
      if (currentState.validate()) {
        if (_isDateValid()) {
          final payload = _createPayload();

          try {
            if (_eventIdController.text.isNotEmpty) {
              switch (type) {
                case EventOperationType.create:
                  _showProgressDialog(message: progressMessage);
                  _runCreateOperation(payload: payload, errorMessage: errorMessage);
                  break;
                case EventOperationType.update:
                  _showProgressDialog(message: progressMessage);
                  _runUpdateOperation(id: _eventIdController.text, payload: payload, errorMessage: errorMessage);
                  break;
                default:
                  throw Exception("Invalid EventOperationType");
              }
            } else {
              _showProgressDialog(message: progressMessage);
              _runCreateOperation(payload: payload, errorMessage: errorMessage);
            }
          } catch (e) {
            Navigator.of(context, rootNavigator: true).pop();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Something went wrong on our end... We are fixing it")));
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Start date must be before end date")));
        }
      }
    }
  }

  Future<void> _postLiveEvent() async {
    final payload = {
      "status": "LIVE",
    };
    final jsonPayload = jsonEncode(payload);

    _showProgressDialog(message: "Going live with event");

    try {
      final isLive = await HttpFunctions.updateEvent(id: _eventIdController.text, payload: jsonPayload);

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (isLive) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Event is now live on Dancepass")));
          ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Unable to post live event")));
        }
      }
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Something went wrong on our end... We are fixing it")));
    }
  }

  void _addGenreFormField() {
    // Add a new form field when the button is clicked
    final newController = TextEditingController();
    setState(() {
      _genreFormControllers.add(newController);
    });
  }

  void _removeGenreFormField(int index) {
    if (_genreFormControllers.length > 1) {
      setState(() {
        _genreFormControllers.removeAt(index);
      });
    }
  }

  void _addLineupFormField() {
    // Add a new form field when the button is clicked
    final newController = TextEditingController();
    setState(() {
      _lineupFormControllers.add(newController);
    });
  }

  void _removeLineupFormField(int index) {
    if (_lineupFormControllers.length > 1) {
      setState(() {
        _lineupFormControllers.removeAt(index);
      });
    }
  }

  void _addTimeline() {
    _addTimelineDescriptionFormField();
    _addTimelineTime();
    _timelineSummaries.add("");
  }

  void _removeTimeline(int index) {
    _removeTimelineDescriptionFormField(index);
    _removeTimelineTime(index);
    _timelineSummaries.removeAt(index);
  }

  void _addTimelineDescriptionFormField() {
    // Add a new form field when the button is clicked
    final newController = TextEditingController();
    setState(() {
      _timelineDescriptionControllers.add(newController);
    });
  }

  void _removeTimelineDescriptionFormField(int index) {
    if (_timelineDescriptionControllers.length > 1) {
      setState(() {
        _timelineDescriptionControllers.removeAt(index);
      });
    }
  }

  void _addTimelineTime() {
    // Add a new form field when the button is clicked
    final newTimeOfDay = TimeOfDay.now();
    setState(() {
      _timelineTimes.add(newTimeOfDay);
    });
  }

  void _removeTimelineTime(int index) {
    if (_timelineTimes.length > 1) {
      setState(() {
        _timelineTimes.removeAt(index);
      });
    }
  }

  String _displayDate({required DateTime rawDateTime, required period}) {
    String summary;

    switch (period) {
      case EventDateTimePeriod.start:
        summary = "Starting on";
        break;
      case EventDateTimePeriod.end:
        summary = "Ending on";
        break;
      default:
        throw Exception("Invalid date period");
    }

    return "$summary ${DateFormat("EE dd MMM", "en").format(rawDateTime)}";
  }

  String _displayTime({required TimeOfDay rawTimeOfDay, required period}) {
    String summary;

    switch (period) {
      case EventDateTimePeriod.start:
        summary = "Starting at";
        break;
      case EventDateTimePeriod.end:
        summary = "Ending at";
        break;
      default:
        throw Exception("Invalid date period");
    }

    final dateTime = DateTime(2021, 1, 1, rawTimeOfDay.hour, rawTimeOfDay.minute);

    return "$summary ${DateFormat("Hm", "en").format(dateTime)}";
  }

  void _setTimelineSummary(int index, String description, TimeOfDay rawTimeOfDay) {
    final dateTime = DateTime(2021, 1, 1, rawTimeOfDay.hour, rawTimeOfDay.minute);

    setState(() {
      _timelineSummaries[index] = "$description at ${DateFormat("Hm", "en").format(dateTime)}";
    });
  }

  List<DropdownMenuItem<String>> _citiesToDropdown() {
    return EventData.cities.map((city) => DropdownMenuItem(value: city, child: Text(city))).toList();
  }

  List<ChoiceChip> _eventCategoriesToChoiceChip() {
    return EventData.eventCategories
        .map((category) => ChoiceChip(
              label: Text(category),
              selected: _selectedCategories.contains(category),
              onSelected: (bool selected) {
                setState(() {
                  if (_selectedCategories.contains(category)) {
                    _selectedCategories.remove(category);
                  } else {
                    _selectedCategories.add(category);
                  }
                });
              },
            ))
        .toList();
  }

  String? _validateUrl({required String url, required String label}) {
    final isValid = Uri.tryParse(_ticketUrlController.text)?.hasScheme == true;
    if (!isValid) {
      return "$label is invalid";
    }
    return null;
  }

  void _getGeoCoordinates() {
    final venue = _venueController.text;
    final streetAddress = _addressController.text;
    final postcode = _postcodeController.text;

    if (streetAddress.isNotEmpty && postcode.isNotEmpty) {

      final firstLine = [streetAddress, _selectedCity].join(", ");

      final address = '$firstLine $postcode';

      HttpFunctions.addressToGeoCoordinates(address).then((coordinates) {
        setState(() {
          _latitudeController.text = coordinates.latitude.toString();
          _longitudeController.text = coordinates.longitude.toString();
        });
      }).catchError((_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Unable to find $venue coordinates")));
      });
    }
  }

  void _showGoLiveBanner() {
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        padding: const EdgeInsets.all(10),
        content: const Text("Event is in draft, do you want to go live now", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        actions: <Widget>[
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
            },
            child: const Text(
              'DISMISS',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () => _postLiveEvent(),
            child: const Text(
              'GO LIVE',
              style: TextStyle(color: Colors.white),
            ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _eventIdController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _venueController.dispose();
    _postcodeController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _bannerUrlController.dispose();
    _hostController.dispose();
    _ticketPriceController.dispose();
    _ticketUrlController.dispose();

    for (var controller in _genreFormControllers) {
      controller.dispose();
    }
    for (var controller in _lineupFormControllers) {
      controller.dispose();
    }
    for (var controller in _timelineDescriptionControllers) {
      controller.dispose();
    }
  }

  void _showEventOperationMenu() async {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
            padding: const EdgeInsets.only(top: 12, right: 8, bottom: 20, left: 8),
            height: 150,
            child: ListView(
              children: [
                ListTile(
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    _submit(progressMessage: 'Updating ${_nameController.text}', errorMessage: 'Unable to update ${_nameController.text}', type: EventOperationType.update);
                  },
                  leading: const Icon(Icons.edit),
                  title: Text(
                    'Update "${_nameController.text}"',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "${_nameController.text} will be updated with provided fields",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded),
                ),
                ListTile(
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    _submit(
                        progressMessage: 'Creating new event draft from "${_nameController.text}"',
                        errorMessage: 'Unable to create new event draft from "${_nameController.text}"',
                        type: EventOperationType.create);
                  },
                  leading: const Icon(Icons.add_circle_outline_outlined),
                  title: Text(
                    'Create new event from "${_nameController.text}"',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("A new event will be created using fields from ${_nameController.text}", style: const TextStyle(color: Colors.grey)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded),
                ),
              ],
            ));
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    final selectedBannerUrl = _selectedBannerUrl;

    return Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: SingleChildScrollView(
          child: Center(
            child: Container(
              width: 700,
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    FormFieldContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Please provide an existing id to update an event",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: CTextFormField(
                                  controller: _eventIdController,
                                  shouldValidate: false,
                                  type: TextInputType.text,
                                  label: 'Event Id',
                                ),
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  _getEvent();
                                },
                                child: const Icon(Icons.search),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    CTextFormField(
                      controller: _nameController,
                      type: TextInputType.name,
                      label: 'Name',
                    ),
                    const SizedBox(
                      height: 15,
                    ),

                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 10,
                      decoration: const InputDecoration(hintText: "Description", border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(3)))),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Description has not been provided';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    Column(
                      children: [
                        Row(
                          children: [
                            DateAndTime(
                                onSelect: () => _selectDate(date: _selectedStartDate, period: EventDateTimePeriod.start),
                                label: _displayDate(rawDateTime: _selectedStartDate, period: EventDateTimePeriod.start)),
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.arrow_circle_right_outlined,
                                size: 18,
                              ),
                            ),
                            DateAndTime(
                                onSelect: () => _selectDate(date: _selectedEndDate, period: EventDateTimePeriod.end),
                                label: _displayDate(rawDateTime: _selectedEndDate, period: EventDateTimePeriod.end)),
                          ],
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Row(
                          children: [
                            DateAndTime(
                                onSelect: () => _selectTime(timeOfDay: _selectedStartTime, period: EventDateTimePeriod.start),
                                label: _displayTime(rawTimeOfDay: _selectedStartTime, period: EventDateTimePeriod.start)),
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.arrow_circle_right_outlined,
                                size: 18,
                              ),
                            ),
                            DateAndTime(
                                onSelect: () => _selectTime(timeOfDay: _selectedEndTime, period: EventDateTimePeriod.end),
                                label: _displayTime(rawTimeOfDay: _selectedEndTime, period: EventDateTimePeriod.end)),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Wrap(
                      alignment: WrapAlignment.start,
                      runAlignment: WrapAlignment.start,
                      spacing: 8.0,
                      children: _eventCategoriesToChoiceChip(),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Genre",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        GestureDetector(
                            onTap: () => _addGenreFormField(),
                            child: const Icon(
                              Icons.add_box,
                              size: 30,
                            )),
                      ],
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    FormFieldContainer(
                      height: 200,
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                        child: ListView.builder(
                          itemCount: _genreFormControllers.length,
                          itemBuilder: (context, index) {
                            return Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    GestureDetector(
                                        onTap: () => _removeGenreFormField(index),
                                        child: const Icon(
                                          Icons.remove_circle_outline,
                                          color: Colors.redAccent,
                                          size: 18,
                                        )),
                                    const SizedBox(
                                      width: 8,
                                    ),
                                    Expanded(
                                      child: CTextFormField(
                                        controller: _genreFormControllers[index],
                                        type: TextInputType.text,
                                        prefixIcon: const Icon(
                                          Icons.music_note_outlined,
                                          color: Colors.grey,
                                          size: 16,
                                        ),
                                        label: 'Genre field ${index + 1}',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 10,
                                )
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    FormFieldContainer(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Where will this event be located",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        CTextFormField(
                          controller: _venueController,
                          type: TextInputType.streetAddress,
                          prefixIcon: const Icon(
                            Icons.maps_home_work_outlined,
                            color: Colors.grey,
                            size: 16,
                          ),
                          label: 'Venue',
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        DropdownButtonFormField(
                          value: _selectedCity,
                          items: _citiesToDropdown(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedCity = value;
                              });
                              _getGeoCoordinates();
                            }
                          },
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        CTextFormField(
                            controller: _postcodeController,
                            type: TextInputType.streetAddress,
                            prefixIcon: const Icon(
                              Icons.maps_home_work_outlined,
                              color: Colors.grey,
                              size: 16,
                            ),
                            label: 'Postcode',
                            onChanged: (value) {
                              if (value != null) {
                                _getGeoCoordinates();
                              }
                            }),
                        const SizedBox(
                          height: 20,
                        ),
                        CTextFormField(
                            controller: _addressController,
                            type: TextInputType.streetAddress,
                            prefixIcon: const Icon(
                              Icons.maps_home_work_outlined,
                              color: Colors.grey,
                              size: 16,
                            ),
                            label: 'Address',
                            onChanged: (value) {
                              if (value != null) {
                                _getGeoCoordinates();
                              }
                            }),
                        const SizedBox(
                          height: 20,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: CTextFormField(
                                controller: _latitudeController,
                                readOnly: true,
                                type: TextInputType.number,
                                prefixIcon: const Icon(
                                  Icons.location_on,
                                  color: Colors.grey,
                                  size: 16,
                                ),
                                label: 'Latitude',
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Expanded(
                              child: CTextFormField(
                                controller: _longitudeController,
                                readOnly: true,
                                type: TextInputType.number,
                                prefixIcon: const Icon(
                                  Icons.location_on,
                                  color: Colors.grey,
                                  size: 16,
                                ),
                                label: 'Longitude',
                              ),
                            ),
                          ],
                        )
                      ],
                    )),
                    const SizedBox(
                      height: 20,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CTextFormField(
                              controller: _bannerUrlController,
                              type: TextInputType.url,
                              label: 'Banner Url',
                              prefixIcon: const Icon(
                                Icons.link,
                                color: Colors.grey,
                                size: 16,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _selectedBannerUrl = _bannerUrlController.text;
                                });
                              },
                              validator: () => _validateUrl(url: _ticketUrlController.text, label: "Banner url")),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        SizedBox(
                          width: 240,
                          height: 240,
                          child: selectedBannerUrl != null
                              ? Image.network(
                                  selectedBannerUrl,
                                  width: 240,
                                  height: 240,
                                  fit: BoxFit.fill,
                                )
                              : Container(
                                  width: 240,
                                  height: 240,
                                  color: Colors.grey.shade400,
                                ),
                        )
                      ],
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    CTextFormField(
                      controller: _hostController,
                      type: TextInputType.name,
                      prefixIcon: const Icon(
                        Icons.verified_outlined,
                        color: Colors.grey,
                        size: 16,
                      ),
                      label: 'Host',
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Row(
                      children: [
                        SizedBox(
                          width: 200,
                          child: CTextFormField(
                              controller: _ticketPriceController,
                              type: TextInputType.number,
                              prefixIcon: const Icon(
                                Icons.attach_money_outlined,
                                color: Colors.grey,
                                size: 16,
                              ),
                              label: 'Ticket price',
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp("[^a-zA-Z\\-]+")),
                              ]),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Expanded(
                            child: CTextFormField(
                                controller: _ticketUrlController,
                                prefixIcon: const Icon(
                                  Icons.link,
                                  color: Colors.grey,
                                  size: 16,
                                ),
                                type: TextInputType.url,
                                label: 'Ticket url',
                                validator: () => _validateUrl(url: _ticketUrlController.text, label: "Ticket url"))),
                      ],
                    ),
                    const SizedBox(
                      height: 20,
                    ),

                    /// Line up
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Lineup of artists",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        GestureDetector(
                            onTap: () => _addLineupFormField(),
                            child: const Icon(
                              Icons.add_box,
                              size: 30,
                            )),
                      ],
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    FormFieldContainer(
                      height: 200,
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                        child: ListView.builder(
                          itemCount: _lineupFormControllers.length,
                          itemBuilder: (context, index) {
                            return Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    GestureDetector(
                                        onTap: () => _removeLineupFormField(index),
                                        child: const Icon(
                                          Icons.remove_circle_outline,
                                          color: Colors.redAccent,
                                          size: 18,
                                        )),
                                    const SizedBox(
                                      width: 8,
                                    ),
                                    Expanded(
                                      child: CTextFormField(
                                        controller: _lineupFormControllers[index],
                                        shouldValidate: false,
                                        type: TextInputType.text,
                                        prefixIcon: const Icon(
                                          Icons.perm_identity_rounded,
                                          color: Colors.grey,
                                          size: 16,
                                        ),
                                        label: 'Artist field ${index + 1}',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 10,
                                )
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),

                    /// Timeline
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Event Timeline",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        GestureDetector(
                            onTap: () => _addTimeline(),
                            child: const Icon(
                              Icons.add_box,
                              size: 30,
                            )),
                      ],
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    FormFieldContainer(
                      height: 300,
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                        child: ListView.builder(
                          itemCount: _timelineDescriptionControllers.length,
                          itemBuilder: (context, index) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    GestureDetector(
                                        onTap: () => _removeTimeline(index),
                                        child: const Icon(
                                          Icons.remove_circle_outline,
                                          color: Colors.redAccent,
                                          size: 18,
                                        )),
                                    const SizedBox(
                                      width: 8,
                                    ),
                                    Expanded(
                                      child: CTextFormField(
                                        controller: _timelineDescriptionControllers[index],
                                        type: TextInputType.text,
                                        label: 'Timeline field ${index + 1}',
                                        prefixIcon: const Icon(
                                          Icons.timeline_rounded,
                                          color: Colors.grey,
                                          size: 16,
                                        ),
                                        shouldValidate: false,
                                        onChanged: (_) {
                                          _setTimelineSummary(index, _timelineDescriptionControllers[index].text, _timelineTimes[index]);
                                        },
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 8,
                                    ),
                                    ElevatedButton(
                                        onPressed: () => _selectTimelinePeriod(index),
                                        child: const Icon(
                                          Icons.access_time_outlined,
                                          size: 18,
                                        ))
                                  ],
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Text(_timelineSummaries[index]),
                                const SizedBox(
                                  height: 10,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => _eventIdController.text.isNotEmpty
                            ? _showEventOperationMenu()
                            : _submit(progressMessage: "Creating new event draft", errorMessage: "Unable to create new event draft", type: EventOperationType.create),
                        child: const Text(
                          'Submit',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ) // This trailing comma makes auto-formatting nicer for build methods.
        );
  }
}
