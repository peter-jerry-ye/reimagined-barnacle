#!/bin/bash

set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

binary_channel_url="https://cli.moonbitlang.com/binaries/nightly/moonbit-darwin-aarch64.tar.gz"
core_channel_url="https://cli.moonbitlang.com/cores/core-nightly.tar.gz"

binary_archive="$work_dir/moonbit.tar.gz"
core_archive="$work_dir/core.tar.gz"

curl -fsSL "$binary_channel_url" -o "$binary_archive"
curl -fsSL "$core_channel_url" -o "$core_archive"

tar -xzf "$binary_archive" -C "$work_dir"
chmod +x "$work_dir"/bin/* \
  "$work_dir"/bin/internal/tcc \
  "$work_dir"/bin/internal/moon-pilot/entrypoint.bash \
  "$work_dir"/bin/internal/moon-pilot/bin/* 2>/dev/null || true

raw_version=$("$work_dir/bin/moonc" -v | head -1)
version=$(printf '%s\n' "$raw_version" | sed -E 's/^v([^ ]+).*/\1/')
encoded_version=${version//+/%2B}
binary_sha=$(shasum -a 256 "$binary_archive" | awk '{print $1}')
core_sha=$(shasum -a 256 "$core_archive" | awk '{print $1}')

cat > "$repo_root/Formula/moonbit-nightly.rb" <<EOF
class MoonbitNightly < Formula
  desc "Build system and package manager for the MoonBit language (nightly)"
  homepage "https://www.moonbitlang.com"
  url "https://cli.moonbitlang.com/binaries/${encoded_version}/moonbit-darwin-aarch64.tar.gz"
  version "${version}"
  sha256 "${binary_sha}"
  depends_on arch: :arm64
  keg_only "it conflicts with moonbit"

  resource "core" do
    url "https://cli.moonbitlang.com/cores/core-${encoded_version}.tar.gz"
    sha256 "${core_sha}"
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
        exec "#{opt_libexec}/bin/#{name}" "\$@"
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
EOF

printf 'Updated moonbit-nightly to %s\n' "$version"
