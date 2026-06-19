import * as powerbi from "powerbi-client";
import { EmbedType, EmbedConfig, Filter } from "types";

export class PowerBiService {
  accessToken = "";
  embedToken = "";
  powerBiService: powerbi.service.Service;
  report: any;
  APIUrl: string;
  instance: PowerBiService;

  constructor(apiUrl: string) {
    this.powerBiService = new powerbi.service.Service(
      powerbi.factories.hpmFactory,
      powerbi.factories.wpmpFactory,
      powerbi.factories.routerFactory
    );
    this.APIUrl = apiUrl;
    this.instance = this;
  }

  hydrate() {
    this.powerBiService.preload({});
  }

  switchMode(id: string, editMode: boolean) {
    const element = document.getElementById(id);
    if (!element) {
      return;
    }
    const report: any = this.powerBiService.get(element!);
    report.switchMode(editMode ? "edit" : "view");
  }

  /**
   *
   * @param id Used to find a container that will host power bi report
   * @param pageName
   * @returns
   */
  switchPage(id: string, pageName: string) {
    const element = document.getElementById(id);
    if (!element) {
      return;
    }
    try {
      const report: any = this.powerBiService.get(element!);
      const page = report.page(pageName);
      page.setActive();
    } catch (error) {}
  }

  setFilter(id: string, filter: Filter) {
    const element = document.getElementById(id);
    if (!element) {
      return;
    }
    const report: powerbi.Report = this.powerBiService.get(
      element!
    ) as powerbi.Report;

    report.removeFilters();
    const newFilter: powerbi.models.IBasicFilter = {
      filterType: powerbi.models.FilterType.Basic,
      target: {
        table: filter.table,
        column: filter.column,
      },
      operator: "In",
      values: [filter.value],
      $schema: "http://powerbi.com/product/schema#basic",
    };

    report.setFilters([newFilter]);
  }

  reload(id: string) {
    const element = document.getElementById(id);
    if (!element) {
      return;
    }

    const report: any = this.powerBiService.get(element!);
    report.reload();
  }

  refresh(id: string) {
    const element = document.getElementById(id);
    if (!element) {
      return;
    }

    const report: any = this.powerBiService.get(element);

    try {
      report.refresh();
    } catch (error) {}
  }

  async loadToken(
    id: string,
    embedConfig: EmbedConfig,
    url?: string
  ): Promise<string> {
    let queryString = embedConfig.editMode ? "editMode=true" : "";
    if (queryString && embedConfig.filter) {
      queryString += (queryString ? "&" : "") + embedConfig.filter;
    }
    queryString = queryString ? "?" + queryString : "";
    if (url) {
      const response = await fetch(`${this.APIUrl}/Token/GetEmbedToken`, {
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
        method: "POST",
        body: JSON.stringify({ url }),
      });

      const token: string = await response.text();
      return token;
    } else {
      const response = await fetch(
        `${this.APIUrl}/api/token/embed/${embedConfig.type}/${id}${queryString}`,
        {
          headers: {
            responseType: "text",
            "Access-Control-Allow-Origin": "*",
          },
        }
      );

      const token: string = await response.text();
      return token;
    }
  }

  async load(id: string, embedConfig: EmbedConfig, url?: string) {
    let token = await this.loadToken(id, embedConfig, url);
    const config: any = {
      type: embedConfig.type,
      accessToken: token,
      background: powerbi.models.BackgroundType.Transparent,
      tokenType: powerbi.models.TokenType.Embed,
      id: id,
      dashboardId: embedConfig.type === EmbedType.Dashboard ? id : "",
      embedUrl:
        embedConfig.type === EmbedType.Report
          ? "https://app.powerbi.com/reportEmbed"
          : embedConfig.type === EmbedType.Dashboard
          ? "https://app.powerbi.com/dashboardEmbed"
          : "https://app.powerbi.com/embed",
      permissions: embedConfig.editMode
        ? powerbi.models.Permissions.Create
        : powerbi.models.Permissions.Read,
      viewMode: embedConfig.editMode
        ? powerbi.models.ViewMode.Edit
        : powerbi.models.ViewMode.View,
      pageView: "fitToWidth",
    };

    if (embedConfig.type === EmbedType.Report) {
      config.settings = {
        filterPaneEnabled: false,
        navContentPaneEnabled: false,
        background: powerbi.models.BackgroundType.Transparent,
      };
    }
    if (embedConfig.pageName) {
      config.pageName = embedConfig.pageName;
    }
    if (embedConfig.height) {
      config.height = embedConfig.height;
    }
    if (embedConfig.width) {
      config.width = embedConfig.width;
    }

    const powerBiService = this.powerBiService;

    try {
      const report = powerBiService.embed(
        document.getElementById(embedConfig.elementId)!,
        config
      );

      let refreshToken = async (id: string, embedConfig: EmbedConfig) => {
        let token = await this.loadToken(id, embedConfig);
        report.setAccessToken(token);
      };

      report.on("error", async (event: CustomEvent) => {
        if (event.detail.message === "TokenExpired") {
          await refreshToken(id, embedConfig);
        }
      });
      report.on("rendered", function (event) {
        if (embedConfig.onRendered) {
          embedConfig.onRendered(event);
        }
      });

      report.on("tileClicked", function (event) {
        if (embedConfig.onClick) {
          embedConfig.onClick(event);
        }
      });

      this.report = report;
    } catch (error) {}
  }

  async load2(id: string, embedConfig: EmbedConfig) {
    let token = await this.loadToken(id, embedConfig);
    const config: any = {
      type: embedConfig.type,
      accessToken: token,
      background: powerbi.models.BackgroundType.Transparent,
      tokenType: powerbi.models.TokenType.Embed,
      id: id,
      dashboardId: embedConfig.type === EmbedType.Dashboard ? id : "",
      embedUrl:
        embedConfig.type === EmbedType.Report
          ? "https://app.powerbi.com/reportEmbed"
          : embedConfig.type === EmbedType.Dashboard
          ? "https://app.powerbi.com/dashboardEmbed"
          : "https://app.powerbi.com/embed",
      permissions: embedConfig.editMode
        ? powerbi.models.Permissions.Create
        : powerbi.models.Permissions.Read,
      viewMode: embedConfig.editMode
        ? powerbi.models.ViewMode.Edit
        : powerbi.models.ViewMode.View,
      pageView: "actualSize",
    };

    if (embedConfig.type === EmbedType.Report) {
      config.settings = {
        filterPaneEnabled: false,
        navContentPaneEnabled: false,
        background: powerbi.models.BackgroundType.Transparent,
      };
    }
    if (embedConfig.pageName) {
      config.pageName = embedConfig.pageName;
    }
    if (embedConfig.height) {
      config.height = embedConfig.height;
    }
    if (embedConfig.width) {
      config.width = embedConfig.width;
    }

    const powerBiService = this.powerBiService;

    try {
      const report = powerBiService.embed(
        document.getElementById(embedConfig.elementId)!,
        config
      );

      let refreshToken = async (id: string, embedConfig: EmbedConfig) => {
        let token = await this.loadToken(id, embedConfig);
        report.setAccessToken(token);
      };

      report.on("error", async (event: CustomEvent) => {
        if (event.detail.message === "TokenExpired") {
          await refreshToken(id, embedConfig);
        }
      });
      report.on("rendered", function (event) {
        if (embedConfig.onRendered) {
          embedConfig.onRendered(event);
        }
      });

      report.on("tileClicked", function (event) {
        if (embedConfig.onClick) {
          embedConfig.onClick(event);
        }
      });

      this.report = report;
    } catch (error) {}
  }
}
