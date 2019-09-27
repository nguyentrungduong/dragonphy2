# DragonPHY

[![Build status](https://badge.buildkite.com/df233a0a276c870f908484cdf1e94db22868edd69514c7a977.svg?branch=master)](https://buildkite.com/stanford-aha/dragonphy)

DragonPHY is the second design in the Open Source PHY project at Stanford.

## Installation

1. Clone the repository.
```shell
> git clone https://github.com/StanfordVLSI/dragonphy.git
```
2. Go into the top-level folder
```shell
> cd dragonphy
```
3. Install the Python package associated with this project.
```shell
> pip install -e .
```

## Upgrading

To upgrade to the latest version of DragonPHY:
1. Pull changes from the **master** branch.
```shell
> git pull origin master
```
2. Re-install the Python package (since dependencies may have changed):
```shell
> pip install -e .
```

## Running tests

1. First install **pytest** if it is not already installed:
```shell
> pip install pytest
```
2. Then, in the top directory of the project, run the tests in the **tests** directory:
```shell
> pytest tests
```