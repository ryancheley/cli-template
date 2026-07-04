# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0]

### Added

- Example CLI (`hello` command) built on click and rich, with `--version`,
  `--help`, shell completion, and meaningful exit codes.
- Full quality toolchain: ruff (lint + format), ty, zizmor, prek hooks,
  pytest with randomized order and an enforced 80% branch-coverage floor.
- justfile interface covering setup, quality, test, build, cli, dev, git,
  release, and docs recipes.
- Guarded `just release` flow with pre-flight checks, rollback recipe, and a
  tag-triggered PyPI trusted-publishing workflow.
