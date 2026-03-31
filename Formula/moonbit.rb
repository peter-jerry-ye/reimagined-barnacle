class Moonbit < Formula
  desc "MoonBit build system and package manager"
  homepage "https://www.moonbitlang.com"
  url "https://cli.moonbitlang.com/binaries/latest/moonbit-darwin-aarch64.tar.gz"
  version "latest"
  sha256 "f2adfbdfbf51e0d65788862ba0160390c0fbb0a4914bb4fc3e93de2768ce8e6c"
  license "AGPL-3.0-or-later"

  depends_on arch: :arm64

  resource "core" do
    url "https://cli.moonbitlang.com/cores/core-latest.tar.gz"
    sha256 "1900367fef9d09f1e7dc6b0a5226daaf8ceaecaa84d0e3fa2bb66b0aba47f139"
  end

  def install
    odie "moonbit currently supports macOS arm64 only" unless OS.mac? && Hardware::CPU.arm?

    libexec.install "bin", "lib", "include", "CREDITS.md"

    resource("core").stage do
      mkdir_p libexec/"lib/core"
      cp_r Dir["*"], libexec/"lib/core"
    end

    ENV.prepend_path "PATH", libexec/"bin"
    system libexec/"bin/moon", "-C", libexec/"lib/core", "bundle", "--warn-list", "-a", "--all"
    system libexec/"bin/moon", "-C", libexec/"lib/core", "bundle", "--warn-list", "-a", "--target", "wasm-gc", "--quiet"

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
    assert_match "moon", shell_output("#{bin}/moon version")
    assert_predicate libexec/"lib/core", :exist?
  end
end
