//
//  Generated file. Do not edit.
//

#import "GeneratedPluginRegistrant.h"

#if __has_include(<amplify_auth_cognito/AuthCognito.h>)
#import <amplify_auth_cognito/AuthCognito.h>
#else
@import amplify_auth_cognito;
#endif

#if __has_include(<amplify_flutter/Amplify.h>)
#import <amplify_flutter/Amplify.h>
#else
@import amplify_flutter;
#endif

#if __has_include(<path_provider/FLTPathProviderPlugin.h>)
#import <path_provider/FLTPathProviderPlugin.h>
#else
@import path_provider;
#endif

#if __has_include(<url_launcher/FLTURLLauncherPlugin.h>)
#import <url_launcher/FLTURLLauncherPlugin.h>
#else
@import url_launcher;
#endif

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [AuthCognito registerWithRegistrar:[registry registrarForPlugin:@"AuthCognito"]];
  [Amplify registerWithRegistrar:[registry registrarForPlugin:@"Amplify"]];
  [FLTPathProviderPlugin registerWithRegistrar:[registry registrarForPlugin:@"FLTPathProviderPlugin"]];
  [FLTURLLauncherPlugin registerWithRegistrar:[registry registrarForPlugin:@"FLTURLLauncherPlugin"]];
}

@end
