# iOS folder

This folder holds the hand-written parts of the iOS runner: `Runner/Info.plist` (permission strings),
`Runner/so.lproj` + `Runner/en.lproj` (localised permission strings), `AppDelegate.swift`, `Podfile`
and the Flutter xcconfigs.

The Xcode project itself (`Runner.xcodeproj`, storyboards, `Assets.xcassets`) is generated on a Mac with:

    cd apps/customer
    flutter create --org com.bajgo --project-name bajgo_customer --platforms ios .

`flutter create` only adds missing files; it does not overwrite the files above. Then set the bundle id
`com.bajgo.customer` in Xcode (Runner target > Signing), run `dart run flutter_launcher_icons` and
`dart run flutter_native_splash:create`, and build with `flutter build ios`.
