package vn.lgsp.control.routes.internal;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import vn.lgsp.control.routes.api.RoutesApi;

/**
 * Dọn nhật ký chạy thử quá hạn lưu trữ (FR-D-042, IP-06 G5-9).
 *
 * Nhật ký chạy thử tăng đều theo số lần bấm «Chạy thử» và không có giá trị vận hành sau
 * vài tháng. Không dọn thì bảng phình vô hạn — và giữ dữ liệu quá thời hạn cần thiết
 * cũng là rủi ro theo Luật Dữ liệu 2024.
 *
 * Số ngày cấu hình được qua `lgsp.routes.test-run-retention-days`; mặc định 90.
 */
@Component
class TestRunRetentionJob {

  private static final Logger log = LoggerFactory.getLogger(TestRunRetentionJob.class);

  private final RoutesApi routesApi;
  private final int retentionDays;

  TestRunRetentionJob(
      RoutesApi routesApi,
      @Value("${lgsp.routes.test-run-retention-days:90}") int retentionDays) {
    this.routesApi = routesApi;
    this.retentionDays = retentionDays;
  }

  /** Chạy lúc 03:15 hằng ngày — ngoài giờ cao điểm của cổng dịch vụ công. */
  @Scheduled(cron = "${lgsp.routes.test-run-purge-cron:0 15 3 * * *}")
  void purge() {
    try {
      int removed = routesApi.purgeTestRuns(retentionDays);
      if (removed > 0) {
        log.info("Đã dọn {} lần chạy thử quá {} ngày", removed, retentionDays);
      }
    } catch (RuntimeException e) {
      // Dọn dẹp thất bại không được làm sập ứng dụng; lần chạy sau sẽ thử lại.
      log.warn("Dọn nhật ký chạy thử thất bại", e);
    }
  }
}
