vim -s increment.vim ios/App/App.xcodeproj/project.pbxproj
sudo xcodebuild -allowProvisioningUpdates -workspace WildlifeTracker/WildlifeTracker.xcworkspace -scheme WildlifeTracker -configuration Release clean archive -archivePath buildArchive/WildlifeTracker.xcarchive CODE_SIGN_IDENTITY="BC Moose Tracker App Store" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
