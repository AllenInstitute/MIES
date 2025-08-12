[![GitHub release (latest by date)](https://img.shields.io/github/v/release/AllenInstitute/MIES?style=plastic)](https://github.com/AllenInstitute/MIES/releases)
[![Build Main](https://github.com/AllenInstitute/MIES/actions/workflows/build-release.yml/badge.svg?branch=main)](https://github.com/AllenInstitute/MIES/actions/workflows/build-release.yml)
[![Documentation](https://img.shields.io/badge/docs-doxygen%2Fbreathe%2Fsphinx-blue.svg?style=plastic)](https://alleninstitute.github.io/MIES/user.html)
[![Signed Installer](https://img.shields.io/badge/Signed%20Installer-Yes-success?style=plastic)](https://alleninstitute.github.io/MIES/developers.html#signed-installer)
[![Coverage](https://byte-physics.de/public-downloads/aistorage/transfer/report/coverage/badge_combined.svg)](https://byte-physics.de/public-downloads/aistorage/transfer/report/coverage/)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit)](https://github.com/pre-commit/pre-commit)
[![GitHub contributors](https://img.shields.io/github/contributors/AllenInstitute/MIES?style=plastic)](https://github.com/AllenInstitute/MIES/graphs/contributors)

## Multichannel Igor Electrophysiology Suite

The Multichannel Igor Electrophysiology Suite (MIES) is a proven sweep based data acquisition
software package for [intracellular electrophysiology](https://en.wikipedia.org/wiki/Electrophysiology#Intracellular_recording) (patch clamp) \[[1](https://www.science.org/stoken/author-tokens/ST-374/full),
[2](https://doi.org/10.1038/s41586-021-03813-8),
[3](https://doi.org/10.1038/s41593-019-0417-0),
[4](https://elifesciences.org/articles/37349),
[5](https://doi.org/10.1038/s41586-021-03813-8),
[6](https://doi.org/10.7554/eLife.65482)\].
It offers top of its class flexibility and robustness for stimulus generation, data
acquisition, and analysis.

## Highlights

- Run up to five DACs in parallel for scalable data acquisition.
- Acquire data on up to eight headstage on a single DAC to probe up to 56 connections at once.
- Create arbitrarily complex stimulus sets with an intuitive GUI.
- Export all data, including all of its metadata, into the industry-standard [NWBv2-format](https://doi.org/10.1101/523035) and read it back in
- Run custom code during data acquisition for Automatic Experiment Control and real-time adaptability.
- Automate experimental setup using configuration files for streamlined workflows.
- Interact with MIES from other programming languages (Python, C++, Javascript, ...) through [ZeroMQ](https://zeromq.org/).
- Track and manage your experiments with comprehensive metadata acquisition and browsing tools.
- Leverage the integrated scripting language for flexible, on-the-fly electrophysiology data evaluation.
- Ensure compatibility with every earlier version of MIES, protecting your previous work and workflows.

## Getting started

- Download the [latest release](https://github.com/AllenInstitute/MIES/releases/tag/latest)
- Windows: Run the installer
- MacOSX (analysis only): [Manual installation](https://alleninstitute.github.io/MIES/installation.html#manual-installation)
- View the [documentation](https://alleninstitute.github.io/MIES/user.html)

### Brief visual overview

![Slideshow showing the main graphical user interfaces of MIES in Igor Pro](Packages/Artwork/readme-teaser.gif)

### Postsynaptic data analysis

[![Demonstration of postsynaptic data analysis](https://img.youtube.com/vi/O2WxPzBsEfc/0.jpg)](https://www.youtube.com/watch?v=O2WxPzBsEfc)

Video tutorial of the postsynaptic potential/postsynaptic current data (PSX) analysis module

## Required Software

- [Igor Pro 9 (nightly) or later](https://alleninstitute.github.io/MIES/installation.html#igor-pro-update-nightly)

### For Data Analysis

- Windows 10 64-bit or MacOSX 10.10

### For Data Acquisition

- Windows 10 64-bit
- [NIDAQ MX XOP](https://www.wavemetrics.com/products/nidaqtools/nidaqtools.htm)

## Supported Hardware

- Digital to analog converters (DAC):
  - National Instruments:
    - [PCIe-6341](https://www.ni.com/de-de/support/model.pcie-6341.html)
    - [PCIe-6343](https://www.ni.com/en-us/support/model.pcie-6343.html)
    - [PXI-6259](https://www.ni.com/en-us/support/model.pxi-6259.html)
    - [USB-6346](https://www.ni.com/de-de/support/model.usb-6346.html)

      Other NI hardware models can be added on request. Please open an issue from within MIES,
  `MIES Panels->Report an issue`, for that.

  Better results are obtained if your hardware's analog input channels support Referenced Single Ended (RSE)
  Terminal Configuration, but Differential is also supported as a fallback. See also
  [this](https://knowledge.ni.com/KnowledgeArticleDetails?id=kA00Z0000019QRZSA2) article from NI Support.

  - Instrutech/HEKA ITC:
    - [16](http://www.heka.com/downloads/hardware/manual/itc16.pdf)
    - [18](http://www.heka.com/downloads/hardware/manual/m_itc18.pdf)
    - [1600](http://www.heka.com/downloads/hardware/manual/m_itc1600.pdf)

     ITC devices are at the End-Of-Service-Life (EOSL). National Instruments DACs are recommended for MIES users looking for new hardware.

- Amplifier: Molecular Devices [700B](https://www.moleculardevices.com/products/axon-patch-clamp-system/amplifiers/axon-instruments-patch-clamp-amplifiers)
- Pressure control (optional):
  - [QPV High Resolution Pressure Regulator](https://proportionair.com/product/qpv/) from Proportion-Air, Inc.; Part name: QPV regulator (custom, see part No), -10 psi to +10 psi; Part no.: QPV1TBNEEN10P10PSGAXLDD
  - controlled through ITC 18/1600 or National Instruments [USB 6001](https://www.ni.com/en-us/support/model.usb-6001.html)

## Support statement

The last released version receives fixes for all critical bugs.

## Bug reporting

[Report a Bug](https://alleninstitute.github.io/MIES/reportingbugs.html)
