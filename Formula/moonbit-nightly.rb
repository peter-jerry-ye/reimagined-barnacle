class MoonbitNightly < Formula
  desc "Build system and package manager for the MoonBit language (nightly)"
  homepage "https://www.moonbitlang.com"
  version "0.10.4+4f2e8f7dc-nightly"
  keg_only "it conflicts with moonbit"

  on_macos do
    url "https://cli.moonbitlang.com/binaries/0.10.4%2B4f2e8f7dc-nightly/moonbit-darwin-aarch64.tar.gz"
    sha256 "f633684bcfeea779e2cce9dbb2ebc0d97c7f7541313d5ee804fc517e4844a71b"
    depends_on arch: :arm64
  end

  on_linux do
    url "https://cli.moonbitlang.com/binaries/0.10.4%2B4f2e8f7dc-nightly/moonbit-linux-x86_64.tar.gz"
    sha256 "adee41659574235a05b3e0309ce449d7714c0e6ced6ae0e16c95f0da73c71d8d"
    depends_on arch: :x86_64
  end

  resource "core" do
    url "https://cli.moonbitlang.com/cores/core-0.10.4%2B4f2e8f7dc-nightly.tar.gz"
    sha256 "83df986c4c565abde2dcec2899b713ed800dc85acf48650909c253e2d7f15d8f"
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
