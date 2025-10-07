import { TicketItem } from "./ticket-item-model";

export interface TicketData {
  companyName: string;
  designer: string;
  client: string;
  creationDate: Date;
  saleDetails: TicketItem[];
  totalPrice: number;
  advance: number;
  discount: number;
  igv: number;
  finalAmount: number;
  printDate: Date;
}