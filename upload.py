import json
import logging
import os

import boto3
import httpx
from botocore.exceptions import ClientError

logging.basicConfig(format='%(asctime)s - %(name)s - %(levelname)s - %(message)s', level=logging.INFO)
logger = logging.getLogger(__name__)

bucket = 'resource'
base_path = os.path.dirname(os.path.abspath(__file__))
resource_lock_file = os.path.join(base_path, 'resource_lock.json')
resource_file_map = {}
resource_file_set = set()

resource_base_path = os.path.join(base_path, bucket)
len_resource_path = len(resource_base_path) + 1

bucket_name = f'{bucket}-{os.getenv("QCLOUD_APP_ID")}'
tencentcloud_client = boto3.client(
    's3',
    endpoint_url='https://cos.ap-shanghai.myqcloud.com',
    aws_access_key_id=os.getenv('QCLOUD_SECRET_ID'),
    aws_secret_access_key=os.getenv('QCLOUD_SECRET_KEY'),
)
s3_clients = {
    'TencentCloud': tencentcloud_client,
}


def get_etag(response):
    if 'ETag' not in response:
        return None
    return response['ETag'][1:-1]  # remove quote


def upload(full_path):
    file_key = full_path[len_resource_path:]
    if not file_key:
        return

    global s3_clients, resource_file_map, resource_file_set

    resource_file_set.add(file_key)

    for vendor, client in s3_clients.items():
        if file_key in resource_file_map:
            etag = resource_file_map[file_key]
            try:
                response = client.head_object(Bucket=bucket_name, Key=file_key)
                if get_etag(response) == etag:
                    logger.info(f'skipped {file_key}[{etag}] in {vendor}')
                    continue
            except ClientError:
                pass

        # upload to TencentCloud
        with open(full_path, 'rb') as fp:
            response = client.put_object(Bucket=bucket_name, Key=file_key, Body=fp)
        etag = get_etag(response)
        resource_file_map[file_key] = etag
        logger.info(f'uploaded {file_key}[{etag}] in {vendor}')


def listdir_iter(path):
    for f in os.listdir(path):
        full_path = os.path.join(path, f)
        if os.path.isfile(full_path):
            upload(full_path)
        elif os.path.isdir(full_path):
            listdir_iter(full_path)


def main():
    logger.info(f'working at {base_path}')
    logger.info('loading resource lock file.')
    global resource_file_map, resource_file_set

    if os.path.exists(resource_lock_file):
        with open(resource_lock_file) as json_file:
            resource_file_map = json.load(json_file)

    listdir_iter(resource_base_path)

    for k in resource_file_map.keys():
        if k not in resource_file_set:
            resource_file_map.pop(k, None)

    with open(resource_lock_file, 'w') as fp:
        fp.write(json.dumps(resource_file_map, ensure_ascii=False, sort_keys=True, indent=2))
    logger.info('successfully updated resource lock file.')


def download_react(react_version: str):
    react_version = react_version.strip()
    base_url = 'https://unpkg.com/{m}@{v}/umd/{m}.production.min.js'
    version_path = os.path.join(resource_base_path, 'react', f'v{react_version}')
    os.makedirs(version_path, exist_ok=True)
    for module in ['react', 'react-dom']:
        filename = f'{module}.production.min.js'
        url = base_url.format(m=module, v=react_version)
        try:
            with httpx.Client(http2=True).stream("GET", url) as r:
                with open(os.path.join(version_path, filename), 'wb') as f:
                    for data in r.iter_bytes():
                        f.write(data)
                    logger.info(f'Saving {filename} success')
        except Exception as e:
            logger.error(f'Downloading {filename} error', e)


if __name__ == '__main__':
    # download_react("17.0.1")
    main()
