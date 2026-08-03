/* ============================================================
   LGSP Mockup — Chế độ sáng / tối

   Nạp ĐỒNG BỘ trong <head>, trước khi trang vẽ, để tránh nhấp nháy
   nền sáng một khoảnh khắc rồi mới đổi sang nền tối.

   Thứ tự ưu tiên: lựa chọn đã lưu của người dùng → thiết lập hệ điều hành.
   ============================================================ */

(function () {
  var KEY = 'lgsp-theme';
  var mql = window.matchMedia ? window.matchMedia('(prefers-color-scheme: dark)') : null;

  function saved() {
    try { return localStorage.getItem(KEY); } catch (e) { return null; }
  }

  function apply(theme) {
    document.documentElement.setAttribute('data-theme', theme);
  }

  apply(saved() || (mql && mql.matches ? 'dark' : 'light'));

  /* Người dùng chưa chọn thủ công thì bám theo hệ điều hành */
  if (mql && mql.addEventListener) {
    mql.addEventListener('change', function (e) {
      if (!saved()) apply(e.matches ? 'dark' : 'light');
    });
  }

  window.LGSP_THEME = {
    get: function () {
      return document.documentElement.getAttribute('data-theme') || 'light';
    },
    set: function (theme) {
      apply(theme);
      try { localStorage.setItem(KEY, theme); } catch (e) { /* chế độ riêng tư */ }
    },
    toggle: function () {
      this.set(this.get() === 'dark' ? 'light' : 'dark');
    },
  };
})();
