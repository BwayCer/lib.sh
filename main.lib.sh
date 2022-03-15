#!/bin/bash
# 基礎腳本 v1.0


##shArea ###


_PWD=$PWD
_br="
"

# 文件路徑資訊
_createFileInfo() {
  local shCmd="$1"
  local execPath="$2"
  local filename=`realpath "$execPath"`
  eval "
    ${shCmd}__filename=$filename
    ${shCmd}_dirsh=`dirname "$filename"`
    ${shCmd}_fileName=`basename "$filename"`
  "
}


##shArea fColor


# _fColor <顏色表示值 (字體色、背景色、背景色、底線共四碼)>
_fColor() {
  local bgcolor underline
  local setFont=$1
  local color=${setFont:0:1}
  local bold=${setFont:1:1}

  [ -t 1 ] || return

  if [ "$setFont" == "N" ]; then
    printf "\e[00m"
    return
  fi

  case "$color" in
    [01234567] ) printf "\e[3${color}m" ;;
    * ) echo $color ;;
  esac

  [ "$bold" == "1" ] && printf "\e[01m" || :

  [ $setFont -lt 100 ] && return || :

  bgcolor=${1:2:1}
  underline=${1:3:1}

  case "$bgcolor" in
    [01234567] ) printf "\e[4${bgcolor}m" ;;
  esac

  [ "$underline" == "1" ] && printf "\e[04m" || :
}

# 提供 3+1 種基本色變量
_fN=`printf "\e[00m"`       # `_fColor N`  # 無色
_fRedB=`printf "\e[31;01m"` # `_fColor 11` # 粗體紅色
_fGreB=`printf "\e[32;01m"` # `_fColor 21` # 粗體綠色
_fYelB=`printf "\e[33;01m"` # `_fColor 31` # 粗體黃色


##shArea shScript


shs_route() {
  local shCmd="$1"; shift
  while type "${shCmd}_$1" >/dev/null 2>&1; do shCmd+="_$1"; shift; done
  $shCmd "$@"
}


# showHelp
shs_showHelp() {
  local filename="$1"
  local cmdName="$2"

  local allHelpMarkTxt=`grep -n "^#\(help:\w\+:.*\|pleh\)$" "$filename"`
  local helpMarkTxt=`(
    grep -m 1 -A 1 "#help:${cmdName}:" |
    cut -d : -f 1
  ) <<< "$allHelpMarkTxt"`
  [ -n "$helpMarkTxt" ] || return

  local startNum=`sed -n 1p <<< "$helpMarkTxt"`
  local endNum=`  sed -n 2p <<< "$helpMarkTxt"`
  local txtHelp=`(
    grep -m 1 "#help:${cmdName}:" | cut -d : -f 4-
  ) <<< "$allHelpMarkTxt"`
  txtHelp+=$_br`
    sed -n "$((startNum + 1)),$((endNum - 1))p" "$filename" |
      sed "s/^# //" |
      sed "s/*\(USAGE:\)/\\n\1/" |
      sed "s/*\(\(SubCmd\|Opt\):\)/\\n\1\\n/"
  `

  local subCmdName subCmdBriefly
  local regexBriefly="\[\[BRIEFLY:\([^]]\+\)\]\]"
  while [ -n "`echo "$txtHelp" | grep "$regexBriefly"`" ]
  do
    subCmdName=`(
      grep -m 1 "$regexBriefly" | sed "s/.*$regexBriefly.*/\1/"
    ) <<< "$txtHelp"`
    subCmdBriefly=`(
      grep -m 1 "#help:${subCmdName}:" | cut -d : -f 4-
    ) <<< "$allHelpMarkTxt"`
    txtHelp=`
      sed "s/\[\[BRIEFLY:$subCmdName\]\]/$subCmdBriefly/" <<< "$txtHelp"
    `
  done

  echo "$txtHelp$_br"
  return
}


##shArea shScript parseOption


shs_poArgs=()
shs_poErrMsgs=()
shs_poShiftLength=0
shs_poOpt=""
shs_poVal=""
shs_parseOption() {
  shs_poArgs=("$@")
  shs_poErrMsgs=()
  shs_poShiftLength=0
}
shs_poParse() {
  local nextOpt
  local opt=${shs_poArgs[0]}
  local val=${shs_poArgs[1]}

  if [ "$opt" == "--" ] || [ "$opt" == "" ] || [[ "$opt" =~ (^[^-]|\ ) ]]; then
    shs_poOpt="--"
    shs_poVal=""
    return
  fi

  if [[ "$opt" =~ ^-[^-]. ]]; then
    nextOpt="-${opt:2}"
    opt=${opt:0:2}
    val=""
    shs_poArgs=("$opt" "$nextOpt" "${shs_poArgs[@]:1}")
  elif [[ "$val" =~ ^-[^\ ]+$ ]]; then
    val=""
  fi

  shs_poOpt="$opt"
  shs_poVal="$val"
}
shs_poShift() {
  local poShift=$1

  local valueTxt
  local cutLen=0
  case $poShift in
    # 已使用 1 個參數
    1 ) cutLen=1 ;;
    # 已使用 2 個參數
    2 ) cutLen=2 ;;
    3 )
      cutLen=1
      shs_poErrMsgs+=("找不到 \"$shs_poOpt\" 選項。")
      ;;
    4 )
      [ -n "$shs_poVal" ] && cutLen=2 || cutLen=1
      valueTxt="\"$shs_poVal\""
      shs_poErrMsgs+=("$valueTxt 不符合 \"$shs_poOpt\" 選項的預期值。")
      ;;
  esac
  ((shs_poShiftLength= shs_poShiftLength + cutLen))
  [ $cutLen -gt 0 ] && shs_poArgs=("${shs_poArgs[@]:$cutLen}")
}
shs_poEnd() {
  local filename="$1"

  shs_poOpt=""
  shs_poVal=""

  local argu
  if [ "${shs_poArgs[0]}" == "--" ]; then
    shs_poArgs=("${shs_poArgs[@]:1}")
  elif [ ${#shs_poArgs[@]} -gt 0 ]; then
    for argu in "${shs_poArgs[@]}"
    do
      [[ "$argu" =~ ^-[^\ ]+$ ]] || continue
      shs_poErrMsgs+=('不符合 "[命令] [選項] [參數]" 的命令用法。')
      break
    done
  fi

  local errMsg
  local fileInfo formatArgus
  if [ ${#shs_poErrMsgs[@]} -gt 0 ]; then
    [ -z "$filename" ] || fileInfo="[$filename]: "
    formatArgus="$_fRedB$fileInfo%s$_fN$_br"

    for errMsg in "${shs_poErrMsgs[@]}"
    do
      printf "$formatArgus" "$errMsg" >&2
    done

    return 1
  fi
}


##shArea shScript <Ctrl>+c 退出事件


# USAGE: <命令 ... (`sh -c` 可有效執行的命令文字)>
# # 範例：
# #   * `shs_onCtrlC "echo \"觸發 <Ctrl>+C 退出事件\" >&2"`
shs_onCtrlC() {
  local val
  for val in "$@"
  do
    _shs_onCtrlC_cmd+=$val$_br
  done

  $_shs_onCtrlC_isTrap || {
    _shs_onCtrlC_isTrap=true
    trap 'sh -c "echo; $_shs_onCtrlC_cmd echo"; exit' 2
  }
}
_shs_onCtrlC_isTrap=false
_shs_onCtrlC_cmd=""

