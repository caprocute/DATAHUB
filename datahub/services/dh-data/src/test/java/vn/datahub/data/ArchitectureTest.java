package vn.datahub.data;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.classes;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.methods;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;

import com.tngtech.archunit.core.domain.JavaClasses;
import com.tngtech.archunit.core.importer.ClassFileImporter;
import com.tngtech.archunit.core.importer.ImportOption;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.modulith.core.ApplicationModules;

/**
 * Kiến trúc DU: Spring Modulith verify() (CC-MOD-02/03) và luật ArchUnit của D04-01 CC-MOD-05 áp
 * được cho dh-data (thư viện chung vn.datahub.common.archtest chưa có nên luật viết tại chỗ).
 */
class ArchitectureTest {

  private static JavaClasses production;

  @BeforeAll
  static void importClasses() {
    production =
        new ClassFileImporter()
            .withImportOption(ImportOption.Predefined.DO_NOT_INCLUDE_TESTS)
            .importPackages("vn.datahub.data");
  }

  @Test
  @DisplayName("Modulith: module rdm đúng ranh giới, không vòng phụ thuộc")
  void modulesRespectBoundaries() {
    ApplicationModules modules = ApplicationModules.of(DataApplication.class);
    modules.verify();
  }

  @Test
  @DisplayName("Khai báo module: rdm là module nghiệp vụ, shared là nhân mở")
  void modulesAreDetected() {
    ApplicationModules modules = ApplicationModules.of(DataApplication.class);
    org.assertj.core.api.Assertions.assertThat(modules.getModuleByName("rdm")).isPresent();
    org.assertj.core.api.Assertions.assertThat(modules.getModuleByName("shared")).isPresent();
  }

  @Test
  @DisplayName("@Entity và @Repository chỉ nằm trong ..internal.. hoặc nhân persistence")
  void entitiesAndRepositoriesAreInternal() {
    classes()
        .that()
        .areAnnotatedWith(jakarta.persistence.Entity.class)
        .or()
        .areAssignableTo(org.springframework.data.repository.Repository.class)
        .should()
        .resideInAPackage("..internal..")
        .check(production);
  }

  @Test
  @DisplayName("@RestController chỉ nằm trong ..internal.web..")
  void controllersAreInternalWeb() {
    classes()
        .that()
        .areAnnotatedWith(org.springframework.web.bind.annotation.RestController.class)
        .should()
        .resideInAPackage("..internal.web..")
        .check(production);
  }

  @Test
  @DisplayName("..api.. và ..events.. không phụ thuộc jakarta.persistence")
  void publishedApiHasNoJpa() {
    noClasses()
        .that()
        .resideInAnyPackage("..api..", "..events..")
        .should()
        .dependOnClassesThat()
        .resideInAPackage("jakarta.persistence..")
        .check(production);
  }

  @Test
  @DisplayName("Không tạo DataSource hoặc dùng DriverManager ngoài shared.persistence")
  void noRawConnections() {
    noClasses()
        .that()
        .resideOutsideOfPackage("..shared.persistence..")
        .should()
        .dependOnClassesThat()
        .haveFullyQualifiedName("java.sql.DriverManager")
        .orShould()
        .dependOnClassesThat()
        .haveFullyQualifiedName("org.springframework.boot.jdbc.DataSourceBuilder")
        .check(production);
  }

  @Test
  @DisplayName("Không @Query(nativeQuery = true)")
  void noNativeQueries() {
    methods()
        .should(
            new com.tngtech.archunit.lang.ArchCondition<com.tngtech.archunit.core.domain.JavaMethod>(
                "không gắn @Query(nativeQuery = true)") {
              @Override
              public void check(
                  com.tngtech.archunit.core.domain.JavaMethod method,
                  com.tngtech.archunit.lang.ConditionEvents events) {
                method
                    .tryGetAnnotationOfType(org.springframework.data.jpa.repository.Query.class)
                    .filter(org.springframework.data.jpa.repository.Query::nativeQuery)
                    .ifPresent(
                        q ->
                            events.add(
                                com.tngtech.archunit.lang.SimpleConditionEvent.violated(
                                    method, method.getFullName() + " dùng nativeQuery")));
              }
            })
        .check(production);
  }

  @Test
  @DisplayName("Tenant chỉ đặt từ token (shared.security): không ai gọi TenantContext.runAs ngoài nó")
  void tenantContextRunAsOnlyInSecurity() {
    // TenantContext.set là package-private nên trình biên dịch đã chặn; runAs dành cho tác vụ nền
    // (chưa có trong lát cắt) nên cũng bị giới hạn cho tới khi có luật riêng.
    noClasses()
        .that()
        .resideOutsideOfPackage("..shared.security..")
        .should()
        .callMethod(
            vn.datahub.data.shared.security.TenantContext.class,
            "runAs",
            String.class,
            java.util.function.Supplier.class)
        .check(production);
  }

  @Test
  @DisplayName("Không dùng System.out, java.util.Date, printStackTrace")
  void noForbiddenApis() {
    noClasses()
        .should()
        .accessField(System.class, "out")
        .orShould()
        .accessField(System.class, "err")
        .orShould()
        .dependOnClassesThat()
        .haveFullyQualifiedName("java.util.Date")
        .orShould()
        .callMethod(Throwable.class, "printStackTrace")
        .check(production);
  }

  @Test
  @DisplayName("Mọi phương thức xử lý yêu cầu của @RestController có @PreAuthorize (từ chối mặc định)")
  void controllerMethodsAreAuthorized() {
    methods()
        .that()
        .areDeclaredInClassesThat()
        .areAnnotatedWith(org.springframework.web.bind.annotation.RestController.class)
        .and()
        .areAnnotatedWith(org.springframework.web.bind.annotation.RequestMapping.class)
        .or()
        .areAnnotatedWith(org.springframework.web.bind.annotation.GetMapping.class)
        .or()
        .areAnnotatedWith(org.springframework.web.bind.annotation.PostMapping.class)
        .or()
        .areAnnotatedWith(org.springframework.web.bind.annotation.PatchMapping.class)
        .or()
        .areAnnotatedWith(org.springframework.web.bind.annotation.PutMapping.class)
        .or()
        .areAnnotatedWith(org.springframework.web.bind.annotation.DeleteMapping.class)
        .should()
        .beAnnotatedWith(org.springframework.security.access.prepost.PreAuthorize.class)
        .allowEmptyShould(true)
        .check(production);
  }

  @Test
  @DisplayName("Entity của module chỉ ánh xạ bảng trong schema ph07_rdm (CC-JPA-06)")
  void entitiesMapOwnSchema() {
    classes()
        .that()
        .areAnnotatedWith(jakarta.persistence.Entity.class)
        .and()
        .resideInAPackage("vn.datahub.data.rdm..")
        .should(
            new com.tngtech.archunit.lang.ArchCondition<com.tngtech.archunit.core.domain.JavaClass>(
                "có @Table(schema = \"ph07_rdm\")") {
              @Override
              public void check(
                  com.tngtech.archunit.core.domain.JavaClass item,
                  com.tngtech.archunit.lang.ConditionEvents events) {
                boolean ok =
                    item.tryGetAnnotationOfType(jakarta.persistence.Table.class)
                        .map(t -> "ph07_rdm".equals(t.schema()))
                        .orElse(false);
                if (!ok) {
                  events.add(
                      com.tngtech.archunit.lang.SimpleConditionEvent.violated(
                          item, item.getName() + " không ánh xạ schema ph07_rdm"));
                }
              }
            })
        .check(production);
  }
}
