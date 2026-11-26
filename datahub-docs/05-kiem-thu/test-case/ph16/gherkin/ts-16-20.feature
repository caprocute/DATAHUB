# language: vi
# Sinh tự động từ D05-02-PH16 bằng ph16/tools/gen_gherkin.py; không sửa tay.
@PH-16 @TS-16-20
Tính năng: TS-16-20 · Bảng điều khiển, chi tiết chỉ tiêu và so sánh hai kỳ

  @TC-16-076 @P1 @Dương
  Kịch bản: TC-16-076 Bảng điều khiển năm nhóm, lọc và so sánh hai kỳ
    # Truy vết: FR-16-038, FR-16-040 · API-16-090, 091 · UI-16-01, UI-16-02 · BR-16-002, BR-16-016, BR-16-007 · NFR-16-005
    Biết T90 sau F-KY-1 (`M-2026-10` chưa chốt, `M-2026-09` đã chốt); U-T90-VW.
    Khi `GET /dashboard`
    Và `GET /dashboard?periodCode=M-2026-10&view=LATEST`
    Và `GET /dashboard?periodCode=M-2026-09&view=OFFICIAL`
    Và mở `/giam-sat/chi-tieu`
    Và `GET /dashboard?periodCode=M-2026-10&groupCode=KET_NOI&status=AT_RISK`
    Và `GET /dashboard?periodCode=M-2026-10&compareTo=M-2026-09`
    Thì bước 1 mặc định kỳ tháng gần nhất đã tính. Bước 2 `overallScore = 66,5`, năm `groups[]` đúng bảng 2.4, `statusCounts` 12/5/3/4, `attention[]` gồm chỉ tiêu `OFF_TRACK` rồi `AT_RISK` sắp theo trọng số, `flags` có `MISSING_SOURCE`, `provisional = true`. Bước 3 chỉ kỳ đã chốt, `provisional = false`. Bước 4 hiện điểm tổng, năm vòng nhóm, xu hướng 13 kỳ; chỉ tiêu `NO_DATA` có nhãn "Chưa có số liệu". Tải ≤ 2 giây p95. Bước 5 chỉ chỉ tiêu `KET_NOI` ở `AT_RISK`. Bước 6 `comparison[]` có `valueA`, `valueB`, `delta`, `deltaPct`, `statusA`, `statusB`, `definitionChanged = true` cho chỉ tiêu đổi định nghĩa giữa hai kỳ.

  @TC-16-077 @P1 @Âm
  Kịch bản: TC-16-077 Bảng điều khiển: kỳ sai, chưa có kỳ, tenant trống
    # Truy vết: FR-16-038, FR-16-039 · API-16-090, 091 · ERR-16-057, ERR-16-001
    Biết T93 chưa có kỳ nào; T90.
    Khi Ở T90 `GET /dashboard?periodCode=2026-10`
    Và Ở T90 `GET /dashboard?periodCode=M-2031-01`
    Và Ở T93 `GET /dashboard`
    Và Ở T90 `GET /indicators/khong-co/series`
    Thì bước 1 `400` ERR-16-057. Bước 2 `404` ERR-16-001. Bước 3 `404` ERR-16-001 hoặc `200` thân trống kèm trạng thái "Chưa có kỳ nào được tính" (không bịa số). Bước 4 `404` ERR-16-001.

  @TC-16-078 @P1 @Dương
  Kịch bản: TC-16-078 Chi tiết chỉ tiêu: chuỗi thời gian, đường mục tiêu, truy tới quan sát
    # Truy vết: FR-16-039 · API-16-091, 054, 043 · UI-16-02 · BR-16-001
    Biết T90, F-LICHSU (36 kỳ); `httt-ket-noi-ty-le` có định nghĩa ACTIVE; U-T90-TO1.
    Khi `GET /indicators/httt-ket-noi-ty-le/series?periodType=MONTH&from=M-2026-01&to=M-2026-10&lineage=true`
    Và từ một điểm chọn `GET /values/{valueId}/lineage`
    Và từ `inputs[0].observationId` `GET /observations?metricCode=ph01.httt.connected&periodCode=M-2026-10`
    Thì bước 1 `series[]` 10 điểm có `value`, `status`, `completeness`, `version`; `targetLine` = 95; `definition` có công thức và ngưỡng. Bước 2 `inputs[]` có `variable`, `metricCode`, `observationId`, `value`. Bước 3 trả quan sát gốc với `sourceRef`, `idempotencyRef`. Truy nguồn đi trọn từ số tới quan sát.
