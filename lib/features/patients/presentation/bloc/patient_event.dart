part of 'patient_bloc.dart';

abstract class PatientEvent {
  const PatientEvent();
}

class LoadPatients extends PatientEvent {
  const LoadPatients();
}

class SearchPatients extends PatientEvent {
  final String query;
  final bool searchFromApi;
  
  const SearchPatients(this.query, {this.searchFromApi = false});
}

class LoadPatientDetail extends PatientEvent {
  final String id;
  
  const LoadPatientDetail(this.id);
}

class CreatePatient extends PatientEvent {
  final String nama;
  final String tempatLahir;
  final String tanggalLahir;
  final String jenisKelamin;
  final String alamat;
  final String noTelp;
  final String? nik;
  final String? noBpjs;
  final String? golonganDarah;
  
  const CreatePatient({
    required this.nama,
    required this.tempatLahir,
    required this.tanggalLahir,
    required this.jenisKelamin,
    required this.alamat,
    required this.noTelp,
    this.nik,
    this.noBpjs,
    this.golonganDarah,
  });
}

class UpdatePatient extends PatientEvent {
  final String id;
  final String nama;
  final String tempatLahir;
  final String tanggalLahir;
  final String jenisKelamin;
  final String alamat;
  final String noTelp;
  final String? nik;
  final String? noBpjs;
  final String? golonganDarah;
  
  const UpdatePatient({
    required this.id,
    required this.nama,
    required this.tempatLahir,
    required this.tanggalLahir,
    required this.jenisKelamin,
    required this.alamat,
    required this.noTelp,
    this.nik,
    this.noBpjs,
    this.golonganDarah,
  });
}

class DeletePatient extends PatientEvent {
  final String id;
  
  const DeletePatient(this.id);
}

class RefreshPatients extends PatientEvent {
  const RefreshPatients();
}

class FilterPatients extends PatientEvent {
  final String? filterType; // null = all, 'registered' = sudah teregistrasi, 'unregistered' = belum teregistrasi
  
  const FilterPatients(this.filterType);
}
