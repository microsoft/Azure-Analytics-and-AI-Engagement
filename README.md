# AzureHeroDemos - Motor Parts Unlimited

## Project Overview
Motor Parts Unlimited is a full-stack web application featuring a .NET backend (PartsUnitBacked) and a modern React frontend. The project demonstrates best practices for building scalable, maintainable, and cloud-ready applications.

## Features
- Product catalog with categories
- Shopping cart functionality
- Product search and filtering
- Responsive UI
- RESTful API backend
- PostgreSQL database integration

## Tech Stack
- **Backend:** .NET 9 (ASP.NET Core), Entity Framework Core, PostgreSQL
- **Frontend:** React, TypeScript, Vite, Tailwind CSS

## Project Structure
```
AzureHeroDemos/
  backend/      # .NET backend (API, data, services)
  frontend/     # React frontend (UI, assets, state)
```

## Getting Started

### Prerequisites
- [.NET 9 SDK](https://dotnet.microsoft.com/download)
- [Node.js (v18+)](https://nodejs.org/)
- [PostgreSQL](https://www.postgresql.org/)

### Backend Setup
1. Navigate to the backend directory:
   ```sh
   cd backend
   ```
2. Restore dependencies:
   ```sh
   dotnet restore
   ```
3. Update `appsettings.Development.json` with your PostgreSQL connection string.
4. Apply database migrations:
   ```sh
   dotnet ef database update
   ```
5. Run the backend:
   ```sh
   dotnet run
   ```
   The API will be available at `https://localhost:5001` (or as configured).

### Frontend Setup
1. Navigate to the frontend directory:
   ```sh
   cd frontend
   ```
2. Install dependencies:
   ```sh
   npm install
   ```
3. Create a `.env` file if needed (see Environment Variables section).
4. Start the development server:
   ```sh
   npm run dev
   ```
   The app will be available at `http://localhost:5173` (or as configured).

## Environment Variables

### Backend
- `appsettings.Development.json` should contain your database connection string and other secrets.

### Frontend
- `.env` (optional):
  - `VITE_API_URL` — URL of the backend API (e.g., `https://localhost:5001`)

## Useful Scripts

### Backend
- `dotnet run` — Start the backend server
- `dotnet ef database update` — Apply EF Core migrations

### Frontend
- `npm run dev` — Start the frontend dev server
- `npm run build` — Build the frontend for production
- `npm run preview` — Preview the production build

## License
This project is licensed under the MIT License.

## Contact
For questions or support, please contact the project maintainer. 