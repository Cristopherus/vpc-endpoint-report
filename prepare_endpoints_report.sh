#!/bin/bash
set -eu -o pipefail -E

ENVS=()
REGION=eu-west-1

usage() {
  echo "$__usage"
  exit 1
}

__usage="
Usage: $(basename "$0") [OPTIONS]

Options:
  -e, --envs         environment list (separated by comma) i.e. dev,stage,prod
  -r, --region       aws region
"

if (( $# < 1 ))
then
  usage
fi

while [ $# -gt 0 ]; do
  case "$1" in
    -e|--envs)
      shift
      IFS=, read -ra ENVS <<< "$1"
      ;;
    -e=*|--envs=*)
      IFS=, read -ra ENVS <<< "${1#*=}" 
      ;;
    -r|--region)
      shift
      REGION="$1"
      ;;
    -r|--region=*)
      REGION="${1#*=}"
      ;;
    -h|--help|-h=*|--help=*)
      usage
      ;;
    *)
      usage
      ;;
  esac
  shift
done

if [[ -z "$ENVS" ]]
then
  usage
fi

for env in "${ENVS[@]}"
do
  export AWS_PROFILE=abacai-$env
  aws sso login
  ENDPOINTS=$(aws ec2 describe-vpc-endpoints --region "$REGION" |jq -r '.VpcEndpoints[] | "\(.VpcEndpointId),\(.VpcEndpointType),\(.VpcId),\(.Tags[] | select(.Key=="Name") | .Value),\(.CreationTimestamp)"')
  if [[ -n "$ENDPOINTS" ]]
  then
    echo "endpoint id,type,vpc,name,creation timestamp" > "endpoint-list-$env.csv"
    echo "$ENDPOINTS" >> "endpoint-list-$env.csv"
  fi
  COSTS=$(aws ce get-cost-and-usage --region "$REGION" --time-period Start=2021-12-01,End=2022-01-01 --granularity DAILY --metrics "UnblendedCost" --group-by Type=DIMENSION,Key=USAGE_TYPE --filter file://filter.json | jq -r '.ResultsByTime[] | "\(.TimePeriod.Start),\(.TimePeriod.End),\(.Groups[] | "\(.Keys[]),\(.Metrics.UnblendedCost.Amount),\(.Metrics.UnblendedCost.Unit)")"')
  if [[ -n "$COSTS" ]]
  then
    echo "start date, stop date, name, value, unit" > "costs-$env.csv"
    echo "$COSTS" >> "costs-$env.csv"
  fi
done
python3 prepare_report.py

pdflatex endpoints.tex
pdflatex endpoints.tex
