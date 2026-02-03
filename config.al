{
    "store": {
        "type": "sqlite",
        "dbname": "networkprocessor_db"
    },
    "service": {
        "port": "#js parseInt(process.env.SERVICE_PORT || '8084')"
    },
    "integrations": {
        "host": "#js process.env.INTEG_MANAGER_HOST || 'http://localhost:8000'",
        "username": "#js process.env.INTEG_MANAGER_USER || ''",
        "password": "#js process.env.INTEG_MANAGER_PASSWORD || ''",
        "connections": {
            "servicenow": "networkprocessor/servicenow"
        }
    }
}
