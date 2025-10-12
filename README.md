# Ansible Tenant Onboarding

This repository implements an example onboarding for new tenants. A tenant is a user or a group of users that would like to deploy and use their automation code on Ansible Automation Platform (AAP).

The goal is enabling tenants to work independently of the platform team operating Ansible Automation
Platform.

Onboarding of tenants provided by the platform team is done via Configuration as Code (CaC). This repository contains all relevant automation code.

Furthermore, each tenant will get a separate repository containing automation code relevant to the tenant.

Each tenant will get

- [x] An organization within AAP
- [x] A project pointing to the CaC repository for the tenant
- [x] A job template to trigger synchronization of AAP objects with the configuration stored in the CaC repository
- [x] An example repository containing an inventory and a simple playbook

## Onboarding process overview

![image](docs/images/onboarding_overview.png)
