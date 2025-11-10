import 'package:flutter/material.dart';
import 'package:lakiite/presentation/calendar/schedule_form_page.dart';

class CreateSchedulePage extends StatelessWidget {
  const CreateSchedulePage({
    super.key,
    this.initialDate,
  });

  final DateTime? initialDate;

  @override
  Widget build(BuildContext context) {
    return ScheduleFormPage(
      initialDate: initialDate,
    );
  }
}
