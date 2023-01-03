import 'dart:developer' as developer;
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_html/flutter_html.dart';

import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../include.dart';
import '../models.dart' as Models;
import '../ajax.dart' as Ajax;
import '../utils.dart' as Utils;
import '../globals.dart' as Globals;

class AmenityBookingPage extends StatefulWidget {
  late Models.Amenity _amenity;

  AmenityBookingPage({args}) {
    _amenity = args['amenity'];
  }

  @override
  _AmenityBookingPageState createState() => _AmenityBookingPageState(_amenity);
}

class _AmenityBookingPageState extends State<AmenityBookingPage> {
  late Models.Amenity _amenity;
  DateTime? _minDate = null;
  late DateTime _tarDate;
  List<TimeSlot> _slots = []; // Timeslot calculated
  Future<bool>? _futureData;
  late List<Models.TenantAmenityBooking> _dbBookings;
  var _uuid = Uuid();

  /////////////////////////// Getters/Setters ///////////////////////////

  // Called by child to check total booking is reach limit
  int get _totalBookMinutes {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    int total = 0;
    _slots.forEach((s) {
      if (s.bookStatus == BookStatus.bookedByMe) {
        if (this._amenity.bookingTimeBasic == 'time') {
          total += this._amenity.timeIncrement!;
        } else if (this._amenity.bookingTimeBasic == 'section') {
          total += s.duration;
        } else {
          throw 'Unhandled book basic: ${this._amenity.bookingTimeBasic}';
        }
      }
    });
    return total;
  }

  int get _bookIncrement {
    return this._amenity.timeIncrement!;
  }

  int get _bookMaximum {
    return this._amenity.timeMaximum!;
  }

  List<TimeSlot> get _timeSlots {
    return _slots;
  }

  //////////////////////////////// Functions ////////////////////////////////

  _AmenityBookingPageState(Models.Amenity amenity) {
    this._amenity = amenity;
  }

