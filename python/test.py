import json

# print ('[ source.split("dev.", 1)[1] ]')
# source="integration-test-dev.vwcredit.com"
# print (source)
# print (source.split("dev.", 1)[1])
# print (' ')
#
# source="integration-test.dev.vwcredit.com"
# print (source)
# print (source.split("dev.", 1)[1])
# print (' ')
#
# source="dev.integration-test.vwcredit.com"
# print (source)
# print (source.split("dev.", 1)[1])
# print (' ')


create_lambda_event = json.loads('{\"RequestType\":\"Create\",\"ServiceToken\":\"arn:aws:sns:us-east-1:346510131851:HostedZoneTopic\",\"ResponseURL\":\"https://cloudformation-custom-resource-response-useast1.s3.amazonaws.com/arn%3Aaws%3Acloudformation%3Aus-east-1%3A346510131851%3Astack/vci-tenant-infra-custom-rss-test/7ca58450-85e1-11eb-851f-1266e578c117%7CHZONE%7Cff9a8f0f-a8ac-4979-a03e-77c016ca97b1?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Date=20210315T225517Z&X-Amz-SignedHeaders=host&X-Amz-Expires=7199&X-Amz-Credential=AKIA6L7Q4OWT3UXBW442%2F20210315%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Signature=b64424e3aea00fd6d07dade94b245d0ba101f9560006211abfe15554128cb263\",\"StackId\":\"arn:aws:cloudformation:us-east-1:346510131851:stack/vci-tenant-infra-custom-rss-test/7ca58450-85e1-11eb-851f-1266e578c117\",\"RequestId\":\"ff9a8f0f-a8ac-4979-a03e-77c016ca97b1\",\"LogicalResourceId\":\"HZONE\",\"ResourceType\":\"Custom::HZONE\",\"ResourceProperties\":{\"ServiceToken\":\"arn:aws:sns:us-east-1:346510131851:HostedZoneTopic\",\"TenantsHostedZoneNames\":\"hostedzone-integration-test-dev.vwcredit.com\"}}')

delete_lambda_event = json.loads('{\"RequestType\":\"Delete\",\"ServiceToken\":\"arn:aws:sns:us-east-1:346510131851:HostedZoneTopic\",\"ResponseURL\":\"https://cloudformation-custom-resource-response-useast1.s3.amazonaws.com/arn%3Aaws%3Acloudformation%3Aus-east-1%3A346510131851%3Astack/vci-tenant-infra-custom-rss-test/7ca58450-85e1-11eb-851f-1266e578c117%7CHZONE%7C4ace6c24-ece4-4d0b-bc39-5802cc59e1d6?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Date=20210315T225542Z&X-Amz-SignedHeaders=host&X-Amz-Expires=7200&X-Amz-Credential=AKIA6L7Q4OWT3UXBW442%2F20210315%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Signature=857d57c1f0afd677ce9f2f358f866e800508d3a29d810336900fa7dfd1faafac\",\"StackId\":\"arn:aws:cloudformation:us-east-1:346510131851:stack/vci-tenant-infra-custom-rss-test/7ca58450-85e1-11eb-851f-1266e578c117\",\"RequestId\":\"4ace6c24-ece4-4d0b-bc39-5802cc59e1d6\",\"LogicalResourceId\":\"HZONE\",\"PhysicalResourceId\":\"2021/03/15/[$LATEST]aaf4307e4cb04366ab7422552137d0b3\",\"ResourceType\":\"Custom::HZONE\",\"ResourceProperties\":{\"ServiceToken\":\"arn:aws:sns:us-east-1:346510131851:HostedZoneTopic\",\"TenantsHostedZoneNames\":\"hostedzone-integration-test-dev.vwcredit.com\"}}')

print('------ Create lambda event ------')
lambda_event = create_lambda_event
request_type = lambda_event['RequestType']
print ('Request type: ' + request_type)
hosted_zone_names = lambda_event['ResourceProperties']['TenantsHostedZoneNames']

print('------ Delete lambda event ------')
lambda_event = delete_lambda_event
request_type = lambda_event['RequestType']
print ('Request type: ' + request_type)
hosted_zone_names = lambda_event['ResourceProperties']['TenantsHostedZoneNames']


for hosted_zone_name in hosted_zone_names.split():
    print("hosted_zone name: " + hosted_zone_name)
