package vn.lgsp.camel.dancu;

import static org.junit.jupiter.api.Assertions.assertTrue;

import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import org.apache.camel.ProducerTemplate;
import org.junit.jupiter.api.Test;

@QuarkusTest
class CdmMapperTest {

  @Inject ProducerTemplate producerTemplate;

  @Test
  void mapsLegacyCitizenToPersonV1() {
    String out =
        producerTemplate.requestBody(
            "direct:cdm-map-person",
            "{\"maCongDan\":\"P001\",\"hoTen\":\"Nguyen Van A\",\"ngaySinh\":\"1990-01-02\",\"soCMND\":\"012345678\"}",
            String.class);
    assertTrue(out.contains("\"personId\":\"P001\""));
    assertTrue(out.contains("\"fullName\":\"Nguyen Van A\""));
  }
}
