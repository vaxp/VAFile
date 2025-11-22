import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vafile/application/file_manager/file_manager_bloc.dart' as fm;

class NavigationControls extends StatelessWidget {
  const NavigationControls({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocSelector<fm.FileManagerBloc, fm.FileManagerState, ({bool canGoBack, bool canGoForward})>(
      selector: (state) {
        if (state is fm.FileManagerLoaded) {
          return (canGoBack: state.canGoBack, canGoForward: state.canGoForward);
        }
        return (canGoBack: false, canGoForward: false);
      },
      builder: (context, navigation) {
        return Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                size: 16,
                color: navigation.canGoBack ? Colors.white70 : Colors.white24,
              ),
              onPressed: navigation.canGoBack ? () => context.read<fm.FileManagerBloc>().add(fm.NavigateBack()) : null,
            ),
            IconButton(
              icon: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: navigation.canGoForward ? Colors.white70 : Colors.white24,
              ),
              onPressed: navigation.canGoForward ? () => context.read<fm.FileManagerBloc>().add(fm.NavigateForward()) : null,
            ),
          ],
        );
      },
    );
  }
}