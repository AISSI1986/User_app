import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_directionality_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/order/controllers/order_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/order_details/controllers/order_details_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/order_details/domain/models/order_details_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/order_details/widgets/review_reply_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/product_details/domain/models/product_details_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/refund/widgets/refund_request_bottom_sheet.dart';
import 'package:flutter_sixvalley_ecommerce/features/review/controllers/review_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/review/widgets/review_dialog_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/refund/controllers/refund_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/refund/widgets/refunded_details_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/domain/models/config_model.dart';
import 'package:flutter_sixvalley_ecommerce/helper/price_converter.dart';
import 'package:flutter_sixvalley_ecommerce/localization/controllers/localization_controller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:provider/provider.dart';


class OrderDetailsWidget extends StatefulWidget {
  final OrderDetailsModel orderDetailsModel;
  final String orderType;
  final String orderId;
  final String paymentStatus;
  final Function callback;
  final bool fromTrack;
  final int? isGuest;
  final int index;
  const OrderDetailsWidget({super.key, required this.orderDetailsModel, required this.callback,
    required this.orderType, required this.paymentStatus,  this.fromTrack = false, this.isGuest, required this.orderId, required this.index});

  @override
  State<OrderDetailsWidget> createState() => _OrderDetailsWidgetState();
}

class _OrderDetailsWidgetState extends State<OrderDetailsWidget> {
  final ReceivePort _port = ReceivePort();


  @override
  void initState() {
    super.initState();

    IsolateNameServer.registerPortWithName(_port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) {
      setState((){ });
    });

