import 'package:flutter/material.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:lakiite/presentation/calendar/schedule_form_page.dart';

class EditSchedulePage extends StatelessWidget {
  final Schedule schedule;
  const EditSchedulePage({super.key, required this.schedule});

  @override
  Widget build(BuildContext context) {
    return ScheduleFormPage(schedule: schedule);
  }
}
