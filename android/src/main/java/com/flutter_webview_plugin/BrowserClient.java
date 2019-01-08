package com.flutter_webview_plugin;

import android.annotation.TargetApi;
import android.app.Activity;
import android.graphics.Bitmap;
import android.util.Log;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import java.util.HashMap;
import java.util.Map;

/**
 * Created by lejard_h on 20/12/2017.
 */

public class BrowserClient extends WebViewClient {
    Activity activity;
    AliOverrideUrlIntercept aliOverrideUrlIntercept;
    public BrowserClient(Activity activity) {
        super();
        aliOverrideUrlIntercept = new AliOverrideUrlIntercept(activity);
        this.activity = activity;
    }

    public boolean shouldOverrideUrlLoading(WebView view, String url) {
        Log.i("BrowserClient", "shouldOverrideUrlLoading: " + url);
        if (!(url.startsWith("http") || url.startsWith("https"))) {
            return true;
        }

        // 阿里系拦截
        boolean isIntercept = aliOverrideUrlIntercept.isIntercept(url);

        if (isIntercept) {
            return true;
        }
        // 其他拦截

        return false;
    }

    @Override
    public void onPageStarted(WebView view, String url, Bitmap favicon) {
        Log.i("onPageStarted", "onPageStarted: " + url);
        super.onPageStarted(view, url, favicon);
        Map<String, Object> data = new HashMap<>();
        data.put("url", url);
        data.put("type", "startLoad");
        FlutterWebviewPlugin.channel.invokeMethod("onState", data);
    }

    @Override
    public void onPageFinished(WebView view, String url) {
        super.onPageFinished(view, url);
        Map<String, Object> data = new HashMap<>();
        data.put("url", url);

        FlutterWebviewPlugin.channel.invokeMethod("onUrlChanged", data);

        data.put("type", "finishLoad");
        FlutterWebviewPlugin.channel.invokeMethod("onState", data);

    }

    @SuppressWarnings("deprecation")
    @Override
    public void onReceivedError(WebView view, int errorCode, String description, String failingUrl) {
        super.onReceivedError(view, errorCode, description, failingUrl);
        Map<String, Object> data = new HashMap<>();
        data.put("url", failingUrl);
        data.put("code", Integer.toString(errorCode));
        FlutterWebviewPlugin.channel.invokeMethod("onHttpError", data);
    }

    @TargetApi(android.os.Build.VERSION_CODES.M)
    @Override
    public void onReceivedHttpError(WebView view, WebResourceRequest request, WebResourceResponse errorResponse) {
        super.onReceivedHttpError(view, request, errorResponse);
        Map<String, Object> data = new HashMap<>();
        data.put("url", request.getUrl().toString());
        data.put("code", Integer.toString(errorResponse.getStatusCode()));
        FlutterWebviewPlugin.channel.invokeMethod("onHttpError", data);
    }
}