export interface MenuItem {
  title: string;
  href: string;
  id: number;
  icon: string;
}

export interface Menu {
  id: number;
  menuIcon: string;
  menuName: string;
  menuItems?: MenuItem[];
  href?: string;
}
