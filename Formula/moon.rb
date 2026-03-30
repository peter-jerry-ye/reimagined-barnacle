class Moon < Formula
  desc "MoonBit build system and package manager"
  homepage "https://www.moonbitlang.com"
  url "https://cli.moonbitlang.com/install/unix.sh"
  version "latest"
  sha256 "2ef9218b787037880737337a06dc99287be6db07517d2815841b26b770637350"
  license "AGPL-3.0-or-later"

  def install
    libexec.install "unix.sh" => "install-unix.sh"

    moon_home = var/"moon"

    # Bootstrap the toolchain using the official installer into Homebrew-managed var.
    system({ "MOON_HOME" => moon_home.to_s }, "bash", libexec/"install-unix.sh", "latest")

    wrappers = %w[
      moon
      moonc
      moonrun
      mooncake
      moondoc
      moonfmt
      mooninfo
      moon-ide
      moon-lsp
      moonbit-lsp
      moon_cove_report
    ]

    wrappers.each do |name|
      (bin/name).write <<~SH
        #!/bin/bash
        export MOON_HOME="${MOON_HOME:-#{moon_home}}"
        exec "${MOON_HOME}/bin/#{name}" "$@"
      SH
      chmod 0755, bin/name
    end
  end

  def caveats
    <<~EOS
      MoonBit toolchain files are installed into:
        #{var}/moon

      You can override this at runtime with:
        export MOON_HOME=/path/to/another/moon-home
    EOS
  end

  test do
    assert_match "moon", shell_output("#{bin}/moon version")
  end
end
