package vn.lgsp.control.onboarding.internal;

import java.net.URI;
import java.util.Set;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.core.ResponseBytes;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.S3Configuration;
import software.amazon.awssdk.services.s3.model.CreateBucketRequest;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.GetObjectResponse;
import software.amazon.awssdk.services.s3.model.HeadBucketRequest;
import software.amazon.awssdk.services.s3.model.NoSuchBucketException;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.model.S3Exception;

/**
 * Lưu tệp đính kèm hồ sơ kết nạp vào object storage tương thích S3
 * (SeaweedFS ở DEV theo ADR-020 — không dùng MinIO).
 *
 * Tệp **không** nằm trong CSDL: hồ sơ năng lực có thể là bản quét vài chục MB, để
 * trong Postgres sẽ phình bản sao lưu và làm chậm truy vấn danh sách.
 */
@Component
class AttachmentStorage {

  /**
   * Chỉ nhận các định dạng hồ sơ hành chính thường dùng. Danh sách cho phép
   * (allow-list) thay vì chặn theo đuôi tệp: chặn thì luôn sót.
   */
  static final Set<String> ALLOWED_TYPES =
      Set.of(
          "application/pdf",
          "image/png",
          "image/jpeg",
          "application/msword",
          "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
          "application/vnd.ms-excel",
          "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");

  /** Trần 20 MB mỗi tệp — đủ cho bản quét quyết định, chặn tải lên nhầm. */
  static final long MAX_BYTES = 20L * 1024 * 1024;

  private final S3Client s3;
  private final String bucket;

  AttachmentStorage(
      @Value("${lgsp.attachments.endpoint:http://localhost:8333}") String endpoint,
      @Value("${lgsp.attachments.access-key:lgsp_audit_dev}") String accessKey,
      @Value("${lgsp.attachments.secret-key:lgsp_audit_dev_secret_change_me}") String secretKey,
      @Value("${lgsp.attachments.bucket:lgsp-onboarding}") String bucket) {
    this.bucket = bucket;
    this.s3 =
        S3Client.builder()
            .endpointOverride(URI.create(endpoint))
            .region(Region.US_EAST_1)
            .credentialsProvider(
                StaticCredentialsProvider.create(AwsBasicCredentials.create(accessKey, secretKey)))
            .serviceConfiguration(
                S3Configuration.builder()
                    // SeaweedFS chỉ hiểu path-style, không hiểu virtual-host style.
                    .pathStyleAccessEnabled(true)
                    // Tắt chữ ký theo khối: SeaweedFS lưu nguyên khung `chunk-signature`
                    // vào nội dung tệp, làm tệp tải về khác tệp đã gửi.
                    .chunkedEncodingEnabled(false)
                    .build())
            .build();
  }

  /** Tạo bucket nếu chưa có. Gọi lười lúc tải lên đầu tiên để khởi động không phụ thuộc storage. */
  private void ensureBucket() {
    try {
      s3.headBucket(HeadBucketRequest.builder().bucket(bucket).build());
    } catch (NoSuchBucketException e) {
      s3.createBucket(CreateBucketRequest.builder().bucket(bucket).build());
    } catch (S3Exception e) {
      if (e.statusCode() == 404) {
        s3.createBucket(CreateBucketRequest.builder().bucket(bucket).build());
      } else {
        throw e;
      }
    }
  }

  void put(String objectKey, byte[] content, String contentType) {
    ensureBucket();
    s3.putObject(
        PutObjectRequest.builder().bucket(bucket).key(objectKey).contentType(contentType).build(),
        RequestBody.fromBytes(content));
  }

  byte[] get(String objectKey) {
    ResponseBytes<GetObjectResponse> res =
        s3.getObjectAsBytes(GetObjectRequest.builder().bucket(bucket).key(objectKey).build());
    return res.asByteArray();
  }
}
