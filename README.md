# reimagined-barnacle (temporary tap)

Temporary Homebrew tap for MoonBit binary distribution on macOS arm64.

Install:

```bash
brew tap --custom-remote peter-jerry-ye/reimagined-barnacle git@github.com:peter-jerry-ye/reimagined-barnacle.git
brew install peter-jerry-ye/reimagined-barnacle/moonbit
```

This package installs the `moon` executable and bundled core files directly
from versioned upstream release artifacts. It does not run the upstream shell
installer.
