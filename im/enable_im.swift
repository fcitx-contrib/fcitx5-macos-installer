import Carbon

let bundleId = "org.fcitx.inputmethod.Fcitx5"
let inputSourceId = bundleId

let conditions = NSMutableDictionary()
conditions.setValue(bundleId, forKey: kTISPropertyBundleID as String)
// There are 2 items with kTISPropertyBundleID.
// We enable the parent, which has kTISPropertyInputSourceID: org.fcitx.inputmethod.Fcitx5
conditions.setValue(inputSourceId, forKey: kTISPropertyInputSourceID as String)
if let array = TISCreateInputSourceList(conditions, true)?.takeRetainedValue() as? [TISInputSource]
{
  for inputSource in array {
    TISEnableInputSource(inputSource)
  }
}
