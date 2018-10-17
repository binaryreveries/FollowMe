# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- Make road based on player position and angle.

### Changed
- Draw ordering to ensure player sprite is not color of bounding box.

## [0.2.5] - 2018-10-02
### Changed
- Windows packaging procedure to unzip LÖVE before `cat`ing with game package.

## [0.2.4] - 2018-10-01
### Added
- This changelog to track the project as it evolves.

## [0.2.3] - 2018-09-27
### Added
- Deployment of fully built binaries for Windows and macOS as well as LÖVE
  package to GitHub Releases on each tag.

## [0.2.2] - 2018-09-23
### Added
- Drag and drop support for changing player sprite.
- Friction between player and driving surface.
- Speed-o-meter (broken)
- `conf.lua` which informs LÖVE of the minimal compatible version supported.
- Bounding box drawing for collison debugging.

### Changed
- Improve handling by adding torque to turning.
- Wrap left and right edges of world.

### Removed
- Commented and unused code.

## [0.2.1] - 2018-09-16
### Added
- Borders at top and bottom world boundaries.

## [0.2.0] - 2018-09-14
### Added
- Continuous integration supported by [TravisCI](https://travis-ci.org).
- Basic block obstacle.

### Changed
- Replace existing Unity3D game with version made with LÖVE.

### Removed
- Road building functionality until it can be reimplemented.

## [0.1.0] - 2018-09-13
### Added
- Hello World unity project.
- Basic road building functionality.

[Unreleased]: https://github.com/binaryreveries/FollowMe/compare/v0.2.5...HEAD
[0.2.5]: https://github.com/binaryreveries/FollowMe/compare/v0.2.4...v0.2.5
[0.2.4]: https://github.com/binaryreveries/FollowMe/compare/v0.2.3...v0.2.4
[0.2.3]: https://github.com/binaryreveries/FollowMe/compare/v0.2.2...v0.2.3
[0.2.2]: https://github.com/binaryreveries/FollowMe/compare/v0.2.1...v0.2.2
[0.2.1]: https://github.com/binaryreveries/FollowMe/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/binaryreveries/FollowMe/compare/v0.1.0...v0.2.0