package vn.lgsp.control.routes.api;

import java.util.List;

/** Chi tiết một lần chạy thử: siêu dữ liệu + waterfall theo chặng (FR-D-040). */
public record TestRunDetailDto(TestRunSummaryDto run, List<TestRunStageDto> stages) {

  /** Một chặng trên đường chạy. `errorText` đã cắt ngắn và không chứa thân bản tin. */
  public record TestRunStageDto(
      int seqNo, String stage, String status, int durationMs, int offsetMs, String errorText) {}
}
