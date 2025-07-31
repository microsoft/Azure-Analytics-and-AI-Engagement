import { Menu } from "types";

export const getMenu = ({
  demoId,
  title,
}: {
  demoId?: string;
  title?: string;
}) => {
  if (demoId)
    return [
      {
        id: 1,
        menuIcon: "icon1.png",
        menuName: "Intro & CEO Dashboard",
        menuItems: [
          {
            id: 2,
            title: `${title ?? "Contoso"} Slogan`,
            icon: "icon1_2.png",
            href: `/${demoId}/landing-page`,
          },
          {
            id: 3,
            title: "World Map",
            icon: "icon1_4.png",
            href: `/${demoId}/world-map`,
          },
          {
            id: 4,
            title: "Miami Beach",
            icon: "icon4_3.png",
            href: `/${demoId}/miami-beach`,
          },
          {
            id: 5,
            title: "Executive Dashboard - Before",
            icon: "icon1_5.png",
            href: `/${demoId}/executive-dashboard-before`,
          },
          {
            id: 6,
            title: "Org Chart",
            icon: "icon1_3.png",
            href: `/${demoId}/org-chart`,
          },
        ],
      },
      {
        id: 7,
        menuIcon: "icon2.png",
        menuName: "Before Using Microsoft Fabric",
        menuItems: [
          {
            id: 8,
            title: "Current State Architecture",
            icon: "icon12.png",
            href: `/${demoId}/current-state-architecture`,
          },
          {
            id: 9,
            title: "CDO Top of Mind",
            icon: "icon12.png",
            href: `/${demoId}/scalable-analytics`,
          },

          {
            id: 10,
            title: "CDO Metrics - Current State",
            icon: "icon1_5.png",
            href: `/${demoId}/cdo-dashboard-before`,
          },
          // {
          //   id: 13,
          //   title: "Introduction to Microsoft Fabric - 1",
          //   icon: "icon12.png",
          //   href: `/${demoId}/introduction-to-microsoft-fabric-1`,
          // },
        ],
      },
      {
        id: 7,
        menuIcon: "icon2.png",
        menuName: "With Microsoft Fabric",
        menuItems: [
          {
            id: 11,
            title: "Introduction to Microsoft Fabric",
            icon: "icon12.png",
            href: `/${demoId}/introduction-to-microsoft-fabric`,
          },
          {
            id: 12,
            title: "Microsoft Fabric Dream Demo Architecture",
            icon: "icon12.png",
            href: `/${demoId}/future-state-architecture`,
          },
          {
            id: 13,
            title: "Lakehouse Creation Demo (Click-by-Click)",
            icon: "icon11_1.png",
            href: `/${demoId}/lake-house`,
          },
          {
            id: 28,
            title: "OneLake Explorer Demo (Click-by-Click)",
            icon: "icon11_1.png",
            href: `/${demoId}/onelake-explorer`,
          },
          {
            id: 14,
            title: "Data Warehouse Creation Demo (Click-by-Click)",
            icon: "icon11_1.png",
            href: `/${demoId}/dataware-house`,
          },
        ],
      },
      {
        id: 7,
        menuIcon: "icon2.png",
        menuName: "Power BI Reports by Departments",
        menuItems: [
          {
            id: 17,
            title: "Sales - Customer Churn Report",
            icon: "icon12.png",
            href: `/${demoId}/customer-churn-report`,
          },
          {
            id: 29,
            title: "Sales - Sales Performance",
            icon: "icon12.png",
            href: `/${demoId}/sales-performence-report`,
          },
          {
            id: 16,
            title: "Finance - Revenue and Profitability",
            icon: "icon12.png",
            href: `/${demoId}/finance-revenue-and-profitability`,
          },

          {
            id: 18,
            title: "Marketing - Campaign Analytics",
            icon: "icon12.png",
            href: `/${demoId}/campaign-analytics-report`,
          },
          {
            id: 19,
            title: "HR - Employee Management",
            icon: "icon12.png",
            href: `/${demoId}/hr-analytics-report`,
          },
          {
            id: 20,
            title: "Operations - Warehouse Operating Expense",
            icon: "icon12.png",
            href: `/${demoId}/operations-report`,
          },
          {
            id: 21,
            title: "IT - IT Operations",
            icon: "icon12.png",
            href: `/${demoId}/it-report`,
          },
        ],
      },
      {
        id: 22,
        menuIcon: "icon10_1.png",
        menuName: "Post Microsoft Fabric Implementation",
        menuItems: [
          {
            id: 24,
            title: "Sales Event Video",
            icon: "icon_video.png",
            href: `/${demoId}/store-overview`,
          },
          {
            id: 23,
            title: "CDO Metrics - After",
            icon: "icon11_1.png",
            href: `/${demoId}/cdo-dashboard-after`,
          },

          {
            id: 25,
            title: "Executive Dashboard - After",
            icon: "icon11_1.png",
            href: `/${demoId}/executive-dashboard-after`,
          },
          {
            id: 26,
            title: "Finale Video",
            icon: "icon_video.png",
            href: `/${demoId}/final-video`,
          },
        ],
      },
      {
        id: 27,
        menuIcon: "header_icon_logout.png",
        menuName: "Logout",
        href: `/${demoId}/logout`,
      },
    ] as Menu[];
  else
    return [
      {
        id: 1,
        menuIcon: "icon1.png",
        menuName: "Intro & CEO Dashboard",
        menuItems: [
          {
            id: 2,
            title: `${title ?? "Contoso"} Slogan`,
            icon: "icon1_2.png",
            href: `/landing-page`,
          },
          {
            id: 3,
            title: "World Map",
            icon: "icon1_4.png",
            href: `/world-map`,
          },
          {
            id: 4,
            title: "Miami Beach",
            icon: "icon4_3.png",
            href: `/miami-beach`,
          },
          {
            id: 5,
            title: "Executive Dashboard - Before",
            icon: "icon1_5.png",
            href: `/executive-dashboard-before`,
          },
          {
            id: 6,
            title: "Org Chart",
            icon: "icon1_3.png",
            href: `/org-chart`,
          },
        ],
      },
      {
        id: 7,
        menuIcon: "icon2.png",
        menuName: "Before Using Microsoft Fabric",
        menuItems: [
          {
            id: 8,
            title: "Current State Architecture",
            icon: "icon12.png",
            href: `/current-state-architecture`,
          },
          {
            id: 9,
            title: "CDO Top of Mind",
            icon: "icon12.png",
            href: `/scalable-analytics`,
          },

          {
            id: 10,
            title: "CDO Metrics - Current State",
            icon: "icon1_5.png",
            href: `/cdo-dashboard-before`,
          },
          // {
          //   id: 13,
          //   title: "Introduction to Microsoft Fabric - 1",
          //   icon: "icon12.png",
          //   href: `/introduction-to-microsoft-fabric-1`,
          // },
        ],
      },
      {
        id: 7,
        menuIcon: "icon2.png",
        menuName: "With Microsoft Fabric",
        menuItems: [
          {
            id: 11,
            title: "Introduction to Microsoft Fabric",
            icon: "icon12.png",
            href: `/introduction-to-microsoft-fabric`,
          },
          {
            id: 12,
            title: "Microsoft Fabric Dream Demo Architecture",
            icon: "icon12.png",
            href: `/future-state-architecture`,
          },
          {
            id: 13,
            title: "Lakehouse Creation Demo (Click-by-Click)",
            icon: "icon11_1.png",
            href: `/lake-house`,
          },
          {
            id: 28,
            title: "OneLake Explorer Demo (Click-by-Click)",
            icon: "icon11_1.png",
            href: `/onelake-explorer`,
          },
          {
            id: 14,
            title: "Data Warehouse Creation Demo (Click-by-Click)",
            icon: "icon11_1.png",
            href: `/dataware-house`,
          },
        ],
      },
      {
        id: 7,
        menuIcon: "icon2.png",
        menuName: "Power BI Reports by Departments",
        menuItems: [
          {
            id: 17,
            title: "Sales - Customer Churn Report",
            icon: "icon12.png",
            href: `/customer-churn-report`,
          },
          {
            id: 29,
            title: "Sales - Sales Performance",
            icon: "icon12.png",
            href: `/sales-performence-report`,
          },
          {
            id: 16,
            title: "Finance - Revenue and Profitability",
            icon: "icon12.png",
            href: `/finance-revenue-and-profitability`,
          },

          {
            id: 18,
            title: "Marketing - Campaign Analytics",
            icon: "icon12.png",
            href: `/campaign-analytics-report`,
          },
          {
            id: 19,
            title: "HR - Employee Management",
            icon: "icon12.png",
            href: `/hr-analytics-report`,
          },
          {
            id: 20,
            title: "Operations - Warehouse Operating Expense",
            icon: "icon12.png",
            href: `/operations-report`,
          },
          {
            id: 21,
            title: "IT - IT Operations",
            icon: "icon12.png",
            href: `/it-report`,
          },
        ],
      },
      {
        id: 22,
        menuIcon: "icon10_1.png",
        menuName: "Post Microsoft Fabric Implementation",
        menuItems: [
          {
            id: 24,
            title: "Sales Event Video",
            icon: "icon_video.png",
            href: `/store-overview`,
          },
          {
            id: 23,
            title: "CDO Metrics - After",
            icon: "icon11_1.png",
            href: `/cdo-dashboard-after`,
          },

          {
            id: 25,
            title: "Executive Dashboard - After",
            icon: "icon11_1.png",
            href: `/executive-dashboard-after`,
          },
          {
            id: 26,
            title: "Finale Video",
            icon: "icon_video.png",
            href: `/final-video`,
          },
        ],
      },
      {
        id: 27,
        menuIcon: "header_icon_logout.png",
        menuName: "Logout",
        href: `/logout`,
      },
    ] as Menu[];
};
