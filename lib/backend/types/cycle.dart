import 'package:ovulize/backend/types/cyclephase.dart';

class OvulationCycle {
  List<CyclePhase> phases;
  DateTime startDate;
  DateTime endDate;

  OvulationCycle({
    required this.phases,
    required this.startDate,
    required this.endDate,
  });
}