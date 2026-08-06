package vn.lgsp.control.routes.api;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record RouteCreateRequest(
    @NotBlank @Pattern(regexp = "^[a-z0-9-]+$") String routeCode,
    @NotBlank String title,
    String routeType,
    /**
     * Loại tài nguyên Camel: `ROUTE` | `KAMELET` | `PIPE` | `TEST` (IP-07 K2-5).
     *
     * Khác hẳn `routeType` — cột đó nói **cách vận chuyển** (`SYNC`/`ASYNC`), còn cột này
     * nói **loại tệp**. Bỏ trống thì hiểu là `ROUTE`.
     */
    String resourceKind,
    @NotBlank String sourceSystem,
    String targetSystem,
    @NotBlank String definitionYaml) {}
