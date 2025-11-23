#!/bin/bash

# GitHub Workflow 触发脚本
# 用于触发指定的 GitHub Actions workflow
# 添加如下定时任务
# 0 2,6,10,14,18,22 * * * /root/GitHub_Workflow-v3.sh>>/root/GitHub_Workflow-v3.log


# 配置变量
source /etc/profile
GITHUB_TOKEN="${GITHUB_TOKEN}"  # 从环境变量读取 GitHub Token。在 Tokens (classic) https://github.com/settings/tokens 这个页面申请 
REPO_OWNER="ggg5945"
REPO_NAME="g-test-action-v2"
WORKFLOW_FILE="Backend%20Services-v3.yml"  # "Backend Services-v3.yml" 需要url编码
REF="master"  # 分支名称，可根据需要修改

# 检查 GitHub Token
if [ -z "$GITHUB_TOKEN" ]; then
    echo "[$(TZ='Asia/Shanghai' date '+%Y-%m-%d %H:%M:%S')] 错误: 未设置 GITHUB_TOKEN 环境变量"
    echo "[$(TZ='Asia/Shanghai' date '+%Y-%m-%d %H:%M:%S')] 请设置: export GITHUB_TOKEN='your_github_token'"
    exit 1
fi

# 重试配置
MAX_RETRIES=10
RETRY_INTERVAL=3
attempt=1

# 触发 workflow（带重试）
echo "[$(TZ='Asia/Shanghai' date '+%Y-%m-%d %H:%M:%S')] 正在触发 workflow: $WORKFLOW_FILE"
echo "[$(TZ='Asia/Shanghai' date '+%Y-%m-%d %H:%M:%S')] 仓库: $REPO_OWNER/$REPO_NAME"
echo "[$(TZ='Asia/Shanghai' date '+%Y-%m-%d %H:%M:%S')] 分支: $REF"
echo ""

while [ $attempt -le $MAX_RETRIES ]; do
    echo "[$(TZ='Asia/Shanghai' date '+%Y-%m-%d %H:%M:%S')] 尝试 $attempt/$MAX_RETRIES ..."
    
    response=$(curl -X POST \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer $GITHUB_TOKEN" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/actions/workflows/$WORKFLOW_FILE/dispatches \
      -d "{\"ref\":\"$REF\"}" \
      -w "\n%{http_code}" \
      -s)
    
    # 提取 HTTP 状态码
    http_code=$(echo "$response" | tail -n1)
    response_body=$(echo "$response" | sed '$d')
    
    # 检查响应
    if [ "$http_code" -eq 204 ]; then
        echo "[$(TZ='Asia/Shanghai' date '+%Y-%m-%d %H:%M:%S')] ✓ Workflow 触发成功！"
        echo "[$(TZ='Asia/Shanghai' date '+%Y-%m-%d %H:%M:%S')] 查看运行状态: https://github.com/$REPO_OWNER/$REPO_NAME/actions/workflows/$WORKFLOW_FILE"
        exit 0
    else
        echo "[$(TZ='Asia/Shanghai' date '+%Y-%m-%d %H:%M:%S')] ✗ 第 $attempt 次尝试失败 (HTTP $http_code)"
        if [ -n "$response_body" ]; then
            echo "[$(TZ='Asia/Shanghai' date '+%Y-%m-%d %H:%M:%S')] 响应内容: $response_body"
        fi
        
        # 如果未达到最大重试次数，则等待后重试
        if [ $attempt -lt $MAX_RETRIES ]; then
            echo "[$(TZ='Asia/Shanghai' date '+%Y-%m-%d %H:%M:%S')] 等待 $RETRY_INTERVAL 秒后重试..."
            sleep $RETRY_INTERVAL
            attempt=$((attempt + 1))
        else
            echo ""
            echo "[$(TZ='Asia/Shanghai' date '+%Y-%m-%d %H:%M:%S')] ✗ 已达到最大重试次数 ($MAX_RETRIES)，触发失败"
            exit 1
        fi
    fi
done

echo "[$(TZ='Asia/Shanghai' date '+%Y-%m-%d %H:%M:%S')] ------------------------------------------------ over ------------------------------------------------"