    FlutterDownloader.registerCallback(downloadCallback);
  }

  void downloadCallback(String id, int status, int progress) async {
    final SendPort? send = IsolateNameServer.lookupPortByName('downloader_send_port');
    send?.send([id, status, progress]);
  }


  DigitalVariation? digitalVariation;

  String? downloadMessage;
  File? downloadedFile;

  @override
  Widget build(BuildContext context) {
    ConfigModel? configModel = Provider.of<SplashController>(context, listen: false).configModel;
    final bool isLtr = Provider.of<LocalizationController>(context, listen: false).isLtr;

    if(widget.orderDetailsModel.productDetails != null && widget.orderDetailsModel.variant != null && widget.orderDetailsModel.variant!.isNotEmpty && widget.orderDetailsModel.productDetails?.productType == 'digital') {
      for(DigitalVariation dv in widget.orderDetailsModel.productDetails!.digitalVariation ?? []) {
        if(dv.variantKey == widget.orderDetailsModel.variant){
          digitalVariation = dv;
        }
      }
    }

    return Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
      child: Stack(children: [
          Card(color: Theme.of(context).cardColor,
            child: Column(children: [
                const SizedBox(height: Dimensions.paddingSizeLarge),
                Row(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const SizedBox(width: Dimensions.marginSizeDefault),

                    ClipRRect(borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
                      child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
                        border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha:.125))),
                        child: CustomImageWidget(image: '${widget.orderDetailsModel.productDetails?.thumbnailFullUrl?.path}', width: 80, height: 80),
                      ),
                    ),
                    const SizedBox(width: Dimensions.marginSizeDefault),

                    Expanded(flex: 3,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: Text(
                            widget.orderDetailsModel.productDetails?.name ?? '',
                            style: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge?.color),
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                          )),
                          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                        ]),
                        const SizedBox(height: Dimensions.marginSizeExtraSmall),

                        Row(children: [
                          Text(
                            "${getTranslated('price', context)}: ",
                            style: titilliumRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeSmall),
                          ),

                          Expanded(
                            child: Text(
                              PriceConverter.convertPrice(context, widget.orderDetailsModel.price),
                              style: titilliumSemiBold.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: Dimensions.fontSizeDefault),
                              maxLines: 1,
                            ),
                          ),
                        ]),

                        widget.orderDetailsModel.productDetails!.taxModel == 'exclude'?
                        Text(
                          '(${getTranslated('tax', context)} ${PriceConverter.convertPrice(context, widget.orderDetailsModel.tax)})',
                          style: titilliumRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeDefault),
                        ) :
                        Text(
                          '(${getTranslated('tax', context)} ${widget.orderDetailsModel.productDetails!.taxModel})',
                          style: titilliumRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeDefault),
                        ),
                        const SizedBox(height: Dimensions.marginSizeExtraSmall),

                        Text('${getTranslated('qty', context)}: ${widget.orderDetailsModel.qty}',
                            style: titilliumRegular.copyWith(color: Theme.of(context).hintColor, fontSize: 14)),
                        const SizedBox(height: Dimensions.marginSizeExtraSmall),

                        (widget.orderDetailsModel.variant != null && widget.orderDetailsModel.variant!.isNotEmpty) ?
                        Padding(padding: const EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
                          child: Row(children: [
                            Text('${getTranslated('variations', context)}: ',
                                style: titilliumSemiBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyLarge?.color)),


                              Flexible(child: Text(widget.orderDetailsModel.variant!,
                                  style: textRegular.copyWith(fontSize: Dimensions.fontSizeSmall,
                                    color: Theme.of(context).disabledColor,))),
                            ]),
                          ) : const SizedBox(),
                          const SizedBox(height: Dimensions.marginSizeExtraSmall),

                          ///Downloadable Product////////////

                        Row(children: [
                          const Spacer(),
                          SizedBox(height: (widget.orderDetailsModel.productDetails != null &&
                              widget.orderDetailsModel.productDetails?.productType =='digital' && widget.paymentStatus == 'paid')?
                          Dimensions.paddingSizeExtraLarge : 0),
                          widget.orderDetailsModel.productDetails?.productType =='digital' && widget.paymentStatus == 'paid'?
                          Consumer<OrderDetailsController>(
                              builder: (context, orderProvider, _) {
                                return InkWell(onTap : () async {
                                  if(widget.orderDetailsModel.productDetails!.digitalProductType == 'ready_after_sell' &&
                                      widget.orderDetailsModel.digitalFileAfterSell == null ){

                                    showCustomSnackBar(getTranslated('product_not_uploaded_yet', context), context, isToaster: true);
                                  }else{
                                    if(Provider.of<AuthController>(context, listen: false).isLoggedIn() && widget.isGuest == 0){
                                      _downloadProduct();
                                    }else{
                                      orderProvider.downloadDigitalProduct(orderDetailsId: widget.orderDetailsModel.id!).then((value){
                                        if(value.response?.statusCode == 200){
                                          // Navigator.push(context, MaterialPageRoute(builder: (_)=>  VerificationScreen('', '', '',
                                          //   widget.orderDetailsModel.id, fromDigitalProduct: true, fromPage: FromPage.digitalProduct)));
                                        }
                                      });
                                    }
                                  }
                                },
                                  child: Align(alignment: Alignment.centerRight,
                                      child: Builder(
                                        builder: (context) {
                                          return Container(width: 130, padding: const EdgeInsets.only(left: 5), height: 38,
                                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(5),
                                                color: Theme.of(context).primaryColor),
                                            alignment: Alignment.center,
                                            child: (orderProvider.isDownloaodLoading &&  orderProvider.downloaodIndex == widget.index) ? const SizedBox(height: 28,  width: 28, child: CircularProgressIndicator(color: Colors.white)) : Center(child:  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                              Text('${getTranslated('download', context)}',
                                                style: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault,color: Theme.of(context).cardColor),),
                                              const SizedBox(width: Dimensions.paddingSizeSmall),
                                              SizedBox(width: Dimensions.iconSizeDefault,
                                                  child: Image.asset(Images.fileDownload, color: Theme.of(context).cardColor))])));
                                        }
                                      )),
                                );
                              }
                          ) : const SizedBox(),

                          const SizedBox(width: 10),
                        ]),


                          const SizedBox(height: Dimensions.paddingSizeSmall),
                        ],
                      ),
                    ),
                  ],
                ),

              ///Review and Refund Request///////////////////
              Consumer<OrderController>(
                builder: (context, orderController, _) {
                  return Padding(padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
                      child: Row(children: [
                        const Spacer(),
                        orderController.orderTypeIndex == 1 && widget.orderType != "POS"?
                        InkWell(
                          onTap: () {
                            if(orderController.orderTypeIndex == 1) {
                              Provider.of<ReviewController>(context, listen: false).removeData();
                              showDialog(context: context, builder: (context) => Dialog(
                                insetPadding: EdgeInsets.zero, backgroundColor: Colors.transparent,
                                child: ReviewDialog(productID: widget.orderDetailsModel.productDetails!.id.toString(),
                                    orderId: widget.orderId,
                                    callback: widget.callback,
                                    orderDetailsModel: widget.orderDetailsModel,
                                    orderType: widget.orderType),
                              ));
                            }
                          },
                          child: _ReviewButtonWidget(widget: widget),
                        ) : const SizedBox.shrink(),

                        const SizedBox(width: Dimensions.paddingSizeSmall),

                        Consumer<RefundController>(builder: (context,refund,_) {
                          return _canRefundRequest(configModel) ?
                          InkWell(
                            onTap: () {
                              Provider.of<ReviewController>(context, listen: false).removeData();
                              refund.getRefundReqInfo(widget.orderDetailsModel.id).then((value) {
                                if(value.response!.statusCode==200) {
                                  if(context.mounted){
                                    Navigator.push(context, MaterialPageRoute(builder: (_) =>
                                        RefundBottomSheet(product: widget.orderDetailsModel.productDetails,
                                          orderDetailsId: widget.orderDetailsModel.id!, orderId: widget.orderId,)));
                                  }
                                }
                              });
                            },

                            child: refund.isRefund ?
                            Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor)) :
                            Container(
                              margin: const EdgeInsets.only(left: Dimensions.paddingSizeSmall),
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: Dimensions.paddingSizeDefault),
                              decoration: BoxDecoration(
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(getTranslated('refund_request', context)!,
                                  style: titilliumRegular.copyWith(fontSize: Dimensions.fontSizeDefault,
                                    color: Theme.of(context).highlightColor,)),),)
                              : const SizedBox();
                        }),


                        Consumer<RefundController>(builder: (context,refundController,_){
                          return (orderController.orderTypeIndex == 1 && widget.orderDetailsModel.refundReq != 0 &&
                              widget.orderType != "POS") ?

                          InkWell(onTap: () {
                            Provider.of<ReviewController>(context, listen: false).removeData();
                            refundController.getRefundReqInfo(widget.orderDetailsModel.id).then((value) {
                              if(value.response!.statusCode==200){
                                if(context.mounted) {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) =>
                                    RefundDetailsWidget(product: widget.orderDetailsModel.productDetails,
                                      orderDetailsId: widget.orderDetailsModel.id,
                                      orderDetailsModel:  widget.orderDetailsModel, createdAt: widget.orderDetailsModel.createdAt,)));
                                }
                              }});},



                              child: refundController.isLoading?
                              Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor)):
                              Container(
                                margin: const EdgeInsets.only(left: Dimensions.paddingSizeSmall),
                                padding: const EdgeInsets.symmetric(vertical: 8,
                                    horizontal: Dimensions.paddingSizeDefault),
                                decoration: BoxDecoration(color: Theme.of(context).textTheme.bodyMedium?.color,
                                  borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),),

                                child: Text(getTranslated('refund_status_btn', context)??'',
                                    style: titilliumRegular.copyWith(fontSize: Dimensions.fontSizeDefault,
                                      color: Theme.of(context).highlightColor,)),)) :const SizedBox();}),
                        const SizedBox(width: 10)]));}),

              widget.orderDetailsModel.deliveryStatus == 'delivered' && widget.orderType != "POS" ?
              ReviewReplyWidget(orderDetailsModel: widget.orderDetailsModel, index: widget.index) : const SizedBox(),

              const SizedBox(height: Dimensions.paddingSizeSmall),

               //widget.orderDetailsModel.refundReq == 0 && widget.orderType != "POS"?
              //const SizedBox(height: Dimensions.paddingSizeLarge) : const SizedBox(),

              ],
            ),
          ),

        if(widget.orderDetailsModel.discount! > 0) Positioned(
          top: 35,
          left: isLtr ? 20 : null,
          right: isLtr ? null : 20,
          child: Container(
            height: 20,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.horizontal(
                right: Radius.circular(isLtr ? Dimensions.paddingSizeExtraSmall : 0),
                left: Radius.circular(isLtr ? 0 : Dimensions.paddingSizeExtraSmall),
              ),
            ),
            child: CustomDirectionalityWidget(
              child: Text(
                widget.orderDetailsModel.productDetails?.clearanceSale != null ?
                PriceConverter.percentageCalculation(context, widget.orderDetailsModel.productDetails?.unitPrice, widget.orderDetailsModel.productDetails?.clearanceSale?.discountAmount, widget.orderDetailsModel.productDetails?.clearanceSale?.discountType) :
                PriceConverter.percentageCalculation(
                  context, (widget.orderDetailsModel.price! * widget.orderDetailsModel.qty!),
                  widget.orderDetailsModel.productDetails?.discount,
                  widget.orderDetailsModel.productDetails?.discountType,
                ),
                style: titilliumRegular.copyWith(
                  fontSize: Dimensions.fontSizeExtraSmall,
                  color:  Theme.of(context).colorScheme.secondaryContainer,
                ),
              ),
            ),
          ),
        )

      ],
      ),
    );
  }

  bool _canRefundRequest(ConfigModel? configModel) => widget.orderDetailsModel.order?.status == 'delivered'
      && widget.orderDetailsModel.refundReq == 0
      && widget.orderType != "POS"
      && DateTime.parse(widget.orderDetailsModel.createdAt!)
          .difference(DateTime.now())
          .inDays
          .abs() <= (configModel?.refundDayLimit ?? 0)
      && (configModel?.refundDayLimit != 0);

  void _downloadProduct(){
    String url = widget.orderDetailsModel.productDetails!.digitalProductType == 'ready_after_sell'?
    '${widget.orderDetailsModel.digitalFileAfterSellFullUrl?.path}':
    '${widget.orderDetailsModel.productDetails?.digitalFileReadyFullUrl?.path}';

    String filename = widget.orderDetailsModel.productDetails!.digitalProductType == 'ready_after_sell'?
    '${widget.orderDetailsModel.digitalFileAfterSellFullUrl?.key}':
    '${widget.orderDetailsModel.productDetails?.digitalFileReadyFullUrl?.key}';

    Provider.of<OrderDetailsController>(context, listen: false).productDownload(
        url: url,
        fileName: filename,
        index: widget.index
    );
  }


}

class _ReviewButtonWidget extends StatelessWidget {
  const _ReviewButtonWidget({
    required this.widget,
  });

  final OrderDetailsWidget widget;

  @override
  Widget build(BuildContext context) {
    return Container(decoration: BoxDecoration(color:  Colors.deepOrangeAccent,
      borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: Row(children: [
        const SizedBox(width: Dimensions.paddingSizeExtraSmall),
        const Icon(Icons.star_outline_outlined, color: Colors.white, size: 20,),
        const SizedBox(width: Dimensions.paddingSizeSmall),
    
        Text(getTranslated(widget.orderDetailsModel.reviewModel == null ? 'review' : 'reviewed', context)!, style: textRegular.copyWith(
            fontSize: Dimensions.fontSizeDefault, color:  Theme.of(context).colorScheme.secondaryContainer)),
        const SizedBox(width: Dimensions.paddingSizeExtraSmall),
      ]),
    );
  }
}

