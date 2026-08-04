package vn.lgsp.camel.dancu.pipeline;

/** Chín chặng bắt buộc PH-04 — không được gỡ khỏi metadata route. */
public final class StageIds {

  public static final String RECEIVE = "receive";
  public static final String SCHEMA = "schema";
  public static final String AUTHZ = "authz";
  public static final String TRANSFORM = "transform";
  public static final String ENRICH = "enrich";
  public static final String ROUTE = "route";
  public static final String DELIVER = "deliver";
  public static final String AUDIT = "audit";
  public static final String RESPOND = "respond";

  public static final String[] ORDERED = {
    RECEIVE, SCHEMA, AUTHZ, TRANSFORM, ENRICH, ROUTE, DELIVER, AUDIT, RESPOND
  };

  private StageIds() {}
}
