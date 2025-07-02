// iOS Universal Links Configuration
//
// 1. Add the Associated Domains capability in Xcode:
//    - Go to your target's Signing & Capabilities tab
//    - Add the Associated Domains capability
//    - Add an entry: applinks:openslot.app
//
// 2. Make sure you have an Apple App Site Association file at:
//    https://openslot.app/.well-known/apple-app-site-association
//
// 3. The file should be a JSON file with this structure:
//    {
//      "applinks": {
//        "apps": [],
//        "details": [
//          {
//            "appID": "TEAM_ID.com.openslot.app",
//            "paths": ["/event/*"]
//          }
//        ]
//      }
//    }
//
// 4. Replace TEAM_ID with your actual Apple Developer Team ID
//
// Note: AASA files must be served with the Content-Type: application/json header 