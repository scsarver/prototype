# import sys
import json
# import os
import boto3
# import copy
# import base64
import requests
import pymsteams

# import traceback
# from botocore.exceptions import ClientError


ec2 = boto3.resource('ec2')
sns = boto3.client('sns')

alias = boto3.client('iam').list_account_aliases()['AccountAliases'][0]

# def lambda_handler(event, context):
    # print("SNS Event: " + json.dumps(event))
    # lambdaevent = event['Records'][0]['Sns']
    # security_group_id = lambdaevent['Message']
    # print("security_group_id: " + security_group_id)
    # security_group = ec2.SecurityGroup(security_group_id)
    # print("group_description: " + security_group.description)
    # print("group_id: " + security_group.group_id)
    # print("group_name: " + security_group.group_name)
    #
    # try:
    #     for sg_ingress in security_group.ip_permissions:
    #         print(json.dumps(sg_ingress))
    #
    #         if (is_open_to_any(sg_ingress)):
    #             ingress_copy = copy.deepcopy(sg_ingress)
    #             security_group.revoke_ingress(
    #                     DryRun=False,
    #                     IpPermissions=[sg_ingress]
    #                 )
    #             if 'Ipv6Ranges' in ingress_copy:
    #                 ingress_copy['Ipv6Ranges'].clear()
    #             ip_ranges = ingress_copy['IpRanges']
    #             if contains_vci_ip(ip_ranges):
    #                 for ip_v4 in ip_ranges:
    #                     if ip_v4['CidrIp'].startswith("0.0.0.0"):
    #                         ip_ranges.remove(ip_v4)
    #             else:
    #                 for ip_v4 in ip_ranges:
    #                     if ip_v4['CidrIp'].startswith("0.0.0.0"):
    #                         ip_v4['CidrIp'] = vci_ip_v4
    #                         ip_v4['Description'] = "Auto Remediation replaced 0.0.0.0 to " + vci_ip_v4
    #             print("ip_ranges modified: " + json.dumps(ip_ranges))
    #             security_group.authorize_ingress(
    #                     DryRun=False,
    #                     IpPermissions=[ingress_copy]
    #                 )
    #     message = construct_message(
    #         alias, security_group_id, security_group.group_name, True)
    #     sns.publish(
    #         TopicArn=sg_successful_topic_arn,
    #         Message=message
    #     )
    #     webex = json.loads(get_webex())
    #     uri = webex['uri']
    #     data = {}
    #     data = {
    #         "roomId": webex['roomId'],
    #         "text": message
    #     }
    #     requests.post(uri, json.dumps(data), headers={
    #                         'Authorization': webex['token'],
    #                         'Content-Type': 'application/json'
    #                         }
    #                   )
    # except:
    #     print("Unexpected error:", sys.exc_info()[0])
    #     traceback.print_exc()
    #     message = construct_message(
    #         alias, security_group_id, security_group.group_name, False)
    #     sns.publish(
    #         TopicArn=sg_failed_topic_arn,
    #         Message=message
    #     )
    #     webex = json.loads(get_webex())
    #     uri = get_teams_endpoint()
    #     data = {}
    #     data = {
    #         "roomId": webex['roomId'],
    #         "text": message
    #     }
    #     requests.post(uri, json.dumps(data), headers={
    #                         'Authorization': webex['token'],
    #                         'Content-Type': 'application/json'
    #                         }
    #                   )


def send_message(uri,data):
    headers={'Content-Type': 'application/json'}


    print("Sending to:" + uri )
    # print("Sending the follwing message:")
    # print(json.dumps(data))
    #
    # response = requests.post(uri, json.dumps(data), headers)
    # print(response)
    # print(response.text)
    # print(response.content)

    # myTeamsMessage = pymsteams.connectorcard("<Microsoft Webhook URL>")
    # myTeamsMessage.text("this is my text")
    # myTeamsMessage.send()


    # https://pypi.org/project/pymsteams/
    myTeamsMessage = pymsteams.connectorcard(uri)
    myTeamsMessage.text("this is my text")
    myTeamsMessage.title("This is my message title")
    myTeamsMessage.addLinkButton("This is the button Text", "https://github.com/rveachkc/pymsteams/")
    # myTeamsMessage.color("<Hex Color Code>")
    myTeamsMessage.color("#628daa")


    myTeamsMessage.printme()

    response2 = myTeamsMessage.send()
    print(response2)



def construct_message():
    messageBody = 'test text line 1'
    # messageBody += '\\ntest text line 2'

    # message = ""
    # message += '{'
    # message += '    "\$schema": "https://adaptivecards.io/schemas/adaptive-card.json",'
    # message += '    "type": "AdaptiveCard",'
    # message += '    "version": "1.0",'
    # message += '    "body": ['
    # message += '        {'
    # message += '            "type": "TextBlock",'
    # message += '            "text": "' + messageBody + '",'
    # message += '            "wrap": true'
    # message += '        }'
    # message += '    ]'
    # message += '}'

    payload ={
        "$schema": "https://adaptivecards.io/schemas/adaptive-card.json",
        "type": "AdaptiveCard",
        "version": "1.0",
        "body": [
            {
                "type": "TextBlock",
                "text": messageBody,
                "wrap": 'true'
            }
        ]
    }
    return json.dumps(payload)

def get_teams_endpoint():
    teams_endpoint = "https://some.webhook.office.com/webhookb2/0dd35e19-5ea0-40b5-95de-notthehashyouarelookingfor/IncomingWebhook/d762stillnotthehashyouarelookingforc26fdb/988d4331-definatelynotthehashyouarelookingfor1b19"
    return teams_endpoint

send_message(get_teams_endpoint(),construct_message())
