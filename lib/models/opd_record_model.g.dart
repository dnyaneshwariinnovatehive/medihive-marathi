// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'opd_record_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OPDRecordModelAdapter extends TypeAdapter<OPDRecordModel> {
  @override
  final int typeId = 1;

  @override
  OPDRecordModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OPDRecordModel(
      id: fields[0] as String,
      patientId: fields[1] as String,
      type: fields[2] as String,
      symptoms: fields[3] as String,
      diagnosis: fields[4] as String,
      medicines: fields[5] as String,
      visitDate: fields[6] as DateTime,
      isDraft: fields[7] as bool,
      isSynced: fields[8] as bool,
      createdAt: fields[9] as DateTime,
      updatedAt: fields[10] as DateTime,
      clinicalNotes: (fields[11] as String?) ?? '',
      consultationFee: (fields[12] as String?) ?? '',
      medicineFee: (fields[13] as String?) ?? '',
      discount: (fields[14] as String?) ?? '',
      paymentMode: (fields[15] as String?) ?? '',
      chargeType: (fields[16] as String?) ?? '',
      previousVisitDate: (fields[17] as String?) ?? '',
      followUpReason: (fields[18] as String?) ?? '',
      nextVisit: (fields[19] as String?) ?? '',
      bloodGroup: (fields[20] as String?) ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, OPDRecordModel obj) {
    writer
      ..writeByte(21)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.patientId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.symptoms)
      ..writeByte(4)
      ..write(obj.diagnosis)
      ..writeByte(5)
      ..write(obj.medicines)
      ..writeByte(6)
      ..write(obj.visitDate)
      ..writeByte(7)
      ..write(obj.isDraft)
      ..writeByte(8)
      ..write(obj.isSynced)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.updatedAt)
      ..writeByte(11)
      ..write(obj.clinicalNotes)
      ..writeByte(12)
      ..write(obj.consultationFee)
      ..writeByte(13)
      ..write(obj.medicineFee)
      ..writeByte(14)
      ..write(obj.discount)
      ..writeByte(15)
      ..write(obj.paymentMode)
      ..writeByte(16)
      ..write(obj.chargeType)
      ..writeByte(17)
      ..write(obj.previousVisitDate)
      ..writeByte(18)
      ..write(obj.followUpReason)
      ..writeByte(19)
      ..write(obj.nextVisit)
      ..writeByte(20)
      ..write(obj.bloodGroup);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OPDRecordModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
