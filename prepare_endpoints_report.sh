#!/bin/bash
set -eu -o pipefail -E

ENVS=()

usage() {
  echo "$__usage"
  exit 1
}

__usage="
Usage: $(basename "$0") [OPTIONS]

Options:
  -e, --envs         environment list (separated by comma) i.e. dev,stage,prod
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

  ENDPOINTS=$(aws ec2 describe-vpc-endpoints |jq -r '.VpcEndpoints[] | "\(.VpcEndpointId),\(.VpcEndpointType),\(.VpcId),\(.Tags[] | select(.Key=="Name") | .Value),\(.CreationTimestamp)"')
  if [[ -n "$ENDPOINTS" ]]
  then
    echo "endpoint id,type,vpc,name,creation timestamp" > "$env.csv"
    echo "$ENDPOINTS" >> "$env.csv"
  fi
done
python3 prepare_report.py

pdflatex endpoints.tex
pdflatex endpoints.tex
