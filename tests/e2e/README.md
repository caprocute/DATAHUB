# E2E thin-slice (W1 / WP-16)

## Tiên quyết

```bash
make up-dev                 # + wiremock + apisix
# terminal riêng:
make run-control
make run-adapter            # apps/adapter-mgr :8082
make run-camel              # camel/dancu :8088
```

## Chạy

```bash
chmod +x tests/e2e/thin-slice.sh
./tests/e2e/thin-slice.sh
```

Kỳ vọng: HTTP 200 từ `/demo/tra-cuu`, body có `nguon=wiremock-httt-gia`, header `X-Trace-Id`.

Bằng chứng tạm: `/tmp/lgsp-e2e-headers.txt`, `/tmp/lgsp-e2e-body.json`.
