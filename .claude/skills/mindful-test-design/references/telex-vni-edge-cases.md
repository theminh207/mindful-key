# Ma trận ca biên Telex/VNI

> Lấy tinh thần **Field-Level Validation** của Anh Tester testing-kit (mỗi loại nhập có checklist
> ca biên riêng, cấm xài chung 1 bộ) và dịch sang bàn phím tiếng Việt. "Field" của mình không
> phải ô form web mà là **loại luật gõ**.
>
> ⚠️ **Verify đừng đoán:** cột "Mong đợi" dưới đây bám luật chính tả tiếng Việt + cấu hình harness
> hiện tại (Telex, Unicode, `vUseModernOrthography=1`, `vCheckSpelling=1`, `vRestoreIfWrongSpelling=1`,
> `vQuickTelex=0`). Trước khi khóa 1 ca thành regression trong `tests/core/test_engine.cpp`, **CHẠY
> `make test` xác nhận output engine thật** — hành vi undo/restore/đặt-dấu là của engine, không phải
> suy đoán. Ca nào chưa chạy đánh dấu 🔬 (cần verify).

## Đã verify (5 ca gốc trong test_engine.cpp — coi là mỏ neo)
| Input Telex | Mong đợi | Trạng thái |
|---|---|---|
| `xin chaof cacs banj` | `xin chào các bạn` | ✅ trong `main()` |
| `tieengs vieetj` | `tiếng việt` | ✅ |
| `tooi ddang vui` | `tôi đang vui` | ✅ |
| *(2 ca còn lại)* | *(đọc `test_engine.cpp` — đừng chép lại từ trí nhớ)* | ✅ |

> Mọi ca thêm mới KHÔNG được mâu thuẫn cơ chế `runCase`/`decodeChar` của harness này.

## Đã verify thêm — lô dogfood 2026-07-11 (8 ca, đã khóa regression)
`nawm→năm` (aw) · `hown→hơn` (ow) · `tuw→tư` (uw) · `as→á` · `af→à` · `dddi→ddi` (undo đ) ·
`ass→as` (undo thanh) · `hello→hello` (xen Anh, SmartSwitch OFF). Tất cả PASS bằng `make test-core`.
> ⚙️ Cùng lô này đã vá lỗ hổng harness: `test_engine.cpp` giờ đếm ca sai + trả **exit code ≠ 0**,
> nên `make test`/CI **thật sự đỏ được** khi có regression (trước đó luôn thoát 0 = xanh giả).

---

## Loại 1 — Nguyên âm & phụ âm biến hình
| Ca | Input | Mong đợi | Ghi chú |
|---|---|---|---|
| aa→â | `caau` | `câu` | nền tảng |
| ee→ê | `eem` | `êm` | |
| oo→ô | `coon` | `côn` | |
| aw→ă | `nawm` | `năm` | ✅ đã khóa (2026-07-11) |
| ow→ơ | `hown` | `hơn` | ✅ đã khóa (2026-07-11) |
| uw→ư | `tuw` | `tư` | ✅ đã khóa (2026-07-11) |
| `w` đơn = ư? | `w` | `ư` 🔬 | chưa chạy — verify riêng |
| dd→đ | `ddi` | `đi` | |
| Biến hình 2 lần liền | `dddi` | `ddi` | ✅ verify 2026-07-11: gõ đ lần 3 = trả chữ gốc. Đã khóa regression |

## Loại 2 — Dấu thanh (s/f/r/x/j) + vị trí đặt dấu
| Ca | Input | Mong đợi | Ghi chú |
|---|---|---|---|
| sắc/huyền/hỏi/ngã/nặng | `as af ar ax aj` | `á à ả ã ạ` | ✅ `as`→á, `af`→à đã khóa (2026-07-11); ar/ax/aj chưa chạy |
| Đặt dấu trên nguyên âm chính | `hoas` | `hoá` 🔬 | vị trí dấu — verify theo orthography |
| Nguyên đôi/ba — dấu đúng chỗ | `khuyaas`→`khuyảس`? | 🔬 | ca khó nhất, **phải chạy** |
| Dấu gõ sau cả âm | `vieetj` | `việt` | như ca gốc |

## Loại 3 — Xóa dấu / undo
| Ca | Input | Mong đợi | Ghi chú |
|---|---|---|---|
| `z` xóa dấu | `asz` | `a` 🔬 | verify z-behavior |
| Gõ thanh 2 lần = bỏ + trả chữ | `ass` | `as` | ✅ verify 2026-07-11: bỏ dấu + trả lại `s`. Đã khóa regression |
| Đổi thanh | `asf` | `à` 🔬 | thanh sau ghi đè thanh trước? verify |

