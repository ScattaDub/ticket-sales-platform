import { NestFactory } from '@nestjs/core';
import { ConfigService } from '@nestjs/config';
import { AppModule } from './app.module';
import { Env } from './config/env.validation';
import { ValidationPipe } from '@nestjs/common';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  // Without this, SIGTERM/SIGINT terminate the process directly
  // and onModuleDestroy hooks never run.
  app.enableShutdownHooks();

  const configService = app.get<ConfigService<Env, true>>(ConfigService);
  await app.listen(configService.get('PORT'));
}
void bootstrap();
