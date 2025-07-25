# Asset Manager
Sample project for migration tool code remediation that manages assets in cloud storage.

## Current Infrastructure
The project currently uses the following infrastructure, in [`main`](https://github.com/Azure-Samples/java-migration-copilot-samples/tree/main/asset-manager) branch:
* AWS S3 for image storage, using password-based authentication (access key/secret key)
* RabbitMQ for message queuing, using password-based authentication
* PostgreSQL database for metadata storage, using password-based authentication

## Current Architecture
```mermaid
flowchart TD

%% Applications
WebApp[Web Application]
Worker[Worker Service]

%% Storage Components
S3[(AWS S3)]
LocalFS[("Local File System<br/>dev only")]

%% Message Broker
RabbitMQ(RabbitMQ)

%% Database
PostgreSQL[(PostgreSQL)]

%% Queues
Queue[image-processing queue]
RetryQueue[image-processing.retry queue]

%% User
User([User])

%% User Flow
User -->|Upload Image| WebApp
User -->|View Images| WebApp

%% Web App Flows
WebApp -->|Store Original Image| S3
WebApp -->|Store Original Image| LocalFS
WebApp -->|Send Processing Message| RabbitMQ
WebApp -->|Store Metadata| PostgreSQL
WebApp -->|Retrieve Images| S3
WebApp -->|Retrieve Images| LocalFS
WebApp -->|Retrieve Metadata| PostgreSQL

%% RabbitMQ Flow
RabbitMQ -->|Push Message| Queue
Queue -->|Processing Failed| RetryQueue
RetryQueue -->|After 1 min delay| Queue
Queue -->|Consume Message| Worker

%% Worker Flow
Worker -->|Download Original| S3
Worker -->|Download Original| LocalFS
Worker -->|Upload Thumbnail| S3
Worker -->|Upload Thumbnail| LocalFS
Worker -->|Store Metadata| PostgreSQL
Worker -->|Retrieve Metadata| PostgreSQL

%% Styling
classDef app fill:#90caf9,stroke:#0d47a1,color:#0d47a1
classDef storage fill:#a5d6a7,stroke:#1b5e20,color:#1b5e20
classDef broker fill:#ffcc80,stroke:#e65100,color:#e65100
classDef db fill:#ce93d8,stroke:#4a148c,color:#4a148c
classDef queue fill:#fff59d,stroke:#f57f17,color:#f57f17
classDef user fill:#ef9a9a,stroke:#b71c1c,color:#b71c1c

class WebApp,Worker app
class S3,LocalFS storage
class RabbitMQ broker
class PostgreSQL db
class Queue,RetryQueue queue
class User user
```
Password-based authentication

## Migrated Infrastructure
After migration, the project will use the following Azure services, in [`expected`](https://github.com/Azure-Samples/java-migration-copilot-samples/tree/expected/asset-manager) branch:
* Azure Blob Storage for image storage, using managed identity authentication
* Azure Service Bus for message queuing, using managed identity authentication
* Azure Database for PostgreSQL for metadata storage, using managed identity authentication

## Migrated Architecture
```mermaid
flowchart TD

%% Applications
WebApp[Web Application]
Worker[Worker Service]

%% Azure Storage Components
AzBlob[(Azure Blob Storage)]
LocalFS[("Local File System<br/>dev only")]

%% Azure Message Broker
ServiceBus(Azure Service Bus)

%% Azure Database
AzPostgreSQL[(Azure PostgreSQL)]

%% Queues
Queue[image-processing queue]
RetryQueue[retry queue]

%% User
User([User])

%% User Flow
User -->|Upload Image| WebApp
User -->|View Images| WebApp

%% Web App Flows
WebApp -->|Store Original Image| AzBlob
WebApp -->|Store Original Image| LocalFS
WebApp -->|Send Processing Message| ServiceBus
WebApp -->|Store Metadata| AzPostgreSQL
WebApp -->|Retrieve Images| AzBlob
WebApp -->|Retrieve Images| LocalFS
WebApp -->|Retrieve Metadata| AzPostgreSQL

%% Service Bus Flow
ServiceBus -->|Push Message| Queue
Queue -->|Processing Failed| RetryQueue
RetryQueue -->|After 1 min delay| Queue
Queue -->|Consume Message| Worker

%% Worker Flow
Worker -->|Download Original| AzBlob
Worker -->|Download Original| LocalFS
Worker -->|Upload Thumbnail| AzBlob
Worker -->|Upload Thumbnail| LocalFS
Worker -->|Store Metadata| AzPostgreSQL
Worker -->|Retrieve Metadata| AzPostgreSQL

%% Styling
classDef app fill:#90caf9,stroke:#0d47a1,color:#0d47a1
classDef storage fill:#68B3A1,stroke:#006064,color:#006064
classDef broker fill:#B39DDB,stroke:#4527A0,color:#4527A0
classDef db fill:#90CAF9,stroke:#1565C0,color:#1565C0
classDef queue fill:#81C784,stroke:#2E7D32,color:#2E7D32
classDef user fill:#ef9a9a,stroke:#b71c1c,color:#b71c1c

class WebApp,Worker app
class AzBlob,LocalFS storage
class ServiceBus broker
class AzPostgreSQL db
class Queue,RetryQueue queue
class User user
```
Managed identity based authentication

## Run Locally

Check out the [`main`](https://github.com/Azure-Samples/java-migration-copilot-samples/tree/main/asset-manager) branch to run the current infrastructure locally:

```bash
git clone https://github.com/Azure-Samples/java-migration-copilot-samples.git
cd java-migration-copilot-samples/asset-manager
git checkout main
```

**Prerequisites**: JDK, Docker

Run the following commands to start the apps locally. This will:
* Use local file system instead of S3 to store the image
* Launch RabbitMQ and PostgreSQL using Docker

Windows:

```batch
scripts\start.cmd
```

Linux:

```bash
scripts/start.sh
```

To stop, run `stop.cmd` or `stop.sh` in the `scripts` directory.

## Run Migrated Code on Azure

Check out the [`expected`](https://github.com/Azure-Samples/java-migration-copilot-samples/tree/expected/asset-manager) branch to run the migrated infrastructure on Azure:

```bash
git clone https://github.com/Azure-Samples/java-migration-copilot-samples.git
cd java-migration-copilot-samples/asset-manager
git checkout expected
```

**Prerequisites**: Azure CLI and you have signed in using `az login`

Run the following commands to deploy the apps to Azure. This will:
* Use Azure Blob Storage instead of S3 to store the image
* Use Azure Service Bus instead of RabbitMQ for message queuing
* Use Azure Database for PostgreSQL Flexible Server instead of PostgreSQL for metadata storage

Windows:

```batch
scripts\deploy-to-azure.cmd -ResourceGroupName <your resource group name> -Location <your resource group location, e.g., eastus2> -Prefix <your unique resource prefix>
```

Linux:

```bash
scripts/deploy-to-azure.sh -ResourceGroupName <your resource group name> -Location <your resource group location, e.g., eastus2> -Prefix <your unique resource prefix>
```

To clean up, run `scripts\cleanup-azure-resources.cmd -ResourceGroupName <your resource group name>` or `scripts/cleanup-azure-resources.sh -ResourceGroupName <your resource group name>` for Windows and Linux, respectively.

### Use GitHub Codespaces for Deployment

The deployment scripts can also be executed in GitHub Codespaces, which pre-installs the necessary dependencies. Follow the steps below to deploy the apps to Azure using GitHub Codespaces:

1. Open the repository in GitHub Codespaces by selecting on the **Code** button, selecting **Codespaces** tab, openining the existing codespace or selecting **Create codespace** for the target branch.
1. The codespace will automatically open in the browser. Wait until it is ready.
1. Navigate to the terminal in the codespace and run `az login` to sign in to Azure. Follow the instructions to complete the sign-in process.
1. At the last step of the sign-in process, you will be asked to select a subscription and tenant. Select the appropriate subscription and tenant.
1. Run the following commands in the terminal to deploy the apps to Azure:

   ```bash
   cd asset-manager && git pull
   scripts/deploy-to-azure.sh -ResourceGroupName <your resource group name> -Location <your resource group location, e.g., eastus2> -Prefix <your unique resource prefix>
   ```

1. To clean up, run `scripts\cleanup-azure-resources.cmd -ResourceGroupName <your resource group name>` or `scripts/cleanup-azure-resources.sh -ResourceGroupName <your resource group name>` for Windows and Linux, respectively.

## Java Migration Copilot Workshop

Check out the [`workshop`](https://github.com/Azure-Samples/java-migration-copilot-samples/tree/workshop/asset-manager) branch for Java Migration Copilot workshop:

```bash
git clone https://github.com/Azure-Samples/java-migration-copilot-samples.git
cd java-migration-copilot-samples/asset-manager
git checkout workshop
```

Compared to the `main` branch, the `workshop` branch has additional commits that have already migrated the code for **Web Application** with custom code remediation, including:
* Azure Blob Storage for image storage, using managed identity authentication
* Azure Service Bus for message queuing, using managed identity authentication

The remaining targets of the workshop are:
* For both **Web Application** and **Worker Service**, migrate to Azure Database for PostgreSQL Flexible server for metadata storage with managed identity authentication, using predefined prompt.
* For **Worker Service**, migrate to Azure Blob Storage and Azure Service Bus for image storage and message queuing, respectively, with managed identity authentication, using custom propmt created from existing commits that migrated the **Web Application**.

Once the workshop is successfully completed, you should be able to run the migrated code on Azure, similar to [Run Migrated Code on Azure](#run-migrated-code-on-azure) but using the `workshop` branch with the migrated code.

For more details, refer to the [workshop guide](https://github.com/Azure-Samples/java-migration-copilot-samples/blob/workshop/asset-manager/WORKSHOP.md).
