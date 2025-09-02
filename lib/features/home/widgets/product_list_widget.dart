import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/no_internet_screen_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/paginated_list_view_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/product_shimmer_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/product_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/controllers/product_controller.dart';
import 'package:flutter_sixvalley_ecommerce/helper/responsive_helper.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

class HomeProductListWidget extends StatelessWidget {
  const HomeProductListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductController>(
      builder: (context, productController, child) {
        if (productController.selectedProductModel?.products?.isNotEmpty ?? false) {

          return PaginatedListView(
            onPaginate: (int? offset) async {
              await productController.getSelectedProductModel(offset ?? 1);
            },
            totalSize: productController.selectedProductModel?.totalSize,
            offset: productController.selectedProductModel?.offset,
            limit: productController.selectedProductModel?.limit,
            itemView: Expanded(child: MasonryGridView.count(
              itemCount: productController.selectedProductModel?.products?.length ?? 0,
              crossAxisCount: ResponsiveHelper.isTab(context) ? 3 : 2,
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
              itemBuilder: (BuildContext context, int index) {
                return ProductWidget(productModel: productController.selectedProductModel!.products![index]);
              },
            )), // Replace with your actual item view
          );

        } else if (productController.selectedProductModel?.products?.isEmpty ?? false) {
          return const NoInternetOrDataScreenWidget(isNoInternet: false);

        } else {
          return const ProductShimmer(isHomePage: false, isEnabled: true);
        }
      },
    );
  }
}
