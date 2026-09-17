# Run after `flutter create .` to add the AdMob App ID placeholders to native projects.
$root = Split-Path -Parent $PSScriptRoot
$androidManifest = Join-Path $root 'android/app/src/main/AndroidManifest.xml'
if (Test-Path $androidManifest) {
  $xml = Get-Content $androidManifest -Raw
  if ($xml -notmatch 'com.google.android.gms.ads.APPLICATION_ID') {
    $xml = $xml -replace '(<application[^>]*>)', '$1`n        <meta-data android:name="com.google.android.gms.ads.APPLICATION_ID" android:value="ca-app-pub-3940256099942544~3347511713"/>', 1
    Set-Content $androidManifest $xml
  }
}
$plist = Join-Path $root 'ios/Runner/Info.plist'
if (Test-Path $plist) {
  $xml = Get-Content $plist -Raw
  if ($xml -notmatch 'GADApplicationIdentifier') {
    $insert = "`n\t<key>GADApplicationIdentifier</key>`n\t<string>ca-app-pub-3940256099942544~1458002511</string>"
    $xml = $xml -replace '</dict>', ($insert + "`n</dict>"), 1
  }
  if ($xml -notmatch 'NSUserTrackingUsageDescription') {
    $insert2 = "`n\t<key>NSUserTrackingUsageDescription</key>`n\t<string>This identifier may be used to provide relevant advertising and measure ad performance.</string>"
    $xml = $xml -replace '</dict>', ($insert2 + "`n</dict>"), 1
  }
  Set-Content $plist $xml
}
Write-Host 'AdMob native placeholders configured. Replace test App IDs before release.'
