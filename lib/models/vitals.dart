import 'dart:convert';

class Vitals {
  final int? bpSystolic;
  final int? bpDiastolic;
  final int? pulse;
  final double? temperature;
  final int? spo2;
  final int? respiratoryRate;
  final double? height;
  final double? weight;
  final int? fbs;
  final int? ppbs;
  final double? hba1c;

  const Vitals({
    this.bpSystolic,
    this.bpDiastolic,
    this.pulse,
    this.temperature,
    this.spo2,
    this.respiratoryRate,
    this.height,
    this.weight,
    this.fbs,
    this.ppbs,
    this.hba1c,
  });

  double? get bmi {
    if (height != null && weight != null && height! > 0) {
      final heightInMeters = height! / 100;
      return weight! / (heightInMeters * heightInMeters);
    }
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'bpSystolic': bpSystolic,
      'bpDiastolic': bpDiastolic,
      'pulse': pulse,
      'temperature': temperature,
      'spo2': spo2,
      'respiratoryRate': respiratoryRate,
      'height': height,
      'weight': weight,
      'fbs': fbs,
      'ppbs': ppbs,
      'hba1c': hba1c,
    };
  }

  factory Vitals.fromMap(Map<String, dynamic> map) {
    return Vitals(
      bpSystolic: map['bpSystolic'] as int?,
      bpDiastolic: map['bpDiastolic'] as int?,
      pulse: map['pulse'] as int?,
      temperature: map['temperature'] as double?,
      spo2: map['spo2'] as int?,
      respiratoryRate: map['respiratoryRate'] as int?,
      height: map['height'] as double?,
      weight: map['weight'] as double?,
      fbs: map['fbs'] as int?,
      ppbs: map['ppbs'] as int?,
      hba1c: map['hba1c'] as double?,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory Vitals.fromJson(String source) =>
      Vitals.fromMap(jsonDecode(source) as Map<String, dynamic>);
}