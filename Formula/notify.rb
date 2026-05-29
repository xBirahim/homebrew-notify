class Notify < Formula
  desc "Send and manage native macOS notifications from the command line"
  homepage "https://github.com/xBirahim/notify"
  url "https://github.com/xBirahim/notify/archive/refs/tags/v0.2.0.tar.gz"
  sha256 "sha256:eb63bf8d69c1dcc1d28459c9ee70d07eb1184515ecd6b6e52b0f3f6ea11f9015"
  license "MIT"
  head "https://github.com/xBirahim/notify.git", branch: "main"

  depends_on :macos => :ventura
  depends_on xcode: ["16.0", :build]

  def install
    system "swift", "build", "-c", "release", "--disable-sandbox"

    bundle_macos = prefix/"Notify.app/Contents/MacOS"
    bundle_macos.mkpath
    cp ".build/release/notify", bundle_macos/"notify"
    chmod 0755, bundle_macos/"notify"

    (prefix/"Notify.app/Contents/Info.plist").write <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
          "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>CFBundleExecutable</key>    <string>notify</string>
        <key>CFBundleIdentifier</key>   <string>io.notify.app</string>
        <key>CFBundleName</key>         <string>Notify</string>
        <key>CFBundlePackageType</key>  <string>APPL</string>
        <key>CFBundleShortVersionString</key> <string>#{version}</string>
        <key>CFBundleVersion</key>      <string>1</string>
        <key>NSUserNotificationAlertStyle</key> <string>alert</string>
      </dict>
      </plist>
    XML

    system "codesign", "-s", "-", "--force", "--deep", "#{prefix}/Notify.app"

    (bin/"notify").write <<~SH
      #!/bin/sh
      exec "#{prefix}/Notify.app/Contents/MacOS/notify" "$@"
    SH
    chmod 0755, bin/"notify"
  end

  def caveats
    <<~EOS
      Grant notification permission before first use:
        notify request-permission --sound --badge

      The app bundle is at: #{prefix}/Notify.app
    EOS
  end

  test do
    assert_predicate prefix/"Notify.app/Contents/MacOS/notify", :executable?
    assert_predicate prefix/"Notify.app/Contents/Info.plist",   :file?
    assert_predicate bin/"notify", :executable?
    bundle_id = shell_output(
      "defaults read #{prefix}/Notify.app/Contents/Info.plist CFBundleIdentifier"
    ).strip
    assert_equal "io.notify.app", bundle_id
  end
end
