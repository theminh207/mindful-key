const fs = require('fs');
const buckets = JSON.parse(fs.readFileSync('.ua/tmp/ua-arch-buckets.json', 'utf8'));

const layers = [
  {
    id: 'layer:core-engine',
    name: 'Core Engine — Bộ não gõ phím',
    description:
      'Engine C++ thuần dùng chung mọi hệ điều hành (fork OpenKey của Mai Vũ Tuyên): state machine xử lý phím qua cửa vào duy nhất vKeyHandleEvent, ghép vần/bỏ dấu Telex-VNI, macro gõ tắt, chuyển bảng mã và các shim phím riêng OS trong platforms/ con — tuyệt đối không import header đặc thù OS nào.',
    nodeIds: buckets['core-engine'],
  },
  {
    id: 'layer:core-mood',
    name: 'Core Mood — Lớp cảm xúc/chánh niệm dùng chung',
    description:
      'Lớp nhận diện và diễn giải cảm xúc lúc gõ, thuần C++ và trung lập nền tảng: gom từ thành câu (MoodBuffer), chấm send-risk theo lexicon (SendRiskAnalyzer), quy đổi risk thành biên độ sóng (EmotionWaveAmplitude), hợp đồng nhịp thở gác cổng gửi tin (BreathingPause) và diễn giải câu quan sát ngày (MoodPhrasing) — mọi vỏ OS tiêu thụ chung một hợp đồng để lexicon không trôi lệch.',
    nodeIds: buckets['core-mood'],
  },
  {
    id: 'layer:macos-shell',
    name: 'Vỏ macOS (Apple)',
    description:
      'Vỏ native macOS — công dân hạng nhất của dự án: cầu nối Objective-C/++ vào engine dùng chung (OpenKey.mm, OpenKeyManager), toàn bộ UI AppKit cho popup 3-tab, cửa sổ cài đặt, gác cổng gửi tin, chuông, soi lại cuối ngày, cùng resource bundle của target macOS (Assets.xcassets màu brand, storyboard, entitlements, Info.plist) theo đúng khai báo sources trong project.yml.',
    nodeIds: buckets['macos-shell'],
  },
  {
    id: 'layer:ios-shell',
    name: 'Vỏ iOS (Apple — Keyboard Extension)',
    description:
      'Vỏ native iOS với mandate cố ý hẹp (nhật ký + nhắc thụ động, không gác cổng gửi tin do sandbox chặn): app container (App/) xin Full Access và onboarding, Custom Keyboard Extension (KeyboardExtension/) gõ chữ thật, cùng lớp cầu nối dùng chung riêng cho hai target iOS này (shared/ — App Group, bridge macro/bell/theme) mà project.yml xác nhận KHÔNG được target macOS dùng tới.',
    nodeIds: buckets['ios-shell'],
  },
  {
    id: 'layer:windows-shell',
    name: 'Vỏ Windows',
    description:
      'Vỏ native Win32 C++ — low-level keyboard/mouse hook cầu nối vào engine dùng chung, hệ thống dialog kế thừa BaseDialog, khay hệ thống, và bản port đầy đủ của lớp cảm xúc (MoodWatch, MoodStore mã hoá DPAPI, SendGatekeeper, NudgeCoordinator, ReflectionScreen), cộng bộ cập nhật độc lập OpenKeyUpdate và trình cài đặt Inno Setup.',
    nodeIds: buckets['windows-shell'],
  },
  {
    id: 'layer:emerging-shells',
    name: 'Vỏ nền tảng mới nổi (Linux & Android)',
    description:
      'Các vỏ chưa triển khai — hiện chỉ có README giữ chỗ cho Linux (kể cả thư mục linux-upstream vendor) và Android, cộng README tổng quan của thư mục platforms/; chờ việc thật khi dự án mở rộng thêm hệ điều hành.',
    nodeIds: buckets['emerging-shells'],
  },
  {
    id: 'layer:test',
    name: 'Test — Bằng chứng hành vi',
    description:
      'Bộ test tự viết (không dùng framework) mirror đúng cấu trúc core/platform: harness regression engine, phrasing và send-risk cho core (tests/core, do đội core sở hữu), test cầu nối Objective-C++ cho keyboard extension và các bridge iOS (tests/ios), và test pipeline cảm xúc macOS (tests/macos) — là lưới an toàn duy nhất trước khi coi một hành vi là đã được chứng minh chạy thật.',
    nodeIds: buckets['test'],
  },
  {
    id: 'layer:documentation',
    name: 'Tài liệu dự án (docs/)',
    description:
      'Toàn bộ tài liệu quản trị và kỹ thuật trong docs/: hiến chương AGENT-BRIEF, PRD, các hợp đồng thiết kế (Breathing Pause, Lifecycle Safety), sổ bằng chứng TEST_MATRIX và sổ friction-log, hướng dẫn cài đặt/phát hành từng nền tảng, và trang hướng dẫn sử dụng HTML cho người dùng cuối.',
    nodeIds: buckets['documentation'],
  },
  {
    id: 'layer:project-meta',
    name: 'Cấu hình & tài liệu gốc dự án',
    description:
      'Các file mấu chốt ở gốc repo điều phối toàn bộ dự án: Makefile (đầu vào build/test duy nhất), version.env (nguồn phiên bản duy nhất), appcast.xml (feed tự cập nhật Sparkle), project.yml (cấu hình XcodeGen cho cả hai target Apple), cùng bộ tài liệu giới thiệu/đóng góp/đổi mới ở gốc (README, CLAUDE.md, CONTRIBUTING.md, CHANGELOG.md).',
    nodeIds: buckets['project-meta'],
  },
];

// Sanity check
let total = 0;
const seen = new Set();
for (const l of layers) {
  if (!l.nodeIds || l.nodeIds.length === 0) throw new Error('Empty layer: ' + l.id);
  for (const id of l.nodeIds) {
    if (seen.has(id)) throw new Error('Duplicate id: ' + id);
    seen.add(id);
  }
  total += l.nodeIds.length;
}
console.log('layers:', layers.length, 'total nodeIds:', total);

fs.writeFileSync('.ua/intermediate/layers.json', JSON.stringify(layers, null, 2));
console.log('wrote .ua/intermediate/layers.json');
