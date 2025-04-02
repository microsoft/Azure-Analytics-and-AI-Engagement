/* Program.cs
Purpose: This tuorial program shows how to create a simple web application that uses a GraphQL query to return data from a Power BI dataset. 
Uses the GraphQL.Client library to send the query to the Power BI service, and then displays the results in a web page. 
Uses the DefaultAzureCredential class from the Azure.Identity library to authenticate with Azure Active Directory and 
get an access token to use in the query. 
It uses the WebApplication class from the Microsoft.AspNetCore.Components.WebAssembly.Hosting library to create a web application, 
and the GraphQLHttpClient class from the GraphQL.Client library to send the query. 
It also uses the GraphQLHttpRequest class from the GraphQL.Client library to define the query, and the NewtonsoftJsonSerializer 
class from the GraphQL.Client.Serializer.Newtonsoft library to serialize the response. 
We use the WriteAsync method of the HttpResponse class to write the HTML response to the web page.

Requirements: To run this program, you need to have the .NET SDK installed on your machine. 
You also need to have an Azure subscription and a Power BI dataset with a GraphQL API enabled.
You should install the required libraries with the following commands:

dotnet add package GraphQL.Client --version 3.3.0
dotnet add package GraphQL.Client.Serializer.Newtonsoft --version 3.3.0
dotnet add package Microsoft.AspNetCore.Components.WebAssembly.Hosting --version 5.0.7
dotnet add package Azure.Identity --version 1.4.1

Author: Buck Woody, Microft Corporation 
Last Modified: 2021.09.01
*/

// Set up your libraries
using GraphQL.Client.Http;
using GraphQL.Client.Serializer.Newtonsoft;
using Azure.Identity;

// Make a connection to Azure, and get a token
var credential = new DefaultAzureCredential();
var token = await credential.GetTokenAsync(new Azure.Core.TokenRequestContext(new[] { "https://analysis.windows.net/powerbi/api/.default" }));

// Set up your web application
var builder = WebApplication.CreateBuilder(args);
// Add services to the container.
builder.Services.AddRazorPages();
// Build the application
var app = builder.Build();

// Configure the HTTP request pipeline.
app.UseStaticFiles();
app.UseRouting();

// Add the Razor pages
app.MapRazorPages();
// Add the GraphQL query initial web page
app.MapGet("/", async context =>
{
    var html = @"
<!DOCTYPE html>
<html lang='en'>
<head>
    <meta charset='UTF-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1.0'>
    <title>Product Count by Suppliers</title>
    <link rel='stylesheet' href='https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css'>

    <style>
        .form-inline .form-control {
            width: auto;
            flex: 0 0 50px; /* Adjust the width as needed */
        }
        .form-inline .btn {
            margin-left: 10px; /* Adjust the margin as needed */
        }
    </style>
</head>

<body>
    <div class='container mt-5'>
      <img src='./contoso.png' alt='Contoso Logo' width='200'>
        <h3>Product Count by Suppliers</h3>
        <p><i>Supplier Network Control Center - Supplier Sector Impact Zones by Product (Function NCC-1701)</i></p>
        <p>Enter the impacted Location ID for the Supplier that is facing the outage. The system will return the other Suppliers within that impact area and show the count of items each Supplier provides to Manufacturing.</p>
        <form method='get' action='/graphql' class='form-inline'>
            <label for='locationId' class='mr-2'>Location ID:</label>
            <input type='text' class='form-control' id='locationId' name='locationId' required>
            <button type='submit' class='btn btn-primary'>Search</button>
        </form>
        <div id='result'></div>
    </div>
</body>

</html>";
// Return the HTML
    await context.Response.WriteAsync(html);
});

// Add the GraphQL query
app.MapGet("/graphql", async context =>
{
    var locationId = context.Request.Query["locationId"];
    if (string.IsNullOrEmpty(locationId))
    {
        await context.Response.WriteAsync("Location ID is required.");
        return;
    }

// Set up the GraphQL client - your endpoint goes here
    var graphQLOptions = new GraphQLHttpClientOptions
    {
        EndPoint = new Uri("ReplaceWithYourGraphQLEndpointAddress"),
        MediaType = "application/json",
    };

// Set up the client with headers, use the token
    var graphQLClient = new GraphQLHttpClient(graphQLOptions, new NewtonsoftJsonSerializer());
    graphQLClient.HttpClient.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", token.Token);
    graphQLClient.Options.IsValidResponseToDeserialize = response => response.IsSuccessStatusCode;
// Set up the GraphQL query - you could make this a variable if you wanted to
    var query = new GraphQLHttpRequest
    {
        Query = $@"query {{ vProductsbySuppliers(filter: {{ SupplierLocationID: {{ eq: {locationId} }} }}) 
          {{ items 
              {{ CompanyName SupplierLocationID ProductCount }} 
          }} 
        }}"
    };
// Send the query
    var graphQLResponse = await graphQLClient.SendQueryAsync<dynamic>(query);
    var items = graphQLResponse.Data.vProductsbySuppliers.items;

// Build the HTML response from the query
    var html = @"
    <!DOCTYPE html>
    <html>
    <head>
        <link rel='stylesheet' href='https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css'>
    </head>
    <body>
        <div class='container'>
           <img src='./contoso.png' alt='Contoso Logo' width='200'>
            <h2>Product Count by Suppliers</h2>
            <table class='table table-striped'>
                <thead>
                    <tr>
                        <th>Company Name</th>
                        <th>Supplier Location ID</th>
                        <th>Product Count</th>
                    </tr>
                </thead>
                <tbody>";

    foreach (var item in items)
    {
        html += $"<tr><td>{item.CompanyName}</td><td>{item.SupplierLocationID}</td><td>{item.ProductCount}</td></tr>";
    }

    html += @"
                </tbody>
            </table>
        </div>
    </body>
    </html>";
// Return the HTML
    await context.Response.WriteAsync(html);
});
// Run the application
app.Run();