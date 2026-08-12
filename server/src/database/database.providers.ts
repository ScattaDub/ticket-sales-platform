import { Pool } from 'pg';
import { ConfigService } from '@nestjs/config';
import { Env } from '../config/env.validation';

export const DB_POOL = 'DB_POOL';

export const databaseProviders = [
  {
    provide: DB_POOL,
    inject: [ConfigService],
    useFactory: (configService: ConfigService<Env, true>): Pool => {
      return new Pool({
        host: configService.get('DB_HOST'),
        port: configService.get('DB_PORT'),
        database: configService.get('DB_NAME'),
        user: configService.get('DB_USER'),
        password: configService.get('DB_PASSWORD'),
      });
    },
  },
];
