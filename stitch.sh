#!/bin/bash -e -x

###param {string} name
###param {?string} [msg]
function check_var() {
  local var_name="$1"
  local var_msg="$2"
  local var_value="${!var_name-}" 

  if [[ -z "$var_value" || "$var_value" == "0" ]]; then
    echo "[stitch.sh::check_var] ERROR: \$$var_name is not setup. Hint: $var_msg"
  fi
}

function check_env() {
  check_var "STITCH_IGOR" "Path to Igor.exe"
  check_var "STITCH_PROJECT_NAME" "Name of yyp file without extension"
  check_var "STITCH_PROJECT_PATH" "Path to yyp project without / at the end"
  check_var "STITCH_USER_PATH" "Path to AppData/Roaming/GameMakerStudio2/{USER} without / at the end"
  check_var "STITCH_RUNTIME_PATH" "Path to GameMakerStudio2/Cache/runtimes/{RUNTIME} without / at the end"
  check_var "STITCH_RUNTIME" "Available options: VM, YYC"
  check_var "STITCH_PLATFORM" "Available options: windows"
}

function build_and_run {
  check_env
  clean_out
  set -x
  $STITCH_IGOR \
    --project="$STITCH_PROJECT_PATH/$STITCH_PROJECT_NAME.yyp" \
    --user="$STITCH_USER_PATH" \
    --runtimePath="$STITCH_RUNTIME_PATH" \
    --runtime=$STITCH_RUNTIME \
    --cache="$STITCH_PROJECT_PATH/tmp/igor/cache" \
    --temp="$STITCH_PROJECT_PATH/tmp/igor/temp" \
    --of="$STITCH_PROJECT_PATH/out/${STITCH_PROJECT_NAME}.win" \
    --tf="$STITCH_PROJECT_PATH/$STITCH_PROJECT_NAME.zip" \
    -- $STITCH_PLATFORM Run
  set +x
}

function build_and_run_vm {
  check_env
  clean_out
  set -x
  $STITCH_IGOR \
    --project="$STITCH_PROJECT_PATH/$STITCH_PROJECT_NAME.yyp" \
    --user="$STITCH_USER_PATH" \
    --runtimePath="$STITCH_RUNTIME_PATH" \
    --runtime=VM \
    --cache="$STITCH_PROJECT_PATH/tmp/igor/cache" \
    --temp="$STITCH_PROJECT_PATH/tmp/igor/temp" \
    --of="$STITCH_PROJECT_PATH/out/${STITCH_PROJECT_NAME}.win" \
    --tf="$STITCH_PROJECT_PATH/$STITCH_PROJECT_NAME.zip" \
    -- $STITCH_PLATFORM Run
  set +x
}

function build_and_run_yyc {
  check_env
  clean_out
  set -x
  $STITCH_IGOR \
    --project="$STITCH_PROJECT_PATH/$STITCH_PROJECT_NAME.yyp" \
    --user="$STITCH_USER_PATH" \
    --runtimePath="$STITCH_RUNTIME_PATH" \
    --runtime=YYC \
    --cache="$STITCH_PROJECT_PATH/tmp/igor/cache" \
    --temp="$STITCH_PROJECT_PATH/tmp/igor/temp" \
    --of="$STITCH_PROJECT_PATH/out/${STITCH_PROJECT_NAME}.win" \
    --tf="$STITCH_PROJECT_PATH/$STITCH_PROJECT_NAME.zip" \
    -- $STITCH_PLATFORM Run
  set +x
}

function clean_out {
  check_env
  echo "[stitch.sh::clean_out] Clean out at $STITCH_PROJECT_PATH/out"
  rm -rf $STITCH_PROJECT_PATH/out
}

function clean_tmp {
  check_env
  echo "[stitch.sh::clean_tmp] Clean tmp at $STITCH_PROJECT_PATH/tmp"
  rm -rf $STITCH_PROJECT_PATH/tmp/igor
}

function sync_yyp {
  echo "[stitch.sh::sync_yyp] Sync gm_modules with yyp project"
  gm-cli sync
}

function watch_yyp {
  echo "[stitch.sh::sync_yyp] Watch & sync gm_modules with yyp project"
  gm-cli watch
}

# init
if [ -f "stitch.env.sh" ]; then
  echo "[stitch.sh] source stitch.env.sh"
  source stitch.env.sh
else
  echo "[stitch.sh] stitch.env.sh was not found"
fi

echo "[stitch.sh] Run check_env"
check_env

# print help
echo ""
echo "Source this file to load commands:"
echo "  build_and_run       Build usign \$STITCH_RUNTIME: $STITCH_RUNTIME"
echo "  build_and_run_vm    Build using Virtual Machine and run it"
echo "  build_and_run_yyc   Build using YoYo Compiler and run it"
echo "  clean_out           Remove out folder created by build_and_run"
echo "  clean_tmp           Remove tmp/igor folder created by build_and_run"
echo "  sync_yyp            Sync gm_modules with yyp project"
echo "  watch_yyp           Watch & sync gm_modules with yyp project"
echo ""