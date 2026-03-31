class Moonbit < Formula
  desc "Build system and package manager for the MoonBit language"
  homepage "https://www.moonbitlang.com"
  version "v0.8.4+4d98d95d4"
  url "git@github.com:peter-jerry-ye/reimagined-barnacle.git",
      tag: "v0.8.4+4d98d95d4",
      revision: "e35b37aa5019b691333ec065027d232ac73ff520",
      using: :git
  depends_on arch: :arm64

  def install
    odie "moonbit currently supports macOS only" unless OS.mac?
    odie "moonbit currently supports macOS arm64 only" unless Hardware::CPU.arm?

    artifact_dir = buildpath/"Artifacts"/"v0.8.4+4d98d95d4"
    mkdir_p libexec/"lib"
    system "tar", "xzf", artifact_dir/"moonbit-darwin-aarch64.tar.gz", "-C", libexec
    system "tar", "xzf", artifact_dir/"core-v0.8.4+4d98d95d4.tar.gz", "-C", libexec/"lib"

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
