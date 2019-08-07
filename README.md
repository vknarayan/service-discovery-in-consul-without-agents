# service-discovery-in-consul-without-agents

In an application with microservices architecture, the set of running service instances changes dynamically. Instances have dynamically assigned network locations. Consequently, in order for a client to make a request to a service, it must use a service‑discovery mechanism.

A key part of service discovery is the service registry. The service registry is a database of available service instances. The service registry provides a management API and a query API. Service instances are registered with and deregistered from the service registry using the management API. The query API is used by system components to discover available service instances.

There are two main service‑discovery patterns: client-side discovery and service-side discovery. In systems that use client‑side service discovery, clients query the service registry, select an available instance, and make a request. In systems that use server‑side discovery, clients make requests via a router, which queries the service registry and forwards the request to an available instance.

There are two main ways that service instances are registered with and deregistered from the service registry. One option is for service instances to register themselves with the service registry, the self‑registration pattern. The other option is for some other system component to handle the registration and deregistration on behalf of the service, the third‑party registration pattern. When using consult, we are using thir-part rgistration pattern. The consul agent monitors the services and registers/deregisters the same in the service registry / catalog.

When you are using consul for service discovery, suppose there is a requirement that you cannot use consul agent in all nodes where your services are running. When you have the agent, it takes care of deregistration / registration of services in the consul cluster. How do you handle this, when there is no consul agent on the node.

In this situation, you can use heartbeat to monitor the services remotely. The heartbeat sends the status of monitoring to elasticsearch. You query elasticsearch to know which services are down and in what node. You use this information to deregister the services in the cluster catalog. With this, the consul cluster will have the correct status of the services and so the service discovery will work in the same way when the consul agent is present.

This is done with shell script, elasticalert.sh
