import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _kChannel = 'flutter_webview_plugin';

// TODO: more general state for iOS/android
enum WebViewState { shouldStart, startLoad, finishLoad }

// TODO: use an id by webview to be able to manage multiple webview

/// Singleton class that communicate with a Webview Instance
class FlutterWebviewPlugin {
  factory FlutterWebviewPlugin() => _instance ??= FlutterWebviewPlugin._();

  FlutterWebviewPlugin._() {
    FlutterWebviewPlugin.channel.setMethodCallHandler(_handleMessages);
  }

  static FlutterWebviewPlugin _instance;

  static MethodChannel channel = MethodChannel(_kChannel);

  final _onDestroy = StreamController<Null>.broadcast();
  final _onUrlChanged = StreamController<String>.broadcast();
  final _onStateChanged = StreamController<WebViewStateChanged>.broadcast();
  final _onScrollXChanged = StreamController<double>.broadcast();
  final _onScrollYChanged = StreamController<double>.broadcast();
  final _onTaobaoOrderChange = StreamController<double>.broadcast();
  final _onHttpError = StreamController<WebViewHttpError>.broadcast();

  Future<Null> _handleMessages(MethodCall call) async {
    switch (call.method) {
      case 'onDestroy':
        _onDestroy.add(null);
        break;
      case 'onUrlChanged':
        _onUrlChanged.add(call.arguments['url']);
        break;
      case 'onScrollXChanged':
        _onScrollXChanged.add(call.arguments['xDirection']);
        break;
      case 'onScrollYChanged':
        _onScrollYChanged.add(call.arguments['yDirection']);
        break;
      case 'onTaobaoOrderChange':
        _onTaobaoOrderChange.add(call.arguments);
        break;
      case 'onState':
        _onStateChanged.add(
          WebViewStateChanged.fromMap(
            Map<String, dynamic>.from(call.arguments),
          ),
        );
        break;
      case 'onHttpError':
        _onHttpError.add(WebViewHttpError(call.arguments['code'], call.arguments['url']));
        break;
    }
  }

  /// Listening the OnDestroy LifeCycle Event for Android
  Stream<Null> get onDestroy => _onDestroy.stream;

  /// Listening url changed
  Stream<String> get onUrlChanged => _onUrlChanged.stream;

  /// Listening the onState Event for iOS WebView and Android
  /// content is Map for type: {shouldStart(iOS)|startLoad|finishLoad}
  /// more detail than other events
  Stream<WebViewStateChanged> get onStateChanged => _onStateChanged.stream;

  /// Listening web view y position scroll change
  Stream<double> get onScrollYChanged => _onScrollYChanged.stream;

  /// Listening web view x position scroll change
  Stream<double> get onScrollXChanged => _onScrollXChanged.stream;

  Stream<WebViewHttpError> get onHttpError => _onHttpError.stream;

  // 初始化淘宝SDK
  static Future<bool> tbinit(String pid) async {
    try {
      await FlutterWebviewPlugin.channel.invokeMethod('tbinit', {"pid": pid});
      return Future.value(true);
    }catch (e) {
      print(['tbinit', e]);
      return Future.value(false);
    }
  }

  // 登陆淘宝
  Future<TaobaoUser> tblogin() async {
    try {
      final ret = await FlutterWebviewPlugin.channel.invokeMethod("tblogin", {});
      return TaobaoUser.fromJson(Map.from(ret));
    } catch (e){
      return Future.error((e as PlatformException).message);
    }
  }

  // 淘宝是否登陆
  Future<bool> tbislogin() async {
    try{
      await FlutterWebviewPlugin.channel.invokeMethod("tbislogin", {});
      return Future.value(true);
    }catch (e){
      print(['tbislogin', e]);
      return Future.value(false);
    }
  }

  // 获取淘宝登陆的用户
  Future<TaobaoUser> tbgetuser() async {
    try{
      final ret = await FlutterWebviewPlugin.channel.invokeMethod("tbgetuser", {});
      return TaobaoUser.fromJson(Map.from(ret));
    }catch (e){
      print(['tbgetuser', e]);
      return Future.error((e as PlatformException).message);
    }
  }

  // 退出淘宝登陆
  Future<bool> tblogout() async {
    try{
      await FlutterWebviewPlugin.channel.invokeMethod("tblogout", {});
      return Future.value(true);
    }catch (e){
      print(["tblogout", e]);
      return Future.value(false);
    }
  }

  // 唤醒淘宝打开页面
  Future<bool> opentb(String url) async {
    try{
      await FlutterWebviewPlugin.channel.invokeMethod("opentb", {"url": url});
      return Future.value(true);
    }catch (e){
      print(["opentb", e]);
      return Future.value(false);
    }
  }