## Loại 4 — Chính tả hiện đại vs cũ (`vUseModernOrthography`)
| Ca | Input | Mong đợi | Ghi chú |
|---|---|---|---|
| hoà (hiện đại) | `hoaf` | `hoà` 🔬 | config hiện tại =1 → kiểu mới |
| Nếu đổi cờ =0 | `hoaf` | `hòa` 🔬 | test cả 2 nhánh cờ |

## Loại 5 — Chuỗi không hợp lệ (`vRestoreIfWrongSpelling`)
| Ca | Input | Mong đợi | Ghi chú |
|---|---|---|---|
| Phụ âm cuối sai | `banr`→? | 🔬 | tiếng Việt không có → restore nguyên chuỗi? |
| Cụm phụ âm lạ | `zzz` | `zzz` 🔬 | không bỏ dấu bừa |

## Loại 6 — Backspace / sửa giữa từ ⭐ (dễ vỡ nhất)
| Ca | Kịch bản | Mong đợi | Ghi chú |
|---|---|---|---|
| Backspace giữa âm tiết | gõ `vieetj` rồi ⌫ 1 lần | `việ`? 🔬 | engine tính lại `backspaceCount` — **ca rủi ro cao** |
| Sửa dấu sau khi lỡ | `vietj` → thêm `e` | `việt`? 🔬 | chèn giữa buffer |
| ⌫ về rỗng rồi gõ lại | | không crash, `startNewSession` đúng | |

## Loại 7 — Ranh giới từ (word boundary → `startNewSession`)
| Ca | Input | Mong đợi | Ghi chú |
|---|---|---|---|
| Dấu cách kết từ | `chaof ban` | `chào ban` | space chốt từ trước |
| Dấu câu kết từ | `vui.` | `vui.` | `.`/`,` cũng chốt |
| Số chen giữa | `a1` | `a1` 🔬 | số phá session? |

## Loại 8 — Xen tiếng Anh (SmartSwitchKey — **OFF** trong harness hiện tại)
| Ca | Input | Mong đợi | Ghi chú |
|---|---|---|---|
| Từ Anh không bị bỏ dấu bừa | `hello` | `hello` 🔬 | với `vUseSmartSwitchKey=0` — verify không thành `hello`+dấu |
| Anh-Việt lẫn | `ok chuaw` | `ok chưa` 🔬 | |

## Loại 9 — Hoa/thường
| Ca | Input | Mong đợi | Ghi chú |
|---|---|---|---|
| Shift đầu câu | `Chaof` | `Chào` 🔬 | giữ hoa qua biến hình |
| CAPS | `VIEETJ` | `VIỆT` 🔬 | dấu trên chữ hoa |

## Loại 10 — Riêng tư / bảo mật (bất biến — test cả điều KHÔNG được xảy ra)
| Ca | Kịch bản | Bất biến phải giữ |
|---|---|---|
| Ô mật khẩu | con trỏ ở secure field | KHÔNG đọc/log/hiện sóng (kể cả R2 mood bật) |
| Không rò mạng | gõ câu bất kỳ | 0 network call mang nội dung gõ |
| App Group sạch | extension ghi heartbeat | assert chỉ timestamp/bool, KHÔNG nội dung gõ |

## Loại 11 — VNI (nếu mở `vInputType=1`)
| Ca | Input | Mong đợi | Ghi chú |
|---|---|---|---|
| Số làm dấu | `a1` (sắc) `a2`(huyền)... | `á` `à` 🔬 | VNI khác Telex — số = dấu, **test riêng nhánh cờ** |

## Loại 12 — Stress / chuỗi rác
| Ca | Input | Mong đợi | Ghi chú |
|---|---|---|---|
| Chuỗi rất dài | 500 ký tự Telex hợp lệ | không tràn `charData[MAX_BUFF]`, không crash | |
| Spam modifier | `aaaaaa` | không treo, kết quả ổn định 🔬 | |
| Rỗng | gõ rồi xóa hết | `startNewSession` sạch, không lỗi | |

---

## Cách dùng ma trận này
1. Chọn loại đang đụng (vd Mốc B nối engine → ưu tiên Loại 1,2,6,7).
2. Với mỗi ca 🔬: thêm `runCase("input", "mong đợi")` vào `test_engine.cpp`, **chạy `make test`**, đọc output THẬT, sửa "mong đợi" cho khớp engine (rồi khóa lại làm regression).
3. Ca thuộc Loại 10 (bất biến riêng tư) → viết ở tầng vỏ/mood khi Round 2, không phải engine.
4. Ghi ca đã chứng minh vào `docs/TEST_MATRIX.md` (cột Engine/E2E).

> Ma trận là *bản đồ ca cần nghĩ tới*, KHÔNG phải danh sách kỳ vọng đã chốt. Engine nói sự thật —
> `make test` là trọng tài, không phải bảng này.
