import boto3
from botocore.config import Config

boto3.setup_default_session(profile_name='mcoombs2027')
ec2 = boto3.client('ec2')
list_instances = ec2.describe_instances()
for inst in list_instances['Reservations']:
    for id in inst['Instances']:
        print("Currently running instances: {} Instance type: {} Instance Keyname {}" 
              .format(id['InstanceId'],id['InstanceType'],id['KeyName']))
    