  /// Start the Webview with [url]
  /// - [headers] specify additional HTTP headers
  /// - [withJavascript] enable Javascript or not for the Webview
  ///     iOS WebView: Not implemented yet
  /// - [clearCache] clear the cache of the Webview
  /// - [clearCookies] clear all cookies of the Webview
  /// - [hidden] not show
  /// - [rect]: show in rect, fullscreen if null
  /// - [enableAppScheme]: false will enable all schemes, true only for httt/https/about
  ///     android: Not implemented yet
  /// - [userAgent]: set the User-Agent of WebView
  /// - [withZoom]: enable zoom on webview
  /// - [withLocalStorage] enable localStorage API on Webview
  ///     Currently Android only.
  ///     It is always enabled in UIWebView of iOS and  can not be disabled.
  /// - [withLocalUrl]: allow url as a local path
  ///     Allow local files on iOs > 9.0
  /// - [scrollBar]: enable or disable scrollbar
  Future<Null> launch(String url, {
    Map<String, String> headers,
    bool withJavascript,
    bool clearCache,
    bool clearCookies,
    bool hidden,
    bool enableAppScheme,
    Rect rect,
    String userAgent,
    bool withZoom,
    bool withLocalStorage,
    bool withLocalUrl,
    bool scrollBar,
    bool supportMultipleWindows,
    bool appCacheEnabled,
    bool allowFileURLs,
    bool istb
  }) async {
    final args = <String, dynamic>{
      'url': url,
      'withJavascript': withJavascript ?? true,
      'clearCache': clearCache ?? false,
      'hidden': hidden ?? false,
      'clearCookies': clearCookies ?? false,
      'enableAppScheme': enableAppScheme ?? true,
      'userAgent': userAgent,
      'withZoom': withZoom ?? false,
      'withLocalStorage': withLocalStorage ?? true,
      'withLocalUrl': withLocalUrl ?? false,
      'scrollBar': scrollBar ?? true,
      'supportMultipleWindows': supportMultipleWindows ?? false,
      'appCacheEnabled': appCacheEnabled ?? false,
      'allowFileURLs': allowFileURLs ?? false,
      'istb': istb ?? false,
    };

    if (headers != null) {
      args['headers'] = headers;
    }

    if (rect != null) {
      args['rect'] = {
        'left': rect.left,
        'top': rect.top,
        'width': rect.width,
        'height': rect.height,
      };
    }
    await FlutterWebviewPlugin.channel.invokeMethod('launch', args);
  }

  /// Execute Javascript inside webview
  Future<String> evalJavascript(String code) async {
    final res = await FlutterWebviewPlugin.channel.invokeMethod('eval', {'code': code});
    return res;
  }

  /// Close the Webview
  /// Will trigger the [onDestroy] event
  Future<Null> close() async => await FlutterWebviewPlugin.channel.invokeMethod('close');

  /// Reloads the WebView.
  Future<Null> reload() async => await FlutterWebviewPlugin.channel.invokeMethod('reload');

  /// Navigates back on the Webview.
  Future<Null> goBack() async => await FlutterWebviewPlugin.channel.invokeMethod('back');

  /// Navigates forward on the Webview.
  Future<Null> goForward() async => await FlutterWebviewPlugin.channel.invokeMethod('forward');

  // Hides the webview
  Future<Null> hide() async => await FlutterWebviewPlugin.channel.invokeMethod('hide');

  // Shows the webview
  Future<Null> show() async => await FlutterWebviewPlugin.channel.invokeMethod('show');

  // Reload webview with a url
  Future<Null> reloadUrl(String url) async {
    final args = <String, String>{'url': url};
    await FlutterWebviewPlugin.channel.invokeMethod('reloadUrl', args);
  }

  // Clean cookies on WebView
  Future<Null> cleanCookies() async => await FlutterWebviewPlugin.channel.invokeMethod('cleanCookies');

  // Stops current loading process
  Future<Null> stopLoading() async => await FlutterWebviewPlugin.channel.invokeMethod('stopLoading');

  /// Close all Streams
  void dispose() {
    _onDestroy.close();
    _onUrlChanged.close();
    _onStateChanged.close();
    _onScrollXChanged.close();
    _onScrollYChanged.close();
    _onHttpError.close();
    _instance = null;
  }

  Future<Map<String, String>> getCookies() async {
    final cookiesString = await evalJavascript('document.cookie');
    final cookies = <String, String>{};

    if (cookiesString?.isNotEmpty == true) {
      cookiesString.split(';').forEach((String cookie) {
        final split = cookie.split('=');
        cookies[split[0]] = split[1];
      });
    }

    return cookies;
  }

  /// resize webview
  Future<Null> resize(Rect rect) async {
    final args = {};
    args['rect'] = {
      'left': rect.left,
      'top': rect.top,
      'width': rect.width,
      'height': rect.height,
    };
    await FlutterWebviewPlugin.channel.invokeMethod('resize', args);
  }
}

class WebViewStateChanged {
  WebViewStateChanged(this.type, this.url, this.navigationType);

  factory WebViewStateChanged.fromMap(Map<String, dynamic> map) {
    WebViewState t;
    switch (map['type']) {
      case 'shouldStart':
        t = WebViewState.shouldStart;
        break;
      case 'startLoad':
        t = WebViewState.startLoad;
        break;
      case 'finishLoad':
        t = WebViewState.finishLoad;
        break;
    }
    return WebViewStateChanged(t, map['url'], map['navigationType']);
  }

  final WebViewState type;
  final String url;
  final int navigationType;
}

class WebViewHttpError {
  WebViewHttpError(this.code, this.url);

  final String url;
  final String code;
}


class TaobaoUser {
  String nick;
  String avatarUrl;
  String openId;
  String openSid;
  String accessToken;
  String authCode;

  TaobaoUser(
          {this.nick,
            this.avatarUrl,
            this.openId,
            this.openSid,
            this.accessToken,
            this.authCode});

  TaobaoUser.fromJson(Map<String, dynamic> json) {
    nick = json['nick'];
    avatarUrl = json['avatar_url'];
    openId = json['open_id'];
    openSid = json['open_sid'];
    accessToken = json['access_token'];
    authCode = json['auth_code'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['nick'] = this.nick;
    data['avatar_url'] = this.avatarUrl;
    data['open_id'] = this.openId;
    data['open_sid'] = this.openSid;
    data['access_token'] = this.accessToken;
    data['auth_code'] = this.authCode;
    return data;
  }
}