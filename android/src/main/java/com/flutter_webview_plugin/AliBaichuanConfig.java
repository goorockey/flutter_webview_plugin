package com.flutter_webview_plugin;

import android.content.Context;
import android.util.Log;

import com.alibaba.baichuan.android.trade.AlibcTradeSDK;
import com.alibaba.baichuan.android.trade.callback.AlibcTradeInitCallback;
import com.alibaba.baichuan.android.trade.constants.AlibcConstants;
import com.alibaba.baichuan.android.trade.model.AlibcShowParams;
import com.alibaba.baichuan.android.trade.model.AlibcTaokeParams;
import com.alibaba.baichuan.android.trade.model.OpenType;

import java.util.HashMap;
import java.util.Map;

import javax.security.auth.callback.Callback;

import io.flutter.plugin.common.MethodChannel;


public class AliBaichuanConfig {
    Context mContext;

    private String pid;
    private Map<String, String> exParams;//yhhpass参数
    private AlibcShowParams alibcShowParams;//页面打开方式，默认，H5，Native
    private AlibcTaokeParams alibcTaokeParams = null;//淘客参数，包括pid，unionid，subPid

    static private AliBaichuanConfig mAlibcSdkModule = null;
    static public AliBaichuanConfig sharedInstance(Context context, String pid, MethodChannel.Result result) {
        if (mAlibcSdkModule == null){
            mAlibcSdkModule =  new AliBaichuanConfig(context, pid, result);
        }
        return mAlibcSdkModule;
    }

    static public AliBaichuanConfig getInstance() {
            return mAlibcSdkModule;
    }

    public AliBaichuanConfig(Context context, String pid, final MethodChannel.Result result) {
        mContext = context;
        this.pid = pid;
        alibcTaokeParams = new AlibcTaokeParams(pid, "", "");
        alibcShowParams = new AlibcShowParams(OpenType.Auto, false);
        exParams = new HashMap<>();
        exParams.put(AlibcConstants.ISV_CODE, "appisvcode");
        AlibcTradeSDK.asyncInit(mContext, new AlibcTradeInitCallback() {
            @Override
            public void onSuccess() {
                AlibcTradeSDK.setForceH5(true);
                result.success("success");
            }

            @Override
            public void onFailure(int code, String msg) {
                Log.e("BaichuanModule", "onFailure: 初始化失败(" + String.valueOf(code) + ")" + msg);
                result.error(String.valueOf(code), msg, "");
            }
        });
    }

    public String getPid() {
        return this.pid;
    }

    public Map<String, String> getExParams(){
        return this.exParams;
    }

    public AlibcShowParams getAlibcShowParams() {
        return alibcShowParams;
    }

    public AlibcTaokeParams getAlibcTaokeParams() {
        return alibcTaokeParams;
    }
}
