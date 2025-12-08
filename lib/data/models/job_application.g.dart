// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_application.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class JobApplicationAdapter extends TypeAdapter<JobApplication> {
  @override
  final int typeId = 0;

  @override
  JobApplication read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return JobApplication(
      id: fields[0] as String,
      jobName: fields[1] as String,
      companyName: fields[2] as String?,
      jobLink: fields[3] as String?,
      contactMethod: fields[4] as String?,
      cvUsed: fields[5] as String?,
      notes: fields[6] as String?,
      followUpDate: fields[7] as String?,
      source: fields[8] as String?,
      contactEmail: fields[9] as String?,
      applicationDate: fields[10] as String?,
      status: fields[11] as String?,
      createdAt: fields[12] as String,
      updatedAt: fields[13] as String,
    );
  }

  @override
  void write(BinaryWriter writer, JobApplication obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.jobName)
      ..writeByte(2)
      ..write(obj.companyName)
      ..writeByte(3)
      ..write(obj.jobLink)
      ..writeByte(4)
      ..write(obj.contactMethod)
      ..writeByte(5)
      ..write(obj.cvUsed)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.followUpDate)
      ..writeByte(8)
      ..write(obj.source)
      ..writeByte(9)
      ..write(obj.contactEmail)
      ..writeByte(10)
      ..write(obj.applicationDate)
      ..writeByte(11)
      ..write(obj.status)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JobApplicationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
