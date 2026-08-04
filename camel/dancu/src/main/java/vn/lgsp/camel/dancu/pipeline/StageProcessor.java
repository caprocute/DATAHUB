package vn.lgsp.camel.dancu.pipeline;

import jakarta.enterprise.context.ApplicationScoped;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.apache.camel.Exchange;
import org.apache.camel.Processor;
import org.jboss.logging.Logger;

/** Gắn metadata chặng + waterfall cho test-runner / audit. */
@ApplicationScoped
public class StageProcessor {

  private static final Logger LOG = Logger.getLogger(StageProcessor.class);
  public static final String HEADER_STAGE = "LgspStage";
  public static final String HEADER_WATERFALL = "LgspWaterfall";
  public static final String HEADER_ERROR_CODE = "LgspErrorCode";

  public Processor mark(String stageId) {
    return exchange -> {
      exchange.getMessage().setHeader(HEADER_STAGE, stageId);
      @SuppressWarnings("unchecked")
      List<Map<String, Object>> wf =
          (List<Map<String, Object>>) exchange.getProperty(HEADER_WATERFALL, List.class);
      if (wf == null) {
        wf = new ArrayList<>();
        exchange.setProperty(HEADER_WATERFALL, wf);
      }
      Map<String, Object> step = new LinkedHashMap<>();
      step.put("stage", stageId);
      step.put("at", System.currentTimeMillis());
      step.put("status", "ok");
      wf.add(step);
      LOG.debugf("stage=%s exchange=%s", stageId, exchange.getExchangeId());
    };
  }

  public void failStage(Exchange exchange, String stageId, String errorCode, String detail) {
    exchange.getMessage().setHeader(HEADER_STAGE, stageId);
    exchange.getMessage().setHeader(HEADER_ERROR_CODE, errorCode);
    @SuppressWarnings("unchecked")
    List<Map<String, Object>> wf =
        (List<Map<String, Object>>) exchange.getProperty(HEADER_WATERFALL, List.class);
    if (wf == null) {
      wf = new ArrayList<>();
      exchange.setProperty(HEADER_WATERFALL, wf);
    }
    Map<String, Object> step = new LinkedHashMap<>();
    step.put("stage", stageId);
    step.put("at", System.currentTimeMillis());
    step.put("status", "error");
    step.put("errorCode", errorCode);
    step.put("detail", detail);
    wf.add(step);
  }
}
