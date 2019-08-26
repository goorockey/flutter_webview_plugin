package com.flutter_webview_plugin;

import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.text.TextUtils;
import android.util.Log;

import com.alibaba.baichuan.android.trade.AlibcTrade;
import com.alibaba.baichuan.android.trade.model.AlibcShowParams;
import com.alibaba.baichuan.android.trade.model.OpenType;
import com.alibaba.baichuan.android.trade.page.AlibcBasePage;
import com.alibaba.baichuan.android.trade.page.AlibcPage;
import com.alipay.sdk.app.H5PayCallback;
import com.alipay.sdk.app.PayTask;
import com.alipay.sdk.util.H5PayResultModel;
import com.taobao.applink.TBAppLinkSDK;

import java.net.URLDecoder;
import java.util.HashMap;
import java.util.Map;

public class AliOverrideUrlIntercept {
    Activity activity;
    TBAppLinkSDK appLink;
    Boolean isCoupon = false;
    AliOverrideUrlIntercept(Activity context){
        activity = context;
    }

    private boolean isAppInstalled(String uri) {
        PackageManager pm = activity.getPackageManager();
        boolean installed;
        try {
            pm.getPackageInfo(uri, PackageManager.GET_ACTIVITIES);
            installed = true;
        } catch (PackageManager.NameNotFoundException e) {
            installed = false;
        }
        return installed;
    }

    private Map<String, String> getParams(String url) {
        Map<String, String> ret = new HashMap();
        String[] urls = url.split("\\?");
        if(urls.length > 1) {
            String[] vals = urls[1].split("&");
            for ( String item : vals ) {
                String[] v = item.split("=");
                if (v.length == 0) {
                    ret.put(v[0], URLDecoder.decode(v[1]));
                }
            }
        }
        return ret;
    }

    void openTaobao(String url) {
        if(isAppInstalled("com.taobao.taobao")) {
            Intent intent = new Intent();
            intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            intent.setAction("android.intent.action.VIEW");
            Uri nUri = Uri.parse(url);
            intent.setData(nUri);
            activity.startActivity(intent);
        }
    }

    boolean isIntercept(String url) {
        // 拦截旺旺
        if (url.indexOf("https://h5.m.taobao.com/ww/index.htm") == 0) {
            AlibcBasePage page = new AlibcPage(url);
            AlibcTrade.show(activity,
                    page,
                    new AlibcShowParams(OpenType.Native, false),
                    AliBaichuanConfig.getInstance().getAlibcTaokeParams(),
                    AliBaichuanConfig.getInstance().getExParams(),
                    WebviewManager.alibcTradeCallback);
            return true;
        }

        // 领券后跳转拦截
        // STEP 2 阻止跳转
        if (isCoupon) {
            if (url.indexOf("taobao.com") > -1 && url.indexOf("detail.htm") > -1) {
                isCoupon = false;
                FlutterWebviewPlugin.channel.invokeMethod("onTaobaoCouponSuccess", "");
                return true;
            }else if (url.indexOf("tmall.com") > -1 && url.indexOf("item.htm") > -1) {
                isCoupon = false;
                FlutterWebviewPlugin.channel.invokeMethod("onTaobaoCouponSuccess", "");
                return true;
            }
        }
        // STEP 1 标记领券
        if (url.indexOf("uland.taobao.com/coupon/edetail") > -1) {
            isCoupon = true;
        }



       final PayTask task = new PayTask(activity);
        boolean isIntercepted = task.payInterceptorWithUrl(url, true, new H5PayCallback() {
            @Override
            public void onPayResult(final H5PayResultModel result) {
                // 支付结果返回
                final String url = result.getReturnUrl();
                if (!TextUtils.isEmpty(url)) {
                    Log.i("Alibc", "onPayResult: " + url);
                    Map<String, String> query = getParams(url);
                    String resultCode = result.getResultCode();
                    Map<String, String> ret = new HashMap();
                    switch (new Integer(resultCode)) {
                        case 6002:
                            ret.put("type", "error");
                            ret.put("code", "6002");
                            ret.put("msg", "网络连接出错");
                            break;
                        case 6001:
                            ret.put("type", "error");
                            ret.put("code", "6001");
                            ret.put("msg", "用户中途取消");
                            break;
                        case 4000:
                            ret.put("type", "error");
                            ret.put("code", "4000");
                            ret.put("msg", "订单支付失败");
                            break;
                        case 9000:
                            ret.put("type", "pay");
                            ret.put("orderId", query.get("bizOrderId"));
                            ret.put("returnUrl", url);
                            break;
                        default:

                            ret.put("type", "error");
                            ret.put("code", "6004");
                            ret.put("msg", "支付结果未知");
                            break;
                    }
                    FlutterWebviewPlugin.channel.invokeMethod("onTaobaoOrderChange", ret);
                }
            }
        });

        /**
         * 判断是否成功拦截
         * 若成功拦截，则无需继续加载该URL；否则继续加载
         */
        if (isIntercepted) {
            return true;
        }
        return false;
    }
}
