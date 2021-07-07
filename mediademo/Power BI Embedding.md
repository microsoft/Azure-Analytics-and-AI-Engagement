# Steps to embed Power Bi Reports and Dashboards using Service Principal.

## 1.Check App Registrations on Azure Portal

In your azure portal search for app registrations and open it.

![app registration.](media/appregistration.png)

Under all applications, Search for app name starting with "Media Demo" and open it.

![app registration2.](media/appregistration2.png)

Go to – Api Permissions->Add Permissions->Power BI Permissions ->
Application Permissions ->Tick both the permissions and add them

Click on Grant Admin Consent.

![app permissions.](media/apppermissions.png)

Click on autentication in left pane and enable "Allow Public Client Flow"

![Client Flow.](media/clientflow.png)


## 2.Power BI tenant settings and workspace access.

Navigate to your Power BI portal (app.powerbi.com).

Open your admin portal from settings.

![Admin portal.](media/adminportal.png)

Click on tenant settings and enable "Allow Service Principals to use API's" setting.

![Tenant.](media/tenant.png)

Open your workspace access settings.

![Access.](media/access.png)

Search for your service principal name and assign it Admin access.

![Access.](media/access2.png)

