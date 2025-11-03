import { Component, inject } from '@angular/core';
import { ShopService } from './shop-service';

@Component({
  selector: 'app-shops',
  imports: [],
  templateUrl: './shops.html'
})
export default class Shops {
  private shopService = inject(ShopService);

  async ngOnInit() {
    const shops = await this.shopService.listShops();
    console.log(shops);
  }


}
