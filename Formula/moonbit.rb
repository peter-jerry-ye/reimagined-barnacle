class Moonbit < Formula
  desc "Build system and package manager for the MoonBit language"
  homepage "https://www.moonbitlang.com"
  version "0.8.4+4d98d95d4"

  on_macos do
    url "https://cli.moonbitlang.com/binaries/0.8.4%2B4d98d95d4/moonbit-darwin-aarch64.tar.gz"
    sha256 "f2adfbdfbf51e0d65788862ba0160390c0fbb0a4914bb4fc3e93de2768ce8e6c"
    depends_on arch: :arm64
  end

  on_linux do
    url "https://cli.moonbitlang.com/binaries/0.8.4%2B4d98d95d4/moonbit-linux-x86_64.tar.gz"
    sha256 "4d9f811fce8b10de29292f1b7606b8acf2adf0e84d42ea62ace8ca8600783c84"
    depends_on arch: :x86_64
  end

  resource "core" do
    url "https://cli.moonbitlang.com/cores/core-0.8.4%2B4d98d95d4.tar.gz"
    sha256 "1900367fef9d09f1e7dc6b0a5226daaf8ceaecaa84d0e3fa2bb66b0aba47f139"
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
        export MOON_CORE_OVERRIDE="#{opt_libexec}/lib/core"
        exec "#{opt_libexec}/bin/#{name}" "$@"
      SH
      chmod 0755, bin/name
    end
  end

  def caveats
    <<~EOS
      This package installs MoonBit binaries and the bundled core under:
        #{opt_libexec}

      Mutable user data stays outside the package and continues to use Moon's
      normal per-user locations (for example `~/.moon`) unless you override
      them explicitly.
    EOS
  end

  test do
    assert_match "v0.8.4+4d98d95d4", shell_output("#{bin}/moonc -v")
    assert_path_exists libexec/"lib/core"
  end
end
