fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew cask install fastlane`

# Available Actions
## iOS
### ios test
```
fastlane ios test
```
Runs all the tests
### ios local_register_devices
```
fastlane ios local_register_devices
```

### ios setup_certs
```
fastlane ios setup_certs
```

### ios bump
```
fastlane ios bump
```
Bumps the minor version number

This is useful if you want to submit a new TestFlight build after releasing a build
### ios beta
```
fastlane ios beta
```
Submit a new Beta Build to Apple TestFlight

This will also make sure the profile is up to date
### ios upload
```
fastlane ios upload
```

### ios screenshots
```
fastlane ios screenshots
```


----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
