
cd ..
mkdir -p tmp
terraform output -raw kubeconfig > tmp/kubeconfig.yaml
