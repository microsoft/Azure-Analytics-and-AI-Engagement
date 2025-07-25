require('dotenv').config();

const config = {
  azure: {
    tenantId: process.env.AZURE_TENANT_ID,
    clientId: process.env.AZURE_CLIENT_ID,
    clientSecret: process.env.AZURE_CLIENT_SECRET,
    tokenEndpoint: process.env.AZURE_TOKEN_ENDPOINT
  },
  lakehouse: {
    url: process.env.LAKEHOUSE_URL
  },
  server: {
    port: process.env.PORT || 3002
  }
};

module.exports = config; 