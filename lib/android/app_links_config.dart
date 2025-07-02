// AndroidManifest.xml Configuration for App Links
//
// Add this intent filter to your activity:
//
// <intent-filter android:autoVerify="true">
//   <action android:name="android.intent.action.VIEW" />
//   <category android:name="android.intent.category.DEFAULT" />
//   <category android:name="android.intent.category.BROWSABLE" />
//   
//   <!-- Accept URIs that begin with "https://openslot.app/event/" -->
//   <data 
//     android:scheme="https"
//     android:host="openslot.app" 
//     android:pathPrefix="/event/" />
//   
//   <!-- Accept URIs that begin with "openslot://event/" -->
//   <data 
//     android:scheme="openslot"
//     android:host="event" />
// </intent-filter>
//
// The android:autoVerify="true" attribute is required for App Links 
// to verify ownership of your domain.
//
// Don't forget to upload assetlinks.json to your domain at:
// https://openslot.app/.well-known/assetlinks.json 