---
name: Bug Report
about: Report a bug in the Jyotish library
title: "[BUG] "
labels: bug
assignees: ""
---

**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:

1. Initialize library with '...'
2. Call method '...'
3. See error

**Expected behavior**
A clear and concise description of what you expected to happen.

**Code sample**

```dart
// Minimal code sample that reproduces the issue
final jyotish = Jyotish();
await jyotish.initialize();
// ... your code
```

**Error message**

```
// Paste the full error message here
```

**Environment (please complete the following information):**

- OS: [e.g. Android, iOS, macOS, Windows, Linux]
- Flutter version: [e.g. 3.16.0]
- Dart version: [e.g. 3.2.0]
- Library version: [e.g. v1.0.0 or commit hash]

**Swiss Ephemeris Setup:**

- [ ] Using bundled ephemeris data
- [ ] Using custom ephemeris data files
- [ ] Ephemeris path: [if using custom files]

**Additional context**
Add any other context about the problem here, such as:

- Does it happen with specific dates/locations?
- Is it related to certain planets or calculations?
- Does it work in debug but fail in release builds?
