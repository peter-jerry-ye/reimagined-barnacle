class MoonbitNightly < Formula
  desc "Build system and package manager for the MoonBit language (nightly)"
  homepage "https://www.moonbitlang.com"
  url "https://cli.moonbitlang.com/binaries/0.8.4%2B99d7fb8c8-nightly/moonbit-darwin-aarch64.tar.gz"
  version "0.8.4+99d7fb8c8-nightly"
  sha256 "ca6437d00c552f355f0a0e1bea6a16acb2e7f1f19bd973088de4c14f37c9a69e"
  depends_on arch: :arm64
  keg_only "it conflicts with moonbit"

  resource "core" do
    url "https://cli.moonbitlang.com/cores/core-0.8.4%2B99d7fb8c8-nightly.tar.gz"
    sha256 "1d555117e70b395a7ed208b976f77f934ebac2b933bed1414b892890ef7dc96c"
  end

  def install
    odie "moonbit currently supports macOS only" unless OS.mac?
    odie "moonbit currently supports macOS arm64 only" unless Hardware::CPU.arm?

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
        if [[ -z "${MOON_TOOLCHAIN_ROOT:-}" ]]; then
          export MOON_TOOLCHAIN_ROOT="#{opt_libexec}"
        fi
        if [[ -z "${MOON_CORE_OVERRIDE:-}" ]]; then
          export MOON_CORE_OVERRIDE="#{opt_libexec}/lib/core"
        fi
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
