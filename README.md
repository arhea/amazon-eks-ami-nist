# NIST 800-53 Amazon EKS Optimized AMI

This AMI extends the [Amazon EKS Optimized AMI](https://github.com/awslabs/amazon-eks-ami) with the hardening typically required to meet NIST 800-53 based compliance frameworks such as FedRAMP. This repository uses Packer to enable FIPS 140-2 validated modules and apply the [Amazon Linux 2](https://www.cisecurity.org/benchmark/amazon_linux/), [Docker](https://www.cisecurity.org/benchmark/docker/), and [EKS](https://aws.amazon.com/about-aws/whats-new/2020/07/announcing-cis-benchmark-for-amazon-eks/) CIS Benchmarks.

*Disclaimer: This AMI is not gaurenteed to meet FedRAMP requirements and you should always confirm with your compliance, security, and 3PAO that this AMI is sufficient. This is not an official AMI from Amazon or AWS.*

## Usage

Similar to the EKS Optimized AMI, this AMI is built using the same tooling.

```bash

# build a x86 AMI for EKS
packer build \
  -var 'eks_version=1.18' \
  -var 'vpc_id=vpc-0e8cf1ce122b1b059' \
  -var 'subnet_id=subnet-0eddf1d7d0f9f9772' \
  -var 'volume_size=100' \
  ./amazon-eks-node.json

  # build a arm64 AMI for EKS
packer build \
  -var 'eks_version=1.18' \
  -var 'vpc_id=vpc-0e8cf1ce122b1b059' \
  -var 'subnet_id=subnet-0eddf1d7d0f9f9772' \
  -var 'volume_size=100' \
  ./amazon-eks-node-arm64.json
```

| Parameter | Default | Supported | Description |
|-----------|---------|-----------|-------------|
| eks_version | `1.18` | Any major version supported by EKS | The major Kubernetes version that aligns to your EKS cluster. |
| vpc_id | | `vpc-xxxxxxxxxxxxxxxxx` | The ID of the VPC to place the Packer builder. |
| subnet_id | | `subnet-xxxxxxxxxxxxxxxxx` | The ID of the Subnet to place the Packer builder. |
| volume_size | `100` | Any whole number in Gb | The size of the secondary volume. |

## License

This library is licensed under the MIT-0 License. See the [LICENSE file](./LICENSE).
