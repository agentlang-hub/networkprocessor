module networkprocessor.core

record incidentInformation {
    sys_id String @optional,
    status String @optional,
    data Any @optional,
    category String @optional,
    ai_status String @optional,
    ai_processor String @optional,
    requires_human Boolean @optional,
    ai_reason String @optional,
    resolution String @optional
}

event handleVpnIssue {
    userEmail Email,
    issueType @enum("connection_failed", "slow_speed", "disconnects", "access_denied", "certificate_issue") @optional,
    location String @optional
}

workflow handleVpnIssue {
    console.log("++VPN_ISSUE++ " + handleVpnIssue.userEmail)
}

event handleFirewallRequest {
    requestType @enum("port_open", "port_close", "whitelist_ip", "blacklist_ip", "rule_change"),
    sourceIp String @optional,
    destinationIp String @optional,
    port String @optional,
    protocol @enum("tcp", "udp", "both") @optional,
    justification String @optional
}

workflow handleFirewallRequest {
    console.log("++FIREWALL_REQUEST++ " + handleFirewallRequest.requestType)
}

event handleConnectivityIssue {
    userEmail Email,
    issueType @enum("no_internet", "slow_network", "wifi_issue", "lan_issue", "dns_resolution") @optional,
    affectedService String @optional,
    location String @optional
}

workflow handleConnectivityIssue {
    console.log("++CONNECTIVITY_ISSUE++ " + handleConnectivityIssue.userEmail)
}

agent vpnIssueHandler {
    instruction "Extract details and call handleVpnIssue.",
    tools "networkprocessor.core/handleVpnIssue"
}

agent firewallRequestHandler {
    instruction "Extract details and call handleFirewallRequest.",
    tools "networkprocessor.core/handleFirewallRequest"
}

agent connectivityHandler {
    instruction "Extract details and call handleConnectivityIssue.",
    tools "networkprocessor.core/handleConnectivityIssue"
}

agent networkTriager {
    instruction "Classify the network issue into VPN_ISSUE, FIREWALL_REQUEST, CONNECTIVITY, or UNKNOWN.
Only return one of the strings [VPN_ISSUE, FIREWALL_REQUEST, CONNECTIVITY, UNKNOWN] and nothing else."
}

flow networkOrchestrator {
    networkTriager --> "VPN_ISSUE" vpnIssueHandler
    networkTriager --> "FIREWALL_REQUEST" firewallRequestHandler
    networkTriager --> "CONNECTIVITY" connectivityHandler
    networkTriager --> "UNKNOWN" {servicenow/incident {sys_id? incidentInformation.sys_id, ai_status "failed-to-process", requires_human true}}
    vpnIssueHandler --> {servicenow/incident {sys_id? incidentInformation.sys_id, ai_status "processed"}}
    firewallRequestHandler --> {servicenow/incident {sys_id? incidentInformation.sys_id, ai_status "processed"}}
    connectivityHandler --> {servicenow/incident {sys_id? incidentInformation.sys_id, ai_status "processed"}}
}

@public agent networkOrchestrator {
    role "You are a network operations specialist handling VPN, firewall, and connectivity issues."
}

workflow @after update:servicenow/incident {
    if (servicenow/incident.category == "NETWORK" or servicenow/incident.ai_processor == "network") {
        {incidentInformation {
            sys_id servicenow/incident.sys_id,
            status servicenow/incident.state,
            data servicenow/incident.data,
            category servicenow/incident.category,
            ai_status servicenow/incident.ai_status,
            ai_processor servicenow/incident.ai_processor,
            requires_human servicenow/incident.requires_human,
            ai_reason servicenow/incident.ai_reason,
            resolution servicenow/incident.resolution
        }}

        {networkOrchestrator {message servicenow/incident}}
    }
}
