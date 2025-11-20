module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.4"

  cluster_name    = var.cluster_name
  cluster_version = "1.29"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # EKS API endpoint access
  cluster_endpoint_public_access       = true
  cluster_endpoint_private_access      = true
  
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

  # Managed node group
  eks_managed_node_groups = {
    default = {
      desired_size = 2
      max_size     = 3
      min_size     = 1

      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
    }
  }
  node_security_group_additional_rules = {
    ingress_http_8080 = {
      description      = "Allow inbound 8080"
      protocol         = "tcp"
      from_port        = 8080
      to_port          = 8080
      type             = "ingress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  enable_cluster_creator_admin_permissions = true


  access_entries = {
    jenkins_admin = {
      principal_arn = "arn:aws:iam::903467494111:role/march-2025-eks-role"

      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type       = "cluster"
            namespaces = []
          }
        }
      }
    }
  }

  tags = {
    Environment = "dev"
  }
}
