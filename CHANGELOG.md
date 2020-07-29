# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.2.0]
### Added
- Allow extra_fields to be invoked with job (#16)

## [1.1.0]
### Added
- Honeycomb beeline support (#9)

## [1.0.0]
### Added
- CODE_OF_CONDUCT.md
- CONTRIBUTORS.txt

### Fixed
- Tidied up README.md

## [0.3.1]
### Fixed
- Ensure that `Honeykiq::ServerMiddleware#extra_fields` are still included after a job fails

## [0.3.0]
### Added
- `Honeykiq::ServerMiddleware#extra_fields` so you can add custom fields to an event

## [0.2.0]
### Added
- `Honeykiq::ServerMiddleware` 🙌

### Removed
- `Honeykiq.periodic_reporter`. (Use `Honeykiq::PeriodicReporter.new` instead.)

[Unreleased]: https://github.com/carwow/honeykiq/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/carwow/honeykiq/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/carwow/honeykiq/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/carwow/honeykiq/compare/v0.3.1...v1.0.0
[0.3.1]: https://github.com/carwow/honeykiq/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/carwow/honeykiq/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/carwow/honeykiq/compare/v0.1.0...v0.2.0
