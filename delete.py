import copy
import hashlib
import json
import logging
import os

import boto3


logging.basicConfig(format='[%(levelname)s] %(message)s', level=logging.INFO)
logger = logging.getLogger(__name__)

bucket = 'resource'
base_path = os.path.dirname(os.path.abspath(__file__))
resource_lock_file = os.path.join(base_path, 'resource_lock.json')
resource_file_map = {}
resource_file_set = set()

resource_base_path = os.path.join(base_path, bucket)
len_resource_path = len(resource_base_path) + 1

bucket_name = f'{bucket}-{os.getenv("QCLOUD_APP_ID")}'

s3_clients = {
    'TencentCloud': boto3.client(
        's3',
        endpoint_url='https://cos.ap-shanghai.myqcloud.com',
        aws_access_key_id=os.getenv('QCLOUD_SECRET_ID'),
        aws_secret_access_key=os.getenv('QCLOUD_SECRET_KEY'),
    ),
}

def get_etag(response):
    if 'ETag' not in response:
        return None
    return response['ETag'][1:-1]  # remove quote


def get_md5(file_path: str) -> str:
    hash_md5 = hashlib.md5()
    with open(file_path, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            hash_md5.update(chunk)
    return hash_md5.hexdigest()


def delete(full_path):
    file_key = full_path[len_resource_path:]
    if not file_key:
        return

    global s3_clients, resource_file_map, resource_file_set

    resource_file_set.add(file_key)
    file_md5 = get_md5(full_path)
    for vendor, client in s3_clients.items():
        if not file_md5 == resource_file_map.get(file_key):
            if os.path.isfile(resource_lock_file):
                os.remove(resource_lock_file)

        # deleted to TencentCloud
        with open(full_path, 'rb') as fp:
            response = client.delete_object(Bucket=bucket_name, Key=file_key, Body=fp)
        etag = get_etag(response)
        resource_file_map[file_key] = etag
        logger.info(f'deleted {file_key}[{etag}] in {vendor}')



def listdir_iter(path):
    for f in os.listdir(path):
        full_path = os.path.join(path, f)
        if os.path.isfile(full_path):
            delete(full_path)
        elif os.path.isdir(full_path):
            listdir_iter(full_path)


def main():
    logger.info(f'working at {base_path}')
    logger.info('delete resource lock file.')
    global resource_file_map, resource_file_set

    if os.path.exists(resource_lock_file):
        with open(resource_lock_file) as json_file:
            resource_file_map = json.load(json_file)

    listdir_iter(resource_base_path)

    mapping = copy.copy(resource_file_map)
    for k in mapping.keys():
        if k not in resource_file_set:
            resource_file_map.pop(k, None)

    with open(resource_lock_file, 'w') as fp:
        fp.write(json.dumps(resource_file_map, ensure_ascii=False, sort_keys=True, indent=2))
    logger.info('successfully deleted resource lock file.')


if __name__ == '__main__':
    main()