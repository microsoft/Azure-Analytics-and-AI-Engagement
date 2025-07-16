import * as React from "react";
import { useLocation, useNavigate } from "react-router-dom";
import {
  Drawer as KendoDrawer,
  DrawerContent,
  DrawerItem,
  DrawerItemProps,
  DrawerSelectEvent,
} from "@progress/kendo-react-layout";
import { Button } from "@progress/kendo-react-buttons";
import { chevronDownIcon, chevronRightIcon } from "@progress/kendo-svg-icons";
import { SvgIcon } from "@progress/kendo-react-common";
import { DemoMenu } from "types";
import styles from "./styles.module.scss";
import { useAppDispatch, useAppSelector } from "hooks";
// import { customers } from "pages";
import {
  setCustomerDetails,
  setSideBarCurrentItemMenu,
  setSideBarMenunextExpanded,
} from "store";

const CustomItem = (props: DrawerItemProps) => {
  const { visible, toolTip, ...others } = props;
  const arrowDir = props.dataExpanded ? chevronDownIcon : chevronRightIcon;

  return props.visible === false ? null : (
    <DrawerItem {...others} title={props.text}>
      {props.icon && (
        <img className={styles.icon} src={props.icon} alt={props.text} />
      )}
      <span className={"k-item-text"} title={toolTip}>
        {props.text}
      </span>
      {props.dataExpanded !== undefined && ( // Only show arrow if expandable
        <SvgIcon
          icon={arrowDir}
          style={{
            marginLeft: "auto",
          }}
        />
      )}
    </DrawerItem>
  );
};
export const Drawer = (props: any) => {
  const navigate = useNavigate();
  const [drawerExpanded, setDrawerExpanded] = React.useState(false);
  const [items, setItems] = React.useState<any>([]);
  const [collapsedItems, setCollapsedItems] = React.useState<any>([]);
  const location = useLocation();
  const dispatch = useAppDispatch();
  const { sideBarMenuExpanded, sideBarMenu } = useAppSelector(
    (state) => state.config
  );
  let { demoMenus } = useAppSelector((state: any) => state.config);

  // React.useEffect(() => {
  //   dispatch(setCustomerDetails(customers[0]));
  // }, []);

  const processMenuData = React.useCallback(
    (currentPath: string) => {
      const updatedMenus = (demoMenus as DemoMenu[])?.map((menu, index) => {
        if (menu.demoSubMenus?.length) {
          return {
            id: `${index + 1}`,
            menuName: menu.name,
            menuIcon: menu.icon,
            menuItems: menu.demoSubMenus.map((menuItem, i) => {
              if (menuItem.demoSubMenus?.length) {
                return {
                  id: `${index + 1}-sub-${i + 1}`,
                  title: menuItem.name,
                  icon: null,
                  toolTip: menuItem.toolTip,
                  dataExpanded: false, // Allow expansion only if there are children
                  menuItems: menuItem.demoSubMenus.map((thirdLevelItem, j) => ({
                    id: `${index + 1}-sub-${i + 1}-sub-${j + 1}`,
                    title: thirdLevelItem.name,
                    href: thirdLevelItem.url,
                    icon: null,
                    toolTip: thirdLevelItem.toolTip,
                  })),
                };
              } else {
                return {
                  id: `${index + 1}-sub-${i + 1}`,
                  title: menuItem.name,
                  href: menuItem.url,
                  icon: null,
                  toolTip: menuItem.toolTip,
                  // No dataExpanded property for items without children
                };
              }
            }),
          };
        } else {
          return {
            id: `${index + 1}`,
            menuName: menu.name,
            menuIcon: menu.icon,
            href: `${menu.url}`,
          };
        }
      });

      if (!updatedMenus?.length) return { mappedItems: [], collapsedItems: [] };

      let collapsedItems: any = [];
      const mappedItems = updatedMenus.flatMap((menu) => {
        const topLevelItem = {
          text: menu.menuName,
          icon: menu.menuIcon,
          id: menu.id,
          route: menu.href ? menu.href : null,
          dataExpanded: menu.menuItems ? false : undefined, // Only expandable if there are children
          level: 0,
        };

        collapsedItems.push(topLevelItem);

        const subItems = menu.menuItems
          ? menu.menuItems.flatMap((item: any) => {
              if (item.menuItems?.length) {
                const levelTwoItem = {
                  text: item.title,
                  icon: item.icon,
                  id: item.id,
                  parentId: menu.id,
                  route: item.href,
                  toolTip: item.toolTip,
                  dataExpanded: false, // Allow expansion for level 2 items
                  level: 1,
                };

                const levelThreeItems = item.menuItems.map(
                  (thirdLevelItem: any) => ({
                    text: thirdLevelItem.title,
                    icon: thirdLevelItem.icon,
                    id: thirdLevelItem.id,
                    parentId: item.id,
                    gpId: menu.id,
                    route: thirdLevelItem.href,
                    toolTip: thirdLevelItem.toolTip,
                    level: 2,
                  })
                );

                return [levelTwoItem, ...levelThreeItems];
              } else {
                return [
                  {
                    text: item.title,
                    icon: item.icon,
                    id: item.id,
                    parentId: menu.id,
                    route: item.href,
                    toolTip: item.toolTip,
                    // No dataExpanded for items without children
                    level: 1,
                  },
                ];
              }
            })
          : [];

        return [topLevelItem, ...subItems, { separator: true }];
      });

      // Set initial expansion state based on current route
      const initialData = mappedItems.map((item: any) => {
        if (item.separator) return item;

        const isSelected = item.route === currentPath;
        let shouldExpand = false;

        if (isSelected) {
          if (item.level === 2) {
            const parentItem = mappedItems.find(
              (i: any) => i.id === item.parentId
            );
            const grandParentItem = mappedItems.find(
              (i: any) => i.id === item.gpId
            );
            if (parentItem) parentItem.dataExpanded = true;
            if (grandParentItem) grandParentItem.dataExpanded = true;
          } else if (item.level === 1) {
            const parentItem = mappedItems.find(
              (i: any) => i.id === item.parentId
            );
            if (parentItem) parentItem.dataExpanded = true;
          }
        }

        const isParentOfSelected = mappedItems.some(
          (i: any) =>
            i.route === currentPath &&
            (i.parentId === item.id || i.gpId === item.id)
        );

        shouldExpand = isParentOfSelected;

        return {
          ...item,
          selected: isSelected,
          dataExpanded: shouldExpand || item.dataExpanded,
        };
      });

      return { mappedItems: initialData, collapsedItems };
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [demoMenus]
  );

  const onSelect = (ev: DrawerSelectEvent) => {
    const currentItem = ev?.itemTarget?.props;
    const nextExpanded = !currentItem?.dataExpanded;

    const newData = items.map((item: any) => {
      if (item.separator) return item;

      let newState = { ...item };

      //Handle expansion state
      if (item.id === currentItem?.id) {
        if (currentItem?.dataExpanded !== undefined) {
          newState.dataExpanded = nextExpanded;
        }
        newState.selected = true;
      } else {
        // Maintain expansion state for parents of selected item
        if (
          currentItem?.parentId === item.id ||
          currentItem?.gpId === item.id
        ) {
          newState.dataExpanded = true;
        }
        // Reset selection for other items
        newState.selected = false;
      }

      return newState;
    });

    if (currentItem?.route) {
      navigate(currentItem?.route);
    }
    setItems(newData);
  };

  React.useEffect(() => {
    const { mappedItems, collapsedItems } = processMenuData(location.pathname);
    setItems(mappedItems);
    setCollapsedItems(collapsedItems);
  }, [location.pathname, processMenuData]);

  const handleClick = () => {
    setDrawerExpanded(!drawerExpanded);
  };

  const getVisibleItems = React.useMemo(() => {
    return items.map((item: any) => {
      if (item.separator) return item;

      const { parentId, gpId, ...others } = item;

      if (parentId !== undefined) {
        const parentEl = items.find((parent: any) => parent.id === parentId);
        const grandParentEl = gpId
          ? items.find((parent: any) => parent.id === gpId)
          : null;

        const isVisible =
          parentEl &&
          parentEl.dataExpanded &&
          (!gpId || (grandParentEl && grandParentEl.dataExpanded));

        return {
          ...others,
          visible: isVisible,
        };
      }

      return item;
    });
  }, [items]);

  React.useEffect(() => {
    if (sideBarMenu?.length > 0) {
      let newData: any[] = [];
      sideBarMenu.forEach((sm: any) => {
        const currentItem = sm?.itemTarget?.props;
        const nextExpanded = !currentItem?.dataExpanded;

        newData = items.map((item: any) => {
          if (item.separator) return item;

          let newState = { ...item };

          //Handle expansion state
          if (item.id === currentItem?.id) {
            if (currentItem?.dataExpanded !== undefined) {
              newState.dataExpanded = nextExpanded;
            }
            newState.selected = true;
          } else {
            // Maintain expansion state for parents of selected item
            if (
              currentItem?.parentId === item.id ||
              currentItem?.gpId === item.id
            ) {
              newState.dataExpanded = true;
            }
            // Reset selection for other items
            newState.selected = false;
          }

          return newState;
        });
      });
      setItems(newData);
    }
  }, [sideBarMenu]);

  return (
    <div className={styles.container}>
      {drawerExpanded ? (
        <>
          <div className={styles.toolbar}>
            <Button
              fillMode="flat"
              style={{ padding: "8px 16px" }}
              onClick={handleClick}
              className={styles.toggleBtn}
            >
              <img
                src="https://dreamdemoassets.blob.core.windows.net/daidemo/aoai_2_hamburger.png"
                alt="hamburger"
              />
            </Button>
          </div>
          <KendoDrawer
            expanded={drawerExpanded}
            mode="push"
            width={220}
            items={getVisibleItems}
            item={CustomItem}
            onSelect={onSelect}
            className={styles.drawer}
          >
            <DrawerContent className={styles.content}>
              {props.children}
            </DrawerContent>
          </KendoDrawer>
        </>
      ) : (
        <>
          <div className={styles.toolbar}>
            <Button
              fillMode="flat"
              style={{ padding: "8px 14px" }}
              onClick={handleClick}
              className={styles.toggleBtn}
            >
              <img
                src="https://dreamdemoassets.blob.core.windows.net/daidemo/aoai_2_hamburger.png"
                alt="hamburger"
              />
            </Button>
          </div>
          <KendoDrawer
            expanded={!drawerExpanded}
            mode="push"
            width={50}
            items={collapsedItems}
            item={CustomItem}
            onSelect={() => setDrawerExpanded(true)}
            className={`${styles.drawer} ${styles.collapsedDrawer}`}
          >
            <DrawerContent
              className={`${styles.content} ${styles.notExpanded}`}
            >
              {props.children}
            </DrawerContent>
          </KendoDrawer>
        </>
      )}
    </div>
  );
};
