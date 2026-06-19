import { Menu, MenuItemModel } from "@progress/kendo-react-layout";
import { useLocation } from "react-router-dom";
import styles from "./styles.module.scss";
import { getMenu } from "common";
import NavLink from "./navLink";
import { useDevice } from "hooks";
import { FC, useContext } from "react";
import { SettingsContext } from "context";
import { DemoMenu } from "types";

const { demoMenus, navImageUrl, navColor } = window.config;

export const NavBar: FC = () => {
  const { IconBlobBaseUrl } = window.config;
  const location = useLocation();
  const { isDesktopDevice } = useDevice();

  // const newMenu: any[] = [];
  let updatedMenus: any[] = (demoMenus as DemoMenu[])?.map((menu) => {
    if (menu.demoSubMenus?.length) {
      return {
        id: menu.id,
        menuName: menu.name,
        menuIcon: menu.icon,
        menuItems: menu.demoSubMenus.map((menuItem) => {
          return {
            id: menuItem.id,
            icon: menuItem.icon,
            title: menuItem.name,
            href: `${menuItem.url}`,
          };
        }),
      };
    } else {
      return {
        id: menu.id,
        menuName: menu.name,
        menuIcon: menu.icon,
        href: `${menu.url}`,
      };
    }
  });

  if (!demoMenus?.length) {
    updatedMenus = getMenu({});
  }

  /**
   * It will return an array of items which is compatible to MenuItemModel[]
   * Modify "menu" array in order to change the navbar items
   * Reference: https://www.telerik.com/kendo-react-ui/components/layout/menu/items/properties/#toc-icon
   * API: https://www.telerik.com/kendo-react-ui/components/layout/api/MenuItemModel/
   */
  const items: MenuItemModel[] = updatedMenus
    // logout is filtered out as we show it on mobile only
    ?.filter((menu) => menu.href !== `/logout`)
    .map(({ menuIcon, menuItems, menuName, href }) => {
      // href is optional in case you only have one item in your menu you can directly render it because of this logic
      const hrefList = href
        ? href === location.pathname
          ? href
          : []
        : menuItems?.map(({ href }: any) => href);
      const cssClass = hrefList?.includes(location.pathname)
        ? styles.activeMenuItem
        : undefined;
      const items: MenuItemModel[] = [
        {
          text: menuName,
          ...(href ? { url: `#${href}` } : { disabled: true }),
          cssClass: `${
            href ? styles.singleNavItemWrapper : styles.navItemWrapper
          } ${cssClass}`,
        },
      ];

      if (menuItems?.length) {
        items.push(
          ...menuItems.map(({ href, icon, title }: any) => ({
            render: () => <NavLink title={title} href={href} icon={icon} />,
            cssClass: styles.navItemWrapper,
          }))
        );
      }

      return {
        render: () => (
          <img
            src={
              menuIcon.includes("http")
                ? menuIcon
                : `${IconBlobBaseUrl}${menuIcon}`
            }
            alt={menuName}
          />
        ),
        cssClass,
        items,
      };
    });

  return (
    <>
      <div
        className={styles.navBarContainer}
        style={{
          backgroundImage: `url(${navImageUrl})`,
          backgroundColor: navColor,
        }}
      >
        <Menu id="leftNavMenu"
          openOnClick={!isDesktopDevice}
          className={styles.navBarMenu}
          vertical
          items={items}
        />
      </div>
    </>
  );
};
