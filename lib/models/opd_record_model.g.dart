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
    );
  }

  @override
  void write(BinaryWriter writer, OPDRecordModel obj) {
    writer
      ..writeByte(11)
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
      ..write(obj.updatedAt);
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
