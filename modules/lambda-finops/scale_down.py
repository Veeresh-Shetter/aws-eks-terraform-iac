import os
import boto3

eks = boto3.client("eks")

def handler(event, context):
    cluster_name = os.environ["CLUSTER_NAME"]
    nodegroup_name = os.environ["NODEGROUP_NAME"]

    response = eks.update_nodegroup_config(
        clusterName=cluster_name,
        nodegroupName=nodegroup_name,
        scalingConfig={
            "minSize": 0,
            "maxSize": 2,
            "desiredSize": 0
        }
    )
    print(f"Scaled down {nodegroup_name} in {cluster_name}: {response['update']['id']}")
    return {"status": "scaled_down", "update_id": response["update"]["id"]}
