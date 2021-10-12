sudo rm -rf signed-moose.zip App
cp ~/Downloads/unsigned-moose-signed.zip ./signed-moose.zip
unzip signed-moose.zip 
xcrun altool --upload-app -f WildlifeTracker/WildlifeTracker.ipa -u $APP_STORE_USERNAME -p $APP_SPECIFIC_PASSWORD
