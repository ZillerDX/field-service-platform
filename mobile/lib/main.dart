import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/localization/app_language.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/tickets/presentation/bloc/ticket_bloc.dart';
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLanguage().init();
  runApp(const FieldOpsNexusApp());
}

class FieldOpsNexusApp extends StatefulWidget {
  const FieldOpsNexusApp({super.key});

  @override
  State<FieldOpsNexusApp> createState() => _FieldOpsNexusAppState();
}

class _FieldOpsNexusAppState extends State<FieldOpsNexusApp> {
  late final AuthBloc _authBloc;
  late final TicketBloc _ticketBloc;

  @override
  void initState() {
    super.initState();
    _authBloc = AuthBloc()..add(AppStartedEvent());
    _ticketBloc = TicketBloc();
  }

  @override
  void dispose() {
    _authBloc.close();
    _ticketBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: _authBloc),
        BlocProvider<TicketBloc>.value(value: _ticketBloc),
      ],
      child: MaterialApp.router(
        title: 'FieldOps Nexus',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routerConfig: AppRouter.createRouter(_authBloc),
      ),
    );
  }
}
