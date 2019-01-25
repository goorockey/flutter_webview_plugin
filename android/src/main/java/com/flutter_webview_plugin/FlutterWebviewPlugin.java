package com.flutter_webview_plugin;


import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.graphics.Point;
import android.util.Log;
import android.view.Display;
import android.widget.FrameLayout;
import android.webkit.CookieManager;
import android.webkit.ValueCallback;
import android.os.Build;

import com.ali.auth.third.core.model.Session;
import com.ali.auth.third.login.callback.LogoutCallback;
import com.alibaba.baichuan.android.trade.AlibcTrade;
import com.alibaba.baichuan.android.trade.AlibcTradeSDK;
import com.alibaba.baichuan.android.trade.adapter.login.AlibcLogin;
import com.alibaba.baichuan.android.trade.callback.AlibcLoginCallback;
import com.alibaba.baichuan.android.trade.model.AlibcShowParams;
import com.alibaba.baichuan.android.trade.model.OpenType;
import com.alibaba.baichuan.android.trade.page.AlibcAddCartPage;
import com.alibaba.baichuan.android.trade.page.AlibcBasePage;
import com.alibaba.baichuan.android.trade.page.AlibcPage;
import com.alibaba.fastjson.JSONObject;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.PluginRegistry;

/**
 * FlutterWebviewPlugin
 */
public class FlutterWebviewPlugin implements MethodCallHandler, PluginRegistry.ActivityResultListener {
    private Activity activity;
    private WebviewManager webViewManager;
    static MethodChannel channel;
    private static String pid;
    private static final String CHANNEL_NAME = "flutter_webview_plugin";

    public static void registerWith(PluginRegistry.Registrar registrar) {
        channel = new MethodChannel(registrar.messenger(), CHANNEL_NAME);
        final FlutterWebviewPlugin instance = new FlutterWebviewPlugin(registrar.activity());
        registrar.addActivityResultListener(instance);
        channel.setMethodCallHandler(instance);
    }

