import { PageType } from "types";
import styles from "./styles.module.scss";
import { useState } from "react";
import { DropDownList } from "@progress/kendo-react-dropdowns";
import { PanelBar, PanelBarItem } from "@progress/kendo-react-layout";
import { setIsLevel1FlowOn } from "store";
import { useAppDispatch } from "hooks/useAppDispatch";
const data = {
  solutionAreas: [
    {
      id: "cloud",
      label: "Cloud & AI Platforms",
      heroDemos: [
        {
          id: "demo1",
          label: "Scenario 1A: Innovate with AI Apps and Agents",
          levels: [
            {
              id: "level1",
              label: "Level 1: BDM Version",
              chapters: [
                {
                  id: "chapter1",
                  label: "Chapter 1: The Improved Customer Experience",
                },
                {
                  id: "chapter2",
                  label: "Chapter 2: Smarter Inventory for Store Managers",
                },
              ],
            },
            {
              id: "level2",
              label: "Level 2: TDM Version",
              chapters: [
                {
                  id: "chapter-l2-1",
                  label: "Chapter 1: The Improved Customer Experience",
                },
                {
                  id: "chapter-l2-2",
                  label: "Chapter 2: Intelligent Inventory for Store Managers",
                },
              ],
            },
          ],
        },
        {
          id: "demo1a",
          label: "Scenario 1B: From Hack to Hero: The Developer’s Journey",
          levels: [
            {
              id: "level1",
              label: "Level 1: BDM View – Executive/Seller POV",
              chapters: [
               
              ],
            },
            {
              id: "level2",
              label: "Level 2: TDM View – Dev Lead/Architect POV",
              chapters: [
                {
                  id: "chapter1",
                  label: "Chapter 1: Environment Provisioning",
                },
                {
                  id: "chapter2",
                  label: "Chapter 2: Working with Legacy Code Using Copilot",
                },
                {
                  id: "chapter3",
                  label:
                    "Chapter 3: Building a New App with Copilot Agent Mode",
                },
                {
                  id: "chapter4",
                  label: "Chapter 4: AI Integration with AI Foundry",
                },
                {
                  id: "chapter5",
                  label: "Chapter 5: Secure Deployment",
                },
              ],
            },
          ],
        },
        {
          id: "demo2",
          label: "Scenario 2: Unify your Data Platform",
          levels: [
            {
              id: "level1",
              label: "Level 1: BDM View – Executive/Account Lead POV",
              chapters: [
                {
                  id: "chapter-d2-l1-1",
                  label: "Chapter 1: Business Challenge and Vision",
                },
                {
                  id: "chapter-d2-l1-2",
                  label:
                    "Chapter 2: Drive down operating costs with Unified Data and Real-Time Decisions ",
                },
                {
                  id: "chapter-d2-l1-3",
                  label:
                    "Chapter 3: Reduce churn rates with Predictive Insights & AI-Powered Action",
                },
                {
                  id: "chapter-d2-l1-4",
                  label:
                    "Chapter 4: Drive down compliance alerts and vulnerabilities",
                },
              ],
            },
            {
              id: "level2",
              label: "Level 2: TDM View – Architect/Technical Specialist POV",
              chapters: [
                {
                  id: "chapter-d2-l2-1",
                  label: "Chapter 1: Ingest + Unify a Disconnected Estate",
                },
                {
                  id: "chapter-d2-l2-2",
                  label: "Chapter 2: AI Agents + Insights from OneLake",
                },
                {
                  id: "chapter-d2-l2-3",
                  label: "Chapter 3: Data Science + AI Workflows",
                },
                {
                  id: "chapter-d2-l2-4",
                  label:
                    "Chapter 4: Power BI + Copilot for Business Analysis at enterprise scale",
                },
                {
                  id: "chapter-d2-l2-5",
                  label: "Chapter 5: Security, Governance, and Scaling",
                },
              ],
            },
          ],
        },
        {
          id: "demo3",
          label: "Scenario 3: Migrate and Modernize Your Data Estate",
          levels: [
            {
              id: "level1",
              label: "Level 1: BDM View – Executive/Seller POV",
              chapters: [
                {
                  id: "chapter1",
                  label: "Chapter 1: Empowering Business Growth with Cloud",
                },
                {
                  id: "chapter2",
                  label: "Chapter 2: Building the Right Cloud Strategy ",
                },
                {
                  id: "chapter3",
                  label:
                    "Chapter 3: Executing a Phased, Collaborative Transformation",
                },
                {
                  id: "chapter4",
                  label: "Chapter 4: Improving Efficiency from Day 1",
                },
                {
                  id: "chapter5",
                  label:
                    "Chapter 5: Turning Disparate Data into a Strategic Asset",
                },
                {
                  id: "chapter6",
                  label: "Chapter 6: Scaling Securely and Compliantly",
                },
                {
                  id: "chapter7",
                  label:
                    "Chapter 7: Better Customer Experiences from Better Employee Experiences",
                },
                {
                  id: "chapter8",
                  label: "Chapter 8: Sustaining Innovation and Growth",
                },
              ],
            },
            {
              id: "level2",
              label: "Level 2: TDM View – Architect/Solution Engineer POV",
              chapters: [
                {
                  id: "chapter1",
                  label: "Chapter 1: On-Premises Application Assessment",
                },
                {
                  id: "chapter2",
                  label: "Chapter 2: Migration to Azure",
                },
                {
                  id: "chapter3",
                  label:
                    "Chapter 3: Database Migration from SQL Server to Azure SQL Managed Instance",
                },
                {
                  id: "chapter4",
                  label: "Chapter 4: Code Modernization Planning with GitHub",
                },
                {
                  id: "chapter5",
                  label:
                    "Chapter 5: Legacy Code Modernization (Legacy Java and .NET)",
                },
                {
                  id: "chapter6",
                  label:
                    "Chapter 6: Deploying to Azure Kubernetes Service (AKS)",
                },
                {
                  id: "chapter7",
                  label:
                    "Chapter 7: Security, Monitoring and Cost Optimization",
                },
              ],
            },
          ],
        },
      ],
    },
    {
      id: "ai",
      label: "AI Business Solutions",
      heroDemos: [
        {
          id: "demo4",
          label: "Demo 4: Intelligent Forecasting with Copilot",
          levels: [
            {
              id: "level1",
              label: "Level 1: Business Analyst View",
              chapters: [
                {
                  id: "chapter4",
                  label: "Chapter 4: Power BI + Copilot for Business Analysts",
                },
              ],
            },
          ],
        },
      ],
    },
    {
      id: "security",
      label: "Security",
      heroDemos: [
        {
          id: "demo5",
          label: "Demo 5: Secure Your Infrastructure",
          levels: [
            {
              id: "level3",
              label: "Level 3: Deep Dive - Compliance & Auditing",
              chapters: [
                {
                  id: "chapter5",
                  label: "Chapter 5: Security, Governance, and Scaling",
                },
              ],
            },
          ],
        },
      ],
    },
  ],
};

