//
// TrayPopover.h — [MINDFUL] Cửa sổ Popover bật từ khay hệ thống (mặt tiền của app).
// Đối ứng của PanelViewController.mm bên macOS.
//
#pragma once
#include <windows.h>

// Khởi tạo/Đăng ký class cửa sổ
void TrayPopover_Init(HINSTANCE hInstance);

// Dọn dẹp
void TrayPopover_Uninit();

// Hiện Popover ở vị trí khay hệ thống (nếu đang ẩn) hoặc ẩn đi (nếu đang hiện)
void TrayPopover_Toggle();

// Cập nhật lại dữ liệu (như biểu đồ, trạng thái gác cổng) nếu đang hiện
void TrayPopover_Refresh();
