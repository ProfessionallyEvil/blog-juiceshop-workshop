from aws_cdk import (
    # Duration,
    Stack,
    aws_ec2 as ec2,
    aws_iam as iam,
    aws_ecs as ecs,
)
from constructs import Construct
from requests import get as r_get

class DeployJuiceshopStack(Stack):

    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        juiceshop_port = 3000
        whitelisting_ips = {
            # pulls you're current external IP address
            f"{r_get('https://api.ipify.org/?format=json').json()['ip']}/32": 'your current ip address'
        }
        wanted_containers = 5

        vpc = ec2.Vpc(self, 'CTF_VPC', cidr='10.10.1.0/24')
        ## if you already have a VPC you'd like to deploy to you can use the following code
        ##   it's a bit harder to lookup a VPC (in CDK), so you'll need to uncomment everything below this line
        # vpc = ec2.Vpc.from_lookup(self, "CTF_VPC", vpc_id="<vpc_id>")
        # subnet_id = '<subnet_id>'
        # subnets_in_az = vpc.select_subnets(
        #     availability_zones=Stack.of(self).availability_zones,
        #     # needed to access ec2 subnets that can pull a public IP
        #     subnet_type=ec2.SubnetType.PUBLIC
        # )
        # subnets = []
        # azs = []
        # for subnet in subnets_in_az.subnets:
        #     if subnet_id == subnet.subnet_id:
        #         azs.append(subnet.availability_zone)
        #         subnets.append(subnet)
        # selected_subnets = ec2.SubnetSelection(
        #     availability_zones=azs,
        #     subnets=subnets
        # )

        task_iam_role = iam.Role(self, "AppRole", role_name="JuiceShopRole", assumed_by=iam.ServicePrincipal('ecs-tasks.amazonaws.com'))
        task_def = ecs.FargateTaskDefinition(self, "JuiceShopTask", task_role=task_iam_role)
        task_def.add_container(
            "JuiceShop",
            image=ecs.ContainerImage.from_registry('docker.io/bkimminich/juice-shop:latest'),
            port_mappings=[{'containerPort': juiceshop_port}],
            memory_limit_mib=256,
            cpu=256,
        )
        cluster = ecs.Cluster(self, 'JSCluster', vpc=vpc )

        external_access = ec2.SecurityGroup(self, 'InternetAccess',
            vpc=vpc,
            security_group_name='InternetAccessJuiceShop',
        )
        for external_ip, desc in whitelisting_ips.items():
            external_access.add_ingress_rule(ec2.Peer.ipv4(external_ip), ec2.Port.tcp(juiceshop_port), desc)

        fg_cluster = ecs.FargateService(self, 'CTFFargate',
            task_definition=task_def,
            assign_public_ip=True,
            # vpc_subnets=selected_subnets,
            cluster=cluster,
            service_name='JuiceShop',
            desired_count=wanted_containers,
            enable_execute_command=True,
            security_groups=[external_access]
        )
