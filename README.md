# AWS IoT Shadows example

Flutter application (for Android) for demonstrating AWS IoT shadows.

## Building the Project
- Create a file named `awsconfiguration.json` in the `android/app/src/main/res/raw` directory with the following content:

  ```json
    {
      "UserAgent": "aws-amplify-cli/0.1.0",
      "Version": "0.1.0",
      "IdentityManager": {
        "Default": {}
      },
      "CredentialsProvider": {
        "CognitoIdentity": {
          "Default": {
            "PoolId": "...",
            "Region": "..."
          }
        }
      },
      "CognitoUserPool": {
        "Default": {
          "PoolId": "...",
          "AppClientId": "...",
          "AppClientSecret": "...",
          "Region": "..."
        }
      },
      "Auth": {
        "Default": {}
      }
    }
  ```

- Place the right values instead of `...`

- Go to the `lib` directory and edit `amplify.dart` file. In the `_setupAmplify()` method specify the
  variable named `amplifyConfig` with the amplify configuration. Example of configuration:

  ```dart
    final amplifyConfig = {
      "auth": {
        "plugins": {
          "awsCognitoAuthPlugin": {
            "UserAgent": "aws-amplify-cli/0.1.0",
            "Version": "0.1.0",
            "IdentityManager": {
              "Default": {}
            },
            "CredentialsProvider": {
              "CognitoIdentity": {
                "Default": {
                  "PoolId": "...",
                  "Region": "..."
                }
              }
            },
            "CognitoUserPool": {
              "Default": {
                "PoolId": "...",
                "AppClientId": "...",
                "AppClientSecret": "...",
                "Region": "..."
              }
            },
            "Auth": {
              "Default": {}
            }
          }
        }
      }
    };
  ```

- Open `android/app/src/main/kotlin/io/agilevision/reinventory/LedsShadowController.kt` and place the right values
  to the following variables:

  ```kotlin
  val deviceId = "YOUR_DEVICE_ID_HERE"
  val mqttEndpoint = "PUB_SUB_ENDPOINT_HERE"
  val policyName = "YOUR_POLICY_NAME"
  ```

- Install Flutter Intl plugin (if you use Android Studio). Otherwise execute the
  following commands in order to generate localization files:

  - Only once:

    ```
    $ flutter pub global activate intl_utils
    ```

  - Every time when the localization files (`lib/l10n/*.arb`) are changed:

    ```
    $ flutter pub global run intl_utils:generate
    ```

  - Congratulations! Now you can build the app on your local machine.
  - For testing on non-prod environments you can go to the "Settings" -> "Generate random assets" for
    creating a list of 100 random assets
