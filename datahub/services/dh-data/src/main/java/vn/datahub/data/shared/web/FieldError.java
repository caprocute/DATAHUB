package vn.datahub.data.shared.web;

import com.fasterxml.jackson.annotation.JsonInclude;

/** Một phần tử của {@code errors[]} trong phản hồi lỗi: trường, mã con (REQUIRED, PATTERN, CYCLE…), câu mô tả. */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record FieldError(String field, String code, String message) {}
