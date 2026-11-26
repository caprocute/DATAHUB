package vn.datahub.data;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;
import org.springframework.modulith.Modulithic;

/** Đơn vị triển khai dh-data: ứng dụng Spring Modulith, mỗi phân hệ là một module (ADR-001). */
@SpringBootApplication
@Modulithic(systemName = "dh-data")
@ConfigurationPropertiesScan
public class DataApplication {

  public static void main(String[] args) {
    SpringApplication.run(DataApplication.class, args);
  }
}
