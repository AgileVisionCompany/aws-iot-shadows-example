

import 'package:get_it/get_it.dart';
import 'package:shadows/amplify.dart';
import 'package:shadows/model/accounts/accounts_bloc.dart';
import 'package:shadows/model/accounts/accounts_repository.dart';
import 'package:shadows/model/base_bloc.dart';
import 'package:shadows/model/leds/leds_bloc.dart';
import 'package:shadows/model/leds/leds_repository.dart';
import 'package:shadows/native/native_bridge.dart';
import 'package:shadows/utils/logger/logger.dart';
import 'package:shadows/views/router.dart';

// Locator for getting singleton dependencies
final locator = GetIt.instance;

void setupDependencies() {
  _setupStuffs();

  _setupRepositories();

  _setupBlocs();
}

// --- private section & extensions

void _setupStuffs() {
  final bridge = NativeBridge("testapp/method-channel/default");
  locator.registerSingleton<NativeBridge>(bridge);
  bridge.start();

  locator.registerSingleton<AmplifyHolder>(AmplifyHolder());
  locator.registerSingleton<AppLogger>(SimpleAppLogger());
  locator.registerSingleton<AppRouter>(AppRouter());
}

void _setupRepositories() {
  locator.registerRepository<AccountsRepository>(AmplifyAccountsRepository());
  locator.registerRepository<LedsRepository>(LedsRepositoryImpl());
}

void _setupBlocs() {
  _setupActions.clear();

  locator.registerBloc<AccountsBloc>(AccountsBloc());
  locator.registerBloc<LedsBloc>(LedsBloc());

  _processBlocs();
}

typedef _Action = void Function();
final List<_Action> _setupActions = [];

extension LocatorExtension on GetIt {

  void registerBloc<T extends BaseBloc>(T bloc) {
    registerSingleton<T>(bloc);
    _setupActions.add(() { bloc.setup(); });
  }

  void registerRepository<T>(T repository) {
    locator.registerSingleton(repository);
  }

}

void _processBlocs() {
  _setupActions.forEach((action) { action.call(); });
  _setupActions.clear();
}