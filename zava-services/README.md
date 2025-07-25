# Azure Lakehouse Data Server

A Node.js server that authenticates with Azure using service principal credentials and fetches data from Azure Fabric Lakehouse.

## Features

- 🔐 Azure Service Principal authentication
- 📊 Fetch data from Azure Fabric Lakehouse
- 🔄 Automatic token refresh
- 📋 CSV to JSON conversion
- 🏥 Health check endpoints
- 🛡️ Error handling and logging

## Prerequisites

- Node.js (v14 or higher)
- npm or yarn
- Azure service principal credentials

## Installation

1. Clone or download this project
2. Install dependencies:
   ```bash
   npm install
   ```

## Configuration

The server uses Azure service principal credentials, which should be provided as environment variables:

- **AZURE_TENANT_ID**
- **AZURE_CLIENT_ID**
- **AZURE_CLIENT_SECRET**
- **AZURE_TOKEN_ENDPOINT**

Set these in your environment or in a `.env` file (if supported by your environment):

```bash
export AZURE_TENANT_ID=your-tenant-id
export AZURE_CLIENT_ID=your-client-id
export AZURE_CLIENT_SECRET=your-client-secret
export AZURE_TOKEN_ENDPOINT=https://login.microsoftonline.com/your-tenant-id/oauth2/v2.0/token
```

## Running the Server

### Development Mode
```bash
npm run dev
```

### Production Mode
```bash
npm start
```

The server will start on port 3000 by default. You can change this by setting the `PORT` environment variable.

## API Endpoints

### 1. Root Endpoint
- **URL**: `GET /`
- **Description**: Server information and available endpoints
- **Response**: JSON with server details and endpoint list

### 2. Health Check
- **URL**: `GET /health`
- **Description**: Check server health and uptime
- **Response**: 
  ```json
  {
    "status": "healthy",
    "timestamp": "2024-01-01T00:00:00.000Z",
    "uptime": 123.456
  }
  ```

### 3. Configuration
- **URL**: `GET /config`
- **Description**: Get current configuration (without sensitive data)
- **Response**: JSON with Azure and Lakehouse configuration

### 4. Raw Data
- **URL**: `GET /data`
- **Description**: Fetch raw data from Lakehouse
- **Response**: 
  ```json
  {
    "success": true,
    "data": "CSV content...",
    "contentType": "text/csv",
    "contentLength": "1234"
  }
  ```

### 5. JSON Data
- **URL**: `GET /data/json`
- **Description**: Fetch data from Lakehouse and convert to JSON
- **Response**: 
  ```json
  {
    "success": true,
    "data": [
      {
        "column1": "value1",
        "column2": "value2"
      }
    ],
    "totalRecords": 100,
    "headers": ["column1", "column2"]
  }
  ```

## Error Responses

All endpoints return consistent error responses:

```json
{
  "success": false,
  "error": "Error description",
  "message": "Detailed error message"
}
```

## Lakehouse Data Source

The server fetches data from:
```
https://onelake.dfs.fabric.microsoft.com/Azure_Hero_DreamDemo/Lakehouse_Bronze.Lakehouse/Files/bronze/Dimension%20Customer.csv/part-00000-d096d7c5-e06a-4e88-9fc4-a819c967fd4c-c000.csv
```

## Authentication Flow

1. Server obtains access token from Azure AD using service principal credentials
2. Token is cached and automatically refreshed before expiry
3. Bearer token is used to authenticate requests to Lakehouse
4. Data is fetched and optionally converted to JSON format

## Security Notes

- Service principal credentials are stored in `config.js`
- In production, consider using environment variables or Azure Key Vault
- Tokens are automatically refreshed to maintain security
- All requests include proper headers and timeout settings

## Troubleshooting

### Common Issues

1. **Authentication Failed**
   - Verify service principal credentials
   - Check if service principal has proper permissions on Lakehouse
   - Ensure tenant ID is correct

2. **Data Fetch Failed**
   - Verify Lakehouse URL is accessible
   - Check network connectivity
   - Ensure proper permissions on the data file

3. **Token Expiry**
   - Tokens are automatically refreshed
   - Check logs for authentication errors

### Logs

The server provides detailed logging for:
- Authentication attempts
- Token refresh operations
- Data fetch operations
- Error conditions

## Development

### Project Structure
```
server-node/
├── index.js          # Main server file
├── config.js         # Configuration file
├── package.json      # Dependencies and scripts
└── README.md         # This file
```

### Adding New Endpoints

1. Add route handlers in `index.js`
2. Follow the existing error handling pattern
3. Use the `lakehouseService` for data operations
4. Test with the health check endpoint first

## License

ISC 