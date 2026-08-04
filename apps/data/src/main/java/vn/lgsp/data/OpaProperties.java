package vn.lgsp.data;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "lgsp.opa")
public class OpaProperties {

  /** Khi false — bỏ PEP OPA (profile test / DEV khẩn). */
  private boolean enabled = true;

  private String url = "http://localhost:8181";

  public boolean isEnabled() {
    return enabled;
  }

  public void setEnabled(boolean enabled) {
    this.enabled = enabled;
  }

  public String getUrl() {
    return url;
  }

  public void setUrl(String url) {
    this.url = url;
  }
}
