#!/bin/bash

# Set the resource group name and service URL
resource_group="ghaf-infra-mikanokka"
service_url="ghaf-binary-cache-mikanokka.northeurope.cloudapp.azure.com"

# Get the list of VMs in the resource group
vms=$(az vm list -g $resource_group --query "[].name" -o tsv)

# Check if each VM exists
for vm in $vms
do
  vm_info=$(az vm show --name $vm --resource-group $resource_group --query "name" -o tsv)
  if [ -z "$vm_info" ]
  then
    echo "VM $vm does not exist"
  else
    echo "VM $vm exists"
  fi
done

# Test infra creation and destruction
# echo "Testing infra creation..."
# terraform apply -auto-approve
# echo "Testing infra destruction..."
# terraform destroy -auto-approve

# Test VM boot-up
echo "Testing VM boot-up..."
vms=$(az vm list -g $resource_group --query "[].name" -o tsv)
for vm in $vms
do
  status=$(az vm get-instance-view --name $vm --resource-group $resource_group --query "instanceView.statuses[?code=='PowerState/running']" -o tsv)
  if [ -z "$status" ]
  then
    echo "VM $vm did not boot up properly"
  else
    echo "VM $vm booted up properly"
  fi
done

# Test service start-up
# This will depend on the specific services you're running
# You might need to SSH into the VM and check the service status

# Test service accessibility
echo "Testing service accessibility..."
response=$(curl -s -o /dev/null -w "%{http_code}" $service_url)
if [ $response -eq 200 ]
then
  echo "The service at $service_url is accessible"
else
  echo "The service at $service_url is not accessible"
fi

# Trigger a build
curl -X POST http://jenkins_url/job/job_name/build --user username:token

# Wait for the build to finish
sleep 60

# Check if the build result is in the binary cache
build_result=$(curl -u username:password "http://artifactory_url/artifactory/api/storage/repository_name/build_name")

if [[ $build_result == *"errors"* ]]; then
  echo "Build result is not in the binary cache"
else
  echo "Build result is in the binary cache"
fi

# Verify the signing of the build result
# This will depend on how your signing is set up
# For example, you might have a script that checks the signature
./check-signature.sh build_name