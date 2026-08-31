import type { ExpoConfig } from 'expo/config';

import appJson from './app.json';

const iosGoogleMapsApiKey = process.env.GOOGLE_MAPS_IOS_API_KEY;
const androidGoogleMapsApiKey = process.env.GOOGLE_MAPS_ANDROID_API_KEY;
const base = appJson.expo as unknown as ExpoConfig;
const plugins = [...(base.plugins ?? [])];

if (iosGoogleMapsApiKey || androidGoogleMapsApiKey) {
  plugins.push([
    'react-native-maps',
    {
      ...(iosGoogleMapsApiKey ? { iosGoogleMapsApiKey } : {}),
      ...(androidGoogleMapsApiKey ? { androidGoogleMapsApiKey } : {}),
    },
  ]);
}

const config: ExpoConfig = {
  ...base,
  plugins,
};

export default config;
