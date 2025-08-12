# zmk-config

Configuration for my keyboards running [ZMK](https://github.com/zmkfirmware/zmk).

## Keyboards

| Keyboard | Vendor | Display | Microcontroller | Build Command |
|----------|--------|---------|-----------------|---------------|
| [Wireless Corne](https://typeractive.xyz/) | [typeractive](https://typeractive.xyz/) | [nice!view](https://typeractive.xyz/products/nice-view) | [nice_nano_v2](https://typeractive.xyz/products/nice-nano) | `./build.sh --name corne --side <left\|right>` |
| [Wired Aurora Corne](https://splitkb.com/collections/keyboard-kits/products/aurora-corne)* | [splitkb](https://splitkb.com) | none | [Liatris](https://splitkb.com/collections/keyboard-parts/products/liatris) | `./build.sh --name aurora-corne --side <left\|right>` |

- \*The wired aurora corne uses full-duplex UART over the TRRS cable. It repurposes the
  RGB pin (`GPIO0` / `D3`) for the UART tx. **This also means there is no RGB support.** For this to work,
  you need to:
  - On the _left_ side: Wire the RGB (`GPIO0` / `D3`) pin to `R2` (labeled `RB` on the board).
  - On the _right_ side: Cut the `JP1` jumper. Wire the the RGB (`GPIO0` / `D3`) pin to
    `R1` (labeled `RA` on the board). Wire the DATA (`GPIO1` / `D2`) pin to `R2` (labeled
    `RB` on the board).

  In the end, `TX` on the left side should be connected to `RX` on the right side, and
  vice versa.
> [!WARNING]  
> Do not plug or unplug the TRRS cable while the splits are powered, this could cause
> irreparable damage to the microcontrollers (see also
> [this](https://zmk.dev/docs/features/split-keyboards#split-transports)).
  
## Building Locally

Follow the [Native Setup of the ZMK
docs](https://zmk.dev/docs/development/local-toolchain/setup/native).
The `build.sh` script expects the ZMK git checkout to be in `../zmk`, you can change this
by passing `--zmk-dir <dir>/app`.

Run the build command in the table above to build the the firmware.
The `build.sh` scripts accepts the following arguments (output of `--help`):
```txt
Build the keyboard firmware.
Arguments:
  --zmk-dir <zmk-dir>: Directory of the zmk/app folder, defaults to `../zmk/app`.
  --side <left|right>: Which side to build, defaults to `right`.
  --cfg <keyboard configuration json>: A keyboard config json file, defaults to `./build.json`.
  --name <cfg name>: The name of the keyboard in the config to build, optional.
  --board <board>: Which board to build, defaults to the one specified in the config.
  --shield <shields>: Which shields to include, defaults to the shield specified in the config.
  --zmk-config <dir>: The directory of the zmk config, defaults to `config` or the one specified in the config.
  --build-dir <build-dir>: The build dir, defaults to `build/<side>`.
  --usb-logging: Enable USB logging.
  -p: Whether to clean before building (make a fresh build).
  --all: Build all boards and sides which are enabled in the config (has priority over --name).
  --ci: Print a JSON object per build for CI, with the name and side.
  --help: Print this help message.
  --jq <jq>: Use a custom jq binary, defaults to `jq` in PATH.
```

The build configuration can be passed verbatim with the `--board` and `--shield`
arguments, or it can be configured in [`build.json`](./build.json) (or another JSON file
supplied with the `--cfg` argument). A specific configuration in the supplied config can
be built by supplying the `--name` and `--side` arguments.
