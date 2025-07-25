# Java Migration Copilot Samples

Some sample projects that can be fed to the Java migration tool to replatform them to Azure.

## Project Structure

- `asset-manager/` - Spring Boot backend (web app and worker) for asset management, image processing, and cloud integration.
- `frontend/` - Modern React + TypeScript + Vite + Tailwind CSS frontend for e-commerce UI.
- `mi-sql-public-demo/` - Sample Java SQL project.
- `rabbitmq-sender/` - Java RabbitMQ sender sample.

---

## Technology Stack

### Backend (`asset-manager/`)
- Java 21, Spring Boot 3.4.x
- Modules: Web (Thymeleaf, REST), Worker (background processing)
- AWS S3 (or Azure Blob), RabbitMQ (or Azure Service Bus), PostgreSQL (or Azure Database for PostgreSQL)
- Maven for dependency management

### Frontend (`frontend/`)
- React 18, TypeScript, Redux Toolkit, React Router
- Vite (build tool), Tailwind CSS (styling)
- ESLint for linting

---

## Prerequisites

### Backend
- Java 21+
- Maven 3.8+
- Docker (for local RabbitMQ/PostgreSQL)
- (Optional) AWS/Azure credentials for cloud integration

### Frontend
- Node.js 18+
- npm 9+ (or compatible with Node version)

---

## Setup & Installation

### Backend (`asset-manager/`)

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Azure-Samples/java-migration-copilot-samples.git
   cd AzureHeroDemos/asset-manager
   ```

2. **Install dependencies:**
   ```bash
   ./mvnw clean install
   ```

3. **Start local infrastructure (RabbitMQ, PostgreSQL):**
   - **Windows:**  
     `scripts\start.cmd`
   - **Linux/macOS:**  
     `./scripts/start.sh`

4. **Run the web app:**
   ```bash
   cd web
   ../mvnw spring-boot:run
   ```

5. **Run the worker:**
   ```bash
   cd ../worker
   ../mvnw spring-boot:run
   ```

6. **Stop local infrastructure:**
   - **Windows:**  
     `scripts\stop.cmd`
   - **Linux/macOS:**  
     `./scripts/stop.sh`

---

### Frontend (`frontend/`)

1. **Navigate to the frontend directory:**
   ```bash
   cd ../frontend
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Start the development server:**
   ```bash
   npm run dev
   ```
   The app will be available at [http://localhost:5173](http://localhost:5173) by default.

4. **Build for production:**
   ```bash
   npm run build
   ```

5. **Preview production build:**
   ```bash
   npm run preview
   ```

---

## .gitignore Notes

Only necessary files/folders in `frontend` are ignored:
- `frontend/node_modules/`
- `frontend/dist/`
- `frontend/logs/`
- `frontend/.env`

The rest of the `frontend` directory is tracked in version control.

---

## Additional Notes

- For more details on backend architecture and migration, see `asset-manager/README.md`.
- For customizing the frontend, see the configuration files in `frontend/` (e.g., `vite.config.ts`, `tailwind.config.js`).
