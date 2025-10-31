import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../application/file_manager/file_manager_bloc.dart' as fm;
import '../core/theme/app_theme.dart';
import 'presentation/pages/home_page.dart';

class FileManagerApp extends StatelessWidget {
  const FileManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => fm.FileManagerBloc()..add(fm.InitializeFileManager()),
      child: MaterialApp(
        title: 'VA File Manager',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const FileManagerHomePage(),
      ),
    );
  }
}