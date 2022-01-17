#!/bin/bash
set -eu -o pipefail -E

ENVS=()
REGION="eu-west-1"
END_DATE=$(date +'%Y-%m-%d')
BEGINNING_DATE=$(date +'%Y-%m-%d' -d "7 days ago")
TIME_PERIOD="Start=$BEGINNING_DATE,End=$END_DATE"

usage() {
  echo "$__usage"
  exit 1
}

__usage="
Usage: $(basename "$0") [OPTIONS]

Options:
  -e, --envs         environment list (separated by comma) i.e. dev,stage,prod
  -r, --region       aws region
  -t, --time         time period in format Start=2022-01-01,End=2022-01-13
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
    -r=*|--region=*)
      REGION="${1#*=}"
      ;;
    -t|--time)
      shift
      TIME_PERIOD="$1"
      ;;
    -t=*|--time=*)
      TIME_PERIOD="${1#*=}"
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

export AWS_PROFILE=web-dev
aws sso login --profile $AWS_PROFILE
for env in "${ENVS[@]}"
do
  export AWS_PROFILE=$env
  ENDPOINTS=$(aws ec2 describe-vpc-endpoints --region "$REGION" | jq -r '.VpcEndpoints[] | "\((.Tags[] | select(.Key=="Name").Value)? // ""),\(.VpcEndpointType),\(.CreationTimestamp)"')
  if [[ -n "$ENDPOINTS" ]]
  then
    echo "name,type,creation timestamp" > "endpoint-list-$env.csv"
    echo "$ENDPOINTS" >> "endpoint-list-$env.csv"
  fi
  COSTS=$(aws ce get-cost-and-usage --time-period "$TIME_PERIOD" --granularity MONTHLY --metrics "UNBLENDED_COST" "USAGE_QUANTITY" --group-by Type=TAG,Key=Name --filter file://filter.json )
  if [[ -n "$COSTS" ]]
  then
    echo "start date,stop date,name,value,unit" > "costs-$env.csv"
    echo "${COSTS//Name$}" | jq -r '.ResultsByTime[] | "\(.TimePeriod.Start),\(.TimePeriod.End),\(.Groups[] | "\(.Keys[]),\(.Metrics.UnblendedCost.Amount),\(.Metrics.UnblendedCost.Unit)")"' >> "costs-$env.csv"
    echo "start date,stop date,name,value,unit" > "usage-$env.csv"
    echo "${COSTS//Name$}" | jq -r '.ResultsByTime[] | "\(.TimePeriod.Start),\(.TimePeriod.End),\(.Groups[] | "\(.Keys[]),\(.Metrics.UsageQuantity.Amount),\(.Metrics.UsageQuantity.Unit)")"' >> "usage-$env.csv"
  fi
done
python3 prepare_report.py

pdflatex endpoints-report.tex
pdflatex endpoints-report.tex

mkdir -p ./reports
mv *.csv reports/
mv endpoints-report.pdf reports/

