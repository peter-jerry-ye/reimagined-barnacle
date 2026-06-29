class MoonbitNightly < Formula
  desc "Build system and package manager for the MoonBit language (nightly)"
  homepage "https://www.moonbitlang.com"
  version "0.10.2+b172f0c83-nightly"
  keg_only "it conflicts with moonbit"

  on_macos do
    url "https://cli.moonbitlang.com/binaries/0.10.2%2Bb172f0c83-nightly/moonbit-darwin-aarch64.tar.gz"
    sha256 "5a44695559902ba7dc803ec01245bb298e2236de8d91f394cc53075aad4588db"
    depends_on arch: :arm64
  end

  on_linux do
    url "https://cli.moonbitlang.com/binaries/0.10.2%2Bb172f0c83-nightly/moonbit-linux-x86_64.tar.gz"
    sha256 "ce061ee75a8d6d95f365aee325dd06a78c5778e1f6859d6aa5d1e081a9f9c2cb"
    depends_on arch: :x86_64
  end

  resource "core" do
    url "https://cli.moonbitlang.com/cores/core-0.10.2%2Bb172f0c83-nightly.tar.gz"
    sha256 "9d472c73f09161d0fa863bd63598017dbece431099968de2d9064cd223f31ced"
  end

  def install
    odie "moonbit currently supports macOS arm64 and Linux x86_64 only" unless OS.mac? || OS.linux?
    odie "moonbit currently supports macOS arm64 only" if OS.mac? && !Hardware::CPU.arm?
    odie "moonbit currently supports Linux x86_64 only" if OS.linux? && !Hardware::CPU.intel?

    libexec.install "bin", "lib", "include", "CREDITS.md"

    resource("core").fetch
    system "tar", "xzf", resource("core").cached_download, "-C", libexec/"lib"

    chmod 0755, Dir[libexec/"bin/*"]
    chmod 0755, libexec/"bin/internal/tcc"
    chmod 0755, libexec/"bin/internal/moon-pilot/entrypoint.bash"
    chmod 0755, Dir[libexec/"bin/internal/moon-pilot/bin/*"]

    ENV.prepend_path "PATH", libexec/"bin"
    system libexec/"bin/moon", "-C", libexec/"lib/core", "bundle", "--warn-list", "-a", "--all"
    system libexec/"bin/moon", "-C", libexec/"lib/core", "bundle",
           "--warn-list", "-a", "--target", "llvm"
    system libexec/"bin/moon", "-C", libexec/"lib/core", "bundle",
           "--warn-list", "-a", "--target", "wasm-gc", "--quiet"

    wrappers = %w[
      moon
      moonc
      moonrun
      mooncake
      moondoc
      moonfmt
      mooninfo
      moon-ide
      moonbit-lsp
      moon_cove_report
      moon-wasm-opt
      moon-pilot
    ]

    wrappers.each do |name|
      (bin/name).write <<~SH
        #!/bin/bash
        exec "#{opt_libexec}/bin/#{name}" "$@"
      SH
      chmod 0755, bin/name
    end
  end

  def caveats
    <<~EOS
      This formula is keg-only, so Homebrew does not link it into:
        #{HOMEBREW_PREFIX}/bin

      Stable moonbit can stay installed and linked while this nightly is
      installed side-by-side. Use the nightly explicitly via:
        #{opt_bin}/moon

      To temporarily make nightly the default in Homebrew's prefix:
        brew unlink moonbit
        brew link --force moonbit-nightly
    EOS
  end

  test do
    assert_match "v#{version}", shell_output("#{bin}/moonc -v")
    assert_path_exists libexec/"lib/core"
  end
end
