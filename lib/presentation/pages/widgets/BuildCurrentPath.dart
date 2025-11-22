import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vafile/application/file_manager/file_manager_bloc.dart' as fm;

class Buildcurrentpath extends StatelessWidget {
  const Buildcurrentpath({super.key});

  @override
 Widget build(BuildContext context) {
    return Expanded(
      child: BlocSelector<fm.FileManagerBloc, fm.FileManagerState, String>(
        selector: (state) {
          if (state is fm.FileManagerLoaded) {
            return state.currentPath;
          }
          return '';
        },
        builder: (context, currentPath) {
          if (currentPath.isEmpty) {
            return const SizedBox();
          }
          return Text(
            currentPath,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
            overflow: TextOverflow.ellipsis,
          );
        },
      ),
    );
  }
}