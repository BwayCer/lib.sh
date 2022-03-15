#!/bin/bash
# 範例腳本


#---
# ##shArea 介面函式
# # 對外接口 請驗證輸入值
# # 禁止介面函式間相互調用 避免全域變數混雜
#
# ##shArea 共享
# # 建議以 _xxx, var_xxx, fnXxx, rtnXxx 命名
#
# ##shArea ###/標題描述
# # 其他分類
#---


##shArea test env


_pjDirsh=$(dirname "$(realpath "$0")")
[ -z "`grep ":$_pjDirsh:" <<< ":$PATH:"`" ] && PATH="$_pjDirsh:$PATH"


##shArea ###


set -e

# 若是以鏈結文件被執行，將導向至原執行文件路徑
# [ ! -L "$0" ] || exec "`realpath "$0"`" "$@"

# 標準輸入變量
_stdin=`[ -t 0 ] || while read pipeData; do echo "$pipeData"; done <&0`

sourcePkg() {
  local pkg="$1" pkgUrl="$2" codeTxt
  (type "$pkg" >/dev/null 2>&1 || [ -x "$pkg" ]) && source "$pkg" || {
    set +e
    [ "$pkgUrl" != "noLink" ] && codeTxt=`curl -sf "$pkgUrl"`
    [ $? -eq 0 ] || { echo "Not Found file: $pkg ($pkgUrl)" >&2; exit 22; }
    set -e
    source <(cat <<< $codeTxt)
  }
}
sourcePkg main.lib.sh "https://raw.githubusercontent.com/BwayCer/lib.sh/main/main.lib.sh"
sourcePkg "$_pjDirsh/sample.lib.sh" "noLink"


##shArea 介面函式


#help:sample:主命令簡述
# # 主命令說明 1
# # 主命令說明 2
# # 主命令說明 3 ...
# *USAGE: [SubCmd] [Opt] [多個參數]
# *SubCmd:
#   subCmdA      [[BRIEFLY:sample_subCmdA]]
#   pressCtrlC   [[BRIEFLY:sample_pressCtrlC]]
# *Opt:
#   -f, --showFileInfo   顯示文件路徑資訊。
#   -i, --showStdin      顯示標準輸入。
#   -h, --help           幫助。
#pleh
fnSample() {
  [ $# -eq 0 ] && { shs_showHelp "$0" "sample"; return; }

  local opt_showFileInfo=0
  local opt_showStdin=0
  local opt_carryOpt=()

  shs_parseOption "$@"
  while [ -n "y" ]
  do
    shs_poParse
    case "$shs_poOpt" in
      -f | --fileInfo )
        opt_showFileInfo=1
        opt_carryOpt+=("$shs_poOpt")
        shs_poShift 1
        ;;
      -i | --showStdin )
        opt_showStdin=1
        opt_carryOpt+=("$shs_poOpt")
        shs_poShift 1
        ;;
      -h | --help )
        shs_showHelp "$0" "sample"
        return
        ;;
      -- ) break ;;
      * )
        if [ -z "$shs_poVal" ]; then
          opt_carryOpt+=("$shs_poOpt")
          shs_poShift 1
        else
          opt_carryOpt+=("$shs_poOpt=\"$shs_poVal\"")
          shs_poShift 2
        fi
        ;;
    esac
  done
  shs_poEnd && shift $shs_poShiftLength || return 1

  if [ $opt_showFileInfo -ne 0 ]; then
    _createFileInfo tarGit $0
    echo "文件路徑資訊："
    printf "  %s: %s\n" \
      "__filename" "$sample__filename" \
      "_dirsh" "$sample_dirsh" \
      "_fileName" "$sample_fileName"
    echo
  fi

  if [ $opt_showStdin -ne 0 ]; then
    echo "標準輸入的內容："
    [ -n "$_stdin" ] &&
      echo "---$_br$_stdin$_br---" ||
      echo "  (空)"
    echo
  fi

  printf "執行主命令：\n  攜帶選項： %s\n  攜帶參數： %s\n" \
    "${opt_carryOpt[*]}" "($#) $*"
}

#help:sample_subCmdA:A 子命令
# *USAGE: [SubCmd] [Opt]
# *SubCmd:
#   subCmdB   [[BRIEFLY:sample_sca_subCmdB]]
# *Opt:
#   -h, --help   幫助。
#pleh
fnSample_subCmdA() {
  shs_parseOption "$@"
  while [ -n "y" ]
  do
    shs_poParse
    case "$shs_poOpt" in
      -h | --help )
        shs_showHelp "$0" "sample_subCmdA"
        return
        ;;
      -- ) break ;;
      * ) shs_poShift 3 ;;
    esac
  done
  shs_poEnd || return 1

  echo "執行 A 子命令"
}

#help:sample_sca_subCmdB:B 子命令
# *USAGE: [Opt]
# *Opt:
#   -h, --help   幫助。
#pleh
fnSample_subCmdA_subCmdB() {
  local argu
  for argu in "$@"
  do
    case "$argu" in
      -h | --help )
        shs_showHelp "$0" "sample_sca_subCmdB"
        return
        ;;
      -- ) break ;;
      -* ) continue ;;
      * ) break ;;
    esac
  done

  echo "-- 執行 B 子命令 --"
  shLib_sample "$@"
}

#help:sample_pressCtrlC:<Ctrl>+C 退出測試。
# *USAGE: [Opt]
# *Opt:
#   -h, --help   幫助。
#pleh
fnSample_pressCtrlC() {
  shs_parseOption "$@"
  while [ -n "y" ]
  do
    shs_poParse
    case "$shs_poOpt" in
      -h | --help )
        shs_showHelp "$0" "sample_pressCtrlC"
        return
        ;;
      -- ) break ;;
      * ) [ -z "$shs_poVal" ] && shs_poShift 1 || shs_poShift 2 ;;
    esac
  done
  local args=("${shs_poArgs[@]}")
  shs_poEnd || return 1

  shs_onCtrlC \
    "echo \"$_fRedB觸發 <Ctrl>+C 退出事件$_fN\" >&2" \
    "echo \"$_fRedB請檢查命令。 ($0 ${_origArgs[*]})$_fN\" >&2"

  echo "執行 pressCtrlC 子命令"
  printf "（請按下 <Ctrl>+C 繼續）"
  sleep 86400
}


##shArea ###


_origArgs=("$@")
shs_route "fnSample" "$@"

