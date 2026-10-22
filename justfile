fmt:
    tofu fmt -recursive
    shfmt -w scripts/

validate:
    tofu -chdir=infra/tofu validate
    kubeconform -strict cluster/**/*.yaml

plan:
    tofu -chdir=infra/tofu plan

status:
    kubectl get nodes -o wide
    kubectl get pods -A

