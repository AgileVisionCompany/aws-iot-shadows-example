package io.agilevision.reinventory;

import android.content.Intent;
import android.util.Log;

import androidx.annotation.NonNull;

import com.amazonaws.amplify.amplify_auth_cognito.AuthCognito;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.PluginRegistry;

public class AuthCognitoPluginWrapper implements FlutterPlugin, ActivityAware, PluginRegistry.ActivityResultListener {

    private AuthCognito authCognito;

    public AuthCognitoPluginWrapper(AuthCognito authCognito) {
        this.authCognito = authCognito;
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        try {
            authCognito.onAttachedToEngine(binding);
        } catch (Exception e) {
            Log.e(AuthCognitoPluginWrapper.class.getSimpleName(), "Suppression for error (workaround!)", e);
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        authCognito.onDetachedFromEngine(binding);
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        authCognito.onAttachedToActivity(binding);
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        authCognito.onDetachedFromActivityForConfigChanges();
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        authCognito.onReattachedToActivityForConfigChanges(binding);
    }

    @Override
    public void onDetachedFromActivity() {
        authCognito.onDetachedFromActivity();
    }

    @Override
    public boolean onActivityResult(int requestCode, int resultCode, Intent data) {
        return authCognito.onActivityResult(requestCode, resultCode, data);
    }

}
