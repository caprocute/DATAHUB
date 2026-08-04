package vn.lgsp.control.routes.api;

import java.util.List;

public record ValidationResultDto(boolean valid, List<ValidationFinding> findings) {}
