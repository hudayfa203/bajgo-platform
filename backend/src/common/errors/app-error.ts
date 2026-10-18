import { HttpException } from '@nestjs/common';

/**
 * Every API error is `{ error: { code, message, details } }` (docs/API.md).
 * Throw AppError (or a subclass) from services; the HttpExceptionFilter shapes it.
 */
export class AppError extends HttpException {
  constructor(
    public readonly status: number,
    public readonly code: string,
    message: string,
    public readonly details: Record<string, unknown> = {},
  ) {
    super({ error: { code, message, details } }, status);
  }
}

export class ValidationError extends AppError {
  constructor(message = 'Validation failed', details: Record<string, unknown> = {}) {
    super(400, 'VALIDATION_ERROR', message, details);
  }
}
export class UnauthorizedError extends AppError {
  constructor(code = 'UNAUTHORIZED', message = 'Authentication required', details = {}) {
    super(401, code, message, details);
  }
}
export class ForbiddenError extends AppError {
  constructor(code = 'FORBIDDEN', message = 'You do not have permission to do this', details = {}) {
    super(403, code, message, details);
  }
}
export class NotFoundError extends AppError {
  constructor(entity = 'Resource', details = {}) {
    super(404, 'NOT_FOUND', `${entity} not found`, details);
  }
}
export class ConflictError extends AppError {
  constructor(code: string, message: string, details = {}) {
    super(409, code, message, details);
  }
}
export class BusinessRuleError extends AppError {
  constructor(code: string, message: string, details = {}) {
    super(422, code, message, details);
  }
}
export class RateLimitError extends AppError {
  constructor(code = 'RATE_LIMITED', message = 'Too many requests', details = {}) {
    super(429, code, message, details);
  }
}
/** Thrown by provider adapters that need real credentials which are not configured. */
export class ProviderNotConfigured extends AppError {
  constructor(provider: string, missing: string[] = []) {
    super(503, 'PROVIDER_NOT_CONFIGURED', `${provider} is not configured in this environment`, { provider, missing });
  }
}
