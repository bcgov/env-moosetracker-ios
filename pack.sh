rm -rf ~/Downloads/unsigned-moose-signed.zip
cd buildArchive
cp -a ../options.plist .
sudo zip -r unsigned-moose.zip options.plist WildlifeTracker.xcarchive
open https://mss.developer.gov.bc.ca/
