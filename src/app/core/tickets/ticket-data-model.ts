import { TicketItem } from "./ticket-item-model";

export interface TicketData {
  companyName: string;
  socialReason: string;
  ruc: string;
  address: string;
  designer: string;
  client: string;
  methodOfPayment: string;
  creationDate: Date;
  saleDetails: TicketItem[];
  totalPrice: number;
  discount: number;
  advance: number;
  igv: number;
  finalAmount: number;
  printDate: Date;
}