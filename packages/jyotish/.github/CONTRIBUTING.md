# Contributing to Jyotish

Thank you for your interest in contributing to the Jyotish Flutter library! This document provides guidelines for contributing to this Vedic astrology library.

## How to Contribute

### Reporting Bugs

1. **Check existing issues** first to avoid duplicates
2. **Use the bug report template** when creating a new issue
3. **Include minimal reproduction code** that demonstrates the problem
4. **Specify your environment** (OS, Flutter version, etc.)

### Requesting Features

1. **Use the feature request template** for new feature ideas
2. **Explain the Vedic astrology use case** you're trying to solve
3. **Reference traditional sources** if applicable
4. **Consider implementation complexity** and compatibility

### Contributing Code

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/amazing-feature`)
3. **Write tests** for your new functionality
4. **Ensure all tests pass** (`flutter test`)
5. **Follow the existing code style** (`dart format .`)
6. **Update documentation** if needed
7. **Create a pull request**

## Development Setup

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Swiss Ephemeris library (see SETUP.md)

### Getting Started

```bash
# Clone the repository
git clone https://github.com/rajsanjib/jyotish-flutter-library.git
cd jyotish-flutter-library

# Get dependencies
flutter pub get

# Run tests
flutter test

# Run the example app
cd example
flutter run
```

### Swiss Ephemeris Setup

Follow the instructions in `SETUP.md` to compile and install the Swiss Ephemeris library for your platform.

## Code Guidelines

### Code Style

- Use `dart format .` to format code
- Follow Dart naming conventions
- Write descriptive commit messages
- Add documentation comments for public APIs

### Testing

- Write unit tests for all new functionality
- Test with real astronomical data when possible
- Include integration tests for Swiss Ephemeris calculations
- Verify accuracy against known ephemeris values

### Documentation

- Update README.md for significant changes
- Add examples for new features
- Document any breaking changes in CHANGELOG.md
- Include Vedic astrology references where relevant

## Vedic Astrology Guidelines

### Accuracy Requirements

- All calculations must use **sidereal zodiac** (not tropical)
- Default to **Lahiri ayanamsa** unless specified otherwise
- Verify calculations against traditional sources
- Include references to classical texts when possible

### Traditional Sources

When implementing new features, consider referencing:

- **Brihat Parashara Hora Shastra** - Classical foundational text
- **Saravali** by Kalyana Varma - Comprehensive classical work
- **Jataka Parijata** - Classical text on birth chart interpretation
- **Modern authorities** like B.V. Raman, K.S. Krishnamurti

### Supported Calculations

Current scope includes:

- ✅ Planetary positions (9 planets + Rahu/Ketu)
- ✅ House cusps and Ascendant
- ✅ Nakshatras and padas
- ✅ Planetary dignities
- ✅ Combustion detection

Future scope may include:

- 🔄 Dasha (planetary periods)
- 🔄 Transits and predictions
- 🔄 Divisional charts (Navamsa, etc.)
- 🔄 Ashtakavarga
- 🔄 Yoga detection

## Pull Request Process

1. **Create descriptive PR title** and description
2. **Link related issues** using "Fixes #123" syntax
3. **Ensure CI passes** (tests, analysis, formatting)
4. **Request review** from maintainers
5. **Address feedback** promptly
6. **Squash commits** if requested before merging

## Code Review Criteria

Reviewers will check for:

- **Correctness**: Do calculations match Vedic astrology principles?
- **Accuracy**: Are results verified against known values?
- **Testing**: Are there adequate tests with good coverage?
- **Documentation**: Is the code well-documented?
- **Performance**: Are calculations efficient?
- **Compatibility**: Does it work across supported platforms?

## Questions or Help?

- **Library usage questions**: Create a GitHub Discussion
- **Bug reports**: Use the bug report template
- **Feature requests**: Use the feature request template
- **Security issues**: Email maintainers directly

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Recognition

Contributors will be acknowledged in:

- CHANGELOG.md for significant contributions
- README.md contributors section
- GitHub repository insights

Thank you for helping make Vedic astrology calculations accessible to Flutter developers! 🙏
