FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS base
WORKDIR /app
ENV ASPNETCORE_URLS=http://+:8080
ENV DOTNET_USE_POLLING_FILE_WATCHER=true

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY ["HcpPortalApi.Api/HcpPortalApi.Api.csproj", "HcpPortalApi.Api/"]
COPY ["HcpPortalApi.Application/HcpPortalApi.Application.csproj", "HcpPortalApi.Application/"]
COPY ["HcpPortalApi.Domain/HcpPortalApi.Domain.csproj", "HcpPortalApi.Domain/"]
COPY ["HcpPortalApi.Infrastructure/HcpPortalApi.Infrastructure.csproj", "HcpPortalApi.Infrastructure/"]
COPY ["HcpPortalApi.Worker/HcpPortalApi.Worker.csproj", "HcpPortalApi.Worker/"]
RUN dotnet restore "HcpPortalApi.Worker/HcpPortalApi.Worker.csproj"
COPY . .
WORKDIR "/src/HcpPortalApi.Worker"
RUN dotnet publish "HcpPortalApi.Worker.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "HcpPortalApi.Worker.dll"]
