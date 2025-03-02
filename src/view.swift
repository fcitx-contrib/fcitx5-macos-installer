import AlertToast
import Carbon
import SwiftUI

let logPath = "/tmp/Fcitx5Installer.log"

let bundleId = "org.fcitx.inputmethod.Fcitx5"
let inputSourceId = "org.fcitx.inputmethod.Fcitx5.fcitx5"

func selectInputMethod() {
  let conditions = NSMutableDictionary()
  conditions.setValue(bundleId, forKey: kTISPropertyBundleID as String)
  // There are 2 items with kTISPropertyBundleID.
  // We've enabled the parent, which has kTISPropertyInputSourceID: org.fcitx.inputmethod.Fcitx5
  // Now we select the child, which has kTISPropertyInputSourceID: org.fcitx.inputmethod.Fcitx5.fcitx5
  conditions.setValue(inputSourceId, forKey: kTISPropertyInputSourceID as String)
  if let array = TISCreateInputSourceList(conditions, true)?.takeRetainedValue()
    as? [TISInputSource]
  {
    for inputSource in array {
      TISSelectInputSource(inputSource)
    }
  }
}

func getDate() -> String {
  let isoDateFormatter = ISO8601DateFormatter()
  if let date = isoDateFormatter.date(from: date) {
    let dateFormatter = DateFormatter()

    dateFormatter.dateStyle = .medium
    dateFormatter.timeStyle = .medium

    dateFormatter.locale = Locale.current
    return dateFormatter.string(from: date)
  }
  return "Unknown"
}

func quote(_ s: String) -> String {
  return s.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
}

func twiceQuote(_ s: String) -> String {
  let quoted = quote(s)
  return quote("\"\(quoted)\"")
}

enum InstallationState {
  case pending, installing, success
}

struct ContentView: View {
  @State private var state: InstallationState = .pending
  @State private var hasError = false
  @State private var sudoError = false
  @State private var errorMsg: String? = nil {
    didSet {
      hasError = (errorMsg != nil)
    }
  }
  @State private var logContent: String? = nil

  var body: some View {
    VStack {
      if let iconURL = Bundle.main.url(forResource: "fcitx", withExtension: "icns"),
        let icon = NSImage(contentsOf: iconURL)
      {
        Image(nsImage: icon)
          .resizable()
          .frame(width: 100, height: 100)
      }
      Text("Fcitx5 macOS").font(.system(size: 20))

      Spacer().frame(height: 10)

      if !edition.isEmpty {
        Text(edition)
        Spacer().frame(height: 5)
      }

      Button(
        action: {
          if let url = URL(
            string:
              "https://github.com/fcitx-contrib/fcitx5-macos/"
              + (releaseTag == "latest" ? "commit/" + commit : "tree/" + releaseTag)
          ) {
            NSWorkspace.shared.open(url)
          }
        },
        label: {
          Text(releaseTag == "latest" ? String(commit.prefix(7)) : releaseTag)
            .foregroundColor(.blue)
        }
      )
      .buttonStyle(PlainButtonStyle())
      .focusable(false)
      .alert(
        "Error",
        isPresented: $hasError,
        presenting: ()
      ) { _ in
        Button("OK") {
          errorMsg = nil
        }
        if !sudoError {
          Button("Copy log") {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(logContent ?? "", forType: .string)
          }
        }
      } message: { details in
        Text(errorMsg ?? "Unknown Error")
      }

      Spacer().frame(height: 5)

      Text(getDate())

      Spacer().frame(height: 50)

      Button(
        action: {
          if state == .pending {
            state = .installing
            sudoError = false
            DispatchQueue.global().async {
              let success = executeInstallScript()
              DispatchQueue.main.async {
                state = success ? .success : .pending
              }
            }
          } else {
            selectInputMethod()
            NSApplication.shared.terminate(self)
          }
        },
        label: {
          Text(state == .pending ? "Install" : state == .installing ? "Installing" : "Start typing")
            .padding()
            .padding()
        }
      )
      .controlSize(.large)
      .disabled(state == .installing)
      .background(state == .pending ? Color.blue : state == .success ? Color.green : Color.gray)
      .cornerRadius(5)
    }.toast(
      isPresenting: Binding(
        get: { state == .installing },
        set: { _ in }
      )
    ) {
      AlertToast(type: .loading)
    }
  }

  func executeInstallScript() -> Bool {
    guard let resourcesPath = Bundle.main.resourcePath else {
      print("Resources not found")
      return false
    }
    guard let scriptPath = Bundle.main.path(forResource: "install", ofType: "sh") else {
      print("install.sh not found")
      return false
    }
    let user = NSUserName()

    let script =
      "do shell script \"\(twiceQuote(scriptPath)) \(twiceQuote(user)) \(twiceQuote(resourcesPath)) 2>\(logPath)\" with administrator privileges"
    guard let appleScript = NSAppleScript(source: script) else {
      return false
    }
    var error: NSDictionary? = nil
    var sudoCanceled = false
    appleScript.executeAndReturnError(&error)
    if let error = error {
      errorMsg = error["NSAppleScriptErrorBriefMessage"] as? String ?? "Unknown Error"
      if let errno = error["NSAppleScriptErrorNumber"] as? Int {
        if errno == -128 {
          sudoCanceled = true
          DispatchQueue.main.async {
            sudoError = true
          }
        }
      }
      if !sudoCanceled {
        DispatchQueue.main.async {
          logContent = nil
          do {
            let logURL = URL(fileURLWithPath: logPath)
            let logData = try Data(contentsOf: logURL)
            if let logString = String(data: logData, encoding: .utf8) {
              logContent = logString
            }
          } catch {
            print("Error reading log file: \(error.localizedDescription)")
          }
        }
      }
      return false
    }
    return true
  }
}