interface Props {
  pageTitle: string;
  pageType: PageType;
  src: string;
  className?: string;
  originalSize?: boolean;
  backgroundImage?: string;
}

export const LandingPage = ({
  pageTitle,
  pageType,
  src,
  className,
  originalSize,
  backgroundImage,
}: Props) => {
  const [activeSolution, setActiveSolution] = useState("cloud");
  const [activeDemo, setActiveDemo] = useState("");
  const [activeLevel, setActiveLevel] = useState<string | null>(null);
  type Chapter = { id: string; label: string };
  const dispatch = useAppDispatch();

  const solution = data.solutionAreas.find((s) => s.id === activeSolution);
  const demo = solution?.heroDemos.find((d) => d.id === activeDemo);
  const level = demo?.levels.find((l) => l.id === activeLevel);
  const handleChapterRedirect = (chapterId: string) => {
    switch (chapterId) {
      case "chapter1":
        dispatch(setIsLevel1FlowOn(true));
        window.location.href = "#/world-map";
        break;
      case "chapter2":
        window.location.href = "#/smarter-inventory-control";
        break;
      case "chapter-l2-1":
        window.location.href = "#/assessment-strategy";
        break;
      case "chapter-l2-2":
        window.location.href = "#/migration-tools-best-practices";
        break;
      case "chapter-d2-l1-1":
        window.location.href = "#/Business-Challenge-and-Vision";
        break;
      case "chapter-d2-l1-2":
        window.location.href = "#/drive-down-operating-costs";
        break;
      case "chapter-d2-l1-3":
        window.location.href = "#/reduce-churn-rates";
        break;
      case "chapter-d2-l1-4":
        window.location.href =
          "#/drive-down-compliance-alerts-and-vulnerabilities";
        break;
      case "chapter-d2-l2-1":
        window.location.href = "#/data-engineering";
        break;
      case "chapter-d2-l2-2":
        window.location.href = "#/ai-agents";
        break;
      case "chapter-d2-l2-3":
        window.location.href = "#/copilot-for-data-science-in-fabric";
        break;
      case "chapter-d2-l2-4":
        window.location.href = "#/copilot-for-power-bi-in-fabric";
        break;
      case "chapter-d2-l2-5":
        window.location.href = "#/security-governance-and-scaling";
        break;
      case "chapter3":
        window.location.href = "#/building-new-app-with-copilot-agent-mode";
        break;
      default:
        window.location.href = "#/wip";
        break;
    }
  };

  return (

    <div className={`${styles.container} ${className}`}>
      <div className={styles.title}>
        {/* <img
          className={styles.titleImage}
          src="https://dreamdemoassets.blob.core.windows.net/dataandaidemo/HeroDemosTitle2.png"
        /> */}
        <span>Azure Hero Demos</span>
      </div>

      <div className={styles.wrapper}>
        <div className={styles.column}>
          <h3>Solution Area</h3>
          {data.solutionAreas.map((area) => (
            <div
           
              className={
                area.id === activeSolution ? styles.active : styles.inactive
              }
              onClick={() => {
                setActiveSolution(area.id);
                setActiveDemo("");
                setActiveLevel("");
              }}
            >
              {area.label}
            </div>
          ))}
        </div>

        {/* Hero Demos */}
        <div className={styles.column}>
          <h3>Hero Demos</h3>
          {solution?.heroDemos.map((d) => (
            <div
             
              className={d.id === activeDemo ? styles.active : styles.inactive}
              onClick={() => {
                setActiveDemo(d.id);
                setActiveLevel("");
              }}
            >
              {d.label}
            </div>
          ))}
        </div>

        {/* Levels */}
        <div className={styles.column}>
          <h3>Levels</h3>
          {demo?.levels.map((level) => {
            if (level.id === "level2") {
              return (
                <PanelBar
                 
                  className={styles.customPanelBar}
                  expandMode="single"
                >
                  <PanelBarItem
                    title={level.label}
                    expanded={level.id === activeLevel}
                    onExpandChange={() =>
                      setActiveLevel(level.id === activeLevel ? null : level.id)
                    }
                    className={
                      level.id === "level2" ? styles.specialPanelItem : ""
                    }
                  >
                    <ul className={styles.chapterList}>
                      {level.chapters.map((chapter) => (
                        <li
                          
                          className={styles.liItem}
                          onClick={(e) => {
                            e.stopPropagation();
                            handleChapterRedirect(chapter.id);
                          }}
                        >
                          {chapter.label}
                        </li>
                      ))}
                    </ul>
                  </PanelBarItem>
                </PanelBar>
              );
            } else {
              return (
                <div
                  key={level.id}
                  className={
                    level.id === activeDemo ? styles.active : styles.inactive
                  }
                  onClick={() => {
                    setActiveLevel(level.id);
                    if (level.chapters.length > 0) {
                      handleChapterRedirect(level.chapters[0].id);
                    }
                  }}
                >
                  {level.label} dasfwefewggvgvfdg
                </div>
              );
            }
          })}
        </div>
      </div>
    </div>
  );
};
