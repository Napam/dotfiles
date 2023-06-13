How to setup azure kubernetes
1. `az login` &rarr; login into azure cli
1. `az account list -o table` &rarr; list subscriptions
1. `az account set -s <SubscriptionId>` &rarr; set active subscription
1. `az aks list -o table` &rarr; view kubernetes stuff
1. `az aks get-credentials -g <ResourceGroup> -n <Name> --admin` &rarr; get .kube info for cluster
