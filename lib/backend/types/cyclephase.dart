import 'package:ovulize/backend/types/cyclephasetype.dart';

class CyclePhase {
  CyclePhaseType type;
  int durationDays;

  CyclePhase({
    required this.type,
     required this.durationDays,
  });
}