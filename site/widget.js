/* =============================================================
   GNH Feedback Widget — bong bóng nổi góc phải
   Cài đặt: dán 1 dòng vào landing page (trước </body>):
       <script src="https://key.bketech.xyz/widget.js"></script>
   ============================================================= */
(function () {
  if (window.__gnhWidgetLoaded) return;         // tránh nạp 2 lần
  window.__gnhWidgetLoaded = true;

  // Tìm thư mục chứa widget.js để nạp chat.html cùng chỗ (chạy được cả local lẫn trên domain)
  var me   = document.currentScript || (function () { var s = document.getElementsByTagName('script'); return s[s.length - 1]; })();
  var BASE = new URL('.', me.src).href;
  var CHAT_URL = BASE + 'chat.html';

  var LOGO = '<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg" style="width:60%;height:60%">'
    + '<defs>'
    + '<circle id="w-lobe" cx="100" cy="56" r="44" fill="#fff"/>'
    + '<path id="w-c" d="M100 100 C120 62 120 40 100 22 C80 40 80 62 100 100 Z" fill="#A8DCE0"/>'
    + '<path id="w-y" d="M100 100 C113 66 113 48 100 32 C87 48 87 66 100 100 Z" fill="#F5B720"/>'
    + '</defs>'
    + '<g stroke="#1C8C86" stroke-width="2" stroke-linejoin="round">'
    + '<use href="#w-lobe" transform="rotate(0 100 100)"/><use href="#w-lobe" transform="rotate(45 100 100)"/>'
    + '<use href="#w-lobe" transform="rotate(90 100 100)"/><use href="#w-lobe" transform="rotate(135 100 100)"/>'
    + '<use href="#w-lobe" transform="rotate(180 100 100)"/><use href="#w-lobe" transform="rotate(225 100 100)"/>'
    + '<use href="#w-lobe" transform="rotate(270 100 100)"/><use href="#w-lobe" transform="rotate(315 100 100)"/></g>'
    + '<g stroke="#fff" stroke-width="1.6" stroke-linejoin="round">'
    + '<use href="#w-c" transform="rotate(22.5 100 100)"/><use href="#w-c" transform="rotate(67.5 100 100)"/>'
    + '<use href="#w-c" transform="rotate(112.5 100 100)"/><use href="#w-c" transform="rotate(157.5 100 100)"/>'
    + '<use href="#w-c" transform="rotate(202.5 100 100)"/><use href="#w-c" transform="rotate(247.5 100 100)"/>'
    + '<use href="#w-c" transform="rotate(292.5 100 100)"/><use href="#w-c" transform="rotate(337.5 100 100)"/></g>'
    + '<g stroke="#fff" stroke-width="1.6" stroke-linejoin="round">'
    + '<use href="#w-y" transform="rotate(0 100 100)"/><use href="#w-y" transform="rotate(45 100 100)"/>'
    + '<use href="#w-y" transform="rotate(90 100 100)"/><use href="#w-y" transform="rotate(135 100 100)"/>'
    + '<use href="#w-y" transform="rotate(180 100 100)"/><use href="#w-y" transform="rotate(225 100 100)"/>'
    + '<use href="#w-y" transform="rotate(270 100 100)"/><use href="#w-y" transform="rotate(315 100 100)"/></g>'
    + '<circle cx="100" cy="100" r="6" fill="#1C8C86"/></svg>';

  var css = ''
    + '#gnh-launcher{position:fixed;bottom:22px;right:22px;width:60px;height:60px;border-radius:50%;'
    +   'background:linear-gradient(135deg,#1C8C86,#136f6a);border:none;cursor:pointer;z-index:2147483000;'
    +   'box-shadow:0 8px 26px rgba(19,111,106,.42);display:grid;place-items:center;transition:transform .18s,box-shadow .18s;}'
    + '#gnh-launcher:hover{transform:scale(1.06);box-shadow:0 12px 32px rgba(19,111,106,.5);}'
    + '#gnh-launcher .ic{width:34px;height:34px;display:grid;place-items:center;transition:opacity .15s,transform .2s;}'
    + '#gnh-launcher .ic-close{position:absolute;color:#fff;font-size:26px;line-height:1;opacity:0;transform:rotate(-90deg);}'
    + '#gnh-launcher.open .ic-logo{opacity:0;transform:rotate(90deg);}'
    + '#gnh-launcher.open .ic-close{opacity:1;transform:rotate(0);}'
    + '#gnh-invite{position:fixed;bottom:64px;right:88px;background:#fff;color:#1e2a24;font:600 13px/1.35 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Arial,sans-serif;'
    +   'padding:9px 13px;border-radius:14px 14px 4px 14px;box-shadow:0 8px 24px rgba(0,0,0,.14);z-index:2147482999;max-width:210px;'
    +   'opacity:0;transform:translateY(8px);transition:opacity .25s,transform .25s;pointer-events:none;}'
    + '#gnh-invite.show{opacity:1;transform:translateY(0);}'
    + '#gnh-frame{position:fixed;bottom:94px;right:22px;width:380px;height:600px;max-height:calc(100vh - 120px);'
    +   'border:none;border-radius:18px;overflow:hidden;background:#fff;z-index:2147483000;'
    +   'box-shadow:0 18px 60px rgba(20,60,45,.28);opacity:0;transform:translateY(16px) scale(.98);pointer-events:none;'
    +   'transition:opacity .22s,transform .22s;}'
    + '#gnh-frame.open{opacity:1;transform:translateY(0) scale(1);pointer-events:auto;}'
    + '@media (max-width:480px){'
    +   '#gnh-frame{width:calc(100vw - 24px);height:calc(100vh - 100px);right:12px;bottom:84px;}'
    +   '#gnh-launcher{bottom:16px;right:16px;}#gnh-invite{display:none;}}';

  function el(html) { var d = document.createElement('div'); d.innerHTML = html; return d.firstChild; }

  function init() {
    var style = document.createElement('style'); style.textContent = css; document.head.appendChild(style);

    var launcher = el('<button id="gnh-launcher" aria-label="Gửi phản hồi">'
      + '<span class="ic ic-logo">' + LOGO + '</span><span class="ic ic-close">✕</span></button>');
    var invite = el('<div id="gnh-invite">Bạn có góp ý cho GNH? Nhấn vào đây 🌿</div>');
    var frame = el('<iframe id="gnh-frame" title="Bot ghi nhận phản hồi GNH"></iframe>');
    document.body.appendChild(frame);
    document.body.appendChild(invite);
    document.body.appendChild(launcher);

    var loaded = false, open = false;
    function setOpen(v) {
      open = v;
      launcher.classList.toggle('open', v);
      frame.classList.toggle('open', v);
      if (v) { invite.classList.remove('show'); if (!loaded) { frame.src = CHAT_URL; loaded = true; } }
    }
    launcher.addEventListener('click', function () { setOpen(!open); });

    // Chat trong iframe bấm nút ✕ → gửi message xuống đây để đóng
    window.addEventListener('message', function (e) {
      if (e.data && e.data.gnh === 'close') setOpen(false);
    });

    // Nhắc nhẹ 1 lần sau 3.5s (chỉ khi chưa mở)
    setTimeout(function () { if (!open) invite.classList.add('show'); }, 3500);
    setTimeout(function () { invite.classList.remove('show'); }, 11000);
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init);
  else init();
})();
