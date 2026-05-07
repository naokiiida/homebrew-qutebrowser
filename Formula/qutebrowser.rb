class Qutebrowser < Formula
  include Language::Python::Virtualenv

  desc "Keyboard-driven, vim-like browser based on Qt WebEngine (with codec support)"
  homepage "https://www.qutebrowser.org/"
  url "https://github.com/qutebrowser/qutebrowser/releases/download/v3.7.0/qutebrowser-3.7.0.tar.gz"
  sha256 "c7f95884ea5e6675e584025bea55cff950c47d749aff7f415f68da03fcce0f92"
  license "GPL-3.0-or-later"

  depends_on "libyaml"
  depends_on :macos
  depends_on "pyqt"
  depends_on "python@3.14"
  depends_on "qtwebengine"

  resource "adblock" do
    url "https://files.pythonhosted.org/packages/f2/62/f77f4ef114a74e15104675a1e0f77302aad72bcc0bfcdda867e4c24f7ffe/adblock-0.6.0.tar.gz"
    sha256 "11651e956c69b3ee571404754df665854717255b80f437e9dc323ee82b564e72"
  end

  resource "colorama" do
    url "https://files.pythonhosted.org/packages/d8/53/6f443c9a4a8358a93a6792e2acffb9d9d5cb0a5cfd8802644b7b1c9a02e4/colorama-0.4.6.tar.gz"
    sha256 "08695f5cb7ed6e0531a20572697297273c47b8cae5a63ffc6d6ed5c201be6e44"
  end

  resource "jinja2" do
    url "https://files.pythonhosted.org/packages/df/bf/f7da0350254c0ed7c72f3e33cef02e048281fec7ecec5f032d4aac52226b/jinja2-3.1.6.tar.gz"
    sha256 "0137fb05990d35f1275a587e9aee6d56da821fc83491a0fb838183be43f66d6d"
  end

  resource "markupsafe" do
    url "https://files.pythonhosted.org/packages/7e/99/7690b6d4034fffd95959cbe0c02de8deb3098cc577c67bb6a24fe5d7caa7/markupsafe-3.0.3.tar.gz"
    sha256 "722695808f4b6457b320fdc131280796bdceb04ab50fe1795cd540799ebe1698"
  end

  resource "packaging" do
    url "https://files.pythonhosted.org/packages/d7/f1/e7a6dd94a8d4a5626c03e4e99c87f241ba9e350cd9e6d75123f992427270/packaging-26.2.tar.gz"
    sha256 "ff452ff5a3e828ce110190feff1178bb1f2ea2281fa2075aadb987c2fb221661"
  end

  resource "pygments" do
    url "https://files.pythonhosted.org/packages/c3/b2/bc9c9196916376152d655522fdcebac55e66de6603a76a02bca1b6414f6c/pygments-2.20.0.tar.gz"
    sha256 "6757cd03768053ff99f3039c1a36d6c0aa0b263438fcab17520b30a303a82b5f"
  end

  resource "pyobjc-core" do
    url "https://files.pythonhosted.org/packages/b8/b6/d5612eb40be4fd5ef88c259339e6313f46ba67577a95d86c3470b951fce0/pyobjc_core-12.1.tar.gz"
    sha256 "2bb3903f5387f72422145e1466b3ac3f7f0ef2e9960afa9bcd8961c5cbf8bd21"
  end

  resource "pyobjc-framework-cocoa" do
    url "https://files.pythonhosted.org/packages/02/a3/16ca9a15e77c061a9250afbae2eae26f2e1579eb8ca9462ae2d2c71e1169/pyobjc_framework_cocoa-12.1.tar.gz"
    sha256 "5556c87db95711b985d5efdaaf01c917ddd41d148b1e52a0c66b1a2e2c5c1640"
  end

  resource "pyyaml" do
    url "https://files.pythonhosted.org/packages/05/8e/961c0007c59b8dd7729d542c61a4d537767a59645b82a0b521206e1e25c2/pyyaml-6.0.3.tar.gz"
    sha256 "d76623373421df22fb4cf8817020cbb7ef15c725b9d5e45f17e189bfc384190f"
  end

  def install
    virtualenv_install_with_resources(without: "adblock")

    # adblock is a Rust extension (Brave's adblock-rust via pyo3/maturin).
    # The sdist cannot be built from source: its Cargo dependency rmp-serde 0.13.7
    # was yanked from crates.io and it requires maturin <0.13. Install the
    # pre-built wheel instead (abi3-cp37 stable ABI, works with any Python 3.7+).
    python3 = "python3.14"
    system libexec/"bin"/python3, "-m", "pip", "install", "--no-deps",
           "--no-build-isolation", "--only-binary=:all:", "adblock==0.6.0"

    # qutebrowser's pakjoy.py looks for QtWebEngineCore resources under
    # qt_data_path/lib/QtWebEngineCore.framework/Resources, but Homebrew's
    # qtwebengine doesn't link its framework into share/qt/lib. Replace the
    # auto-generated entrypoint with a wrapper that sets the env var and
    # auto-detects Widevine CDM from installed Chromium-based browsers.
    qtwe_lib = Formula["qtwebengine"].opt_lib
    resources_path = qtwe_lib/"QtWebEngineCore.framework/Versions/A/Resources"
    (bin/"qutebrowser").unlink
    (bin/"qutebrowser").write <<~BASH
      #!/bin/bash
      export QTWEBENGINE_RESOURCES_PATH="#{resources_path}"

      # Widevine CDM auto-detection for DRM content (Netflix, Spotify, etc.)
      # Widevine is proprietary (Google) and cannot be redistributed — it must be
      # sourced from an installed Chromium-based browser at runtime.
      WIDEVINE_PATH="${QUTEBROWSER_WIDEVINE_PATH:-}"
      if [ -z "$WIDEVINE_PATH" ]; then
        widevine_search_dirs=(
          "$HOME/Library/Application Support/BraveSoftware/Brave-Browser/WidevineCdm"
          "/Applications/Google Chrome.app/Contents/Frameworks/Google Chrome Framework.framework/Versions/Current/Libraries/WidevineCdm"
          "/Applications/Google Chrome Dev.app/Contents/Frameworks/Google Chrome Framework.framework/Versions/Current/Libraries/WidevineCdm"
          "$HOME/Library/Application Support/Google/Chrome/WidevineCdm"
          "$HOME/Library/Application Support/Chromium/WidevineCdm"
        )
        for search_dir in "${widevine_search_dirs[@]}"; do
          if [ -d "$search_dir" ]; then
            found=$(find "$search_dir" -name "libwidevinecdm.dylib" -path "*mac_arm64*" 2>/dev/null | sort -V | tail -1)
            if [ -n "$found" ]; then
              WIDEVINE_PATH="$found"
              break
            fi
          fi
        done
      fi

      WIDEVINE_FLAGS=()
      if [ -n "$WIDEVINE_PATH" ]; then
        WIDEVINE_FLAGS=(--qt-flag "widevine-path=${WIDEVINE_PATH}")
      fi

      exec "#{libexec}/bin/qutebrowser" "${WIDEVINE_FLAGS[@]}" "$@"
    BASH

    # --- .app bundle ---
    app_contents = prefix/"qutebrowser.app/Contents"
    (app_contents/"MacOS").mkpath
    (app_contents/"Resources").mkpath

    # Custom icon (iOS-style globe design, generated from 1024x1024 PNG)
    tap_resources = Pathname(__FILE__).dirname.parent/"resources"
    cp tap_resources/"qutebrowser.icns", app_contents/"Resources/"

    (app_contents/"Info.plist").write <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>CFBundleDevelopmentRegion</key>
        <string>en</string>
        <key>CFBundleExecutable</key>
        <string>qutebrowser</string>
        <key>CFBundleIconFile</key>
        <string>qutebrowser</string>
        <key>CFBundleIdentifier</key>
        <string>org.qutebrowser.qutebrowser</string>
        <key>CFBundleInfoDictionaryVersion</key>
        <string>6.0</string>
        <key>CFBundleName</key>
        <string>qutebrowser</string>
        <key>CFBundlePackageType</key>
        <string>APPL</string>
        <key>CFBundleShortVersionString</key>
        <string>#{version}</string>
        <key>CFBundleVersion</key>
        <string>#{version}</string>
        <key>NSHighResolutionCapable</key>
        <true/>
        <key>NSSupportsAutomaticGraphicsSwitching</key>
        <true/>
        <key>NSRequiresAquaSystemAppearance</key>
        <false/>
        <key>CFBundleURLTypes</key>
        <array>
          <dict>
            <key>CFBundleURLName</key>
            <string>http(s) URL</string>
            <key>CFBundleURLSchemes</key>
            <array>
              <string>http</string>
              <string>https</string>
            </array>
          </dict>
          <dict>
            <key>CFBundleURLName</key>
            <string>local file URL</string>
            <key>CFBundleURLSchemes</key>
            <array>
              <string>file</string>
            </array>
          </dict>
        </array>
        <key>CFBundleDocumentTypes</key>
        <array>
          <dict>
            <key>CFBundleTypeName</key>
            <string>HTML document</string>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
            <key>LSItemContentTypes</key>
            <array><string>public.html</string></array>
          </dict>
          <dict>
            <key>CFBundleTypeName</key>
            <string>XHTML document</string>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
            <key>LSItemContentTypes</key>
            <array><string>public.xhtml</string></array>
          </dict>
          <dict>
            <key>CFBundleTypeName</key>
            <string>GIF image</string>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
            <key>LSItemContentTypes</key>
            <array><string>com.compuserve.gif</string></array>
          </dict>
          <dict>
            <key>CFBundleTypeName</key>
            <string>JPEG image</string>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
            <key>LSItemContentTypes</key>
            <array><string>public.jpeg</string></array>
          </dict>
          <dict>
            <key>CFBundleTypeName</key>
            <string>PNG image</string>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
            <key>LSItemContentTypes</key>
            <array><string>public.png</string></array>
          </dict>
          <dict>
            <key>CFBundleTypeName</key>
            <string>SVG document</string>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
            <key>LSItemContentTypes</key>
            <array><string>public.svg-image</string></array>
          </dict>
          <dict>
            <key>CFBundleTypeName</key>
            <string>Plain text document</string>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
            <key>LSItemContentTypes</key>
            <array><string>public.text</string></array>
          </dict>
          <dict>
            <key>CFBundleTypeName</key>
            <string>JavaScript script</string>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
            <key>LSItemContentTypes</key>
            <array><string>com.netscape.javascript-source</string></array>
          </dict>
          <dict>
            <key>CFBundleTypeName</key>
            <string>PDF Document</string>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
            <key>LSItemContentTypes</key>
            <array><string>com.adobe.pdf</string></array>
          </dict>
          <dict>
            <key>CFBundleTypeName</key>
            <string>MHTML document</string>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
            <key>LSItemContentTypes</key>
            <array><string>org.ietf.mhtml</string></array>
          </dict>
          <dict>
            <key>CFBundleTypeName</key>
            <string>HTML5 Audio (Ogg)</string>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
            <key>LSItemContentTypes</key>
            <array><string>org.xiph.ogg-audio</string></array>
          </dict>
          <dict>
            <key>CFBundleTypeName</key>
            <string>HTML5 Video (Ogg)</string>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
            <key>LSItemContentTypes</key>
            <array><string>org.xiph.ogv</string></array>
          </dict>
          <dict>
            <key>CFBundleTypeName</key>
            <string>HTML5 Video (WebM)</string>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
            <key>LSItemContentTypes</key>
            <array><string>org.webmproject.webm</string></array>
          </dict>
          <dict>
            <key>CFBundleTypeName</key>
            <string>WebP image</string>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
            <key>LSItemContentTypes</key>
            <array><string>org.webmproject.webp</string></array>
          </dict>
        </array>
        <key>UTImportedTypeDeclarations</key>
        <array>
          <dict>
            <key>UTTypeConformsTo</key>
            <array>
              <string>public.data</string>
              <string>public.content</string>
            </array>
            <key>UTTypeDescription</key>
            <string>MIME HTML document</string>
            <key>UTTypeIdentifier</key>
            <string>org.ietf.mhtml</string>
            <key>UTTypeTagSpecification</key>
            <dict>
              <key>com.apple.ostype</key>
              <string>MHTM</string>
              <key>public.filename-extension</key>
              <array>
                <string>mht</string>
                <string>mhtml</string>
              </array>
              <key>public.mime-type</key>
              <array>
                <string>multipart/related</string>
                <string>application/x-mimearchive</string>
              </array>
            </dict>
          </dict>
          <dict>
            <key>UTTypeConformsTo</key>
            <array><string>public.audio</string></array>
            <key>UTTypeDescription</key>
            <string>Ogg Audio</string>
            <key>UTTypeIdentifier</key>
            <string>org.xiph.ogg-audio</string>
            <key>UTTypeTagSpecification</key>
            <dict>
              <key>public.filename-extension</key>
              <array>
                <string>ogg</string>
                <string>oga</string>
              </array>
              <key>public.mime-type</key>
              <array><string>audio/ogg</string></array>
            </dict>
          </dict>
          <dict>
            <key>UTTypeConformsTo</key>
            <array><string>public.movie</string></array>
            <key>UTTypeDescription</key>
            <string>Ogg Video</string>
            <key>UTTypeIdentifier</key>
            <string>org.xiph.ogv</string>
            <key>UTTypeTagSpecification</key>
            <dict>
              <key>public.filename-extension</key>
              <array>
                <string>ogm</string>
                <string>ogv</string>
              </array>
              <key>public.mime-type</key>
              <array><string>video/ogg</string></array>
            </dict>
          </dict>
        </array>
        <key>NSCameraUsageDescription</key>
        <string>A website in qutebrowser wants to use the camera.</string>
        <key>NSMicrophoneUsageDescription</key>
        <string>A website in qutebrowser wants to use your microphone.</string>
        <key>NSLocationUsageDescription</key>
        <string>A website in qutebrowser wants to use your location information.</string>
        <key>NSBluetoothAlwaysUsageDescription</key>
        <string>A website in qutebrowser wants to access Bluetooth.</string>
      </dict>
      </plist>
    XML

    (app_contents/"MacOS/qutebrowser").write <<~BASH
      #!/bin/bash
      exec "#{opt_bin}/qutebrowser" "$@"
    BASH
    (app_contents/"MacOS/qutebrowser").chmod 0755

    # Ad-hoc codesign so macOS treats it as a proper app bundle
    system "codesign", "--force", "--deep", "--sign", "-", prefix/"qutebrowser.app"
  end

  def caveats
    <<~EOS
      qutebrowser has been installed with:
        - H.264/H.265 codec support (via Homebrew's Qt WebEngine)
        - Widevine DRM auto-detection (for Netflix, Spotify, etc.)
        - A .app bundle for Dock/Spotlight integration

      App bundle (Spotlight, Launchpad, Raycast):
        mkdir -p ~/Applications
        osascript -e 'tell application "Finder" to make alias file to POSIX file "#{opt_prefix}/qutebrowser.app" at POSIX file "'"$HOME"'/Applications"'

      Widevine DRM:
        Automatically detected from Brave, Google Chrome, or Chrome Dev.
        To specify manually:
          export QUTEBROWSER_WIDEVINE_PATH="/path/to/libwidevinecdm.dylib"

        If no Chromium-based browser is installed, download the CDM from
        a Chrome .dmg and place libwidevinecdm.dylib where the auto-detection
        can find it (~/Library/Application Support/Google/Chrome/WidevineCdm/).
    EOS
  end

  test do
    assert_match "qutebrowser", shell_output("#{bin}/qutebrowser --version", 1)
  end
end
