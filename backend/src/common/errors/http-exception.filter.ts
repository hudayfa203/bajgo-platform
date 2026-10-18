import { ArgumentsHost, Catch, ExceptionFilter, HttpException, HttpStatus, Logger } from '@nestjs/common';
import { Request, Response } from 'express';
import { ZodValidationException } from 'nestjs-zod';
import { AppError } from './app-error';

const CODE_BY_STATUS: Record<number, string> = {
  400: 'BAD_REQUEST',
  401: 'UNAUTHORIZED',
  403: 'FORBIDDEN',
  404: 'NOT_FOUND',
  409: 'CONFLICT',
  413: 'PAYLOAD_TOO_LARGE',
  415: 'UNSUPPORTED_MEDIA_TYPE',
  422: 'UNPROCESSABLE',
  429: 'RATE_LIMITED',
  500: 'INTERNAL_ERROR',
  503: 'SERVICE_UNAVAILABLE',
};

@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger('Http');

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const res = ctx.getResponse<Response>();
    const req = ctx.getRequest<Request>();
    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let body: { error: { code: string; message: string; details: unknown } };

    if (exception instanceof AppError) {
      status = exception.status;
      body = { error: { code: exception.code, message: exception.message, details: exception.details } };
    } else if (exception instanceof ZodValidationException) {
      status = 400;
      const zerr = exception.getZodError();
      body = {
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Validation failed',
          details: { issues: zerr.issues.map((i) => ({ path: i.path.join('.'), message: i.message })) },
        },
      };
    } else if (exception instanceof HttpException) {
      status = exception.getStatus();
      const resp = exception.getResponse() as Record<string, unknown> | string;
      const message = typeof resp === 'string' ? resp : ((resp.message as string) ?? exception.message);
      body = { error: { code: CODE_BY_STATUS[status] ?? 'ERROR', message: Array.isArray(message) ? message.join('; ') : message, details: {} } };
    } else {
      this.logger.error(`Unhandled error on ${req.method} ${req.url}: ${(exception as Error)?.stack ?? exception}`);
      body = { error: { code: 'INTERNAL_ERROR', message: 'Something went wrong', details: {} } };
    }
    res.status(status).json(body);
  }
}
