import boto3
from verify import verify_event


def already_running():
    ecs = boto3.client('ecs')
    return ecs.list_tasks(family='omegat-git-svn-sync-task')['taskArns']


def put_event():
    events = boto3.client('events')
    return events.put_events(Entries=[
        {
            'Source': 'omegat-git-svn-sync-lambda',
            'DetailType': '{}',
            'Detail': '{}'
        }
    ])


def run():
    if already_running():
        return 'OK (skipped)'
    else:
        result = put_event()
        print(result)
        return 'OK'


def lambda_handler(event, context):
    print(event)
    if not verify_event(event):
        return {
            'statusCode': 401,
            'body': 'Unauthorized',
            'headers': {},
            'isBase64Encoded': False
        }
    body = run()
    # Format to be consumed by API Gateway proxy:
    # https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html#api-gateway-simple-proxy-for-lambda-output-format
    return {
        'statusCode': 200,
        'body': body,
        'headers': {},
        'isBase64Encoded': False
    }
