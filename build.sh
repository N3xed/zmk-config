#!/bin/bash
help=$(cat << EOF
Build the keyboard firmware.
Arguments:
  --zmk-dir <zmk-dir>: Directory of the zmk/app folder, defaults to \`../zmk/app\`.
  --side <left|right>: Which side to build, defaults to \`right\`.
  --cfg <keyboard configuration json>: A keyboard config json file, defaults to \`./build.json\`.
  --name <cfg name>: The name of the keyboard in the config to build, optional.
  --board <board>: Which board to build, defaults to the one specified in the config.
  --shield <shields>: Which shields to include, defaults to the shield specified in the config.
  --build-dir <build-dir>: The build dir, defaults to \`build/<side>\`.
  --usb-logging: Enable USB logging.
  -p: Whether to clean before building (make a fresh build).
  --all: Build all boards and sides which are enabled in the config (has priority over --name).
  --ci: Print a JSON object per build for CI, with the name and side.
  --help: Print this help message.
EOF
)

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    --help)
      echo "$help"
      exit 0
      ;;
    --zmk-dir)
      zmk_dir="$2"
      shift # past argument
      shift # past value
      ;;
    --board)
      board="$2"
      shift # past argument
      shift # past value
      ;;
    --side)
      side="$2"
      shift
      shift
      ;;
    --build-dir)
      build_dir="$2"
      shift # past argument
      shift # past value
      ;;
    --cfg)
      cfg="$2"
      shift
      shift
      ;;
    --name)
      name="$2"
      shift
      shift
      ;;
    --usb-logging)
      usb_log="-S zmk-usb-logging"
      shift
      ;;
    -p)
      pristine=-p
      shift
      ;;
    --all)
      all=1
      shift
      ;;
    --ci)
      all=1
      ci=1
      shift
      ;;
    *)
      
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done
set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

if [ "$zmk_dir" = "" ]; then
    zmk_dir="${ZMK_DIR:-$SCRIPT_DIR/../zmk/app}"
fi
cd ${zmk_dir}

if [ "$side" = "" ]; then
    side="right"
fi
if [ "$build_dir" = "" ]; then
    if [ "$all" = "1" ]; then
        build_dir="${SCRIPT_DIR}/build"
    else
        build_dir="${SCRIPT_DIR}/build/$side"
    fi
fi
if [ "$cfg" = "" ]; then
    cfg="$SCRIPT_DIR/build.json"
fi
if [ "$shield" != "" ]; then
    shield+=" "
fi

if [ "$all" = "1" ]; then
    if [ "$ci" != "1" ]; then
        echo "Building all boards and sides which are enabled in the config..."
    fi

    jq -r 'to_entries | map(select(.value | type == "object" and .enabled == true)) | .[].key' "$cfg" | while read -r board_name; do
        jq -r ".\"$board_name\" | keys[]" "$cfg" | while read -r side_name; do
            if [ "$side_name" != "left" ] && [ "$side_name" != "right" ]; then
                continue
            fi
            if [ "$ci" = "1" ]; then
                echo {\"name\": \"$board_name\",\"side\": \"$side_name\"}
            else
                echo "Building $board_name on $side_name side"
                "$SCRIPT_DIR/build.sh" --zmk-dir "$zmk_dir" --side "$side_name" --cfg "$cfg" --name "$board_name" --build-dir "$build_dir"/"$board_name"_"$side_name" -p
            fi
        done
    done
    exit 0
fi


get_board=".\"$name\".$side.board"
get_shield=".\"$name\".$side.shield"
get_config=".\"$name\".config"
if [ "$name" != "" ]; then
    board=$(jq "$get_board" -r -c "$cfg")
    shield+=$(jq "$get_shield" -r -c "$cfg")
    config_dir=$(jq "$get_config" -r -c "$cfg")
fi
if [ "$board" = "" ]; then
    echo "No board specified, use the \`--name <cfg name>\` argument, or specify the board with --board."
    exit 1
fi

# Use default config directory if not specified in JSON
if [ "$config_dir" = "" ] || [ "$config_dir" = "null" ]; then
    config_dir="config"
fi

echo build_dir=$build_dir
echo side=$side
echo board=$board
echo shield=$shield
echo config_dir=$config_dir

west build -d "$build_dir" -b $board $pristine $usb_log  -- -DSHIELD="$shield" -DZMK_EXTRA_MODULES="$SCRIPT_DIR" -DZMK_CONFIG="$SCRIPT_DIR/$config_dir" $*