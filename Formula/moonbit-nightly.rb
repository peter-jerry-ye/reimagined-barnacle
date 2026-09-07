class MoonbitNightly < Formula
  desc "Build system and package manager for the MoonBit language (nightly)"
  homepage "https://www.moonbitlang.com"
  version "0.10.12+8a549c039-nightly"
  keg_only "it conflicts with moonbit"

  on_macos do
    url "https://cli.moonbitlang.com/binaries/0.10.12%2B8a549c039-nightly/moonbit-darwin-aarch64.tar.gz"
    sha256 "ea99bacd4a61c8a10b5a8b89964a34a1129da8f33ab20a3d3bda06a3b81f4eb5"
    depends_on arch: :arm64
  end

  on_linux do
    url "https://cli.moonbitlang.com/binaries/0.10.12%2B8a549c039-nightly/moonbit-linux-x86_64.tar.gz"
    sha256 "86bca50210ce43ec1363e9f3a6708cee17122e9a96bb4044a0b2f1b89ef89099"
    depends_on arch: :x86_64
  end

  resource "core" do
    url "https://cli.moonbitlang.com/cores/core-0.10.12%2B8a549c039-nightly.tar.gz"
    sha256 "3d93b38d5c25059f353a319646d994074fc2550447002a8f38ab4783261ef057"
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
