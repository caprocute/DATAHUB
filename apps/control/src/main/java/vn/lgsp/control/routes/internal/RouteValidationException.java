package vn.lgsp.control.routes.internal;

import vn.lgsp.control.routes.api.ValidationResultDto;

class RouteValidationException extends RuntimeException {

  private final ValidationResultDto result;

  RouteValidationException(String message, ValidationResultDto result) {
    super(message);
    this.result = result;
  }

  ValidationResultDto result() {
    return result;
  }
}
