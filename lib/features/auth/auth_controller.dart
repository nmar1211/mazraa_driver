import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazraa_driver/core/constants/build_flags.dart';
import 'package:mazraa_driver/core/models/app_models.dart';
import 'package:mazraa_driver/core/network/api_exception.dart';
import 'package:mazraa_driver/core/network/driver_api.dart';
import 'package:mazraa_driver/core/network/providers.dart';
import 'package:mazraa_driver/core/storage/secure_session_store.dart';

enum AuthState {
  initial,
  restoring,
  preparingHome,
  bootstrapFailed,
  signedOut,
  signingIn,
  authenticated,
}

class AuthController extends ChangeNotifier {
  AuthController(this._api, this._store) {
    if (BuildFlags.ciSmokeHome) {
      state = AuthState.authenticated;
      profile = const DriverProfile(
        userId: 77,
        driverCode: 'DRV-SMOKE-77',
        name: 'عبدالرحمن',
        email: 'driver-smoke@local.invalid',
        phone: '+966 500 000 000',
        vehicleType: 'Motorcycle',
        approvalStatus: 'Approved',
        operationalStatus: 'Offline',
        isAcceptingOrders: false,
        isVerified: true,
        ratingAverage: 4.9,
        ratingCount: 128,
        currentLatitude: 24.7136,
        currentLongitude: 46.6753,
      );
    }
  }

  static const _storageTimeout = Duration(seconds: 6);
  static const _requestTimeout = Duration(seconds: 25);
  static const _homeBootstrapTimeout = Duration(seconds: 35);

  final DriverApi _api;
  final SecureSessionStore _store;

  AuthState state = AuthState.initial;
  AuthSession? session;
  DriverProfile? profile;
  String? errorMessage;

  bool get isAuthenticated => state == AuthState.authenticated;
  bool get isBootstrapping =>
      state == AuthState.restoring || state == AuthState.preparingHome;

  Future<void> initialize({
    Future<void> Function()? preloadHome,
    bool force = false,
  }) async {
    if (!force &&
        state != AuthState.initial &&
        state != AuthState.bootstrapFailed) {
      return;
    }

    errorMessage = null;
    state = AuthState.restoring;
    notifyListeners();

    AuthSession? stored;
    try {
      stored = await _store.read().timeout(_storageTimeout);
    } on TimeoutException {
      _failBootstrap(
        'تعذر قراءة الجلسة المحفوظة في الوقت المحدد. أعد المحاولة.',
      );
      return;
    } catch (error) {
      _failBootstrap('تعذر استعادة الجلسة المحفوظة: $error');
      return;
    }

    if (stored == null) {
      _setSignedOut();
      return;
    }

    session = stored;

    try {
      profile = await _api.getDriver(stored.userId).timeout(_requestTimeout);
      state = AuthState.preparingHome;
      notifyListeners();

      if (preloadHome != null) {
        await preloadHome().timeout(_homeBootstrapTimeout);
      }

      errorMessage = null;
      state = AuthState.authenticated;
      notifyListeners();
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _clearSessionSafely();
        _setSignedOut(message: error.message);
        return;
      }
      _failBootstrap(error.message);
    } on TimeoutException {
      _failBootstrap(
        state == AuthState.preparingHome
            ? 'استغرق تحميل بيانات الشاشة الرئيسية وقتًا أطول من المتوقع. تحقق من الاتصال وأعد المحاولة.'
            : 'استغرق التحقق من حساب السائق وقتًا أطول من المتوقع. تحقق من الاتصال وأعد المحاولة.',
      );
    } catch (error) {
      _failBootstrap(error.toString());
    }
  }

  Future<bool> login(
    String email,
    String password, {
    Future<void> Function()? preloadHome,
  }) async {
    if (state == AuthState.signingIn) return false;
    state = AuthState.signingIn;
    errorMessage = null;
    notifyListeners();

    try {
      final nextSession = await _api
          .login(email, password)
          .timeout(_requestTimeout);
      final nextProfile = await _api
          .getDriver(nextSession.userId)
          .timeout(_requestTimeout);

      session = nextSession;
      profile = nextProfile;
      state = AuthState.preparingHome;
      notifyListeners();

      if (preloadHome != null) {
        await preloadHome().timeout(_homeBootstrapTimeout);
      }

      state = AuthState.authenticated;
      errorMessage = null;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _clearSessionSafely();
        session = null;
        profile = null;
        state = AuthState.signedOut;
      } else if (session != null) {
        state = AuthState.bootstrapFailed;
      } else {
        state = AuthState.signedOut;
      }
      errorMessage = error.message;
      notifyListeners();
      return false;
    } on TimeoutException {
      errorMessage = session == null
          ? 'انتهت مهلة تسجيل الدخول. تحقق من الإنترنت وحاول مجددًا.'
          : 'تم تسجيل الدخول، لكن تحميل بيانات الشاشة الرئيسية لم يكتمل. أعد المحاولة.';
      state = session == null
          ? AuthState.signedOut
          : AuthState.bootstrapFailed;
      notifyListeners();
      return false;
    } catch (error) {
      errorMessage = error.toString();
      state = session == null
          ? AuthState.signedOut
          : AuthState.bootstrapFailed;
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshProfile() async {
    if (BuildFlags.ciSmokeHome) return;
    final current = session;
    if (current == null) return;
    profile = await _api.getDriver(current.userId).timeout(_requestTimeout);
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await _api.logout().timeout(_requestTimeout);
    } finally {
      session = null;
      profile = null;
      errorMessage = null;
      state = AuthState.signedOut;
      notifyListeners();
    }
  }

  void _failBootstrap(String message) {
    errorMessage = message;
    state = AuthState.bootstrapFailed;
    notifyListeners();
  }

  void _setSignedOut({String? message}) {
    session = null;
    profile = null;
    errorMessage = message;
    state = AuthState.signedOut;
    notifyListeners();
  }

  Future<void> _clearSessionSafely() async {
    try {
      await _store.clear().timeout(_storageTimeout);
    } catch (_) {
      // A failed local cleanup must never leave the bootstrap spinner running.
    }
  }
}

final authControllerProvider = ChangeNotifierProvider<AuthController>((ref) {
  return AuthController(
    ref.watch(driverApiProvider),
    ref.watch(sessionStoreProvider),
  );
});
