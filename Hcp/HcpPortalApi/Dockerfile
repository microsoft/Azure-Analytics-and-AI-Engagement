FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS base
WORKDIR /app
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY ["HcpPortalApi.Api/HcpPortalApi.Api.csproj", "HcpPortalApi.Api/"]
COPY ["HcpPortalApi.Application/HcpPortalApi.Application.csproj", "HcpPortalApi.Application/"]
COPY ["HcpPortalApi.Domain/HcpPortalApi.Domain.csproj", "HcpPortalApi.Domain/"]
COPY ["HcpPortalApi.Infrastructure/HcpPortalApi.Infrastructure.csproj", "HcpPortalApi.Infrastructure/"]
RUN dotnet restore "HcpPortalApi.Api/HcpPortalApi.Api.csproj"
COPY . .
WORKDIR "/src/HcpPortalApi.Api"
RUN dotnet publish "HcpPortalApi.Api.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "HcpPortalApi.Api.dll"]
