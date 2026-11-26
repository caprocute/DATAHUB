package vn.datahub.data.bdd;

import io.cucumber.java.Before;
import vn.datahub.data.support.Db;

/** Mỗi kịch bản bắt đầu từ dữ liệu nền (seed COMMON) để các kịch bản độc lập nhau (CC-TEST-05). */
public class Hooks {

  @Before(order = 0)
  public void resetDatabase() {
    Db.resetToSeed();
  }
}
