#!/bin/bash
set -euo pipefail

# 預設值
K8S_VERSION="${K8S_VERSION:-1.33}"
REGION="${REGION:-${AWS_REGION:-ap-northeast-1}}"

# 將人類可讀的地名轉換為 AWS Region Code
case "$(echo "$REGION" | tr '[:upper:]' '[:lower:]')" in
  # 亞太地區 - 東北亞
  "tokyo" | "東京" )
    TARGET_REGION="ap-northeast-1"
    ;;
  "seoul" | "首爾" )
    TARGET_REGION="ap-northeast-2"
    ;;
  "osaka" | "大阪" )
    TARGET_REGION="ap-northeast-3"
    ;;
  "taipei" | "台北" | "臺北" )
    TARGET_REGION="ap-northeast-1"  # 台北目前使用東京地區
    ;;

  # 亞太地區 - 東南亞
  "singapore" | "新加坡" )
    TARGET_REGION="ap-southeast-1"
    ;;
  "bangkok" | "曼谷" )
    TARGET_REGION="ap-southeast-1"  # 曼谷使用新加坡地區
    ;;
  "sydney" | "雪梨" )
    TARGET_REGION="ap-southeast-2"
    ;;
  "jakarta" | "雅加達" )
    TARGET_REGION="ap-southeast-3"
    ;;
  "melbourne" | "墨爾本" )
    TARGET_REGION="ap-southeast-4"
    ;;

  # 亞太地區 - 其他
  "hongkong" | "hong kong" | "香港" )
    TARGET_REGION="ap-east-1"
    ;;
  "mumbai" | "孟買" )
    TARGET_REGION="ap-south-1"
    ;;

  # 美洲地區
  "virginia" | "維吉尼亞" | "us-east" )
    TARGET_REGION="us-east-1"
    ;;
  "ohio" | "俄亥俄" )
    TARGET_REGION="us-east-2"
    ;;
  "california" | "加州" | "北加州" )
    TARGET_REGION="us-west-1"
    ;;
  "oregon" | "奧勒岡" )
    TARGET_REGION="us-west-2"
    ;;
  "canada" | "加拿大" )
    TARGET_REGION="ca-central-1"
    ;;
  "saopaulo" | "聖保羅" )
    TARGET_REGION="sa-east-1"
    ;;

  # 歐洲與中東
  "ireland" | "愛爾蘭" )
    TARGET_REGION="eu-west-1"
    ;;
  "london" | "倫敦" )
    TARGET_REGION="eu-west-2"
    ;;
  "paris" | "巴黎" )
    TARGET_REGION="eu-west-3"
    ;;
  "frankfurt" | "法蘭克福" )
    TARGET_REGION="eu-central-1"
    ;;
  "stockholm" | "斯德哥爾摩" )
    TARGET_REGION="eu-north-1"
    ;;
  "bahrain" | "巴林" )
    TARGET_REGION="me-south-1"
    ;;

  *)
    # 預設直接使用傳入的字串（假設它是正確的 Region Code）
    TARGET_REGION="$REGION"
    ;;
esac

echo "================================================="
echo "🔍 查詢 Amazon EKS AMI"
echo "================================================="
echo "Kubernetes 版本: ${K8S_VERSION}"
echo "AWS 區域: ${TARGET_REGION}"
echo "AMI 類型: Amazon Linux 2023 (x86_64)"
echo "================================================="
echo ""

# 檢查 AWS CLI 是否安裝
if ! command -v aws &> /dev/null; then
    echo "❌ 錯誤: 找不到 AWS CLI"
    echo "請先安裝 AWS CLI: https://aws.amazon.com/cli/"
    exit 1
fi

# 查詢 AMI
aws ec2 describe-images \
  --region "${TARGET_REGION}" \
  --owners amazon \
  --filters "Name=name,Values=amazon-eks-node-al2023-x86_64-standard-${K8S_VERSION}-*" \
            "Name=state,Values=available" \
            "Name=architecture,Values=x86_64" \
            "Name=is-public,Values=true" \
  --query 'reverse(sort_by(Images, &CreationDate))[].{
      Name: Name,
      ImageId: ImageId,
      Architecture: Architecture,
      CreationDate: CreationDate,
      PlatformDetails: PlatformDetails
  }' \
  --output table

echo ""
echo "✅ 查詢完成"
echo "💡 提示: 表格最上方的 AMI 為最新版本"
