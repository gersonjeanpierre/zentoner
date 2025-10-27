import { ApplicationConfig, provideBrowserGlobalErrorListeners, provideZonelessChangeDetection, isDevMode } from '@angular/core';
import { provideRouter } from '@angular/router';

import { routes } from './app.routes';
import { HttpClient, provideHttpClient } from '@angular/common/http';
import { provideTranslateService, provideTranslateLoader } from "@ngx-translate/core";
import { provideTranslateHttpLoader } from "@ngx-translate/http-loader";
import { provideServiceWorker } from '@angular/service-worker';

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideZonelessChangeDetection(),
    provideRouter(routes),
    provideHttpClient(),
    HttpClient,
    provideTranslateService({
      loader: provideTranslateHttpLoader({
        prefix: '/i18n/',
        suffix: '.json'
      }),
      fallbackLang: 'es',
      lang: 'es'
    }), provideServiceWorker('ngsw-worker.js', {
            enabled: !isDevMode(),
            registrationStrategy: 'registerWhenStable:30000'
          })
  ]
};
