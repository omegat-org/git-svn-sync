import boto3


def put_event():
    events = boto3.client('events')
    return events.put_events(Entries=[
        {
            'Source': 'git-svn-sync-lambda',
            'DetailType': '{}',
            'Detail': '{}'
        }
    ])


def run():
    result = put_event()
    print(result)
    return 'OK'


def lambda_handler(event, context):
    print(event)
    body = run()
    # Format to be consumed by API Gateway proxy:
    # https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html#api-gateway-simple-proxy-for-lambda-output-format
    return {
        'statusCode': 200,
        'body': body,
        'headers': {},
        'isBase64Encoded': False
    }
