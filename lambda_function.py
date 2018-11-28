import boto3


def lambda_handler(event, context):
    print(event)
    events = boto3.client('events')
    result = events.put_events(Entries=[
        {
            'Source': 'git-svn-sync-lambda',
            'DetailType': '{}',
            'Detail': '{}'
        }
    ])
    print(result)
    # Format to be consumed by API Gateway proxy:
    # https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html#api-gateway-simple-proxy-for-lambda-output-format
    return {
        'statusCode': 200,
        'body': 'OK',
        'headers': {},
        'isBase64Encoded': False
    }
