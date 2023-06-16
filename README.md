# Towizz *(working title)*
 My entry for [GBcompo23](https://itch.io/jam/gbcompo23).

## Tools used:
 - [RGBDS toolchain](https://rgbds.gbdev.io) (v0.6.1)
 - [hardware.inc](https://github.com/gbdev/hardware.inc)
 - [Visual Studio Code](https://code.visualstudio.com/)
 - [Emulicious](https://emulicious.net/) + [Debug Adapter for VScode](https://marketplace.visualstudio.com/items?itemName=emulicious.emulicious-debugger)
  - [Sukkore](https://github.com/sukus21/sukkore) (project template)

## Building:
 Assumes that `rgbasm`, `rgblink` and `rgbfix` are available in your `path` variable. Developed using v0.6.1, but other versions may work as well.
 To build the project, run `make`, and a file named `build.gb` will appear inside the `build` directory, assuming nothing goes wrong.
