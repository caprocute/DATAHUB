package vn.datahub.data.bdd;

import io.cucumber.spring.CucumberContextConfiguration;
import vn.datahub.data.support.ApiTest;

/** Khởi động ứng dụng thật một lần cho mọi kịch bản Gherkin. */
@CucumberContextConfiguration
public class CucumberSpringConfiguration extends ApiTest {}
