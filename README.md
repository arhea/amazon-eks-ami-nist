# NIST 800-53 Amazon EKS Optimized AMI

This AMI extends the [Amazon EKS Optimized AMI](https://github.com/awslabs/amazon-eks-ami) with the hardening typically required to meet NIST 800-53 based compliance frameworks such as FedRAMP. This repository uses Packer to enable FIPS 140-2 validated modules and apply the [Amazon Linux 2](https://www.cisecurity.org/benchmark/amazon_linux/), [Docker](https://www.cisecurity.org/benchmark/docker/), and [EKS](https://aws.amazon.com/about-aws/whats-new/2020/07/announcing-cis-benchmark-for-amazon-eks/) CIS Benchmarks.

*Disclaimer: This AMI is not gaurenteed to meet FedRAMP requirements and you should always confirm with your compliance, security, and 3PAO that this AMI is sufficient. This is not an official AMI from AWS and is not officially supported.*

## Usage

Similar to the EKS Optimized AMI, this AMI is built using the same tooling.

```bash

# build a x86 AMI for EKS
packer build \
  -var 'eks_version=1.18' \
  -var 'vpc_id=vpc-xxxxxxxxxxxxxxxxx' \
  -var 'subnet_id=subnet-xxxxxxxxxxxxxxxxx' \
  -var 'volume_size=100' \
  ./amazon-eks-node.json

  # build a arm64 AMI for EKS
packer build \
  -var 'eks_version=1.18' \
  -var 'vpc_id=vpc-xxxxxxxxxxxxxxxxx' \
  -var 'subnet_id=subnet-xxxxxxxxxxxxxxxxx' \
  -var 'volume_size=100' \
  ./amazon-eks-node-arm64.json
```

| Parameter | Default | Supported | Description |
|-----------|---------|-----------|-------------|
| eks_version | `1.18` | Any major version supported by EKS | The major Kubernetes version that aligns to your EKS cluster. |
| vpc_id | | `vpc-xxxxxxxxxxxxxxxxx` | The ID of the VPC to place the Packer builder. |
| subnet_id | | `subnet-xxxxxxxxxxxxxxxxx` | The ID of the Subnet to place the Packer builder. |
| volume_size | `100` | Any whole number in Gb | The size of the secondary volume. |

## Hardening

This repository applies the following benchmarks as part of the NIST 800-53 requirements:

- [Amazon Linux 2 CIS Benchmark](https://www.cisecurity.org/benchmark/amazon_linux/)
- [Docker CIS Benchmark](https://www.cisecurity.org/benchmark/docker/)
- [Amazon EKS CIS Benchmark](https://aws.amazon.com/about-aws/whats-new/2020/07/announcing-cis-benchmark-for-amazon-eks/)

The repository also utilizes the Amazon Linux 2 FIPS validated modules:

| Module | Status | Certification | Date |
|--------|:---:|:-----:|:---:|
| Amazon Linux 2 Libreswan Cryptographic Module | :white_check_mark: | [3652](https://csrc.nist.gov/projects/cryptographic-module-validation-program/certificate/3652) | 05/08/2020 |
| Amazon Linux 2 NSS Cryptographic Module | :white_check_mark: | [3646](https://csrc.nist.gov/projects/cryptographic-module-validation-program/certificate/3646) | 04/20/2020 |
| Amazon Linux 2 GnuTLS Cryptographic Module | :white_check_mark: | [3643](https://csrc.nist.gov/projects/cryptographic-module-validation-program/certificate/3643) | 04/20/2020 |
| Amazon Linux 2 Libgcrypt Cryptographic Module | :white_check_mark: | [3618](https://csrc.nist.gov/projects/cryptographic-module-validation-program/certificate/3618) | 02/19/2020 |
| Amazon Linux 2 OpenSSH Client Cryptographic Module | :white_check_mark: | [3567](https://csrc.nist.gov/projects/cryptographic-module-validation-program/certificate/3567) | 11/20/2019 |
| Amazon Linux 2 OpenSSH Server Cryptographic Module | :white_check_mark: | [3562](https://csrc.nist.gov/projects/cryptographic-module-validation-program/certificate/3562) | 11/14/2019 |
| Amazon Linux 2 OpenSSL Cryptographic Module | :white_check_mark: | [3553](https://csrc.nist.gov/projects/cryptographic-module-validation-program/certificate/3553) | 10/23/2019 |
| Amazon Linux 2 Kernel Cryptographic API | :white_check_mark: | [3709](https://csrc.nist.gov/projects/cryptographic-module-validation-program/certificate/3709) | 09/14/2020  |

## Disk Layout

The resulting images consists of two disks, a root disk and a secondary disk. The secondary disk is used to add the required partitions to meet CIS Benchmark requirements.

| Disk | Mount Point | % of Secondary Volume Size | Description |
|------|-------------|----------------------------|-------------|
| `/dev/nvme1n1p1` |`/` | 20% | This is the root disk used by the EKS optimized AMI. |
| `/dev/nvme2n1p1` | `/var` | 20% | A separate partition for `/var` as required by the CIS Benchmark. |
| `/dev/nvme2n1p2` | `/var/log` | 20% | A separate partition for `/var/log` as required by the CIS Benchmark. |
| `/dev/nvme2n1p3` | `/var/log/audit` | 20% | A separate partition for `/var/log/audit` as required by the CIS Benchmark. |
| `/dev/nvme2n1p4` | `/home` | 10% | A separate partition for `/home` as required by the CIS Benchmark. |
| `/dev/nvme2n1p5` | `/var/lib/docker` | 30% | A separate partition for `/var/lib/docker` as required by the CIS Benchmark. |

## License

This library is licensed under the MIT-0 License. See the [LICENSE file](./LICENSE).
