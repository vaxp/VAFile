import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vafile/application/file_manager/file_manager_bloc.dart' as fm;

class Buildcurrentpath extends StatelessWidget {
  const Buildcurrentpath({super.key});

  @override
 Widget build(BuildContext context) {
    return Expanded(
      child: BlocBuilder<fm.FileManagerBloc, fm.FileManagerState>(
        builder: (context, state) {
          if (state is fm.FileManagerLoaded) {
            return Text(
              state.currentPath,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
              overflow: TextOverflow.ellipsis,
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}