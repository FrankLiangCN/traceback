#!/bin/bash

# -----------------------------------------
# VPS 回程路由检测脚本（NextTrace 版本）
# 作者：FrankLiangCN（适配 BusyBox / Alpine / Debian）
# -----------------------------------------

set -e

# 探测目标（可自行扩展）
declare -A TARGETS=(
  ["北京电信"]="219.141.136.10"
  ["北京联通"]="202.106.195.68"
  ["北京移动"]="221.179.155.161"
  ["上海电信"]="202.96.209.133"
  ["上海联通"]="210.22.97.1"
  ["上海移动"]="211.136.112.200"
  ["广州电信"]="58.60.188.222"
  ["广州联通"]="210.21.196.6"
  ["广州移动"]="120.196.165.24"
  ["深圳电信"]="58.60.188.222"
  ["深圳联通"]="120.80.157.101"
  ["深圳移动"]="120.196.165.24"
)

# 精品网 ASN
PREMIUM_ASNS=("AS4809" "AS9929" "AS10099" "AS58807")

# 安装 nexttrace（如未安装）
check_dep() {
  if ! command -v nexttrace >/dev/null 2>&1; then
    echo "未检测到 nexttrace，正在安装..."
    curl -sN https://nxtrace.org/nt | bash
    echo "nexttrace 安装完成"
  fi
}

# 判断是否精品网（任意一跳出现即可）
detect_premium() {
  trace_output="$1"

  # 精品 ASN
  PREMIUM_ASNS=("AS4809" "AS9929" "AS10099" "AS58807")

  # CN2 关键词（BackBone / Global / GIA / GT）
  PREMIUM_KEYWORDS=("CN2" "BackBone" "Global" "GIA" "GT")

  result=""

  # ASN 判断（按顺序输出）
  for asn in "${PREMIUM_ASNS[@]}"; do
    if echo "$trace_output" | grep -q "$asn"; then
      case "$asn" in
        "AS4809")
          result+="电信精品网（CN2 系列：GIA / GT / BackBone / Global） + "
          ;;
        "AS9929")
          result+="联通精品网（AS9929） + "
          ;;
        "AS10099")
          result+="联通高端网（AS10099） + "
          ;;
        "AS58879"|"AS58807")
          result+="移动精品网（CMI Premium） + "
          ;;
      esac
    fi
  done

  # CN2 关键词判断（补充）
  for kw in "${PREMIUM_KEYWORDS[@]}"; do
    if echo "$trace_output" | grep -qi "$kw"; then
      result+="电信精品网（CN2 系列：GIA / GT / BackBone / Global） + "
      break
    fi
  done

  # 如果有结果，去掉最后的 " + "
  if [[ -n "$result" ]]; then
    echo "${result% + }"
    return
  fi

  echo "普通线路"
}

# 执行 nexttrace 并解析 ASN
run_trace() {
  name="$1"
  ip="$2"

  echo ""
  echo "============================================"
  echo " 回程检测：$name ($ip)"
  echo "============================================"

  output=$(nexttrace -q 1 "$ip")

  echo "$output"

  # 判断是否精品网
  premium=$(detect_premium "$output")

  echo ""
  echo " 线路类型：$premium"
  echo ""
}

main() {
  check_dep

  echo "============================================"
  echo " NextTrace 回程检测（精品网任意跳识别版）"
  echo "============================================"

  for name in "${!TARGETS[@]}"; do
    run_trace "$name" "${TARGETS[$name]}"
  done

  echo "============================================"
  echo "检测完成"
  echo "============================================"
}

main
