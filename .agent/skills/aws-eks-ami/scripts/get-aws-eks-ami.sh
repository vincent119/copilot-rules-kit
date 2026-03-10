#!/bin/bash

K8S_VERSION="${K8S_VERSION:-1.33}"
REGION="${REGION:-${AWS_REGION:-ap-northeast-1}}"

# 將人類可讀的地名轉換為 AWS Region 程式碼
case "$(echo "$REGION" | tr '[:upper:]' '[:lower:]')" in
  "tokyo" | "東京" )
    TARGET_REGION="ap-northeast-1"
    ;;
  "seoul" | "首爾" )
    TARGET_REGION="ap-northeast-2"
    ;;
  "osaka" | "大阪" )
    TARGET_REGION="ap-northeast-3"
    ;;
  "singapore" | "新加坡" )
    TARGET_REGION="ap-southeast-1"
    ;;
  "sydney" | "雪梨" )
    TARGET_REGION="ap-southeast-2"
    ;;
  "jakarta" | "雅加達" )
    TARGET_REGION="ap-southeast-3"
    ;;
  "taipei" | "台北" | "臺北" )
    TARGET_REGION="ap-northeast-1" # 台北本地目前只接 local zones，通常查 AMI 還是丟去東京算
    ;;
  "virginia" | "維吉尼亞" | "us-east" )
    TARGET_REGION="us-east-1"
    ;;
  "hongkong" | "香港" )
    TARGET_REGION="ap-east-1"
    ;;
  "bangkok" | "曼谷" )
    TARGET_REGION="ap-southeast-3"
    ;;
  "melbourne" | "墨爾本" )
    TARGET_REGION="ap-southeast-4"
    ;;
  *)
    # 預設直接使用傳入的字串 (假設它本身就是正確的 region code 如 'us-west-2')
    TARGET_REGION="$REGION"
    ;;
esac

echo "=> 正在查詢 EKS AMI (版本: ${K8S_VERSION}, 區域: ${TARGET_REGION})..."

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
      PlatformDetails: PlatformDetails,
      ImageOwnerAlias: ImageOwnerAlias,
      Hypervisor: Hypervisor,
      CreationDate: CreationDate
  }' \
  --output table
