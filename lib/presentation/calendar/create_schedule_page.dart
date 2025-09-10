import 'package:flutter/material.dart';
import 'package:lakiite/presentation/calendar/schedule_form_page.dart';

class CreateSchedulePage extends StatelessWidget {
  final DateTime? initialDate;

  const CreateSchedulePage({
    super.key,
    this.initialDate,
  });

  @override
  Widget build(BuildContext context) {
    return ScheduleFormPage(
      initialDate: initialDate,
    );
  }
}
