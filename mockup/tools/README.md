# Tool `limit-watch`

Theo dõi hết hạn / rate-limit và đánh thức agent tiếp tục mockup.

```bash
./limit-watch.sh once                 # trạng thái JSON
./limit-watch.sh mark <epoch> "note"  # ghi thời điểm được làm lại (khi agent bị chặn)
./limit-watch.sh clear                # xóa trạng thái chặn
./limit-watch.sh watch 90             # vòng lặp; khi hết hạn → AGENT_LOOP_WAKE_mockup_limit
```

Khi Cursor báo rate limit còn X phút:  
`./limit-watch.sh mark $(($(date +%s)+X*60)) "cursor_rate_limit"`

Agent đang chạy `watch` sẽ tự in sentinel và quay lại làm việc (prompt mặc định: tiếp tục gói 6–11).
