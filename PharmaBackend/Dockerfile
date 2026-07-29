# ── Build stage ────────────────────────────────────────────────────────────────
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Restore dependencies first (layer-cache efficiency: only re-runs on .csproj changes)
COPY PharmacyBackend.csproj ./
RUN dotnet restore PharmacyBackend.csproj

# Copy remaining source files and publish
COPY . .
RUN dotnet publish PharmacyBackend.csproj -c Release -o /app/publish --no-restore

# ── Runtime stage ──────────────────────────────────────────────────────────────
FROM mcr.microsoft.com/dotnet/aspnet:10.0-jammy-chiseled AS runtime
WORKDIR /app

EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080

COPY --from=build /app/publish .

# The chiseled image already runs as the non-root 'app' user by default.
ENTRYPOINT ["dotnet", "PharmacyBackend.dll"]
