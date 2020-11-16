
build-x86:
	packer build \
		-var 'eks_version=1.18' \
		-var 'vpc_id=vpc-0e8cf1ce122b1b059' \
		-var 'subnet_id=subnet-0eddf1d7d0f9f9772' \
		./amazon-eks-node.json

build-arm64:
	packer build \
		-var 'eks_version=1.18' \
		-var 'vpc_id=vpc-0e8cf1ce122b1b059' \
		-var 'subnet_id=subnet-0eddf1d7d0f9f9772' \
		./amazon-eks-node-arm64.json
