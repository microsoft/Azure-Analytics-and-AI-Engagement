const axios = require('axios');

async function testEndpoints() {
  const baseUrl = 'http://localhost:3000';
  
  console.log('🧪 Testing Azure Lakehouse Data Server...\n');
  
  try {
    // Test health endpoint
    console.log('1. Testing health endpoint...');
    const healthResponse = await axios.get(`${baseUrl}/health`);
    console.log('✅ Health check passed:', healthResponse.data);
    
    // Test config endpoint
    console.log('\n2. Testing config endpoint...');
    const configResponse = await axios.get(`${baseUrl}/config`);
    console.log('✅ Config retrieved:', configResponse.data);
    
    // Test data endpoint (this will attempt to fetch from Lakehouse)
    console.log('\n3. Testing data endpoint...');
    try {
      const dataResponse = await axios.get(`${baseUrl}/data`);
      console.log('✅ Data endpoint response:', {
        success: dataResponse.data.success,
        contentType: dataResponse.data.contentType,
        contentLength: dataResponse.data.contentLength,
        dataPreview: dataResponse.data.data ? dataResponse.data.data.substring(0, 200) + '...' : 'No data'
      });
    } catch (error) {
      console.log('⚠️  Data endpoint test (this is expected if Azure credentials need setup):', error.response?.data || error.message);
    }
    
    // Test JSON endpoint
    console.log('\n4. Testing JSON endpoint...');
    try {
      const jsonResponse = await axios.get(`${baseUrl}/data/json`);
      console.log('✅ JSON endpoint response:', {
        success: jsonResponse.data.success,
        totalRecords: jsonResponse.data.totalRecords,
        headers: jsonResponse.data.headers,
        dataPreview: jsonResponse.data.data ? jsonResponse.data.data.slice(0, 2) : 'No data'
      });
    } catch (error) {
      console.log('⚠️  JSON endpoint test (this is expected if Azure credentials need setup):', error.response?.data || error.message);
    }
    
    console.log('\n🎉 All endpoint tests completed!');
    console.log('\n📋 Available endpoints:');
    console.log(`   GET ${baseUrl}/health - Health check`);
    console.log(`   GET ${baseUrl}/config - Configuration info`);
    console.log(`   GET ${baseUrl}/data - Raw Lakehouse data`);
    console.log(`   GET ${baseUrl}/data/json - Lakehouse data as JSON`);
    
  } catch (error) {
    console.error('❌ Test failed:', error.message);
    if (error.code === 'ECONNREFUSED') {
      console.log('💡 Make sure the server is running with: npm start');
    }
  }
}

// Run the test
testEndpoints(); 