import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:shadows/const/colors.dart';
import 'package:shadows/const/dimens.dart';
import 'package:shadows/const/images.dart';
import 'package:shadows/generated/l10n.dart';
import 'package:shadows/locator.dart';
import 'package:shadows/model/leds/entities.dart';
import 'package:shadows/model/leds/leds_bloc.dart';
import 'package:shadows/model/paging.dart';
import 'package:shadows/model/result.dart';
import 'package:shadows/views/screens/main/tabs/base_tab.dart';
import 'package:shadows/widgets/leds_image.dart';
import 'package:shadows/widgets/common.dart';
import 'package:shadows/widgets/result_view.dart';

enum PopupLedAction {
  toggle
}

class LedsTab extends MainTabWidget {

  final LedsBloc ledsBloc = locator<LedsBloc>();

  LedsTab(String screenId, String tabTitle) : super(screenId, tabTitle);

  @override
  State createState() {
    return LedsTabState();
  }

}

class LedsTabState extends MainTabState<LedsTab> {

  PagingController<ListPage, Led> _pagingController;
  PagingListUpdater<ListPage, Led> _pagingListUpdater;

  @override
  void initState() {
    super.initState();
    _pagingController = PagingController<ListPage, Led>(
        firstPageKey: ListPage.first()
    );
    _pagingController.addPageRequestListener((page) async {
      try {
        final leds = await widget.ledsBloc.getLeds(page);
        if (leds.list.length < page.size) {
          _pagingController.appendLastPage(leds.list);
        } else {
          _pagingController.appendPage(leds.list, page.next());
        }
      } catch (e) {
        _pagingController.error = e;
      }
    });
    _pagingController.refresh();

    _pagingListUpdater = PagingListUpdater(_pagingController);
    _pagingListUpdater.startListening(widget.ledsBloc.listenLedsChanges());
  }

  @override
  void dispose() {
    super.dispose();
    _pagingListUpdater.dispose();
    _pagingController.dispose();

    router.unregisterBackListener(widget.screenId);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
        onRefresh: () => Future.sync(() => _pagingController.refresh()),
        child: PagedListView.separated(
          pagingController: _pagingController,
          builderDelegate: PagedChildBuilderDelegate<Led>(
            itemBuilder: _buildItem,
            firstPageErrorIndicatorBuilder: (context) {
              return ResultView(
                Result.error(_pagingController.error),
                _pagingController.refresh
              );
            },
            firstPageProgressIndicatorBuilder: (context) {
              return SizedBox.shrink();
           },
            noItemsFoundIndicatorBuilder: (context) {
              return LedsTabState.buildNoItems(context, false);
            },
            newPageErrorIndicatorBuilder: (context) {
              return _buildSubsequentError(context);
            },
            newPageProgressIndicatorBuilder: (context) {
              return _buildSubsequentProgress(context);
            }
          ),
          separatorBuilder: (context, index) => SizedBox(height: 12)
        )
    );
  }
  
  Widget _buildItem(BuildContext context, dynamic led, int index) {
    final shapeBorder = RoundedRectangleBorder(side: BorderSide.none, borderRadius: BorderRadius.circular(AppDimens.smallRadius));
    return Padding(
      padding: EdgeInsets.only(
        top: index == 0 ? AppDimens.tinyPadding : 0,
        left: AppDimens.defaultPadding,
        right: AppDimens.defaultPadding
      ),
      child: Material(
        color: AppColors.itemBackground,
        shape: shapeBorder,
        child: InkWell(
          onTap: () { /* TODO */ },
          customBorder: shapeBorder,
          child: Padding(
            padding: EdgeInsets.all(AppDimens.smallPadding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                LedImage.create(isEnabled: led.enabled),
                Widgets.horizontalSpace(width: AppDimens.defaultPadding),
                Expanded(child: _buildLedContent(led)),
                _buildPopupButton(context, led)
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget buildNoItems(BuildContext context, bool isSearchResults) {
    String image = isSearchResults ? AppImages.imageNotFound : AppImages.imageNoAssets;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        ImageIcon(
          AssetImage(image),
          color: AppColors.extraLightAction,
          size: 80,
        ),
        Widgets.verticalSpace(height: 28),
        Widgets.lightHint(
          (isSearchResults ? S.of(context).assetsNotFound : S.of(context).assetsEmpty).toUpperCase(),
          size: 17
        ),
        Widgets.verticalSpace(),
        Widgets.lightHint(
          isSearchResults ? S.of(context).assetsNotFoundDescription : S.of(context).assetsEmptyDescription,
        ),
      ],
    );
  }

  Widget _buildSubsequentError(BuildContext context) {
    return null;
  }

  Widget _buildSubsequentProgress(BuildContext context) {
    return ResultView(Result.pending(), null);
  }

  Widget _buildLedContent(Led led) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Widgets.hint(
          led.name,
          size: 16,
          bold: true,
          maxLines: 1
        ),
        Widgets.verticalSpace(height: 4),
        Widgets.hint(
          S.of(context).assetsSnHint(led.enabled ? "YES" : "NO"),
          color: AppColors.lightHintText,
          maxLines: 1
        )
      ],
    );
  }

  PopupMenuButton<PopupLedAction> _buildPopupButton(BuildContext context, Led led) {
    return PopupMenuButton<PopupLedAction>(
      onSelected: (action) {
        switch (action) {
          case PopupLedAction.toggle:
            widget.ledsBloc.toggle(led);
            break;
        }
      },
      itemBuilder: (context) => [
        _buildPopupItem(AssetImage(AppImages.iconTabSettings), S.of(context).actionEdit, PopupLedAction.toggle),
      ],
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: EdgeInsets.all(AppDimens.smallPadding),
          child: ImageIcon(AssetImage(AppImages.iconMore), color: AppColors.primaryAction)
        ),
      )
    );
  }

  PopupMenuItem<PopupLedAction> _buildPopupItem(AssetImage image, String title, PopupLedAction action) {
    return PopupMenuItem(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            ImageIcon(image, color: AppColors.lightAction),
            Widgets.horizontalSpace(),
            Widgets.hint(title, size: 16, bold: true, color: AppColors.primaryAction)
          ],
        ),
      value: action,
    );
  }
}
