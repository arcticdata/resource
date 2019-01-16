# -*- coding: utf-8 -*-
import json
import logging
import os
import shutil

import boto3
import qcloud_cos
import requests

logging.basicConfig(format='%(asctime)s - %(name)s - %(levelname)s - %(message)s', level=logging.INFO)
logger = logging.getLogger(__name__)

bucket = 'resource'
base_path = os.path.dirname(os.path.abspath(__file__))
resource_lock_file = os.path.join(base_path, 'resource_lock.json')
resource_file_map = {}
resource_file_set = set()

resource_base_path = os.path.join(base_path, bucket)
len_resource_path = len(resource_base_path) + 1

bucket_name = '{}-{}'.format(bucket, os.getenv('QCLOUD_APP_ID'))
tencentcloud_client = qcloud_cos.CosS3Client(qcloud_cos.CosConfig(
    Region='ap-shanghai',
    SecretId=os.getenv('QCLOUD_SECRET_ID'),
    SecretKey=os.getenv('QCLOUD_SECRET_KEY')
))

qingcloud_client = boto3.client(
    's3',
    endpoint_url='https://s3.sh1a.qingstor.com',
    aws_access_key_id=os.getenv('qingcloud_access_key_id'),
    aws_secret_access_key=os.getenv('qingcloud_secret_access_key'),
)


def get_etag(response):
    if 'ETag' not in response:
        return None
    return response['ETag'][1:-1]  # remove quote


def upload(full_path):
    file_key = full_path[len_resource_path:]
    if not file_key:
        return

    global resource_file_map, resource_file_set

    resource_file_set.add(file_key)

    # ignore same file
    if file_key in resource_file_map:
        etag = resource_file_map[file_key]
        try:
            response = tencentcloud_client.head_object(Bucket=bucket_name, Key=file_key)
            if get_etag(response) == etag:
                logger.info('skipped {}[{}]'.format(file_key, etag))
                return
        except qcloud_cos.CosServiceError:
            pass

    # upload to TencentCloud
    with open(full_path, 'rb') as fp:
        response = tencentcloud_client.put_object(Bucket=bucket_name, Key=file_key, Body=fp)
    etag = get_etag(response)
    resource_file_map[file_key] = etag
    logger.info('uploaded {}[{}] to TencentCloud'.format(file_key, etag))

    # upload to QingCloud
    with open(full_path, 'rb') as fp:
        response = qingcloud_client.put_object(Bucket=bucket_name, Key=file_key, Body=fp)
    print(response)
    exit()
    return


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
    version_path = os.path.join(resource_base_path, 'react', 'v{}'.format(react_version))
    os.makedirs(version_path, exist_ok=True)
    for module in ['react', 'react-dom']:
        url = base_url.format(m=module, v=react_version)
        r = requests.get(url, stream=True)
        filename = '{}.production.min.js'.format(module)
        if r.status_code == 200:
            with open(os.path.join(version_path, filename), 'wb') as f:
                r.raw.decode_content = True
                shutil.copyfileobj(r.raw, f)
                logger.info('Saving {} success'.format(filename))
        else:
            logger.error('Downloading {} error'.format(filename))


if __name__ == '__main__':
    # download_react('16.7.0')
    main()