  @override
  void initState() {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    _tarDate = DateTime.now();

    // When time based booking, gen list of time slots by the time
    try {
      if (_amenity.bookingTimeBasic == 'time') {
        _createTimeSlots();
      } else if (_amenity.bookingTimeBasic == 'section') {
        _createSectionSlots();
      } else {
        throw 'Unhandled booking time basic: ${_amenity.bookingTimeBasic}';
      }
      _futureData = _loadInitialData();
    } catch (error) {
      // To halt this widget
      // https://stackoverflow.com/questions/49466556/flutter-run-method-on-widget-build-complete
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Utils.showAlertDialog(
          context,
          'error'.tr(),
          error as String,
        );
        Navigator.pop(context);
      });
    }

    super.initState();
  }

  Future<bool> _loadInitialData() async {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    await _getTheDateBookings();
    _changeTimeSlotsStatus();

    return true;
  }

  Future<void> _getTheDateBookings() async {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    // Get all booked db records for same date
    Ajax.ApiResponse resp = await Ajax.getTenantBookingsByDate(
        // clientCode: Globals.curClientJson?['code'],
        date: DateFormat('yyyy-MM-dd').format(_tarDate),
        amenityId: _amenity.id);

    // Convert from JSON to Models.TenantAmenityBooking[]
    _dbBookings = [];
    for (int i = 0; i < resp.data.length; ++i) {
      Map<String, dynamic> r = resp.data[i];

      List<Models.TenantAmenityBookingSlot> slots = [];
      for (int j = 0; j < r['time_slots'].length; ++j) {
        Map<String, dynamic> s = r['time_slots'][j];
        slots.add(Models.TenantAmenityBookingSlot(
          id: _uuid.v4(),
          timeStart: s['tenant_amenity_bkgslots_id']['time_start'],
          timeEnd: s['tenant_amenity_bkgslots_id']['time_end'],
          bookingSection: s['tenant_amenity_bkgslots_id']['booking_section'],
          fee: s['tenant_amenity_bkgslots_id']['fee'],
        ));
      }
      _dbBookings.add(Models.TenantAmenityBooking(
        id: r['id'],
        dateCreated: DateTime.parse(r['date_created']),
        tenantId: r['tenant'],
        amenityId: r['amenity'],
        bookingTimeBasic: r['booking_time_basic'],
        date: r['date'],
        totalFee: r['total_fee']?.toDouble(),
        isPaid: r['is_paid'],
        slots: slots,
        // timeStart: r['time_start'],
        // timeEnd: r['time_end'],
        // fee: r['fee'],
      ));
    }
  }

  // Is Monday bookable for current amenity (e.g.)?
  bool _isWeekdayOpen(DateTime day) {
    if (day.weekday == 1) {
      return this._amenity.monday;
    } else if (day.weekday == 2) {
      return this._amenity.tuesday;
    } else if (day.weekday == 3) {
      return this._amenity.wednesday;
    } else if (day.weekday == 4) {
      return this._amenity.thursday;
    } else if (day.weekday == 5) {
      return this._amenity.friday;
    } else if (day.weekday == 6) {
      return this._amenity.saturday;
    } else if (day.weekday == 7) {
      return this._amenity.sunday;
    }
    throw 'Should not be here';
  }

  // Create the screen bookable slots for 'time' based amenity
  void _createTimeSlots() {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    DateTime now = DateTime.now();
    bool isDateChanged = _tarDate.year != now.year ||
        _tarDate.month != now.month ||
        _tarDate.day !=
            now.day; // If date changed, the begin time will be the amenity opening time

    // Calculate the amenity bookable start time & end time
    DateTime startTime;
    DateTime endTime = DateTime(now.year, now.month, now.day,
        this._amenity.timeClose!.hour, this._amenity.timeClose!.minute, 0);
    endTime = endTime.subtract(Duration(minutes: this._amenity.timeIncrement!));

    // Is today pass? If so, proceed to tomorrow's startTime defined in amenity
    if (!isDateChanged && now.isAfter(endTime)) {
      isDateChanged = true;
      _tarDate = _tarDate.add(Duration(days: 1)); // move to tomorrow
    }

    // Skip until the weekday is bookable
    int loop = 0; // To detect whole week is not bookable
    while (!_isWeekdayOpen(_tarDate)) {
      isDateChanged = true;
      _tarDate = _tarDate.add(Duration(days: 1));
      if (++loop > 7) {
        throw 'This amenity is not available all the time (Mon-Sun). Please contact mangement office';
      }
    }

    if (_minDate == null) {
      _minDate = _tarDate; // Tell popup calendar the minimum date
    }

    if (isDateChanged) {
      startTime = DateTime(_tarDate.year, _tarDate.month, _tarDate.day,
          this._amenity.timeOpen!.hour, this._amenity.timeOpen!.minute, 0);
    } else {
      startTime = _tarDate;
    }

    endTime = DateTime(startTime.year, startTime.month, startTime.day,
        this._amenity.timeClose!.hour, this._amenity.timeClose!.minute, 0);
    endTime = endTime.subtract(Duration(minutes: this._amenity.timeIncrement!));

    // is it today?
    if (!isDateChanged) {
      // Is the time earlier than amenity?
      if (now.isBefore(startTime)) {
        startTime = DateTime(now.year, now.month, now.day,
            this._amenity.timeOpen!.hour, this._amenity.timeOpen!.minute, 0);
      } else {
        DateTime dt = DateTime(now.year, now.month, now.day,
            this._amenity.timeOpen!.hour, this._amenity.timeOpen!.minute, 0);
        while (dt.isBefore(now)) {
          dt = dt.add(Duration(minutes: this._amenity.timeIncrement!));
        }
        startTime = dt;
      }
    }

    // Reset the time slots
    _slots = [];
    DateFormat timeFmt1 = DateFormat('h:mm a'); // Time format for human
    DateFormat timeFmt2 = DateFormat('HH:mm'); // time format for computer
    int seq = 0;
    while (startTime.isAtSameMomentAs(endTime) || startTime.isBefore(endTime)) {
      DateTime timeTo =
          startTime.add(Duration(minutes: this._amenity.timeIncrement!));
      TimeSlot slot = new TimeSlot(
          seq: ++seq,
          startText: timeFmt1.format(startTime).toLowerCase(),
          endText: timeFmt1.format(timeTo),
          timeStart: timeFmt2.format(startTime),
          timeEnd: timeFmt2.format(timeTo),
          duration: timeTo.difference(startTime).inMinutes);
      _slots.add(slot);

      startTime = timeTo;
    }
  }

  // Create the screen bookable slots for 'section' based amenity
  void _createSectionSlots() {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    DateTime now = DateTime.now();
    bool isDateChanged = _tarDate.year != now.year ||
        _tarDate.month != now.month ||
        _tarDate.day !=
            now.day; // If date changed, the begin time will be the amenity opening time

    // Sort the sections by time from earliest to latest
    this._amenity.bookingSections!.sort((a, b) {
      return a.timeBegin.compareTo(b.timeBegin);
    });

    if (!isDateChanged) {
      // If today, is now later than last sections begin time? If so, move to tomorrow
      String todayLastSectionBeginTime = this
          ._amenity
          .bookingSections![this._amenity.bookingSections!.length - 1]
          .timeBegin;
      DateTime dtTodayLastSectionBeginTime = DateTime.parse(
          DateFormat('yyyy-MM-dd').format(now) +
              ' ' +
              todayLastSectionBeginTime);
      if (now.isAfter(dtTodayLastSectionBeginTime)) {
        isDateChanged = true;
        _tarDate = _tarDate.add(Duration(days: 1)); // move to tomorrow
      }
    }

    // Skip until the weekday is bookable
    int loop = 0; // To detect whole week is not bookable
    while (!_isWeekdayOpen(_tarDate)) {
      isDateChanged = true;
      _tarDate = _tarDate.add(Duration(days: 1));
      if (++loop > 7) {
        throw 'amenityNotAvailAllTime'.tr();
      }
    }

    if (_minDate == null) {
      _minDate = _tarDate; // Tell popup calendar the minimum date
    }

    // What section(s) will be shown
    List<Models.AmenityBookingSection> sections = [];
    if (isDateChanged) {
      // If not today, all sections are okay
      sections.addAll(this._amenity.bookingSections!);
    } else {
      // If today, calculate what section(s) is past
      String nowTime = DateFormat('HH:mm').format(now);
      for (int i = 0; i < this._amenity.bookingSections!.length; ++i) {
        var bs = this._amenity.bookingSections![i];
        if (nowTime.compareTo(bs.timeBegin) < 0) {
          sections.add(bs);
        }
      }
    }

    // Reset the time slots
    _slots = [];
    int seq = 0;
    DateFormat timeFmt1 = DateFormat('h:mm a'); // Time format for human
    // DateFormat timeFmt2 = DateFormat('HH:mm'); // time format for computer
    for (int i = 0; i < sections.length; ++i) {
      Models.AmenityBookingSection section = sections[i];
      DateTime dtBegin = DateTime.parse(
          DateFormat('yyyy-MM-dd').format(_tarDate) + ' ' + section.timeBegin);
      DateTime dtEnd = DateTime.parse(
          DateFormat('yyyy-MM-dd').format(_tarDate) + ' ' + section.timeEnd);

      TimeSlot slot = new TimeSlot(
        seq: ++seq,
        startText: timeFmt1.format(dtBegin).toLowerCase(),
        endText: timeFmt1.format(dtEnd).toLowerCase(),
        timeStart: section.timeBegin,
        timeEnd: section.timeEnd,
        duration: dtEnd.difference(dtBegin).inMinutes,
        sectionId: section.bookingSectionId,
      );
      _slots.add(slot);
    }
  }

  // Check all current timeslots to change the status if needed
  void _changeTimeSlotsStatus() {
    developer.log(StackTrace.current.toString().split('\n')[0]);
    assert(_slots.length > 0);
    String curTenantId = Globals.curUserJson!['id'];

    for (int i = 0; i < _slots.length; ++i) {
      TimeSlot ts = _slots[i];

      // Is the same time found in database record?
      bool found = false;
      for (int j = 0; j < _dbBookings.length; ++j) {
        Models.TenantAmenityBooking booking = _dbBookings[j];
        for (int k = 0; k < booking.slots.length; ++k) {
          Models.TenantAmenityBookingSlot slot = booking.slots[k];
          // If the same time found, proceed to check the status
          if (slot.timeStart == ts.timeStart) {
            if (_amenity.isRepetitiveBooking) {
              // If it is repetitive booking, check if the tenant is the same
              if (booking.tenantId == curTenantId) {
                found = true;
              }
            } else {
              found = true;
            }
          }
        }
      }
      // _dbBookings.forEach((booking) {
      //   booking.slots.forEach((slot) {
      //     if (slot.timeStart == ts.timeStart) {
      //       found = true;
      //     }
      //   });
      // });

      if (found) {
        // Comment this to test the time booked by other
        ts.bookStatus = BookStatus.bookedInDb;
      }
    }
  }

  void refresh() {
    setState(() {});
  }

  Future<void> _onBtnConfirm(BuildContext context) async {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    // Get all booked slots
    // List<Models.TenantAmenityBooking> bookings = [];
    List<String> times =
        []; // Get selected starting time(s), for verify final status

    List<Models.TenantAmenityBookingSlot> tabslots = [];
    double totalFee = 0.0;
    for (int i = 0; i < _slots.length; ++i) {
      TimeSlot slot = _slots[i];
      if (slot.bookStatus == BookStatus.bookedByMe) {
        String? sectionId = null;
        if (this._amenity.bookingTimeBasic == 'section') {
          sectionId = slot.sectionId;
        }
        totalFee += _amenity.fee.toDouble();

        tabslots.add(Models.TenantAmenityBookingSlot(
          // tenantAmenityBookingId: 0,
          // bookingTimeBasic: amenity.bookingTimeBasic,
          id: _uuid.v4(),
          timeStart: slot.timeStart,
          timeEnd: slot.timeEnd,
          bookingSection: sectionId,
          fee: _amenity.fee.toDouble(),
        ));
        times.add(slot.timeStart);
      }
    }

    if (!_amenity.isRepetitiveBooking) {
      // Verify the latest status: Is someone booked the same time?
      Ajax.ApiResponse resp = await Ajax.getTenantBookingByTimes(
        // clientCode: Globals.curClientJson?['code'],
        amenityId: this._amenity.id,
        date: DateFormat('yyyy-MM-dd').format(_tarDate),
        times: times,
      );

      if (resp.data.length > 0) {
        // Some time(s) is/are booked. So refresh the screen
        List<String> timesDupld = []; // Duplicated time(s)
        for (int i = 0; i < resp.data.length; ++i) {
          var bkg = resp.data[i];
          // Convert the time to human readable format & add to array "times"
          for (int j = 0; j < bkg['time_slots'].length; ++j) {
            var slot = bkg['time_slots'][j];
            String time = slot['tenant_amenity_bkgslots_id']['time_start'];
            timesDupld.add(Utils.formatTime(time));
          }
        }
        String msg = 'amenityBkdByOthers'.tr();
        msg = msg.replaceAll('{time}', timesDupld.join(", "));
        await Utils.showAlertDialog(
          context,
          'amenityBookedFailed'.tr(),
          msg,
          backgroundColor: Colors.red[50],
        );

        await _getTheDateBookings();
        _changeTimeSlotsStatus();
        setState(() {});
      }
    }

    // Now it can save the booking
    Models.TenantAmenityBooking booking = Models.TenantAmenityBooking(
      id: _uuid.v4(),
      dateCreated: DateTime.now(),
      tenantId: Globals.curUserJson?['id'],
      amenityId: _amenity.id,
      bookingTimeBasic: _amenity.bookingTimeBasic,
      date: DateFormat('yyyy-MM-dd').format(_tarDate),
      totalFee: totalFee,
      isPaid: false,
      slots: [],
    );

    String status = totalFee == 0 ? 'confirmed' : 'pending';
    DateTime? autoCancelTime = null;
    if (status == 'pending' && _amenity.autoCancelHours != null) {
      autoCancelTime =
          DateTime.now().add(Duration(hours: _amenity.autoCancelHours!));
    }
    await Ajax.saveAmenityBooking(
        booking: booking,
        slots: tabslots,
        status: status,
        autoCancelTime: autoCancelTime);
    late String msg;
    if (this._amenity.fee == 0) {
      msg = 'amenityBookToCancel'.tr();
    } else {
      msg = 'amenityPayUsageFee'.tr();
      msg = msg.replaceAll('{fee}', totalFee.toString());
      msg = msg.replaceAll('{hours}', _amenity.autoCancelHours.toString());
    }

    await Utils.showAlertDialog(
      context,
      'amenityBookedSuccess'.tr(),
      msg,
    );

    await Globals.homePage.refreshData();
    Navigator.pop(context);
  }

  // The confirm booking board widget at the bottom of screen
  Widget _renderConfirmWidget(BuildContext context) {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    Size size = MediaQuery.of(context).size;

    return ClipRRect(
      child: Container(
        // alignment: Alignment.center,
        padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
        // padding: EdgeInsets.all(10),
        width: size.width,
        height: 85,
        decoration: BoxDecoration(
          color: Theme.of(context).backgroundColor,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  children: [
                    Text(
                      'amenityBkgTotalTime'.tr() +
                          '\n' +
                          Utils.durationText(_totalBookMinutes),
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 17.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                MaterialButton(
                  onPressed: (_totalBookMinutes == 0)
                      ? null
                      : () {
                          _onBtnConfirm(context);
                        },
                  disabledColor: Colors.grey[400],
                  color: Globals.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    'amenityBkgConfirmBooking'.tr(),
                    style: TextStyle(
                      color: (_totalBookMinutes == 0)
                          ? Colors.black45
                          : Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 20.0,
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<void> _onBtnChgDate() async {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    int advanceDays = this._amenity.bookingAdvanceDays;
    if (advanceDays == 0) {
      advanceDays = 365;
    }

    // Max bookable days is 1 year
    DateTime max = DateTime.now().add(Duration(days: advanceDays));

    DateTime? dt = await showDatePicker(
      context: context,
      initialDate: _tarDate,
      firstDate: _minDate!,
      lastDate: max,
      selectableDayPredicate: (DateTime day) {
        if (day.weekday == 1) {
          return (this._amenity.monday);
        } else if (day.weekday == 2) {
          return (this._amenity.tuesday);
        } else if (day.weekday == 3) {
          return (this._amenity.wednesday);
        } else if (day.weekday == 4) {
          return (this._amenity.thursday);
        } else if (day.weekday == 5) {
          return (this._amenity.friday);
        } else if (day.weekday == 6) {
          return (this._amenity.saturday);
        } else if (day.weekday == 7) {
          return (this._amenity.sunday);
        }
        return false;
      },
    );
    if (dt != null &&
        (dt.year != _tarDate.year ||
            dt.month != _tarDate.month ||
            dt.day != _tarDate.day)) {
      DateTime now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        _tarDate = now;
      } else {
        if (this._amenity.bookingTimeBasic == 'time') {
          _tarDate = DateTime(dt.year, dt.month, dt.day,
              this._amenity.timeOpen!.hour, this._amenity.timeOpen!.minute, 0);
        } else {
          _tarDate = DateTime.parse(DateFormat('yyyy-MM-dd').format(dt) +
              ' ' +
              this._amenity.bookingSections![0].timeBegin);
        }
      }

      if (this._amenity.bookingTimeBasic == 'time') {
        _createTimeSlots();
      } else if (this._amenity.bookingTimeBasic == 'section') {
        _createSectionSlots();
      } else {
        throw 'Unhandled book time basic: ${this._amenity.bookingTimeBasic}';
      }
      await _getTheDateBookings();
      _changeTimeSlotsStatus();

      setState(() {});
    }
  } // onBtnChgDate()

  _onBtnBack() {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    Navigator.pop(context);
  }

  Widget _renderTimeBased() {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    Size size = MediaQuery.of(context).size;

    // The appearence is followed this tutorial:
    // https://www.youtube.com/watch?v=Ado9tu_9bcw
    return Container(
      width: size.width,
      height: size.height,
      child: Stack(
        children: <Widget>[
          Container(
            // height: size.height / 4 + 20,
            height: 130,
            width: size.width,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                CachedNetworkImage(imageUrl: _amenity.photo, fit: BoxFit.fill),
                Container(
                  width: size.width,
                  height: size.height,
                  color: Globals.primaryColor.withOpacity(0.1),
                ),
              ],
            ),
          ),
          Positioned(
            // top: size.height / 4 - 30,
            top: 90,
            child: Container(
              width: size.width,
              height: size.height,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(50),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 50),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'amenityBkgTimeslot'.tr(),
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                        Row(
                          children: [
                            Text(DateFormat('yyyy-M-d').format(_tarDate)),
                            IconButton(
                              icon:
                                  Icon(Icons.edit, color: Globals.primaryColor),
                              onPressed: _onBtnChgDate,
                            ),
                          ],
                        )
                      ],
                    ),
                    SizedBox(height: 5),
                    // Widgets to show time slots and its layout
                    SingleChildScrollView(
                      child: SizedBox(
                        height: size.height - 280,
                        // height: 250,
                        child: ListView(
                          children: _slots.map((s) {
                            // Must pass the UniqueKey otherwise the stateful widgets are not redrawn
                            // https://medium.com/flutter/keys-what-are-they-good-for-13cb51742e7d
                            return TimeSlotTile(
                              key: UniqueKey(),
                              timeslot: s,
                              parent: this,
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    SizedBox(height: 5),
                    // confirmWidget,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            // top: size.height / 3 - 130,
            top: 60,
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 20,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _amenity.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      // SizedBox(height: 5),
                      SizedBox(
                        height: 50,
                        child: SingleChildScrollView(
                          child: Html(data: _amenity.details),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 25,
            left: 20,
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: _onBtnBack,
            ),
          ),
        ],
      ),
    );
  }

  Widget _renderBody() {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    List<TimeSlotTile> tiles = _slots.map((s) {
      // Must pass the UniqueKey otherwise the stateful widgets are not redrawn
      // https://medium.com/flutter/keys-what-are-they-good-for-13cb51742e7d
      return TimeSlotTile(
        key: UniqueKey(),
        timeslot: s,
        parent: this,
      );
    }).toList();

    Size size = MediaQuery.of(context).size;

    // The appearence is followed this tutorial:
    // https://www.youtube.com/watch?v=Ado9tu_9bcw
    return Container(
      width: size.width,
      height: size.height,
      child: Stack(
        children: <Widget>[
          Container(
            // height: size.height / 4 + 20,
            height: 130,
            width: size.width,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                CachedNetworkImage(imageUrl: _amenity.photo, fit: BoxFit.fill),
                Container(
                  width: size.width,
                  height: size.height,
                  color: Colors.orange.withOpacity(0.1),
                ),
              ],
            ),
          ),
          // Draw the Back button & Amenity name
          Positioned(
            top: 37,
            left: 10,
            child: Container(
              padding: EdgeInsets.fromLTRB(0, 0, 20, 0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(30.0),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios, color: Colors.black),
                    onPressed: _onBtnBack,
                  ),
                  Text(
                    _amenity.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            // top: size.height / 4 - 30,
            top: 90,
            child: Container(
              width: size.width,
              height: size.height,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(50),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 89),
                    Divider(height: 1, thickness: 1, indent: 0, endIndent: 0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'amenityBkgTimeslot'.tr(),
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                        Row(
                          children: [
                            Text(DateFormat('yyyy-M-d').format(_tarDate)),
                            IconButton(
                              icon:
                                  Icon(Icons.edit, color: Globals.primaryColor),
                              onPressed: _onBtnChgDate,
                            ),
                          ],
                        )
                      ],
                    ),
                    Divider(height: 1, thickness: 1, indent: 0, endIndent: 0),
                    // SizedBox(height: 5),
                    // Widgets to show time slots and its layout
                    SingleChildScrollView(
                      child: SizedBox(
                        height: size.height - 299,
                        // height: 250,
                        child: ListView(children: tiles),
                      ),
                    ),
                    // SizedBox(height: 20),
                    // confirmWidget,
                  ],
                ),
              ),
            ),
          ),
          // Draw the amenity details
          Positioned(
            // top: size.height / 3 - 130,
            top: 100,
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 20,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(
                        height: 80,
                        child: SingleChildScrollView(
                          child: Html(data: _amenity.details),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_futureData == null) {
      // Some error occuried. See initState()
      return Container();
    }

    return Scaffold(
      body: FutureBuilder<bool>(
        future: _futureData,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return _renderBody();
          } else if (snapshot.hasError) {
            return Container(
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'sysError'.tr() + ' ${snapshot.error}',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      bottomSheet: _renderConfirmWidget(context),
    );
  } // build()
} // _AmenityBookingPageState

enum BookStatus {
  available,
  bookedByMe,
  bookedInDb,
}

// Data structure to handle a time slot
class TimeSlot {
  int seq; // sequence
  String startText;
  String endText;
  String timeStart;
  String timeEnd;
  int duration; // duration in minutes
  String? sectionId; // used in section based booking only
  BookStatus bookStatus = BookStatus.available;

  TimeSlot({
    required this.seq,
    required this.startText,
    required this.endText,
    required this.timeStart,
    required this.timeEnd,
    required this.duration,
    this.sectionId,
  });

  String get durationText {
    return Utils.durationText(duration);
  }
}

// Widget to render a booking tile
class TimeSlotTile extends StatefulWidget {
  final TimeSlot timeslot;
  final _AmenityBookingPageState parent;

  TimeSlotTile({Key? key, required this.timeslot, required this.parent})
      : super(key: key);

  @override
  _TimeSlotTileState createState() => _TimeSlotTileState(timeslot, parent);
}

class _TimeSlotTileState extends State<TimeSlotTile> {
  final TimeSlot timeslot;
  final _AmenityBookingPageState parent;

  _TimeSlotTileState(this.timeslot, this.parent);

  Future<void> _onBtnBook(BuildContext context) async {
    developer.log(StackTrace.current.toString().split('\n')[0]);

    // Toogle the book status
    if (this.timeslot.bookStatus == BookStatus.available) {
      if (parent._amenity.bookingTimeBasic == 'time') {
        int totalBooked = parent._totalBookMinutes;
        int bookInc = parent._bookIncrement;
        int bookMax = parent._bookMaximum;
        if (totalBooked + bookInc > bookMax) {
          String msg = 'amenityBkgUpperLimit'.tr();
          msg = msg.replaceAll('{bookMax}', bookMax.toString());
          // Can't book
          await Utils.showAlertDialog(
            context,
            'notAllow'.tr(),
            msg,
          );
        } else {
          // Book okay
          this.timeslot.bookStatus = BookStatus.bookedByMe;
          parent.refresh();
        }
      } else if (parent._amenity.bookingTimeBasic == 'section') {
        var ts = parent._timeSlots
            .where((el) => el.bookStatus == BookStatus.bookedByMe);
        if (ts.isEmpty) {
          // Book okay
          this.timeslot.bookStatus = BookStatus.bookedByMe;
          parent.refresh();
        } else {
          // Can't book
          await Utils.showAlertDialog(
            context,
            'notAllow'.tr(),
            'amenityBkgOnly1Section'.tr(),
          );
        }
      }
    } else if (this.timeslot.bookStatus == BookStatus.bookedByMe) {
      this.timeslot.bookStatus = BookStatus.available;
      parent.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    late Icon stsIcon;

    if (timeslot.bookStatus == BookStatus.available) {
      stsIcon = Icon(
        Icons.radio_button_unchecked,
        color: Globals.primaryLightColor, // Colors.green[200],
        size: 24.0,
      );
    } else if (timeslot.bookStatus == BookStatus.bookedByMe) {
      stsIcon = Icon(
        Icons.radio_button_checked,
        color: Globals.primaryColor, // Colors.green[800],
        size: 24.0,
      );
    } else {
      stsIcon = Icon(
        Icons.radio_button_checked,
        color: Colors.grey,
        size: 24.0,
      );
    }

    Size size = MediaQuery.of(context).size;

    return Container(
      height: 70,
      margin: EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: size.width / 2 - 40,
                child: Text(
                  timeslot.startText,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              // SizedBox(height: 5),
              Text(
                timeslot.durationText,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12.0,
                ),
              )
            ],
          ),
          stsIcon,
          MaterialButton(
            onPressed: (timeslot.bookStatus == BookStatus.bookedInDb)
                ? null
                : () {
                    _onBtnBook(context);
                  },
            disabledColor: Colors.grey[400],
            color: Globals.primaryLightDarkColor, // Colors.green[800],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'amenityBkgBook'.tr(),
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
