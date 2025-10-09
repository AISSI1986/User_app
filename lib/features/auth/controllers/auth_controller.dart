import 'dart:convert';
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/domain/models/register_model.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/error_response.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/response_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/domain/models/signup_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/domain/models/social_login_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/domain/models/user_log_data.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/domain/services/auth_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/enums/from_page.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/screens/login_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/screens/otp_registration_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/screens/otp_verification_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/screens/reset_password_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/dashboard/screens/dashboard_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/controllers/profile_contrroller.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/domain/models/profile_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/domain/models/config_model.dart';
import 'package:flutter_sixvalley_ecommerce/helper/api_checker.dart';
import 'package:flutter_sixvalley_ecommerce/localization/app_localization.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/localization/controllers/localization_controller.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

class AuthController with ChangeNotifier {
  final AuthServiceInterface authServiceInterface;
  AuthController( {required this.authServiceInterface});

  bool _isLoading = false;
  bool? _isRemember = false;
  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;

  bool _isAcceptTerms = false;
  bool get isAcceptTerms => _isAcceptTerms;

  bool _isNumberLogin = false;
  bool get isNumberLogin => _isNumberLogin;

  bool _isActiveRememberMe = false;
  bool get isActiveRememberMe => _isActiveRememberMe;

  String? _loginErrorMessage = '';
  String? get loginErrorMessage => _loginErrorMessage;

  set setIsLoading(bool value)=> _isLoading = value;
  set setIsPhoneVerificationButttonLoading(bool value) => _isPhoneNumberVerificationButtonLoading = value;

  bool _resendButtonLoading = false;
  bool get resendButtonLoading => _resendButtonLoading;


  bool _sendToEmail = false;
  bool get sendToEmail => _sendToEmail;

  String? _verificationMsg = '';
  String? get verificationMessage => _verificationMsg;

  bool _isForgotPasswordLoading = false;
  bool get isForgotPasswordLoading => _isForgotPasswordLoading;
  set setForgetPasswordLoading(bool value) => _isForgotPasswordLoading = value;

  String countryDialCode = '+880';
  void setCountryCode( String countryCode, {bool notify = true}){
    countryDialCode  = countryCode;
    if(notify){
      notifyListeners();
    }
  }

  String? _verificationID = '';
  String? get verificationID => _verificationID;

  updateSelectedIndex(int index, {bool notify = true}){
    _selectedIndex = index;
    if(notify){
      notifyListeners();
    }

  }


  bool get isLoading => _isLoading;
  bool? get isRemember => _isRemember;

  void updateRemember() {
    _isRemember = !_isRemember!;
    notifyListeners();
  }

  Future<void> socialLogin(SocialLoginModel socialLogin, Function callback) async {
    _isLoading = true;
    notifyListeners();

    ApiResponseModel apiResponse = await authServiceInterface.socialLogin(socialLogin.toJson());
    if (apiResponse.response != null && apiResponse.response?.statusCode == 200) {
      final CustomerVerification? customerVerification = Provider.of<SplashController>(Get.context!, listen: false).configModel!.customerVerification;

      _isLoading = false;
      Map map = apiResponse.response!.data;


      String? message = '', token = '', temporaryToken= '', email = '', phone = '';
      ProfileModel? profileModel;
      bool isPhoneVerified = false;
      bool isMailVerified = false;


      try{
        message = map['error_message'];
        token = map['token'];
        temporaryToken = map['temp_token'];
        if(map["user"] != null) {
          email = map["user"]["email"];
          phone = map["user"]["phone"];
          isPhoneVerified = map["user"]["is_phone_verified"] ?? false;
          isMailVerified = map["user"]["is_email_verified"] ?? false;
        }
      }catch(e){
        message = null;
        token = null;
        temporaryToken = null;
      }

      if(token != null){
        authServiceInterface.saveUserToken(token);
        await authServiceInterface.updateDeviceToken();
        setCurrentLanguage(Provider.of<LocalizationController>(Get.context!, listen: false).getCurrentLanguage() ?? 'en');
      }

      if(map.containsKey('user')){
        try{
          profileModel = ProfileModel.fromJson(map['user']);
          callback(true, null, null, profileModel, message, socialLogin.medium, null, socialLogin.email, socialLogin.name);
        }catch(e) {

        }
      }

      if(token != null && token.isNotEmpty) {
        authServiceInterface.saveUserToken(token);
        await authServiceInterface.updateDeviceToken();
        setCurrentLanguage(Provider.of<LocalizationController>(Get.context!, listen: false).getCurrentLanguage() ?? 'en');
        callback(true, token, null, null, message, socialLogin.medium, null, socialLogin.email, socialLogin.name);
      }

      if(temporaryToken != null && temporaryToken.isNotEmpty) {
        callback(true, null, temporaryToken, null, message, socialLogin.medium, null, socialLogin.email, socialLogin.name);
      }

      if(phone != null && phone.isNotEmpty && !isPhoneVerified && (customerVerification?.phone == 1 || customerVerification?.firebase == 1)) {
        callback(true, null, null, null, message, socialLogin.medium, phone, socialLogin.email, socialLogin.name);
      }

    } else {
     ApiChecker.checkApi(apiResponse);
    }
    _isLoading = false;
    notifyListeners();
  }


