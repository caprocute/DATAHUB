package vn.lgsp.data.rdm.api;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

/** Yêu cầu tạo danh mục (FR-07-001). */
public record CreateCatalogRequest(
    @NotBlank @Pattern(regexp = "^[A-Z0-9_]+$", message = "mã danh mục chỉ gồm A-Z, 0-9, _")
        String maDanhMuc,
    @NotBlank String ten,
    // Bắt buộc theo EN-07-01 — người dùng phải biết khi nào dùng danh mục nào.
    @NotBlank String moTa,
    @NotBlank String donViChuQuan,
    @NotBlank String nguonGoc,
    @NotBlank String cauTrucMa,
    boolean coPhanCap,
    String daiMaDiaPhuong) {}
