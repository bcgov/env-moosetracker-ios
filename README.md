![Lifecycle:Stable](https://img.shields.io/badge/Lifecycle-Stable-97ca00)

#Cole's notes for updating annual regs:
The app comes shipped with hunting regs as pdfs.  These are just the main pdf that gets published, but manually split according to region and a few other categories.  This can be done simply by using chrome and printing sections of the pdf to pdfs containing the desired pages.  A quick search in the repo and you can see what they need to be named and what sections there are.

Take a peek in options.plist and make sure you have the hash for the right provisioning profile for signing.  Take a peek in deploy.sh to see the two env vars you need to set for app store deployment.

Finally, this is all that needs to happen:

sh buildAndSign.sh (opens mobile signing, follow the prompts and download the file).
sh deploy.sh (will grab the download and upload to testflight).

Note that the first shell script increments the build version for you.




# env-moosetracker-ios
iOS mobile app that allows hunters to participate in moose conservation and management.

 ## Features

## Usage

## Requirements
The app requires an iOS device running iOS 9.3 or newer.

## Installation
Xcode version 9.4 is required. Clone the repository and open the `WildlifeTracker/WildlifeTracker.xcodeproj` file in Xcode.

To run on a simulator, select your desired device from the scheme menu at the top left of the Xcode window and click the Run triangle icon.

To run on a real device, the app must be signed with a provisioning profile that allows distribution to your development devices. You must set a development team for the WildlifeTracker project target. Xcode should be able to create the necessary App ID and provisioning profile if you choose a valid team and leave "Automatically manage signing" checked. If you are using "Free Provisioning", i.e. not a paid developer account, then the provisioning profile Xcode creates will expire after 7 days. For more information, consult the [Apple documentation](https://help.apple.com/xcode/mac/current/#/dev60b6fbbc7).

## Project Status
In production

## Goals/Roadmap


## Getting Help or Reporting an Issue
To report bugs/issues/feature requests, please file an [issue.](https://github.com/bcgov/env-moosetracker-ios/issues)

## How to Contribute
If you would like to contribute, please see our [CONTRIBUTING guidelines.](https://github.com/bcgov/env-moosetracker-ios/blob/master/CONTRIBUTING.md)

Please note that this project is released with a [Contributor Code of Conduct](https://github.com/bcgov/env-moosetracker-ios/blob/master/CODE-OF-CONDUCT.md). By participating in this project you agree to abide by its terms.

## License
Copyright © 2017, Province of British Columbia. Original Moose Survey app source code modified and licensed with permission from the University of Alberta. More information about the development of University of Alberta’s Moose Survey app can be read in the following journal article: “Moose Survey App for Population Monitoring” by Mark S. Boyce and Rob Corrigan, published in Wildlife Society Bulletin; DOI: 10.1002/wsb.732.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at 

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
