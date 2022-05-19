import json


# print(json.loads('{"key": "value"}'))
# print(json.loads('{"BucketName":{"ResourceValue":{"Value":"RESOURCE_ID"}}, "AutomationAssumeRole":{"StaticValue":{"Values":[{"Fn::Sub":"arn:aws:iam::${AWS::AccountId}:role/automationRole"}]}}}'))
print(json.loads("{\"BucketName\":{\"ResourceValue\":{\"Value\":\"RESOURCE_ID\"}}, \"AutomationAssumeRole\":{\"StaticValue\":{\"Values\":[{\"Fn::Sub\":\"arn:aws:iam::${AWS::AccountId}:role/automationRole\"}]}}}"))
