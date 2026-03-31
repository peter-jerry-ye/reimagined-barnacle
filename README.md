# reimagined-barnacle (temporary tap)

Temporary Homebrew tap for MoonBit binary distribution on macOS arm64.

Install:

```bash
brew tap --custom-remote peter-jerry-ye/reimagined-barnacle git@github.com:peter-jerry-ye/reimagined-barnacle.git
brew install peter-jerry-ye/reimagined-barnacle/moonbit
```

Install nightly side-by-side:

```bash
brew install peter-jerry-ye/reimagined-barnacle/moonbit-nightly
```

`moonbit-nightly` is keg-only, so it can coexist with `moonbit` without
overwriting the linked `moon` binaries in Homebrew's prefix. Use it explicitly
via:

```bash
$(brew --prefix moonbit-nightly)/bin/moon version
```

or switch the linked Homebrew version temporarily:

```bash
brew unlink moonbit
brew link --force moonbit-nightly
```

This package installs the `moon` executable and bundled core files directly
from versioned upstream release artifacts. It does not run the upstream shell
installer.
