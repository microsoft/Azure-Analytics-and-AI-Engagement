export interface OrderHistory {
    title: string;
    firstName: string;
    lastName: string;
    emailAddress: string;
    phoneNumber: string;
    addresses?: Address[];
    orders: Order[];
    profileImageUrl?: string;
  }
  
  interface Address {
    addressLine1: string;
    addressLine2: string;
    city: string;
    state: string;
    zipCode: string;
  }
  
  export interface Order {
    id: string;
    status: string;
    orderedOn: string;
    orderedTotal: number;
    shippedOn?: string;
  }
  
  export interface OrderDetail {
    order: Order;
    items: ProductDetail[];
  }
  
  export interface ProductDetail {
    product: Product[];
    quantity: number;
    lineAmount: number;
  }
  
  interface Product {
    productId: string;
    productName: string;
    imageUrl: string;
  }
  
  export interface CustomerOrderHistory {
    id: string;
    status: string;
    orderedOn: string;
    orderedTotal: number;
    shippedOn?: string;
    lineItems: ProductDetail[];
  }
  