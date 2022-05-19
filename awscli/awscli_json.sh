#!/usr/bin/env bash
#
# Created By: sarvers
# Created Date: 20200520-160714
#
# Purpose and References:
#
#
# Where you want the options to take effect, use set -o option-name or, in short form, set -option-abbrev, To disable an option within a script, use set +o option-name or set +option-abbrev: https://www.tldp.org/LDP/abs/html/options.html
set +x #xtrace
set +v #verbose
set -e #errexit
set -u #nounset


AWS_API="ec2"
# AWS_API_ENDPOINT="describe-transit-gateways"
AWS_API_ENDPOINT="describe-tags"


# bash -c "aws $AWS_API $AWS_API_ENDPOINT help"
DESCRIBE_RESPONSE="$(aws ec2 describe-vpcs)"
echo "$DESCRIBE_RESPONSE  "
echo "============================="

JSON_SKELETON="$(aws $AWS_API $AWS_API_ENDPOINT --generate-cli-skeleton)"
JSON_SKELETON="$(echo $JSON_SKELETON | jq -r '.MaxResults=1000 | .DryRun=false')"
# JSON_SKELETON="$(echo $JSON_SKELETON | jq -r '.Filters[] |= .+ {"Name":"resource-id","Values":["tgw-02e35b0b1e308fc3"]}')"
JSON_SKELETON="$(echo $JSON_SKELETON | jq -r '.Filters[] |= .+ {"Name":"resource-type","Values":["vpc"]}')"

echo "$JSON_SKELETON"
echo "________________________________________________________________________________"
DESCRIBE_RESPONSE="$(aws ec2 describe-tags --cli-input-json "$JSON_SKELETON")"
echo "$DESCRIBE_RESPONSE"

# --filters (list)
#           The filters.
#
#           o key - The tag key.
#
#           o resource-id - The ID of the resource.
#
#           o resource-type  -  The  resource  type  (customer-gateway  |  dedi-
#             cated-host  |  dhcp-options  |  elastic-ip  | fleet | fpga-image |
#             host-reservation | image | instance | internet-gateway |  key-pair
#             | launch-template | natgateway | network-acl | network-interface |
#             placement-group  |  reserved-instances  |  route-table   |   secu-
#             rity-group | snapshot | spot-instances-request | subnet | volume |
#             vpc | vpc-endpoint | vpc-endpoint-service | vpc-peering-connection
#             | vpn-connection | vpn-gateway ).
#
#           o tag  :<key>  -  The key/value combination of the tag. For example,
#             specify "tag:Owner" for the filter name and "TeamA" for the filter
#             value to find resources with the tag "Owner=TeamA".
#
#           o value - The tag value.
