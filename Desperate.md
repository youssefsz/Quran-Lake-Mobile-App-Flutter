cd ios
rm -rf Pods
rm Podfile.lock
pod install
cd ..
flutter clean
flutter build ipa