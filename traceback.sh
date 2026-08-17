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
CT_PREMIUM="AS4809"
CU_PREMIUM="AS9929"
CM_PREMIUM="AS58879"

# 安装 nexttrace（如未安装）
check_dep() {
  if ! command -v nexttrace >/dev/null 2>&1; then
    echo "未检测到 nexttrace，正在安装..."
    curl -sN https://nxtrace.org/nt | bash
    echo "nexttrace 安装完成"
  fi
}

# 判断是否精品网
detect_premium() {
  asn="$1"
  if [[ "$asn" == "$CT_PREMIUM" ]]; then
    echo "电信精品网（CN2 GIA）"
  elif [[ "$asn" == "$CU_PREMIUM" ]]; then
    echo "联通精品网（AS9929）"
  elif [[ "$asn" == "$CM_PREMIUM" ]]; then
    echo "移动精品网（CMI Premium）"
  else
    echo "普通线路"
  fi
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

  # 提取最后一跳 ASN
  asn=$(echo "$output" | grep -Eo "AS[0-9]{3,6}" | tail -n 1)
  [[ -z "$asn" ]] && asn="未知"

  # 判断精品网
  premium=$(detect_premium "$asn")

  echo ""
  echo " ASN：$asn"
  echo " 线路类型：$premium"
  echo ""
}

main() {
  check_dep

  echo "============================================"
  echo " 三网 NextTrace 回程检测"
  echo " 自动识别精品网（AS4809 / AS9929 / AS58879）"
  echo "============================================"

  for name in "${!TARGETS[@]}"; do
    run_trace "$name" "${TARGETS[$name]}"
  done

  echo "============================================"
  echo "检测完成"
  echo "============================================"
}

main
