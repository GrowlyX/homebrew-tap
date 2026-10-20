cask "imbox" do
  version "0.1.1"
  sha256 "b699839bd782e23cf1c537c5b863cf1019d9166289a9879d9f24401b5d179abe"

  url "https://github.com/GrowlyX/imbox/releases/download/v#{version}/Imbox_#{version}_universal.dmg"
  name "Imbox"
  desc "Agent-native inbox for teams and their coding agents"
  homepage "https://github.com/GrowlyX/imbox"

  livecheck do
    url :url
    strategy :github_latest
  end

  # The bundled imbox is built with Go 1.27, which needs macOS 13 or later.
  depends_on macos: :ventura

  app "Imbox.app"
  # The CLI, server, daemon and MCP server: the app's sidecar, on your PATH.
  binary "#{appdir}/Imbox.app/Contents/MacOS/imbox"
  generate_completions_from_executable "#{appdir}/Imbox.app/Contents/MacOS/imbox",
                                       shell_parameter_format: :cobra

  # Imbox.app is ad-hoc signed, not notarized: there is no Apple Developer
  # ID behind it. Homebrew quarantines every cask download, and Gatekeeper
  # refuses to open quarantined code that Apple hasn't notarized, the app
  # and the `imbox` command alike. Installing from this tap is the trust
  # decision, so the flag is cleared before the app is moved into place.
  preflight_steps do
    run "/usr/bin/xattr", args: ["-d", "-r", "com.apple.quarantine", "{{staged_path}}/Imbox.app"]
  end

  # Upgrades run this too: the daemon's agent goes (the app starts the new
  # daemon), but "Start at login" (the Imbox agent) only goes with --zap.
  uninstall launchctl: "gg.growly.imbox.daemon",
            quit:      "gg.growly.imbox"

  zap launchctl: "Imbox",
      trash:     [
        "~/.config/imbox",
        "~/Library/Application Support/gg.growly.imbox",
        "~/Library/Caches/gg.growly.imbox",
        "~/Library/HTTPStorages/gg.growly.imbox",
        "~/Library/Logs/gg.growly.imbox",
        "~/Library/Preferences/gg.growly.imbox.plist",
        "~/Library/Saved Application State/gg.growly.imbox.savedState",
        "~/Library/WebKit/gg.growly.imbox",
      ]

  caveats <<~EOS
    Open Imbox from Applications or Spotlight; it lives in the menu bar.
    Or sign in from a terminal (--sso for single sign-on):
      imbox login https://imbox.example.com --invite <code>

    Teach your coding agents (Claude Code, Codex, Cursor, ...) to use it:
      imbox skills install

    Imbox.app is ad-hoc signed and not notarized by Apple, so this cask
    removes the quarantine flag macOS would otherwise use to block it.
    To have Gatekeeper check it instead, install the .dmg from
    https://github.com/GrowlyX/imbox/releases yourself and approve it in
    System Settings > Privacy & Security. Verify any download with:
      gh attestation verify Imbox_#{version}_universal.dmg --repo GrowlyX/imbox
  EOS
end
