import { AuthContext } from "context";
import { useContext } from "react";
import { NavLink as RouterNavLink, useLocation } from "react-router-dom";

import styles from "./styles.module.scss";

const { IconBlobBaseUrl } = window.config;

const NavLink = ({
  href,
  title,
  icon,
}: {
  href: string;
  title: string;
  icon: string;
}) => {
  const location = useLocation();
  const { trackNavigation } = useContext(AuthContext);

  return (
    <RouterNavLink
      to={href}
      className={`${styles.navItem} ${
        href === location.pathname && styles.activeMenuItem
      }`}
      onClick={() => trackNavigation(title)}
    >
      <div className={styles.navImg}>
        <img
          src={icon.includes("http") ? icon : `${IconBlobBaseUrl}${icon}`}
          alt={title}
        />
      </div>
      <div>{title}</div>
    </RouterNavLink>
  );
};

export default NavLink;
