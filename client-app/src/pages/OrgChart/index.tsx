import axios from "axios";
import { SettingsContext } from "context";
import React, { FC, useContext, useEffect, useState } from "react";
import styles from "./styles.module.scss";

declare var $: any;

const { BackendAPIUrl, id } = window.config;

export const OrgChart: FC = () => {
  const { currentDemo } = useContext(SettingsContext);
  const [isChartRendered, setIsChartRendered] = useState(false);

  useEffect(() => {
    if (id && !isChartRendered) {
      $("#orgChart").kendoOrgChart({
        editable: false,
        dataSource: {
          transport: {
            read: {
              url: BackendAPIUrl + "/Demo/GetOrgChartDataByDemo?id=" + id,
              dataType: "json",
            },
          },

          schema: {
            data: function (response: any) {
              return response.data;
            },
            model: {
              expanded: true,
              fields: {
                id: {
                  field: "id",
                  type: "number",
                  editable: false,
                  nullable: false,
                },
                parentId: { field: "parentId", nullable: true },
                title: { field: "position" },
                avatar: { field: "imageUrl" },
                name: { field: "name" },
              },
            },
          },
        },
        template: `
        <div class="card">
        <img alt="#: data.name #" src="#: data.avatar #" />
        <div>
        <div class="k-card-title k-text-ellipsis" style="text-align: center">#: data.name #</div>
        <div class="k-card-subtitle k-text-ellipsis" style="text-align: center">#: data.title #</div>

        </div>
        </div>
        `,
        // <div class="k-card-body k-hstack">
        // <div class="k-avatar k-avatar-solid-primary k-avatar-solid k-avatar-lg k-rounded-full">
        // <span class="k-avatar-image"><img alt="#: data.name #" src="#: data.avatar #" /></span>
        // </div>
        // <div class="k-vstack k-card-title-wrap">
        // <div class="k-card-title k-text-ellipsis">#: data.name #</div>
        // <span class="k-spacer"></span>
        // <div class="k-card-subtitle k-text-ellipsis">#: data.title #</div>
        // </div>
        // </div>
      });
      setIsChartRendered(true);
    }
  }, [currentDemo, isChartRendered]);

  return <div className={styles.container} id="orgChart"></div>;
};
