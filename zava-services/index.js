require('dotenv').config();
const express = require('express');
const axios = require('axios');
const cors = require('cors');
const config = require('./config');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Azure Authentication Service
class AzureAuthService {
  constructor() {
    this.token = null;
    this.tokenExpiry = null;
  }

  async getAccessToken() {
    // Check if we have a valid token
    if (this.token && this.tokenExpiry && Date.now() < this.tokenExpiry) {
      return this.token;
    }

    try {
      const tokenResponse = await axios.post(config.azure.tokenEndpoint, {
        grant_type: 'client_credentials',
        client_id: config.azure.clientId,
        client_secret: config.azure.clientSecret,
        scope: 'https://storage.azure.com/.default'
      }, {
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded'
        }
      });

      this.token = tokenResponse.data.access_token;
      // Set token expiry (subtract 5 minutes for safety)
      this.tokenExpiry = Date.now() + (tokenResponse.data.expires_in * 1000) - (5 * 60 * 1000);

      console.log('Successfully obtained Azure access token');
      return this.token;
    } catch (error) {
      console.error('Error obtaining Azure access token:', error.response?.data || error.message);
      throw new Error('Failed to authenticate with Azure');
    }
  }
}

// Lakehouse Data Service
class LakehouseDataService {
  constructor(authService) {
    this.authService = authService;
  }

  async fetchData() {
    try {
      const token = await this.authService.getAccessToken();
      
      const response = await axios.get(config.lakehouse.url, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Accept': 'text/csv,application/json',
          'User-Agent': 'Lakehouse-Data-Fetcher/1.0'
        },
        timeout: 30000 // 30 second timeout
      });

      return {
        success: true,
        data: response.data,
        contentType: response.headers['content-type'],
        contentLength: response.headers['content-length']
      };
    } catch (error) {
      console.error('Error fetching data from Lakehouse:', error.response?.data || error.message);
      return {
        success: false,
        error: error.response?.data || error.message,
        status: error.response?.status
      };
    }
  }

  async fetchDataAsJson() {
    try {
      const result = await this.fetchData();
      
      if (!result.success) {
        return result;
      }

      // Parse CSV data to JSON
      const csvData = result.data;
      const lines = csvData.split('\n');
      const headers = lines[0].split(',').map(header => header.trim().replace(/"/g, ''));
      
      const jsonData = lines.slice(1)
        .filter(line => line.trim() !== '')
        .map(line => {
          const values = line.split(',').map(value => value.trim().replace(/"/g, ''));
          const row = {};
          headers.forEach((header, index) => {
            row[header] = values[index] || '';
          });
          return row;
        });

      return {
        success: true,
        data: jsonData,
        totalRecords: jsonData.length,
        headers: headers
      };
    } catch (error) {
      console.error('Error parsing CSV to JSON:', error.message);
      return {
        success: false,
        error: 'Failed to parse CSV data to JSON'
      };
    }
  }
}

// Initialize services
const authService = new AzureAuthService();
const lakehouseService = new LakehouseDataService(authService);

// Routes
app.get('/', (req, res) => {
  res.json({
    message: 'Azure Lakehouse Data Server',
    version: '1.0.0',
    endpoints: {
      '/health': 'Check server health',
      '/data': 'Get raw data from Lakehouse',
      '/data/json': 'Get data as JSON',
      '/config': 'Get current configuration (without secrets)'
    }
  });
});

app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

app.get('/config', (req, res) => {
  res.json({
    azure: {
      tenantId: config.azure.tenantId,
      clientId: config.azure.clientId,
      tokenEndpoint: config.azure.tokenEndpoint
    },
    lakehouse: {
      url: config.lakehouse.url
    },
    server: {
      port: config.server.port
    }
  });
});

app.get('/data', async (req, res) => {
  try {
    const result = await lakehouseService.fetchData();
    res.json(result);
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message
    });
  }
});

app.get('/data/json', async (req, res) => {
  try {
    const result = await lakehouseService.fetchDataAsJson();
    res.json(result);
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: error.message
    });
  }
});

// Error handling middleware
app.use((error, req, res, next) => {
  console.error('Unhandled error:', error);
  res.status(500).json({
    success: false,
    error: 'Internal server error',
    message: error.message
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: 'Endpoint not found',
    message: `Route ${req.method} ${req.path} not found`
  });
});

// Start server
app.listen(config.server.port, () => {
  console.log(`🚀 Server running on port ${config.server.port}`);
  console.log(`📊 Lakehouse URL: ${config.lakehouse.url}`);
  console.log(`🔗 Health check: http://localhost:${config.server.port}/health`);
  console.log(`📈 Data endpoint: http://localhost:${config.server.port}/data`);
  console.log(`📋 JSON endpoint: http://localhost:${config.server.port}/data/json`);
});
