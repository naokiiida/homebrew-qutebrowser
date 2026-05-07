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
    # auto-generated entrypoint with a wrapper that sets the env var.
    resources_path = Formula["qtwebengine"].opt_lib/
      "QtWebEngineCore.framework/Versions/A/Resources"
    (bin/"qutebrowser").unlink
    (bin/"qutebrowser").write <<~BASH
      #!/bin/bash
      export QTWEBENGINE_RESOURCES_PATH="#{resources_path}"
      exec "#{libexec}/bin/qutebrowser" "$@"
    BASH
  end

  def caveats
    <<~EOS
      This formula installs qutebrowser as a CLI command.
      It uses Homebrew's Qt WebEngine which includes H.264/H.265 codec support.

      To launch:
        qutebrowser

      Note: This is a CLI-only install. A .app bundle for Dock/Spotlight
      integration is planned for a future release.
    EOS
  end

  test do
    assert_match "qutebrowser", shell_output("#{bin}/qutebrowser --version", 1)
  end
end
