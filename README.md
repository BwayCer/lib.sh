殼腳本函式庫
=======


加速並友善殼腳本開發的函式庫。



## 引用程式包


```sh
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
# 引用可執行命令 main.lib.sh 或使用 curl 從網路下載程式包
sourcePkg main.lib.sh "https://raw.githubusercontent.com/BwayCer/lib.sh/main/main.lib.sh"
# 引用指定路徑的可執行文件
sourcePkg "path/to/sample.lib.sh" "noLink"
```



## 使用方法


**可參考
[./sample.sh](./sample.sh),
[./sample.lib.sh](./sample.lib.sh)
文件的示範。**



### main.lib.sh


> **sourcePkg [./main.lib.sh](./main.lib.sh)**


#### 命令路由器

判斷命令想調用的函式。

```sh
fnSample() {...}
fnSample_subCmdA() {...}
fnSample_subCmdA_subCmdB() {...}

# shs_route <命令名稱> "$@"
shs_route "fnSample" "$@"
```


#### 顯示幫助

幫助寫法：

```
#help:<名稱>:[命令簡述]
# 內容寫於此 ...
#pleh
```

自動分段關鍵字：

`*USAGE:`, `*SubCmd:`, `*Opt:`

引用子命令描述寫法：

`[[BRIEFLY:<名稱>]]`

完整示例：

```sh
#help:sample:主命令簡述
# # 主命令說明 1
# # 主命令說明 2
# # 主命令說明 3 ...
# *USAGE: [SubCmd] [Opt] [多個參數]
# *SubCmd:
#   subCmdA   [[BRIEFLY:sample_subCmdA]]
# *Opt:
#   -h, --help   幫助。
#pleh

#help:sample_subCmdA:A 子命令
# ...省略子命令內容
#pleh
```

當調用 `shs_showHelp "$0" "sample"` 命令將打印：

```
主命令簡述
# 主命令說明 1
# 主命令說明 2
# 主命令說明 3 ...

USAGE: [SubCmd] [Opt] [多個參數]

SubCmd:

  subCmdA   A 子命令

Opt:

  -h, --help   幫助。
```


#### 解析參數

要求參數需符合 `[命令] [選項] [參數]` 的規則。

```
fnSample() {
  shs_parseOption "$@"
  while [ -n "y" ]
  do
    shs_poParse
    case "$shs_poOpt" in
      -b | --boolean )
        opt_boolean=true
        shift
        ;;
      -a | --add )
        opt_add="$shs_poVal"
        shift 2
        ;;
      -h | --help )
        shs_showHelp "$0" "sample"
        return
        ;;
      -- ) break ;;
      * ) shs_poShift 3 ;;
    esac
  done
  shs_poEnd && shift $shs_poShiftLength || return 1

  "$@" # args
}
```


#### 顏色

```sh
_fColor <顏色表示值>
# 顏色表示值：
#   共四碼，分別表示： 字體色、粗體、背景色、底線。
#   字體色、背景色： 可表示值有 9 種
#     * N： 無設定
#     * 0： 黑 black
#     * 1： 紅 red
#     * 2： 綠 green
#     * 3： 黃 yellow
#     * 4： 藍 blue
#     * 5： 粉 magenta
#     * 6： 青 cyan
#     * 7： 白 white
#   粗體、底線： 可表示值有 2 種
#     * 0： 否
#     * 1： 是
#   例如：
#     * 紅色粗體： _fColor 11、_fColor 11N0
#     * 紅色粗體白底： _fColor 117、_fColor 1170
#     * 紅色粗體白底底線： _fColor 1171
```

另外無色、粗體紅色、粗體綠色、粗體黃色為預設值：

```
_fN=`printf "\e[00m"`       # == `_fColor N`  # 無色
_fRedB=`printf "\e[31;01m"` # == `_fColor 11` # 粗體紅色
_fGreB=`printf "\e[32;01m"` # == `_fColor 21` # 粗體綠色
_fYelB=`printf "\e[33;01m"` # == `_fColor 31` # 粗體黃色
```

用法：

```
echo "${_fRedB}輸出粗體紅色字$_fN"
```


#### Ctrl+C 事件

當用戶按下 <Ctrl>+C 退出事件時觸發命令：

```
shs_onCtrlC "<命令 (`sh -c` 可執行的程式碼)>" "<命令 ...>"
```

