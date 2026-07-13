//
//  MoodLakeViewController.h
//  mindful-key — iOS container app (màn "Mặt hồ" — soi lại cuối ngày, Round 3 story 3.3)
//
//  2 trạng thái NỘI BỘ đổi tại chỗ (không push VC mới), mirror state machine "matho" của bản thiết
//  kế (Mindful Key Prototype.dc.html, tabMatho):
//    - "Soi lại" (mặc định) — câu hỏi phản chiếu là trọng tâm thị giác; số liệu Q4
//      (MoodJournalStore_FetchTodaySummary) chỉ là bối cảnh PHỤ, nhỏ, đặt DƯỚI câu hỏi.
//    - "Thang mặt hồ tâm" — 5 mức An/Nhẹ/Gợn/Sóng/Cuộn, biên độ sóng tăng dần, KHÔNG phải điểm số.
//
//  Xem MoodLakeViewController.m cho chi tiết dựng UI. Đối chiếu hiến chương (docs/AGENT-BRIEF.md):
//  không đèn đỏ/xanh cảm xúc, không emoji chấm điểm, không gamification, "mô tả không phán xét".
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MoodLakeViewController : UIViewController

@end

NS_ASSUME_NONNULL_END
