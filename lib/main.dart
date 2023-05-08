import 'dart:convert';

import 'package:dancepassweb/cities.dart';
import 'package:dancepassweb/datetime_container.dart';
import 'package:dancepassweb/form_field_container.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart' as date_formatter;
import 'package:intl/intl.dart';
import 'package:intl/intl_browser.dart';

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
          textButtonTheme: const TextButtonThemeData(
            style: ButtonStyle()
          ),
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
      home: const MyHomePage(title: 'Welcome Dancepass Web'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _formKey = GlobalKey<FormState>();

  static const start = "START";
  static const end = "END";

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _venueController = TextEditingController();
  final TextEditingController _postcodeController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _bannerUrlController = TextEditingController();
  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _ticketPriceController = TextEditingController();
  final TextEditingController _ticketUrlController = TextEditingController();

  String _selectedCity = CitiesInUK.cities.first;
  final List<String> _selectedCategories = [...CitiesInUK.eventCategories.take(1)];

  String? _selectedBannerUrl;

  final List<TextEditingController> _genreFormControllers = [TextEditingController()];
  final List<TextEditingController> _lineupFormControllers = [TextEditingController()];
  final List<TextEditingController> _timelineDescriptionControllers = [TextEditingController()];
  final List<TimeOfDay> _timelineTimes = [TimeOfDay.now()];
  final List<String> _timelineSummaries = ["event at 17:30"];

  DateTime _selectedStartDate = DateTime.now();
  TimeOfDay _selectedStartTime = TimeOfDay.now();

  DateTime _selectedEndDate = DateTime.now();
  TimeOfDay _selectedEndTime = TimeOfDay.now();

  Future<void> _selectDate({required DateTime date, required period}) async {
    final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (picked != null && picked != date) {
      switch (period) {
        case "START":
          setState(() {
            _selectedStartDate = picked;
          });
          break;
        case "END":
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
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
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
      setState(() {
        _timelineTimes[index] = pickedTime;
        _setTimelineSummary(index, _timelineDescriptionControllers[index].text, _timelineTimes[index]);
      });
    }
  }

  List<String> _getAllTimeline() {
    DateTime now = DateTime.now(); // current date and time

    final timelineDescriptions = _timelineDescriptionControllers.map((controller) => controller.text).toList();
    List<String> timeline = [];
    for (var i = 0; i < timelineDescriptions.length; i++) {
      final dateTime = DateTime(now.year, now.month, now.day, _timelineTimes[i].hour, _timelineTimes[i].minute);
      timeline.add(jsonEncode({"description": timelineDescriptions[i], "time": dateTime.toIso8601String()}));
    }
    return timeline;
  }

  bool _isDateValid() {
    final startDateTime = _getStartDateTime();
    final endDateTime = _getEndDateTime();
    return startDateTime.isBefore(endDateTime);
  }

  Future<void> _createEvent() async {
    final currentState = _formKey.currentState;
    if (currentState != null) {
      if (currentState.validate()) {
        if (_isDateValid()) {
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
            "bannerUrl": _bannerUrlController.text, //"https://d29oxdp3wol7wi.cloudfront.net/public/banners/carribeans_in_london_festival.jpg",
            "hostName": _hostController.text,
            "lineup": _lineupFormControllers.map((controller) => controller.text).toList(),
            "timeline": _getAllTimeline(),
            "ticketPrice": _ticketPriceController.text,
            "ticketsUrl": _ticketUrlController.text
          };

          final json = jsonEncode(payload);

          print(json);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Start date must be before end date")));
        }
      } else {
        print("Event is not being created");
      }
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
    _timelineSummaries.add("event at 17:30");
  }

  void _removeTimeline(int index) {
    _removeTimelineDescriptionFormField(index);
    _removeTimelineTime(index);
    //_timelineSummaries.remove("event at 17:30");
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
      case start:
        summary = "Starting on";
        break;
      case end:
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
      case start:
        summary = "Starting at";
        break;
      case end:
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
    return CitiesInUK.cities.map((city) => DropdownMenuItem(value: city, child: Text(city))).toList();
  }

  List<ChoiceChip> _eventCategoriesToChoiceChip() {
    return CitiesInUK.eventCategories
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

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _venueController.dispose();
    _postcodeController.dispose();
    _addressController.dispose();
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

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.title),
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 700,
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
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
                      onChanged: (value) {},
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
                            DateAndTime(onSelect: () => _selectDate(date: _selectedStartDate, period: start), label: _displayDate(rawDateTime: _selectedStartDate, period: start)),
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.arrow_circle_right_outlined,
                                size: 18,
                              ),
                            ),
                            DateAndTime(onSelect: () => _selectDate(date: _selectedEndDate, period: end), label: _displayDate(rawDateTime: _selectedEndDate, period: end)),
                          ],
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Row(
                          children: [
                            DateAndTime(onSelect: () => _selectTime(timeOfDay: _selectedStartTime, period: end), label: _displayTime(rawTimeOfDay: _selectedStartTime, period: start)),
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.arrow_circle_right_outlined,
                                size: 18,
                              ),
                            ),
                            DateAndTime(onSelect: () => _selectTime(timeOfDay: _selectedEndTime, period: end), label: _displayTime(rawTimeOfDay: _selectedEndTime, period: end)),
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
                    CTextFormField(
                      controller: _venueController,
                      type: TextInputType.streetAddress,
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
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'City has not been provided';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    CTextFormField(
                      controller: _postcodeController,
                      type: TextInputType.streetAddress,
                      label: 'Postcode',
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    CTextFormField(
                      controller: _addressController,
                      type: TextInputType.streetAddress,
                      label: 'Address',
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: CTextFormField(
                            controller: _bannerUrlController,
                            type: TextInputType.url,
                            label: 'Banner Url',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    // Column(
                    //   crossAxisAlignment: CrossAxisAlignment.start,
                    //   children: [
                    //     SizedBox(
                    //       width: 600,
                    //       child: Row(
                    //         children: [
                    //           CTextFormField(
                    //             controller: _bannerUrlController,
                    //             width: 400,
                    //             type: TextInputType.url,
                    //             label: 'Banner',
                    //             onChanged: (value) {
                    //               setState(() {
                    //                 if (value != null) {
                    //                   _selectedBannerUrl = value;
                    //                 }
                    //               });
                    //             },
                    //           ),
                    //           //_selectedBannerUrl != null ? Image.network(_bannerUrlController.text, fit: BoxFit.contain, repeat: ImageRepeat.noRepeat, scale: 1.0, width: 100, height: 100,) : const SizedBox.shrink(),
                    //         ],
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    // const SizedBox(
                    //   height: 20,
                    // ),
                    CTextFormField(
                      controller: _hostController,
                      type: TextInputType.name,
                      label: 'Host',
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    CTextFormField(
                      controller: _ticketPriceController,
                      type: TextInputType.number,
                      label: 'Ticket price',
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    CTextFormField(
                      controller: _ticketUrlController,
                      type: TextInputType.url,
                      label: 'Ticket url',
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
                                        type: TextInputType.text,
                                        label: 'Lineup field ${index + 1}',
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
                                        onChanged: (_) {
                                          _setTimelineSummary(index, _timelineDescriptionControllers[index].text, _timelineTimes[index]);
                                        },
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 8,
                                    ),
                                    GestureDetector(
                                        onTap: () => _selectTimelinePeriod(index),
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
                        onPressed: () => _createEvent(),
                        child: const Text('Create Event', style: TextStyle(fontWeight: FontWeight.bold),),
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