  Future registration(RegisterModel register, Function callback, ConfigModel config) async {
    _isLoading = true;
    notifyListeners();
    ApiResponseModel apiResponse = await authServiceInterface.registration(register.toJson());

    _isLoading = false;
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      Map map = apiResponse.response!.data;
      String? tempToken = '', token = '', message = '';

      if (map.containsKey('temporary_token')) {
        tempToken = map["temporary_token"];
      } else if(map.containsKey('token')) {
        token = map["token"];
      }
      message = map["message"];


      if(token != null && token.isNotEmpty){
        authServiceInterface.saveUserToken(token);
        await authServiceInterface.updateDeviceToken();
        Navigator.pushAndRemoveUntil(Get.context!, MaterialPageRoute(builder: (_) => const DashBoardScreen()), (route) => false);
      } else if (tempToken != null && tempToken.isNotEmpty) {
        String type;
        if(config.customerVerification?.firebase == 1){
          type = 'phone';
        }else if(config.customerVerification?.phone == 1){
          type = 'phone';
        }else{
          type = 'email';
        }
        sendVerificationCode(
            config,
            SignUpModel(email: register.email, phone: register.phone),
            type: type, fromPage: FromPage.login
        );
      }
      notifyListeners();
    }else{
      ApiChecker.checkApi(apiResponse);
    }
    notifyListeners();
  }


  Future logOut() async {
    ApiResponseModel apiResponse = await authServiceInterface.logout();
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {

    }
  }

  Future<void> setCurrentLanguage(String currentLanguage) async {
    ApiResponseModel apiResponse = await authServiceInterface.setLanguageCode(currentLanguage);
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {

    }else{
      ApiChecker.checkApi(apiResponse);
    }
  }



  Future<ResponseModel>  login (String? userInput, String? password, String? type, FromPage? fromPage) async {
    _isLoading = true;
    _loginErrorMessage = '';
    notifyListeners();

    String? Type = type;
    String? userInputData = userInput;

    ApiResponseModel apiResponse = await authServiceInterface.login(userInput, password, Type);


    ResponseModel responseModel;
    _isLoading = false;
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      final ConfigModel config = Provider.of<SplashController>(Get.context!, listen: false).configModel!;
      clearGuestId();
      Map map = apiResponse.response!.data;

      String? temporaryToken = '', token = '', message = '', email, phone;
      bool isPhoneVerified = false;
      bool isMailVerified = false;

      try{
        message = map["message"];
        token = map["token"];
        temporaryToken = map["temporary_token"];
        email = map["email"];
        phone = map["phone"];
        isPhoneVerified = map["is_phone_verified"] ?? false;
        isMailVerified = map["is_email_verified"] ?? false;
      }catch(e){
        message = null;
        token = null;
        temporaryToken = null;
      }

      if(isPhoneVerified && !isMailVerified && config.customerVerification?.phone == 0 && config.customerVerification?.email == 1 && email != null) {
        Type = 'email';
        userInputData = email;
      }

      if(!isPhoneVerified && isMailVerified && config.customerVerification?.phone == 1 && config.customerVerification?.email == 0 && phone != null) {
        Type = 'phone';
        userInputData = phone;
      }


      if(!isPhoneVerified && !isMailVerified && config.customerVerification?.phone == 0 && config.customerVerification?.email == 1 && email != null) {
        Type = 'email';
        userInputData = email;
      }

      if(!isPhoneVerified && !isMailVerified && config.customerVerification?.phone == 1 && config.customerVerification?.email == 0 && phone != null) {
        Type = 'phone';
        userInputData = phone;
      }


      if(token != null && token.isNotEmpty) {
        authServiceInterface.saveUserToken(token);
        await authServiceInterface.updateDeviceToken();
      } else if (temporaryToken != null) {
        //print("=====Else=====>>");
        await sendVerificationCode(Provider.of<SplashController>(Get.context!, listen: false).configModel!, SignUpModel(email: userInputData, phone: userInputData), type: Type, fromPage: fromPage);
      }

      responseModel = ResponseModel('verification', token != null);
      // callback(true, token, temporaryToken, message);
      notifyListeners();
    } else {
      notifyListeners();
      responseModel = ResponseModel(apiResponse.error, false);
      ApiChecker.checkApi(apiResponse);
    }

    _isLoading = false;
    notifyListeners();
    return responseModel;
  }


  Future<void> updateToken(BuildContext context) async {
    ApiResponseModel apiResponse = await authServiceInterface.updateDeviceToken();
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
    } else {
      ApiChecker.checkApi(apiResponse);
    }
  }


  Future<ApiResponseModel> sendOtpToEmail(String email, String temporaryToken, {bool resendOtp = false}) async {
    _isPhoneNumberVerificationButtonLoading = true;
    notifyListeners();
    ApiResponseModel apiResponse;
    if(resendOtp){
      apiResponse = await authServiceInterface.resendEmailOtp(email,temporaryToken);
    }else{
      apiResponse = await authServiceInterface.sendOtpToEmail(email,temporaryToken);
    }
    _isPhoneNumberVerificationButtonLoading = false;
    notifyListeners();
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      resendTime = (apiResponse.response!.data["resend_time"]);
    } else {
      ApiChecker.checkApi(apiResponse);
    }
    notifyListeners();
    return apiResponse;
  }

  Future<void> sendVerificationCode(ConfigModel config, SignUpModel signUpModel, {String? type, FromPage? fromPage}) async {
    _resendButtonLoading = true;

    notifyListeners();
    if(config.customerVerification!.status == 1){
      if(type == 'email' && config.customerVerification?.email == 1){
        await checkEmail(signUpModel.email!, fromPage);
      }else if(type == 'phone' && config.customerVerification?.firebase == 1){
        await firebaseVerifyPhoneNumber(signUpModel.phone!, fromPage!);
      }else if(type == 'phone' &&  config.customerVerification?.phone == 1){
        await checkPhone(signUpModel.phone!, fromPage);
      }
    }
    _resendButtonLoading = false;
    notifyListeners();
  }

  Future<ResponseModel> checkEmail(String email, FromPage? fromPage) async {
    _isPhoneNumberVerificationButtonLoading = true;
    _resendButtonLoading = true;

    _verificationMsg = '';
    notifyListeners();
    ApiResponseModel apiResponse = await  authServiceInterface.checkEmail(email);

    ResponseModel responseModel;


    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      responseModel = ResponseModel(apiResponse.response!.data["token"], true);

      bool callRoute = fromPage != FromPage.verification;

      if(fromPage != null && (fromPage == FromPage.profile || fromPage == FromPage.login)) {
        if(callRoute){
          Navigator.push(Get.context!, MaterialPageRoute(builder: (_) => VerificationScreen(email, fromPage)));
        }
      }
    } else {
      _verificationMsg = ApiChecker.getError(apiResponse).errors![0].message;
      showCustomSnackBar(_verificationMsg, Get.context!);
      responseModel = ResponseModel(_verificationMsg, false);
    }
    _isPhoneNumberVerificationButtonLoading = false;
    _resendButtonLoading = false;
    notifyListeners();

    return responseModel;
  }

  Future<void> firebaseVerifyPhoneNumber(String phoneNumber, FromPage fromPage, {bool isForgetPassword = false}) async {
    _isPhoneNumberVerificationButtonLoading = true;
    _resendButtonLoading = true;
    notifyListeners();

    String? vID;

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      // timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) {},
      verificationFailed: (FirebaseAuthException e) {
        _isPhoneNumberVerificationButtonLoading = false;
        notifyListeners();

        // Navigator.of(Get.context!).pop();

        if(e.code == 'invalid-phone-number') {
          showCustomSnackBar(getTranslated('please_submit_a_valid_phone_number', Get.context!), Get.context!);
        }else{
          showCustomSnackBar(getTranslated('${e.message}'.replaceAll('_', ' ').toCapitalized(), Get.context!), Get.context!);
        }

      },
      codeSent: (String vId, int? resendToken) async {
        _isPhoneNumberVerificationButtonLoading = false;
        _resendButtonLoading = false;
        notifyListeners();

        bool callRoute = fromPage != FromPage.verification;


        await callFirebaseStoretiken(phoneNumber, vId);

        _verificationID = vId;


        if(callRoute) {
          Navigator.push(Get.context!, MaterialPageRoute(builder: (_) => VerificationScreen(phoneNumber, fromPage, session: vId)));
        }
      },

      codeAutoRetrievalTimeout: (String verificationId) {
        _resendButtonLoading = false;
      },
    );


    //await Future.delayed(Duration(seconds: 10));

    _resendButtonLoading = false;
    notifyListeners();
  }


  Future<void> callFirebaseStoretiken (String phoneNumber, String vID) async {
    ApiResponseModel apiResponse = await authServiceInterface.firebaseAuthTokenStore(userInput: phoneNumber, token: vID);
  }

  Future<ResponseModel> checkPhoneForOtp(String phone, FromPage fromPage) async {
    _isPhoneNumberVerificationButtonLoading = true;
    _verificationMsg = '';
    notifyListeners();
    ApiResponseModel apiResponse = await authServiceInterface.checkPhone(phone);
    _isPhoneNumberVerificationButtonLoading = false;
    notifyListeners();
    ResponseModel responseModel;
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      responseModel = ResponseModel(apiResponse.response!.data["token"], true);

      bool callRoute = fromPage != FromPage.verification;

      if(callRoute && apiResponse.response!.data["token"] != 'inactive'){
        Navigator.push(Get.context!, MaterialPageRoute(builder: (_) => VerificationScreen(phone, fromPage)));
      } else{
        showCustomSnackBar(apiResponse.response!.data["message"], Get.context!);
      }
    } else {
      _verificationMsg = ApiChecker.getError(apiResponse).errors![0].message;
      showCustomSnackBar(_verificationMsg, Get.context!);
      responseModel = ResponseModel(_verificationMsg, false);
    }
    notifyListeners();
    return responseModel;
  }

  Future<ResponseModel> checkPhone(String phone, FromPage? fromPage) async {
    _isPhoneNumberVerificationButtonLoading = true;
    _verificationMsg = '';
    notifyListeners();
    ApiResponseModel apiResponse = await authServiceInterface.checkPhone(phone);
    _isPhoneNumberVerificationButtonLoading = false;
    notifyListeners();
    ResponseModel responseModel;
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      responseModel = ResponseModel(apiResponse.response!.data["token"], true);

      bool callRoute = fromPage != FromPage.verification;

      if(callRoute){
        Navigator.push(Get.context!, MaterialPageRoute(builder: (_) => VerificationScreen(phone, fromPage!)));
      }
    } else {

      _verificationMsg = ApiChecker.getError(apiResponse).errors![0].message;
      showCustomSnackBar(_verificationMsg, Get.context!);
      responseModel = ResponseModel(_verificationMsg, false);
    }
    notifyListeners();
    return responseModel;
  }

  Future<ResponseModel> verifyEmail(String email) async {
    _isPhoneNumberVerificationButtonLoading = true;
    _verificationMsg = '';
    notifyListeners();
    ApiResponseModel apiResponse = await authServiceInterface.verifyEmail(email, _verificationCode, '');

    notifyListeners();
    ResponseModel responseModel;
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      String token = apiResponse.response!.data["token"];
      await authServiceInterface.saveUserToken(token);
      // final ProfileProvider profileProvider = Provider.of<ProfileProvider>(Get.context!, listen: false);
      // profileProvider.getUserInfo(true);
      responseModel = ResponseModel(apiResponse.response!.data["message"], true);
    } else {

      _verificationMsg = ApiChecker.getError(apiResponse).errors![0].message;
      showCustomSnackBar(_verificationMsg, Get.context!);
      responseModel = ResponseModel(_verificationMsg, false);
    }
    _isPhoneNumberVerificationButtonLoading = false;
    notifyListeners();
    return responseModel;
  }

  Future<void> firebaseOtpLogin({required String phoneNumber, required String session, required String otp, bool isForgetPassword = false}) async {

    _isPhoneNumberVerificationButtonLoading = true;
    notifyListeners();
    ApiResponseModel apiResponse = await authServiceInterface.firebaseAuthVerify(
      session: session, phoneNumber: phoneNumber,
      otp: otp, isForgetPassword: isForgetPassword,
    );

    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      Map map = apiResponse.response!.data;
      String? token;
      String? tempToken;


      try{
        token = map["token"];
        tempToken = map["temp_token"];
      }catch(error){
        log('$error');
      }

      if(isForgetPassword) {
        Navigator.push(Get.context!, MaterialPageRoute(builder: (_) => ResetPasswordScreen( mobileNumber:  phoneNumber, otp:  otp)));
      }else{
        if(token != null) {
          await authServiceInterface.saveUserToken(token);
          Navigator.pushAndRemoveUntil(Get.context!, MaterialPageRoute(builder: (_) => const DashBoardScreen()), (route) => false);
        } else if(tempToken != null) {
          Navigator.push(Get.context!, MaterialPageRoute(builder: (_) => OtpRegistrationScreen(tempToken: tempToken ?? '', userInput: phoneNumber)));
        }
      }
    } else {
      ApiChecker.checkApi(apiResponse, firebaseResponse: true);
    }

    _isPhoneNumberVerificationButtonLoading = false;
    notifyListeners();
  }

  Future<ResponseModel> registerWithOtp (String name, {String? email, required String phone}) async{
    _isPhoneNumberVerificationButtonLoading = true;
    _loginErrorMessage = '';
    notifyListeners();
    ApiResponseModel apiResponse = await authServiceInterface.registerWithOtp(name, email: email, phone: phone);
    ResponseModel responseModel;
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      String? token;
      Map map = apiResponse.response!.data;
      if(map.containsKey('token')){
        token = map["token"];
      }
      if(token != null){
        await authServiceInterface.saveUserToken(token);
      }
      responseModel = ResponseModel( 'verification', token != null);
    } else {
      _loginErrorMessage = ApiChecker.getError(apiResponse).errors![0].message;
      showCustomSnackBar(_loginErrorMessage, Get.context!);
      responseModel = ResponseModel(_loginErrorMessage, false);
    }
    _isPhoneNumberVerificationButtonLoading = false;
    notifyListeners();
    return responseModel;
  }


  Future<(ResponseModel?, String?)> verifyPhoneForOtp(String phone) async {
    _isPhoneNumberVerificationButtonLoading = true;
    String phoneNumber = phone;
    if(phone.contains('++')) {
      phoneNumber =  phone.replaceAll('++', '+');
    }
    _verificationMsg = '';
    notifyListeners();
    ApiResponseModel apiResponse =  await authServiceInterface.verifyOtp(phoneNumber, _verificationCode);
    notifyListeners();
    ResponseModel? responseModel;
    String? token;
    String? tempToken;
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {

      Map map = apiResponse.response!.data;
      if(map.containsKey('temporary_token')) {
        tempToken = map["temporary_token"];
      }else if(map.containsKey('token')){
        token = map["token"];
      }

      if(token != null){
        await authServiceInterface.saveUserToken(token);
        responseModel = ResponseModel('verification', true);
      }else if(tempToken != null){
        responseModel = ResponseModel( 'verification', true);
      }
    } else {
      _verificationMsg = ApiChecker.getError(apiResponse).errors![0].message;
      showCustomSnackBar(_verificationMsg, Get.context!);
      responseModel = ResponseModel(_verificationMsg, false);
    }
    _isPhoneNumberVerificationButtonLoading = false;
    notifyListeners();
    return (responseModel, tempToken);
  }

  Future<(ResponseModel, String?)> registerWithSocialMedia (String name, {required String email, String? phone}) async {
    _isPhoneNumberVerificationButtonLoading = true;
    _loginErrorMessage = '';
    notifyListeners();
    ApiResponseModel apiResponse  = await authServiceInterface.registerWithSocialMedia(name, email: email, phone: phone);
    ResponseModel responseModel;
    String? token;
    String? tempToken;

    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {

      Map map = apiResponse.response!.data;
      if(map.containsKey('token')){
        token = map["token"];
      }
      if(map.containsKey('temp_token')){
        tempToken = map["temp_token"];
      }

      if(token != null){
        authServiceInterface.saveUserToken(token);
        responseModel = ResponseModel('verification', true);
      }else if(tempToken != null){
        responseModel = ResponseModel('verification', true);
      }else{
        responseModel = ResponseModel('', false);
      }
    } else {
      _loginErrorMessage = ApiChecker.getError(apiResponse).errors![0].message;
      showCustomSnackBar(_loginErrorMessage, Get.context!);
      responseModel = ResponseModel(_loginErrorMessage, false);
    }
    _isPhoneNumberVerificationButtonLoading = false;
    notifyListeners();
    return (responseModel, tempToken);
  }


  int resendTime = 0;

  Future<ResponseModel> sendOtpToPhone(String phone, String temporaryToken,{bool fromResend = false}) async {
    _isPhoneNumberVerificationButtonLoading = true;
    notifyListeners();
    ApiResponseModel apiResponse;
    if(fromResend){
      apiResponse = await authServiceInterface.resendPhoneOtp(phone, temporaryToken);
    }else{
      apiResponse = await authServiceInterface.sendOtpToPhone(phone, temporaryToken);
    }
    _isPhoneNumberVerificationButtonLoading = false;
    notifyListeners();
    ResponseModel responseModel;
    if (apiResponse.response != null && apiResponse.response?.statusCode == 200) {
      responseModel = ResponseModel(apiResponse.response!.data["token"],true);
      // resendTime = (apiResponse.response!.data["resend_time"]);
    } else {
      String? errorMessage;
      if (apiResponse.error is String) {
        errorMessage = apiResponse.error.toString();
      } else {
        ErrorResponse errorResponse = apiResponse.error;
        errorMessage = errorResponse.errors![0].message;
      }
      responseModel = ResponseModel( errorMessage,false);
    }
    notifyListeners();
    return responseModel;
  }

  Future<ResponseModel> verifyProfileInfo(String userInput, String type) async {
    _isPhoneNumberVerificationButtonLoading = true;
    _verificationMsg = '';
    notifyListeners();
    ApiResponseModel apiResponse = await authServiceInterface.verifyProfileInfo(userInput:  userInput, token:  _verificationCode, type: type);
    ResponseModel? responseModel;
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {


      final ProfileController profileProvider = Provider.of<ProfileController>(Get.context!, listen: false);
      profileProvider.getUserInfo(Get.context!);
      showCustomSnackBar(apiResponse.response!.data['message'], Get.context!, isError: false);
      responseModel = ResponseModel('verification', true);

    } else {
      _verificationMsg = ApiChecker.getError(apiResponse).errors![0].message;
      showCustomSnackBar(_verificationMsg, Get.context!);
      responseModel = ResponseModel(_verificationMsg, false);
    }
    _isPhoneNumberVerificationButtonLoading = false;
    notifyListeners();
    return (responseModel);
  }


  Future<ResponseModel> verifyPhone(String phone, String token) async {
    _isPhoneNumberVerificationButtonLoading = true;
    String phoneNumber = phone;
    if(phone.contains('++')) {
      phoneNumber =  phone.replaceAll('++', '+');
    }
    _verificationMsg = '';
    notifyListeners();

    ApiResponseModel apiResponse = await authServiceInterface.verifyPhone(phoneNumber, token, _verificationCode);
    _isPhoneNumberVerificationButtonLoading = false;
    notifyListeners();
    ResponseModel responseModel;
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      responseModel = ResponseModel( apiResponse.response!.data["message"], true);
      String token = apiResponse.response!.data["token"];
      await authServiceInterface.saveUserToken(token);
    } else {
      _verificationMsg = ApiChecker.getError(apiResponse).errors![0].message;
      showCustomSnackBar(_verificationMsg, Get.context!, isError: true);
      responseModel = ResponseModel(_verificationMsg, false);
    }

    _isPhoneNumberVerificationButtonLoading = false;
    notifyListeners();
    return responseModel;
  }


  Future<ApiResponseModel> verifyOtpForResetPassword(String phone) async {
    _isPhoneNumberVerificationButtonLoading = true;
    notifyListeners();

    ApiResponseModel apiResponse = await authServiceInterface.verifyOtp(phone, _verificationCode);
    _isPhoneNumberVerificationButtonLoading = false;
    notifyListeners();
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
    } else {
      _isPhoneNumberVerificationButtonLoading = false;
      ApiChecker.checkApi(apiResponse);
    }
    notifyListeners();
    return apiResponse;
  }


  Future<ApiResponseModel> resetPassword(String identity, String otp, String password, String confirmPassword) async {
    _isPhoneNumberVerificationButtonLoading = true;
    notifyListeners();
    ApiResponseModel apiResponse = await authServiceInterface.resetPassword(identity,otp,password,confirmPassword);
    _isPhoneNumberVerificationButtonLoading = false;
    notifyListeners();
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      showCustomSnackBar(getTranslated('password_reset_successfully', Get.context!), Get.context!, isError: false);
      Navigator.pushAndRemoveUntil(Get.context!, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
    } else {
      _isPhoneNumberVerificationButtonLoading = false;
      ApiChecker.checkApi(apiResponse);
    }
    notifyListeners();
    return apiResponse;
  }


  // for phone verification
  bool _isPhoneNumberVerificationButtonLoading = false;
  bool get isPhoneNumberVerificationButtonLoading => _isPhoneNumberVerificationButtonLoading;
  String _email = '';
  String _phone = '';

  String get email => _email;
  String get phone => _phone;

  updateEmail(String email) {
    _email = email;
    notifyListeners();
  }
  updatePhone(String phone) {
    _phone = phone;
    notifyListeners();
  }


  String _verificationCode = '';
  String get verificationCode => _verificationCode;
  bool _isEnableVerificationCode = false;
  bool get isEnableVerificationCode => _isEnableVerificationCode;

  updateVerificationCode(String query) {
    if (query.length == 6) {
      _isEnableVerificationCode = true;
    } else {
      _isEnableVerificationCode = false;
    }
    _verificationCode = query;
    notifyListeners();
  }



  String getUserToken() {
    return authServiceInterface.getUserToken();
  }

  String? getGuestToken() {
    return authServiceInterface.getGuestIdToken();
  }


  bool isLoggedIn() {
    return authServiceInterface.isLoggedIn();
  }

  bool isGuestIdExist() {
    return authServiceInterface.isGuestIdExist();
  }

  Future<bool> clearSharedData()  {
    return authServiceInterface.clearSharedData();
  }

  Future<bool> clearGuestId() async {
    return await authServiceInterface.clearGuestId();
  }


  void saveUserEmailAndPassword(UserLogData userLogData) {
    authServiceInterface.saveUserEmailAndPassword(jsonEncode(userLogData.toJson()));
  }

  UserLogData? getUserData() {
    UserLogData? userData;
    try{
      userData = UserLogData.fromJson(jsonDecode(authServiceInterface.getUserEmail()));
    }catch(error) {
      debugPrint('error ===> $error');
    }

    return userData;
  }

  Future<bool> clearUserEmailAndPassword() async {
    return authServiceInterface.clearUserEmailAndPassword();
  }


  String getUserPassword() {
    return authServiceInterface.getUserPassword();
  }

  Future<ResponseModel?> forgetPassword({required ConfigModel config, required String phoneOrEmail, required String type}) async {
    ResponseModel? responseModel;
    _isForgotPasswordLoading = true;
    isSentToMail(false);
    notifyListeners();

    if(type == 'phone' && config.customerVerification?.firebase == 1 && config.customerVerification?.phone == 1) {
      await firebaseVerifyPhoneNumber(phoneOrEmail, FromPage.forgetPassword, isForgetPassword: true);
    }else{
      responseModel = await _forgetPassword(phoneOrEmail, type);
    }
    _isForgotPasswordLoading = false;
    notifyListeners();

    return responseModel;
  }

  Future<ResponseModel> _forgetPassword(String email, String type) async {
    _isForgotPasswordLoading = true;
    _resendButtonLoading = true;
    notifyListeners();

    ApiResponseModel apiResponse = await authServiceInterface.forgetPassword(email, type);
    ResponseModel responseModel;

    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      responseModel = ResponseModel(apiResponse.response!.data["message"], true);
      isSentToMail(apiResponse.response!.data["type"] == 'sent_to_mail');

    } else {
      responseModel = ResponseModel(ApiChecker.getError(apiResponse).errors![0].message, false);
      ApiChecker.checkApi(apiResponse);
    }
    _resendButtonLoading = false;
    _isForgotPasswordLoading = false;
    notifyListeners();

    return responseModel;
  }


  void isSentToMail(bool value){
    _sendToEmail = value;
    notifyListeners();
  }


  Future<ResponseModel> verifyToken(String email) async {
    _isPhoneNumberVerificationButtonLoading = true;
    notifyListeners();
    ApiResponseModel apiResponse = await authServiceInterface.verifyToken(email, _verificationCode);

    _isPhoneNumberVerificationButtonLoading = false;
    notifyListeners();
    ResponseModel responseModel;
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      responseModel = ResponseModel(apiResponse.response!.data["message"], true);
    } else {
      responseModel = ResponseModel(ApiChecker.getError(apiResponse).errors![0].message, false);
    }
    return responseModel;
  }


  Future<(ResponseModel?, String?)> existingAccountCheck ({required String email, required int userResponse, required String medium}) async{
    _isPhoneNumberVerificationButtonLoading = true;
    notifyListeners();
    ApiResponseModel apiResponse = await authServiceInterface.existingAccountCheck(email: email, userResponse: userResponse, medium: medium);
    ResponseModel responseModel;
    String? token;
    String? tempToken;
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {


      Map map = apiResponse.response!.data;

      if(map.containsKey('token')){
        token = map["token"];
      }

      if(map.containsKey('temp_token')){
        tempToken = map["temp_token"];
      }

      if(token != null){
        await authServiceInterface.saveUserToken(token);
        responseModel = ResponseModel('token', true);
      } else if(tempToken != null){
        responseModel = ResponseModel('tempToken', true);
      } else{
        responseModel = ResponseModel('', true);
      }
    } else {
      _loginErrorMessage = ApiChecker.getError(apiResponse).errors![0].message;
      showCustomSnackBar(_loginErrorMessage, Get.context!);
      responseModel = ResponseModel(_loginErrorMessage, false);
    }
    _isPhoneNumberVerificationButtonLoading = false;
    notifyListeners();
    return (responseModel, tempToken);
  }

  Future<void> getGuestIdUrl() async {
    ApiResponseModel apiResponse = await authServiceInterface.getGuestId();
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      authServiceInterface.saveGuestId(apiResponse.response!.data['guest_id'].toString());
    } else {
      ApiChecker.checkApi( apiResponse);
    }
    notifyListeners();
  }

  void toggleTermsCheck() {
    _isAcceptTerms = !_isAcceptTerms;
    notifyListeners();
  }

  toggleIsNumberLogin ({bool? value, bool isUpdate = true}) {
    if(value == null) {
      _isNumberLogin = !_isNumberLogin;
    }else {
      _isNumberLogin = value;
    }

    if(isUpdate){
      notifyListeners();
    }
  }

  toggleRememberMe() {
    _isActiveRememberMe = !_isActiveRememberMe;
    notifyListeners();
  }


  void clearVerificationMessage() {
    _verificationMsg = '';
  }


  void removeGoogleLogIn() {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    googleSignIn.disconnect();
  }

}