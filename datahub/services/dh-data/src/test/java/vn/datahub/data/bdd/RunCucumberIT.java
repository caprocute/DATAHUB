package vn.datahub.data.bdd;

import static io.cucumber.junit.platform.engine.Constants.GLUE_PROPERTY_NAME;
import static io.cucumber.junit.platform.engine.Constants.PLUGIN_PROPERTY_NAME;

import org.junit.platform.suite.api.ConfigurationParameter;
import org.junit.platform.suite.api.IncludeEngines;
import org.junit.platform.suite.api.SelectFile;
import org.junit.platform.suite.api.Suite;

/**
 * Chạy ĐÚNG tệp tiêu chí nghiệm thu của gói đặc tả (không chép, không sửa) qua HTTP thật. Đường
 * dẫn tương đối từ thư mục dự án datahub/services/dh-data.
 */
@Suite
@IncludeEngines("cucumber")
@SelectFile("../../spec/PH07/gherkin/F-07-010.feature")
@ConfigurationParameter(key = GLUE_PROPERTY_NAME, value = "vn.datahub.data.bdd")
@ConfigurationParameter(key = PLUGIN_PROPERTY_NAME, value = "summary")
public class RunCucumberIT {}
