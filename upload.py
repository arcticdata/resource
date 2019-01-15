# -*- coding: utf-8 -*-
import json
import logging
import os

from qcloud_cos import CosConfig, CosS3Client

logging.basicConfig(format='%(asctime)s - %(name)s - %(levelname)s - %(message)s', level=logging.INFO)
logger = logging.getLogger(__name__)

bucket = 'resource'
base_path = os.path.dirname(os.path.abspath(__file__))
resource_lock_file = os.path.join(base_path, 'resource_lock.json')
resource_file_map = {}
resource_base_path = os.path.join(base_path, bucket)
len_resource_path = len(resource_base_path) + 1

app_id = os.getenv('QCLOUD_APP_ID')
secret_id = os.getenv('QCLOUD_SECRET_ID')
secret_key = os.getenv('QCLOUD_SECRET_KEY')
bucket_url = '{}-{}'.format(bucket, app_id)

region = 'ap-shanghai'
config = CosConfig(Region=region, SecretId=secret_id, SecretKey=secret_key)  # 获取配置对象
client = CosS3Client(config)


def get_etag(response):
    if 'ETag' not in response:
        return None
    return response['ETag'][1:-1]  # remove quote


def upload(full_path):
    file_key = full_path[len_resource_path:]
    if not file_key:
        return
    logger.info('processing {}'.format(file_key))
    global resource_file_map

    # ignore same file
    if file_key in resource_file_map:
        etag = resource_file_map[file_key]
        response = client.head_object(Bucket=bucket_url, Key=file_key)
        if get_etag(response) == etag:
            logger.info('skipped {}[{}]'.format(file_key, etag))
            return

    with open(full_path, 'rb') as fp:
        response = client.put_object(Bucket=bucket_url, Key=file_key, Body=fp)
    etag = get_etag(response)
    resource_file_map[file_key] = etag
    logger.info('uploaded {}[{}]'.format(file_key, etag))


def listdir_iter(path):
    for f in os.listdir(path):
        full_path = os.path.join(path, f)
        if os.path.isfile(full_path):
            upload(full_path)
        elif os.path.isdir(full_path):
            listdir_iter(full_path)


def main():
    logger.info('working at {}'.format(base_path))
    logger.info('loading resource lock file.')
    global resource_file_map

    if os.path.exists(resource_lock_file):
        with open(resource_lock_file) as json_file:
            resource_file_map = json.load(json_file)

    listdir_iter(resource_base_path)

    with open(resource_lock_file, 'w') as fp:
        fp.write(json.dumps(resource_file_map, ensure_ascii=False, sort_keys=True))
    logger.info('successfully updated resource lock file.')


if __name__ == '__main__':
    main()
