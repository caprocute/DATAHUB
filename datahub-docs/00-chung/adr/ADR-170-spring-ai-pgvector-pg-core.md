---
ma_tai_lieu: ADR-170
ten: Dùng Spring AI và pgvector trên pg-core cho tri thức của trợ lý AI, truy hồi lai vector và từ khóa không dấu
phien_ban: 0.1
ngay: 2026-11-26
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, nhóm PH-17, DBA, ATTT, Hội đồng thẩm định
---

# ADR-170 · Spring AI và pgvector trên pg-core

## Bối cảnh

PH-17 cần lưu khoảng 500.000 đoạn tri thức của một tỉnh vừa (GĐ-17-04) kèm vector 1024 chiều, tìm theo ngữ nghĩa và theo từ khóa tiếng Việt, và phải cô lập theo tenant, theo quyền của người hỏi (SEC-49, THR-56). Dữ liệu cần xóa vật lý trong 60 giây khi đổi phân loại (BR-17-029). Hạ tầng đã chốt PostgreSQL 18 CloudNativePG có RLS (ADR-003); pgvector 0.8 hỗ trợ chỉ mục HNSW và quét lặp có lọc. Lớp gọi mô hình cần trừu tượng để đổi nhà cung cấp mà không đổi mã nghiệp vụ.

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Cơ sở dữ liệu vector riêng (Qdrant, Milvus, OpenSearch) | Tối ưu cho vector, nhiều tính năng | Thêm một hệ cần vận hành, sao lưu, DR, RLS không có sẵn nên phải tự dựng cô lập tenant và xóa lan truyền; tăng diện tấn công ở vùng Z5 |
| B. pgvector trên `pg-core`, dùng `PgVectorStore` của Spring AI | Ít mã | Lược đồ cố định không có `tenant_id`, `acl`, `class_level`, `content_hash`, không có cột từ khóa nên không truy hồi lai được |
| C. **pgvector trên `pg-core`, bảng riêng `knowledge_chunk` có RLS, truy cập bằng `JdbcClient`; Spring AI chỉ cho `ChatModel`, `EmbeddingModel` và đầu ra có cấu trúc; truy hồi lai bằng HNSW cộng `tsvector` không dấu, hợp nhất RRF** | Một hệ lưu trữ, RLS và sao lưu sẵn có, xóa lan truyền là `DELETE` trong cùng cơ sở dữ liệu, lọc ACL ngay trong truy vấn | Phải tự viết lớp truy hồi; HNSW và RLS cần quét lặp; chỉ mục sau xóa cần dựng lại định kỳ |

## Quyết định

Chọn **phương án C**. Cột `embedding vector(1024)` trong bảng `knowledge_chunk` của schema `ph17_assist`; chỉ mục HNSW cosine (`m = 16`, `ef_construction = 64`, `ef_search` 60 với `hnsw.iterative_scan = relaxed_order`) và chỉ mục GIN trên `tsv` dựng từ cấu hình `vi_unaccent` (bản sao `simple` thêm `unaccent`). Truy hồi chạy vector và từ khóa song song, hợp nhất bằng RRF có trọng số (`17.rag.hybrid-weight-vector`), lọc điểm tuyệt đối theo `17.rag.min-score`. Mỗi đoạn mang `embed_model_version`, không trộn hai phiên bản trong một truy vấn. Không dùng tự cấu hình `PgVectorStore`. CI chạy `postgres:16` không có pgvector nên DDL tạo extension và kiểu cột có điều kiện, dùng `real[]` chỉ để CI; kiểm thử cô lập không phụ thuộc pgvector.

## Hệ quả

Tích cực: một nơi duy nhất cho dữ liệu, sao lưu và DR theo `pg-core`; cô lập tenant bằng cơ chế đã kiểm chứng; xóa lan truyền hai pha đạt ≤ 60 giây; không thêm thành phần ở Z5. Tiêu cực: tải truy hồi chung cụm với tải nghiệp vụ, cần theo dõi và có thể tách cụm đọc; chất lượng từ khóa tiếng Việt chỉ ở mức xấp xỉ BM25 (Q17-61); dung lượng phụ thuộc chọn `halfvec` hay `vector` (Q17-60); phân vùng theo tenant còn mở (Q17-64). Có thể đổi sang phương án A sau này vì truy cập nằm sau `RetrievalApi` và `ChunkRepository`.

## Truy vết

FR-17-018, 019, 023, 024; BR-17-016, 027, 034, 035, 086; NFR-17-001, 007, 025; SEC-49, SEC-81, THR-56; ADR-003; D03-02-PH17 §4.3, §4.5, §6.
