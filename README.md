![Ansible Automation Platform Logo](docs/images/Logo-Red_Hat-Ansible_Automation_Platform.jpeg)

# Ansible Automation Platform Tenant Onboarding

This repository implements an example onboarding process for new
tenants to Ansible Automation Platform. A tenant is a user or a group
of users that would like to deploy and use their automation code on
Ansible Automation Platform (AAP).

> [!NOTE]
> The goal is enabling tenants to work independently of the platform
> team operating Ansible Automation Platform.

> [!WARNING]
> The code in this repository is a proof of concept. It
> it's not considered production ready! You have been warned, this might
> eat your cat.

- [Onboarding process and required objects](https://github.com/tosmi-ansible/aap-onboarding?tab=readme-ov-file#onboarding-process-and-required-objects)
- [Onboarding process overview](https://github.com/tosmi-ansible/aap-onboarding?tab=readme-ov-file#onboarding-process-overview)
- [Implementation options](https://github.com/tosmi-ansible/aap-onboarding?tab=readme-ov-file#implementation-options)
  - [Using infra.aap_configuration.dispatch role](https://github.com/tosmi-ansible/aap-onboarding?tab=readme-ov-file#using-infraapp_configuration)
  - [Using a custom role](https://github.com/tosmi-ansible/aap-onboarding?tab=readme-ov-file#using-a-custom-role-for-onboarding)
- [Manual steps to be automated](https://github.com/tosmi-ansible/aap-onboarding?tab=readme-ov-file#manual-steps-to-be-automated)
- [Open Topics](https://github.com/tosmi-ansible/aap-onboarding?tab=readme-ov-file#open-topics)
- [Prerequisites](https://github.com/tosmi-ansible/aap-onboarding?tab=readme-ov-file#open-topics)

This was presented on the 2nd Ansible Anwendertreffen (User Group Meetup) in Austria. The slides are available [here](https://github.com/tosmi-ansible/aap-onboarding/blob/main/docs/Ansible%20Anwender%20Treffen%20202602%20-%20Slides.pdf).

## Onboarding process and required objects

Each tenant will get

- [x] An organization within AAP
- [x] A GIT clone of a repository for storing AAP Settings for the tenant as CaC ([template-org-config](https://github.com/tosmi-ansible/template-org-config))
- [x] A GIT clone of a repository with an example playbook and inventory ([template-example-project](https://github.com/tosmi-ansible/template-example-project))
- [x] An AAP project pointing to the CaC repository for the tenant
- [x] An AAP project pointing to the example project repository for the tenant
- [x] A job template to trigger synchronization of AAP objects with the configuration stored in the CaC repository (tenant-org-config)
- [x] A job template using the [example project](https://github.com/tosmi-ansible/template-example-project/playbooks/hello-world.yaml)
- [x] A job template for pinging machines using the [example project](https://github.com/tosmi-ansible/template-example-project/playbooks/ping.yaml)
- [x] A webhook configured on the tenant CaC repository to [trigger updates](https://github.com/tosmi-ansible/template-org-config/blob/main/playbooks/org-config.yaml) on _git push_
- [x] A webhook on the example project to [deploy new test Virtual Machine](https://github.com/tosmi-ansible/template-org-config/blob/main/playbooks/devenv.yaml) on branch creation
- [x] A [policy](https://github.com/tosmi-ansible/aap-onboarding/blob/main/policies/jt_naming_validation.rego) on the tenant organization to enforce naming conventions on job templates (<id>-<tenant name>-<name of job template)

The example project is a "golden" templates for tenants so they have
an example on how to create their own automation using configuration
as code with AAP. It also provides the option to deploy virtual
machines for testing new features (see the link above).

There are still some manual tasks required. Those tasks are documented
in section [Manual steps to be automated](#manual-steps-to-be-automated). The ultimate goal is to
automate these as well, but this is an ongoing project.

## Onboarding process overview

The following diagram illustrates the onboarding process for new tenants:

![image](docs/images/onboarding_flow.jpg)

- The platform admin adds a new tenant to the platform onboarding repository
  - We would recommend separating onboarding code from other AAP configuration as code (for example day 2 customization's, aka settings)
- The [onboarding playbook](https://github.com/tosmi-ansible/aap-onboarding/blob/main/playbooks/onboarding.yaml)
  triggers the creation of all required objects in AAP for a tenant.
- A clone of the template-org-config repository is created and assigned to the tenant
- A clone of the example-org-config repository is created and assigned to the tenant
- The [tenant CaC job template](https://github.com/tosmi-ansible/template-org-config/blob/main/playbooks/org-config.yaml) creates objects required in the Org.
  - The example project gets created

### Separation of concerns

The onboarding process is designed with a clear separation of concerns:

- **Platform-level Configuration (Superuser required)** :The [platform onboarding CaC playbook](https://github.com/tosmi-ansible/aap-onboarding/blob/main/playbooks/onboarding.yaml) creates object that *only a AAP superuser* is able to create (e.g. organizations). This includes credentials required within the organization, which are not exposed to the tenant (e.g. GitHub tokens).
- **Tenant-level Configuration (Organization admin required)**: The tenant CaC playbook creates all objects within the organization that do *not* require superuser privileges

## Implementation options

Onboarding of tenants by the platform team is done via Configuration
as Code (CaC).

We cover two options in this repository:

- Using [_infra.app_configuration_](https://github.com/redhat-cop/infra.aap_configuration)
- Creating a [custom role](roles/onboard) for onboarding

### Using [_infra.app_configuration_](https://github.com/redhat-cop/infra.aap_configuration)

Our first approach was to leverage the excellent
[_infra.app_configuration_](https://github.com/redhat-cop/infra.aap_configuration)
collection for onboarding. This allows clean separation of
configuration code from configuration data. All configuration data is
stored in an Ansible inventory.

The problem with this approach is that this results in complex variable
merging, which we do not consider practical.

The code for this implementation is in
[onboarding-dispatch.yaml](playbooks/onboarding-dispatch.yaml) and the
inventory. The inventory is currently a private repository. We need to
clean this repository up and will change to public after the cleanup.

[_infra.app_configuration_](https://github.com/redhat-cop/infra.aap_configuration)
uses the standard AAP collections _ansible.platform_,
_ansible.controller_, _ansible.hub_ and _ansible.eda_ in the
background. We could have used those collections directly, but this
has the following disadvantages:

- We need to be careful separating automation code and data
- We need to be careful with ordering required objects. For example,
  before a job template is created, the project needs to exist.

The _dispatch_ role in the _infra.aap_configuration_ takes care of
ordering, and by storing configuration data in the inventory we have a
clear distinction between code and data.

### Using a custom role for onboarding

Because we did not want to mess with complex variable merging, we
decided to implement a custom role for onboarding. The role is
located in [roles/onboard](roles/onboard).

[roles/onboard/main.yaml](roles/onboard/main.yaml) creates the main
objects required for a tenant:

- The organization
- Assign credentials to access automation hub
- Creating a local admin user for tokens
- A authentication token and credential for the tenant admin user to deploy AAP configuration via CaC
- A credential to access a OpenShift (Kubernetes) cluster for deployment of virtual machines
- A vault credential for the tenant
- A fork of the template CaC repository
- A webhook on the CaC repository to deploy CaC code on a git push event

The *main* role also includes [tasks for the tenant example project](https://github.com/tosmi-ansible/aap-onboarding/blob/main/roles/onboard/tasks/example_project.yaml), this role:

- Forks the [template example project](https://github.com/tosmi-ansible/template-example-project)
- Enables a webhook on the forked project which triggers [devenv.yaml](https://github.com/tosmi-ansible/template-org-config/blob/main/playbooks/devenv.yaml).
  - This is a demonstration on how to provision VM's for testing automation code
  - It is only triggered if a new feature branch is created in the example-project repository

Furthermore there is
[opa_policy.yaml](roles/onboard/tasks/opa_policy.yaml) to add a OPA
policy to the organization.

## Manual steps to be automated

- [ ] Automate creation of tokens for GIT repos (GitLab / GitHub)
- [ ] Deployment of OPA and required policies

## Open Topics

- [ ] Create an execution environment with all collections required for onboarding and CaC
- [ ] Tenant 1 has no inventory source configured, so the second example task using a variable fails
- [ ] Tenant 1 currently uses the Hub tokens for community / certified and validated of the default organization. Not sure if this is a good idea.

## Prerequisites

This section lists prerequisites before the onboarding playbook is able to finish successfully.

### Required Ansible collections must be available on the Private Automation hub

The following collections must be available on the Private Automation Hub:

- ansible.controller (Red Hat Galaxy)
- ansible.platform (Red Hat Galaxy)
- ansible.hub (Red Hat Galaxy)
- ansible.eda (Red Hat Galaxy)
- infra.aap_configuration (Ansible Galaxy)
- infra.aap_utilities (Ansible Galaxy)
- kubernetes.core (Red Hat Galaxy): to provision VM's on OpenShift Virtualization

### Hints for syncing collections

#### Dependency between _infra_ and ansible_ collections

_infra.*_ collections have dependency on _ansible.*_ collections. those _ansible_ collections are only available via Red Hat Galaxy. If we pull the _infra_ collection from Galaxy and _ansible_ from Red Hat Galaxy, the hub community sync job fails because it cannot authenticate to the Red Hat Galaxy. One workaround was to disable dependency syncing in the _community_ remote.

But the _infra_ collections are also available on Red Hat Galaxy. So a better option is to pull everything from Red Hat Galaxy. This way we can avoid the dependency issue and the authentication issue. We need to sync the _validated_ collections to our Private Automation Hub. There's a [knowledge base article](https://access.redhat.com/solutions/7057141) describing required steps.

We added the following under _Automation Content / Remotes / validated / YAML requirements:

```yaml
collections:
  - name: infra.aap_configuration
    version: 3.8.2
  - name: infra.aap_utilities
    version: 2.8.0
```
