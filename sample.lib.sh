#!/bin/bash
# 函式庫範例腳本
# # 主命令說明 1
# # 主命令說明 2
# # 主命令說明 3 ...
# *USAGE: [Opt] [多個參數]
# *Opt:
#   -a, --add <value>   添加新值。
#   -y, --yes           添加複數旗標。
#   -n, --no            添加複數旗標。
#   -h, --help          幫助。
shLib_sample() {
  local opt_carryOpt=()

  while [ -n "y" ]
  do
    case "$1" in
      -a | --add )
        opt_carryOpt+=("$1=\"$2\"")
        shift 2
        ;;
      -b | --boolean )
        opt_carryOpt+=("$1")
        shift
        ;;
      -- ) shift; break ;;
      -* )
        echo "[shLib_sample]: 找不到 \"$1\" 選項。" >&2
        return 1
        ;;
      * ) break ;;
    esac
  done

  printf "執行主命令：\n  攜帶選項： %s\n  攜帶參數： %s\n" \
    "${opt_carryOpt[*]}" "($#) $*"
}

