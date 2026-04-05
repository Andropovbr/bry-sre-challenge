## DNS Delegation Requirement

When using Route 53 hosted zones, it is not sufficient to create records inside the hosted zone. The domain must also be delegated to the hosted zone name servers at the registrar level.

In this project, the domain was registered in AWS Route 53 Domains, so it was necessary to explicitly configure the domain's name servers to match the hosted zone's authoritative name servers.

Without this step, public DNS resolvers returned `SERVFAIL`, even though the records were correctly defined inside Route 53.