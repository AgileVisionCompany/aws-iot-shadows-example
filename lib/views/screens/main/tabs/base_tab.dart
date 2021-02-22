

import 'package:flutter/widgets.dart';
import 'package:shadows/locator.dart';
import 'package:shadows/utils/logger/log_holder.dart';
import 'package:shadows/utils/logger/logger.dart';
import 'package:shadows/views/base/toolbar.dart';
import 'package:shadows/views/router.dart';

abstract class MainTabWidget extends StatefulWidget with LogHolderMixin {

  final String screenId;
  final String tabTitle;

  final AppRouter router = locator<AppRouter>();

  MainTabWidget(this.screenId, this.tabTitle) {
    setupLoggerName();
  }

}

abstract class MainTabState<T extends MainTabWidget> extends State<T> {

  ClassLogger get logger => widget.logger;

  AppRouter get router => widget.router;

  AppToolbarState get toolbarState => router.getToolbarState(widget.screenId);

  @override
  void initState() {
    super.initState();
    final toolbarState = initToolbar();
    router.updateToolbar(widget.screenId, toolbarState);
  }

  AppToolbarState initToolbar() {
    return AppToolbarState(
      (_) => widget.tabTitle
    );
  }

}