    private FlutterWebviewPlugin(Activity activity) {
        this.activity = activity;
    }

    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        switch (call.method) {
            case "tbinit":
                tbinit(call, result);
                break;
            case "tblogin":
                tblogin(call, result);
                break;
            case "tbislogin":
                tbislogin(call, result);
                break;
            case "tbgetuser":
                tbgetuser(call, result);
                break;
            case "tblogout":
                tblogout(call, result);
                break;
            case "opentb":
                opentb(call, result);
                break;
            case "addCart":
                addCart(call, result);
                break;
            case "launch":
                openUrl(call, result);
                break;
            case "close":
                close(call, result);
                break;
            case "eval":
                eval(call, result);
                break;
            case "resize":
                resize(call, result);
                break;
            case "reload":
                reload(call, result);
                break;
            case "back":
                back(call, result);
                break;
            case "forward":
                forward(call, result);
                break;
            case "hide":
                hide(call, result);
                break;
            case "show":
                show(call, result);
                break;
            case "reloadUrl":
                reloadUrl(call, result);
                break;
            case "stopLoading":
                stopLoading(call, result);
                break;
            case "cleanCookies":
                cleanCookies(call, result);
                break;
            case "setJavaScriptEnabled":
                setJavaScriptEnabled(call, result);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    private void tbinit(MethodCall call, final MethodChannel.Result result) {
        pid = call.argument("pid");
        AliBaichuanConfig.sharedInstance(activity, pid, result);
    }

    private void tblogin(MethodCall call, final MethodChannel.Result result) {
        AlibcLogin alibcLogin = AlibcLogin.getInstance();
        alibcLogin.showLogin(activity, new AlibcLoginCallback() {
            @Override
            public void onSuccess() {
                Session session = AlibcLogin.getInstance().getSession();
                JSONObject resultJson = new JSONObject();
                resultJson.put("nick", session.nick);
                resultJson.put("avatar_url", session.avatarUrl);
                resultJson.put("open_id", session.openId);
                resultJson.put("open_sid", session.openSid);
                // 下面两个字段安卓不支持获取
                resultJson.put("access_token", "");
                resultJson.put("auth_code", "");
                result.success(resultJson);
            }

            @Override
            public void onFailure(int code, String msg) {
                result.error(String.valueOf(code), msg, "");
            }
        });
    }

    private void tbislogin(MethodCall call, MethodChannel.Result result){
        AlibcTradeSDK.setForceH5(true);
        result.success(AlibcLogin.getInstance().isLogin());
    }

    private void tbgetuser(MethodCall call, MethodChannel.Result result){
        AlibcTradeSDK.setForceH5(true);
        if (AlibcLogin.getInstance().isLogin()) {
            Session session = AlibcLogin.getInstance().getSession();

            JSONObject resultJson = new JSONObject();
            resultJson.put("nick", session.nick);
            resultJson.put("avatar_url", session.avatarUrl);
            resultJson.put("open_id", session.openId);
            resultJson.put("open_sid", session.openSid);
            // 下面两个字段兼容IOS返回格式
            resultJson.put("access_token", "");
            resultJson.put("auth_code", "");
            result.success(resultJson);

        } else {
            result.error("101", "请先登录淘宝账户", "");
        }
    }

    private void tblogout(MethodCall call, final MethodChannel.Result result){
        AlibcTradeSDK.setForceH5(true);
        AlibcLogin alibcLogin = AlibcLogin.getInstance();

        alibcLogin.logout(activity, new LogoutCallback() {
            @Override
            public void onSuccess() {
                result.success("success");
            }

            @Override
            public void onFailure(int code, String msg) {
                result.error(String.valueOf(code), msg, "");
            }
        });
    }

    private void opentb(MethodCall call, final MethodChannel.Result result) {
        String url = call.argument("url");
        AlibcBasePage page = new AlibcPage(url);
        AlibcTrade.show(
            activity,
            page,
            new AlibcShowParams(OpenType.Native, false),
            AliBaichuanConfig.getInstance().getAlibcTaokeParams(),
            AliBaichuanConfig.getInstance().getExParams(),
            WebviewManager.alibcTradeCallback
        );
        result.success("success");
    }

    private void addCart(MethodCall call, final MethodChannel.Result result) {
        String itemId = call.argument("itemId");
        AlibcBasePage page = new AlibcAddCartPage(itemId);
        AlibcTrade.show(
                activity,
                page,
                new AlibcShowParams(OpenType.Native, false),
                AliBaichuanConfig.getInstance().getAlibcTaokeParams(),
                AliBaichuanConfig.getInstance().getExParams(),
                WebviewManager.alibcTradeCallback
        );
        result.success("success");
    }

    private void openUrl(MethodCall call, MethodChannel.Result result) {
        boolean hidden = call.argument("hidden");
        String url = call.argument("url");
        String userAgent = call.argument("userAgent");
        boolean withJavascript = call.argument("withJavascript");
        boolean clearCache = call.argument("clearCache");
        boolean clearCookies = call.argument("clearCookies");
        boolean withZoom = call.argument("withZoom");
        boolean withLocalStorage = call.argument("withLocalStorage");
        boolean supportMultipleWindows = call.argument("supportMultipleWindows");
        boolean appCacheEnabled = call.argument("appCacheEnabled");
        Map<String, String> headers = call.argument("headers");
        boolean scrollBar = call.argument("scrollBar");
        boolean allowFileURLs = call.argument("allowFileURLs");

        // 是否是淘系链接
        boolean istblink = call.argument("istb");

        if (webViewManager == null || webViewManager.closed == true) {
            webViewManager = new WebviewManager(activity);
        }

        if(url.indexOf("//") == 0) {
            url = "https:" + url;
        }
        FrameLayout.LayoutParams params = buildLayoutParams(call);

        activity.addContentView(webViewManager.webView, params);

        webViewManager.openUrl(withJavascript,
                clearCache,
                hidden,
                clearCookies,
                userAgent,
                url,
                headers,
                withZoom,
                withLocalStorage,
                scrollBar,
                supportMultipleWindows,
                appCacheEnabled,
                allowFileURLs,
                istblink
        );

        result.success(null);
    }

    private FrameLayout.LayoutParams buildLayoutParams(MethodCall call) {
        Map<String, Number> rc = call.argument("rect");
        FrameLayout.LayoutParams params;
        if (rc != null) {
            params = new FrameLayout.LayoutParams(
                    dp2px(activity, rc.get("width").intValue()), dp2px(activity, rc.get("height").intValue()));
            params.setMargins(dp2px(activity, rc.get("left").intValue()), dp2px(activity, rc.get("top").intValue()),
                    0, 0);
        } else {
            Display display = activity.getWindowManager().getDefaultDisplay();
            Point size = new Point();
            display.getSize(size);
            int width = size.x;
            int height = size.y;
            params = new FrameLayout.LayoutParams(width, height);
        }

        return params;
    }

    private void stopLoading(MethodCall call, MethodChannel.Result result) {
        if (webViewManager != null) {
            webViewManager.stopLoading(call, result);
        }
    }

    private void close(MethodCall call, MethodChannel.Result result) {
        if (webViewManager != null) {
            webViewManager.close(call, result);
            webViewManager = null;
        }
    }

    /**
     * Navigates back on the Webview.
     */
    private void back(MethodCall call, MethodChannel.Result result) {
        if (webViewManager != null) {
            webViewManager.back(call, result);
        }
    }

    /**
     * Navigates forward on the Webview.
     */
    private void forward(MethodCall call, MethodChannel.Result result) {
        if (webViewManager != null) {
            webViewManager.forward(call, result);
        }
    }

    /**
     * Reloads the Webview.
     */
    private void reload(MethodCall call, MethodChannel.Result result) {
        if (webViewManager != null) {
            webViewManager.reload(call, result);
        }
    }

    private void reloadUrl(MethodCall call, MethodChannel.Result result) {
        if (webViewManager != null) {
            String url = call.argument("url");
            webViewManager.reloadUrl(url);
        }
    }

    private void eval(MethodCall call, final MethodChannel.Result result) {
        if (webViewManager != null) {
            webViewManager.eval(call, result);
        }
    }

    private void resize(MethodCall call, final MethodChannel.Result result) {
        if (webViewManager != null) {
            FrameLayout.LayoutParams params = buildLayoutParams(call);
            webViewManager.resize(params);
        }
        result.success(null);
    }

    private void hide(MethodCall call, final MethodChannel.Result result) {
        if (webViewManager != null) {
            webViewManager.hide(call, result);
        }
    }

    private void show(MethodCall call, final MethodChannel.Result result) {
        if (webViewManager != null) {
            webViewManager.show(call, result);
        }
    }

    private void setJavaScriptEnabled(MethodCall call, final MethodChannel.Result result) {
        if (webViewManager != null) {
            Log.i("webview", "setJavaScriptEnabled: " );
            webViewManager.setJavaScriptEnabled(call, result);
        }
    }

    private void cleanCookies(MethodCall call, final MethodChannel.Result result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            CookieManager.getInstance().removeAllCookies(new ValueCallback<Boolean>() {
                @Override
                public void onReceiveValue(Boolean aBoolean) {

                }
            });
        } else {
            CookieManager.getInstance().removeAllCookie();
        }
        result.success(null);
    }

    private int dp2px(Context context, float dp) {
        final float scale = context.getResources().getDisplayMetrics().density;
        return (int) (dp * scale + 0.5f);
    }

    @Override
    public boolean onActivityResult(int i, int i1, Intent intent) {
        if (webViewManager != null && webViewManager.resultHandler != null) {
            return webViewManager.resultHandler.handleResult(i, i1, intent);
        }
        return false;
    }
}
