![playnub_banner](https://github.com/user-attachments/assets/12446139-e68c-4d22-88d3-b92bc0ccedd1)

<h1 align="center">Playnub</h1>

<p align="center">
  A kit of game development tools for Godot 4.x!
</p>

<p align="center">
  <a href="https://godotengine.org/download/" target="_blank" style="text-decoration:none"><img alt="Godot 4.3+" src="https://img.shields.io/badge/Godot-4.3+-%23478cbf?labelColor=CFC9C8&color=49A9B4" /></a>
</p>

## Table of Contents
- [About](#about)
- [Version](#version)
- [Installation](#installation)
- [License](#license)

## About

### What is Playnub?
The Playnub plugin is a collection of many general-purpose game development patterns, techniques, and tricks drawn from academia and online resources, as both a tool and a guide for creating games effectively and efficiently. Playnub is designed to expedite game development by providing tons of resources built specifically for rapid prototyping and continuous iteration-- enabling developers to focus on making the games they envision, not on programming the framework necessary to do so.

### Features

- Telemetry
  - Record continuous variables with just a few function calls
  - Create multiple tables of data
  - CSV, SQL file, and SQLite database support
- Behaviors
  - Action Lists: for creating discrete sequences of events in code
- Interpolation Systems
  - Control Curves and Envelopes: For control precisely how a data point gets from A to B
  - PID Controller: For controlling how a point follows a target using a control system
- Randomization
  - Fast normal distribution randomness
  - Complete and deck randomness
  - Weighted randomness
  - Seed setting
  - Seed state recording

### Future Plans
The following is a list of things that I would like to implement into this project, time permitting:

- Automation
  - Record user input to a file
  - Play it back for testing/debugging, or for in-game replays
- Behaviors
  - Behavior Tree
  - Probability Curves
  - A* Planner
  - Steering Behaviors
  - Terrain Analysis and Layers
  - Vision Cones
- Physics
  - Jerk Integrator: For creating smooth character and NPC controllers by going a step beyond acceleration

## Version
Playnub requires **at least Godot 4.4**.

## Installation
This project is currently in development and does not yet have a stable release. It will have one when the features of the plugin are solid enough for a release and, ideally, have unit tests in the repository.

## License
This project is licensed under the [MIT License](https://github.com/this-is-bennyk/playnub/blob/main/LICENSE).

Playnub uses a compiled version of [Godot SQLite](https://github.com/2shady4u/godot-sqlite/tree/master), licensed under the [MIT License](https://github.com/this-is-bennyk/playnub/blob/main/addons/playnub/licenses/gdsqlite_LICENSE.txt).
