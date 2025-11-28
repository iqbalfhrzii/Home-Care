import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:homecare_mobile/core/router/app_router.dart';
import 'package:homecare_mobile/features/patients/presentation/bloc/patient_bloc.dart';
import 'package:homecare_mobile/shared/presentation/widgets/pagination_widget.dart';
import 'package:skeletonizer/skeletonizer.dart';

class PatientListPage extends StatelessWidget {
  const PatientListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Pasien'), centerTitle: true),
      body: const PatientListView(),
    );
  }
}

class PatientListView extends StatelessWidget {
  const PatientListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: BlocBuilder<PatientListBloc, PatientState>(
            builder: (context, state) {
              switch (state) {
                case PatientLoading():
                  return Skeletonizer(
                    child: ListView.builder(
                      itemCount: 10,
                      itemBuilder: (_, __) => const Card(
                        child: ListTile(
                          title: Text('Patient Name Placeholder'),
                          subtitle: Text(
                            'RM: 000000\nAlamat: Dummy address\nStatus: Active',
                          ),
                        ),
                      ),
                    ),
                  );
                case PatientReadManySuccess():
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<PatientListBloc>().add(
                        ReadManyPatientEvent(
                          page: state.pagination.currentPage,
                        ),
                      );
                      await context.read<PatientListBloc>().stream.firstWhere(
                        (state) => state is! PatientLoading,
                      );
                    },
                    child: ListView.builder(
                      key: const PageStorageKey<String>('patient_list'),
                      itemCount: state.patients.length,
                      itemBuilder: (BuildContext context, int index) {
                        final patient = state.patients[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            onTap: () => context.push(
                              '${AppRouter.patients}/${patient.id}',
                            ),
                            title: Text(patient.namaPasien),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('RM: ${patient.noRekamMedis}'),
                                Text('Alamat: ${patient.alamat}'),
                                Text('Status: ${patient.statusRujukan}'),
                              ],
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios),
                          ),
                        );
                      },
                    ),
                  );
                case PatientError():
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: ${state.message}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<PatientListBloc>().add(
                              const ReadManyPatientEvent(page: 1),
                            );
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                default:
                  return const SizedBox.shrink();
              }
            },
          ),
        ),

        BlocBuilder<PatientListBloc, PatientState>(
          buildWhen: (previous, current) {
            final isBothSuccessState =
                (previous is PatientReadManySuccess &&
                current is PatientReadManySuccess);

            return isBothSuccessState
                ? previous.pagination != current.pagination
                : current is PatientReadManySuccess;
          },
          builder: (context, state) {
            if (state is PatientReadManySuccess) {
              return PaginationWidget(
                pagination: state.pagination,
                onPageChanged: (page) {
                  context.read<PatientListBloc>().add(
                    ReadManyPatientEvent(page: page),
                  );
                },
              );
            }
            return const SizedBox(height: 56);
          },
        ),
      ],
    );
  }
}
