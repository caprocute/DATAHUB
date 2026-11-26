package vn.datahub.data.shared.web;

/** Mã lỗi nghiệp vụ: mã ERR-nn-nnn, trạng thái HTTP và tiêu đề tiếng Việt cố định theo mã (CC-ERR-02). */
public interface ErrorCode {

  String code();

  int status();

  String title();

  /** Đoạn cuối của {@code type} (https://datahub.gov.vn/problems/rdm/{slug}). */
  String slug();
}
