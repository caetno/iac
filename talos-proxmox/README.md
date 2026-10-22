`identity/`
Creates the talos and kubernetes secrets.
We handle this seperateley so we can destroy and recreate the cluster while keeping the identity fixed.

`cluster/`
Creates the VMs for the cluster and bootstraps it using the identity from the remote state.

`platform/`
Is used to install essential addons and components like CNI, CSI, that bring their own CRDs. We ran into an issue where the kubernetes manifest for the Cilium CRDs failed when building the state from zero.
This could not be avoided with `depends-on`.

`resources/`
Containes Deployments, Services, ConfigMaps, CRs, Secrets, etc.
