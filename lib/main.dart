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
          primarySwatch: Colors.blue,
          inputDecorationTheme: InputDecorationTheme(
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
              borderRadius: BorderRadius.circular(10),
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
              fontSize: 16,
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

  String? _selectedCity;
  final List<String> _selectedCategories = [];

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
        _displayTimelineSummary(index, _timelineDescriptionControllers[index].text, _timelineTimes[index]);
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

  void _addLineupFormField() {
    // Add a new form field when the button is clicked
    final newController = TextEditingController();
    setState(() {
      _lineupFormControllers.add(newController);
    });
  }

  void _addTimeline() {
    _addTimelineFormField();
    _addTimelineTime();
    _timelineSummaries.add("event at 17:30");
  }

  void _addTimelineFormField() {
    // Add a new form field when the button is clicked
    // Add a new form field when the button is clicked
    final newController = TextEditingController();
    setState(() {
      _timelineDescriptionControllers.add(newController);
    });
  }

  void _addTimelineTime() {
    // Add a new form field when the button is clicked
    // Add a new form field when the button is clicked
    final newTimeOfDay = TimeOfDay.now();
    setState(() {
      _timelineTimes.add(newTimeOfDay);
    });
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

  void _displayTimelineSummary(int index, String description, TimeOfDay rawTimeOfDay) {
    setState(() {
      _timelineSummaries[index] = "$description at ";
    });
  }

  List<DropdownMenuItem<String>> _citiesToDropdown() {
    return CitiesInUK.cities.map((city) => DropdownMenuItem(value: city, child: Text(city))).toList();
  }

  List<DropdownMenuItem<String>> _eventCategoriesToDropdown() {
    return CitiesInUK.eventCategories
        .map((category) => DropdownMenuItem(
            value: category,
            child: Row(
              children: [
                Checkbox(
                  value: _selectedCategories.contains(category),
                  onChanged: (_) {
                    setState(() {
                      if (_selectedCategories.contains(category)) {
                        _selectedCategories.remove(category);
                      } else {
                        _selectedCategories.add(category);
                      }
                    });
                  },
                ),
                Text(category),
              ],
            )))
        .toList();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
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
                        const SizedBox(height: 10,),
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
                    // Column(
                    //   crossAxisAlignment: CrossAxisAlignment.start,
                    //   children: [
                    //     const Text("Category"),
                    //     const SizedBox(
                    //       height: 4,
                    //     ),
                    //     SizedBox(
                    //       width: 250,
                    //       child: DropdownButtonFormField(
                    //         items: _eventCategoriesToDropdown(),
                    //         onChanged: (value) {
                    //           setState(() {
                    //             if (value != null) {
                    //               _selectedCategories.add(value);
                    //             }
                    //           });
                    //         },
                    //         validator: (value) {
                    //           if (_selectedCategories.isEmpty) {
                    //             return 'Category has not been provided';
                    //           }
                    //           return null;
                    //         },
                    //       ),
                    //     )
                    //   ],
                    // ),
                    // const SizedBox(
                    //   height: 20,
                    // ),
                    //
                    // /// Genre
                    // const SizedBox(
                    //   height: 20,
                    // ),
                    // const Text(
                    //   "Genre",
                    //   style: TextStyle(fontSize: 14),
                    // ),
                    // const SizedBox(
                    //   height: 4,
                    // ),
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.center,
                    //   crossAxisAlignment: CrossAxisAlignment.start,
                    //   children: [
                    //     Container(
                    //       color: Colors.grey.shade200,
                    //       padding: const EdgeInsets.all(8),
                    //       height: 200,
                    //       width: 400,
                    //       child: ListView.builder(
                    //         itemCount: _genreFormControllers.length,
                    //         itemBuilder: (context, index) {
                    //           return Column(
                    //             crossAxisAlignment: CrossAxisAlignment.start,
                    //             children: [
                    //               CTextFormField(
                    //                 controller: _genreFormControllers[index],
                    //                 width: 400,
                    //                 type: TextInputType.text,
                    //                 label: 'Genre field ${index + 1}',
                    //               ),
                    //               const SizedBox(
                    //                 height: 10,
                    //               )
                    //             ],
                    //           );
                    //         },
                    //       ),
                    //     ),
                    //     const SizedBox(
                    //       width: 10,
                    //     ),
                    //     GestureDetector(
                    //         onTap: () => _addGenreFormField(),
                    //         child: const Icon(
                    //           Icons.add_box,
                    //           size: 30,
                    //         ))
                    //   ],
                    // ),
                    // const SizedBox(
                    //   height: 20,
                    // ),
                    // FormFieldContainer(
                    //     width: 500,
                    //     child: Row(
                    //       children: [
                    //         Column(
                    //           crossAxisAlignment: CrossAxisAlignment.start,
                    //           children: [
                    //             CTextFormField(
                    //               controller: _venueController,
                    //               width: 200,
                    //               type: TextInputType.streetAddress,
                    //               label: 'Venue',
                    //             ),
                    //           ],
                    //         ),
                    //         const SizedBox(
                    //           width: 10,
                    //         ),
                    //         Column(
                    //           crossAxisAlignment: CrossAxisAlignment.start,
                    //           children: [
                    //             SizedBox(
                    //               width: 250,
                    //               child: DropdownButtonFormField(
                    //                 items: _citiesToDropdown(),
                    //                 onChanged: (value) {
                    //                   setState(() {
                    //                     _selectedCity = value;
                    //                   });
                    //                 },
                    //                 validator: (value) {
                    //                   if (value == null || value.isEmpty) {
                    //                     return 'City has not been provided';
                    //                   }
                    //                   return null;
                    //                 },
                    //               ),
                    //             ),
                    //           ],
                    //         ),
                    //       ],
                    //     )),
                    // const SizedBox(
                    //   height: 20,
                    // ),
                    // FormFieldContainer(
                    //     width: 500,
                    //     child: Row(
                    //       children: [
                    //         Column(
                    //           crossAxisAlignment: CrossAxisAlignment.start,
                    //           children: [
                    //             CTextFormField(
                    //               controller: _postcodeController,
                    //               width: 200,
                    //               type: TextInputType.streetAddress,
                    //               label: 'Postcode',
                    //             ),
                    //           ],
                    //         ),
                    //         const SizedBox(
                    //           width: 10,
                    //         ),
                    //         Column(
                    //           crossAxisAlignment: CrossAxisAlignment.start,
                    //           children: [
                    //             CTextFormField(
                    //               controller: _addressController,
                    //               width: 200,
                    //               type: TextInputType.streetAddress,
                    //               label: 'Address',
                    //             ),
                    //           ],
                    //         ),
                    //       ],
                    //     )),
                    // const SizedBox(
                    //   height: 20,
                    // ),
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
                    // Column(
                    //   crossAxisAlignment: CrossAxisAlignment.start,
                    //   children: [
                    //     CTextFormField(
                    //       controller: _hostController,
                    //       width: 400,
                    //       type: TextInputType.name,
                    //       label: 'Host',
                    //     ),
                    //   ],
                    // ),
                    // const SizedBox(
                    //   height: 20,
                    // ),
                    // Container(
                    //   color: Colors.grey.shade200,
                    //   padding: const EdgeInsets.all(8),
                    //   width: 400,
                    //   child: Row(
                    //     children: [
                    //       Column(
                    //         crossAxisAlignment: CrossAxisAlignment.start,
                    //         children: [
                    //           CTextFormField(
                    //             controller: _ticketPriceController,
                    //             width: 100,
                    //             type: TextInputType.number,
                    //             label: 'Ticket Price',
                    //           ),
                    //         ],
                    //       ),
                    //       const SizedBox(
                    //         width: 10,
                    //       ),
                    //       Column(
                    //         crossAxisAlignment: CrossAxisAlignment.start,
                    //         children: [
                    //           CTextFormField(
                    //             controller: _ticketUrlController,
                    //             width: 200,
                    //             type: TextInputType.url,
                    //             label: 'Ticket Url',
                    //           ),
                    //         ],
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    //
                    // /// Lineup
                    // const SizedBox(
                    //   height: 20,
                    // ),
                    // const Text(
                    //   "Line Up",
                    //   style: TextStyle(fontSize: 14),
                    // ),
                    // const SizedBox(
                    //   height: 4,
                    // ),
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.center,
                    //   crossAxisAlignment: CrossAxisAlignment.start,
                    //   children: [
                    //     Container(
                    //       color: Colors.grey.shade200,
                    //       padding: const EdgeInsets.all(8),
                    //       height: 200,
                    //       width: 400,
                    //       child: ListView.builder(
                    //         itemCount: _lineupFormControllers.length,
                    //         itemBuilder: (context, index) {
                    //           return Column(
                    //             crossAxisAlignment: CrossAxisAlignment.start,
                    //             children: [
                    //               CTextFormField(
                    //                 controller: _lineupFormControllers[index],
                    //                 width: 400,
                    //                 type: TextInputType.text,
                    //                 label: 'Lineup field ${index + 1}',
                    //               ),
                    //               const SizedBox(
                    //                 height: 10,
                    //               )
                    //             ],
                    //           );
                    //         },
                    //       ),
                    //     ),
                    //     const SizedBox(
                    //       width: 10,
                    //     ),
                    //     GestureDetector(
                    //         onTap: () => _addLineupFormField(),
                    //         child: const Icon(
                    //           Icons.add_box,
                    //           size: 30,
                    //         ))
                    //   ],
                    // ),
                    //
                    // /// Timeline
                    // const SizedBox(
                    //   height: 20,
                    // ),
                    // const Text(
                    //   "Timeline of events",
                    //   style: TextStyle(fontSize: 14),
                    // ),
                    // const SizedBox(
                    //   height: 4,
                    // ),
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.center,
                    //   crossAxisAlignment: CrossAxisAlignment.start,
                    //   children: [
                    //     Container(
                    //       color: Colors.grey.shade200,
                    //       padding: const EdgeInsets.only(top: 8, right: 8, bottom: 8),
                    //       height: 200,
                    //       width: 400,
                    //       child: ListView.builder(
                    //         itemCount: _timelineDescriptionControllers.length,
                    //         itemBuilder: (context, index) {
                    //           return ListTile(
                    //             title: CTextFormField(
                    //               controller: _timelineDescriptionControllers[index],
                    //               width: 400,
                    //               type: TextInputType.text,
                    //               onChanged: (value) {
                    //                 _displayTimelineSummary(index, _timelineDescriptionControllers[index].text, _timelineTimes[index]);
                    //               },
                    //               label: 'Timeline field ${index + 1}',
                    //             ),
                    //             subtitle: Padding(
                    //               padding: const EdgeInsets.all(8.0),
                    //               child: Text(_timelineSummaries[index]),
                    //             ),
                    //             trailing: IconButton(
                    //               icon: const Icon(Icons.access_time),
                    //               onPressed: () => _selectTimelinePeriod(index),
                    //             ),
                    //           );
                    //         },
                    //       ),
                    //     ),
                    //     const SizedBox(
                    //       width: 10,
                    //     ),
                    //     GestureDetector(
                    //         onTap: () => _addTimeline(),
                    //         child: const Icon(
                    //           Icons.add_box,
                    //           size: 30,
                    //         ))
                    //   ],
                    // ),
                    // const SizedBox(
                    //   height: 20,
                    // ),
                    ElevatedButton(
                      onPressed: () => _createEvent(),
                      child: const Text('Create Event'),
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
