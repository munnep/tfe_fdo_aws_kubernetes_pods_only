from diagrams import Cluster, Diagram, Edge
from diagrams.aws.compute import EC2, ElasticKubernetesService
from diagrams.aws.network import VPC, PublicSubnet, ElbApplicationLoadBalancer
from diagrams.onprem.compute import Server
from diagrams.onprem.client import User
from diagrams.k8s.compute import Pod
from diagrams.k8s.storage import PV

# Variables
title = "VPC with 2 public subnets for the kubernetes cluster\nTFE with ephemeral PostgreSQL, Redis, and MinIO pods"
outformat = "png"
filename = "diagram_tfe_kubernetes"
direction = "TB"


with Diagram(
    name=title,
    direction=direction,
    filename=filename,
    outformat=outformat,
) as diag:
    # Non Clustered
    user = User("user")

    # Kubernetes Pods (separate from AWS infrastructure)
    with Cluster("TFE Application Layer"):
        tfe_pod = Pod("TFE Application")
        postgres_pod = Pod("PostgreSQL")
        redis_pod = Pod("Redis")
        minio_pod = Pod("MinIO Storage")

    # Cluster 
    with Cluster("aws"):
        with Cluster("vpc"):
            # Load Balancer in public network
            load_balancer = ElbApplicationLoadBalancer("Application Load Balancer")
    
            with Cluster("Availability Zone: eu-north-1b"):
                # Subcluster 
                with Cluster("subnet_public2"):
                    with Cluster("EKS Node"):
                        kubernetes2 = ElasticKubernetesService("Kubernetes Node")
                            
            with Cluster("Availability Zone: eu-north-1a"):
                # Subcluster 
                with Cluster("subnet_public1"):
                    with Cluster("EKS Node"):
                        kubernetes1 = ElasticKubernetesService("Kubernetes Node")
                            
    # Diagram connections
    user >> load_balancer >> [kubernetes1, kubernetes2]
    
    tfe_pod >> [postgres_pod, redis_pod, minio_pod]
    
    [kubernetes1, kubernetes2] >> tfe_pod

diag
