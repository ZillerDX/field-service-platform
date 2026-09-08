import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_state.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/tickets/presentation/screens/customer_portal_screen.dart';
import '../features/tickets/presentation/screens/create_ticket_screen.dart';
import '../features/tickets/presentation/screens/ticket_detail_screen.dart';
import '../features/technician/presentation/screens/tech_workspace_screen.dart';
import '../features/technician/presentation/screens/job_execution_screen.dart';
import '../features/dispatcher/presentation/screens/dispatcher_screen.dart';

class AppRouter {
  static GoRouter createRouter(AuthBloc authBloc) {
    return GoRouter(
      initialLocation: '/login',
      refreshListenable: _AuthBlocListenable(authBloc),
      redirect: (BuildContext context, GoRouterState state) {
        final authState = authBloc.state;
        final isLoggingIn = state.matchedLocation == '/login';

        if (authState is Unauthenticated || authState is AuthInitial || authState is AuthFailure) {
          return isLoggingIn ? null : '/login';
        }

        if (authState is Authenticated) {
          if (isLoggingIn) {
            final role = authState.user.role;
            if (role == 'technician') return '/technician';
            if (role == 'admin') return '/dispatcher';
            return '/customer';
          }
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/customer',
          builder: (context, state) => const CustomerPortalScreen(),
        ),
        GoRoute(
          path: '/customer/create-ticket',
          builder: (context, state) => const CreateTicketScreen(),
        ),
        GoRoute(
          path: '/ticket/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return TicketDetailScreen(ticketId: id);
          },
        ),
        GoRoute(
          path: '/technician',
          builder: (context, state) => const TechWorkspaceScreen(),
        ),
        GoRoute(
          path: '/technician/job/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return JobExecutionScreen(ticketId: id);
          },
        ),
        GoRoute(
          path: '/dispatcher',
          builder: (context, state) => const DispatcherScreen(),
        ),
      ],
    );
  }
}

class _AuthBlocListenable extends ChangeNotifier {
  final AuthBloc bloc;
  _AuthBlocListenable(this.bloc) {
    bloc.stream.listen((_) => notifyListeners());
  }
}
