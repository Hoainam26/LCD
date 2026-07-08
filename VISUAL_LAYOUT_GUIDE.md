# 🎨 Giao Diện Trực Quan (Visual Layout Guide)

## 📱 Bố Cục Trang Chủ Thành Viên

```
┌─────────────────────────────────────────────────────────┐
│                    APPBAR                               │
│  [Logos Carousel] | [Search] | [Icons]                  │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ╔══════════════════════════════════════════════════╗   │
│  ║                                                  ║   │
│  ║  B A N N E R   C A R O U S E L   (200px H)      ║   │
│  ║  [Automatic slide every 4 seconds]              ║   │
│  ║                                                  ║   │
│  ╚══════════════════════════════════════════════════╝   │
│                                                           │
│      ● ○ ○ ○  [Banner Indicators]                      │
│                                                           │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  📰 Tin Tức & Thông Báo                                │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━                          │
│                                                           │
│  ┌──────────────────────────────────────┐               │
│  │ [Img] Tiêu Đề Tin 1                 │  ← Card 1    │
│  │ 120px │ Mô tả ngắn...               │               │
│  │       │ 📅 20/03/2026                │               │
│  └──────────────────────────────────────┘               │
│                                                           │
│  ┌──────────────────────────────────────┐               │
│  │ [Img] Tiêu Đề Tin 2                 │  ← Card 2    │
│  │ 120px │ Mô tả ngắn...               │               │
│  │       │ 📅 19/03/2026                │               │
│  └──────────────────────────────────────┘               │
│                                                           │
│  ┌──────────────────────────────────────┐               │
│  │ [Img] Tiêu Đề Tin 3                 │  ← Card 3    │
│  │ 120px │ Mô tả ngắn...               │               │
│  │       │ 📅 18/03/2026                │               │
│  └──────────────────────────────────────┘               │
│                                                           │
│  ┌──────────────────────────────────────┐               │
│  │ [Img] Tiêu Đề Tin 4                 │  ← Card 4    │
│  │ 120px │ Mô tả ngắn...               │               │
│  │       │ 📅 17/03/2026                │               │
│  └──────────────────────────────────────┘               │
│                                                           │
│  ┌──────────────────────────────────────┐               │
│  │ [Img] Tiêu Đề Tin 5                 │  ← Card 5    │
│  │ 120px │ Mô tả ngắn...               │               │
│  │       │ 📅 16/03/2026                │               │
│  └──────────────────────────────────────┘               │
│                                                           │
│          ... (scroll để xem tin 6-10) ...              │
│                                                           │
│  ┌──────────────────────────────────────┐               │
│  │ [Img] Tiêu Đề Tin 10                │  ← Card 10   │
│  │ 120px │ Mô tả ngắn...               │               │
│  │       │ 📅 11/03/2026                │               │
│  └──────────────────────────────────────┘               │
│                                                           │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  🔗 Tin Tức Liên Quan                                  │
│  ━━━━━━━━━━━━━━━━━━━━                                  │
│                                                           │
│  ┌──────────────────────────────────────┐               │
│  │ [Img] Tiêu Đề Liên Quan 1           │  ← Card R1   │
│  │ 120px │ Mô tả ngắn...               │               │
│  │       │ 📅 10/03/2026                │               │
│  └──────────────────────────────────────┘               │
│                                                           │
│  ┌──────────────────────────────────────┐               │
│  │ [Img] Tiêu Đề Liên Quan 2           │  ← Card R2   │
│  │ 120px │ Mô tả ngắn...               │               │
│  │       │ 📅 09/03/2026                │               │
│  └──────────────────────────────────────┘               │
│                                                           │
│  ┌──────────────────────────────────────┐               │
│  │ [Img] Tiêu Đề Liên Quan 3           │  ← Card R3   │
│  │ 120px │ Mô tả ngắn...               │               │
│  │       │ 📅 08/03/2026                │               │
│  └──────────────────────────────────────┘               │
│                                                           │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  📅 Hoạt Động Sắp Tới                                 │
│  ━━━━━━━━━━━━━━━━━  Xem tất cả »                      │
│                                                           │
│  [Event Cards...]                                        │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

---

## 🖱️ Tương Tác (Interactions)

### **1. Khi Click Vào Banner**
```
User clicks any banner
         ↓
Carousel auto-scrolls to next image
         ↓
Indicators update (dots show position)
```

### **2. Khi Click Vào Tin Tức**
```
User Clicks News Card (anywhere on the card)
         ↓
App navigates to NewsDetailScreen
         ↓
ShowFull Article:
  - Large image
  - Full title
  - Complete content
  - Related articles
  - Comments
```

### **3. Hover Effect (Trên Web)**
```
Mouse Hover Over News Card
         ↓
Cursor Changes to ↖ (click hand)
Shadow Increases (card appears elevated)
Background Slightly Lightens
```

---

## 📏 Kích Thước Chi Tiết (Dimensions)

### **Screen Layout**
```
Total Width: 100% (responsive)
Padding: 20px (left & right)
Content Width: 100% - 40px

Mobile:   Full width with 20px padding
Tablet:   Central column with max-width
Desktop:  Central column with max-width
```

### **Banner Section**
```
Height: 200px
Border Radius: 16px
Shadow: 10px blur, 15% opacity
Gap from top: 16px
Gap to indicators: 8px
```

### **Indicator Dots**
```
Size: 8x8px
Gap between: 4px horizontal
Active color: #1E3A8A (bright blue)
Inactive color: #D1D5DB (light gray)
```

### **News Card**
```
Total Height: 120px
Image Width: 120px (left side)
Card Border Radius: 12px
Card Shadow: 10px blur, 8% opacity

Content Padding: 12px all sides
Title Font Size: 14px (bold)
Description Font Size: 12px
Date Font Size: 11px

Gap between components: 8px vertical
```

---

## 🎨 Color Scheme

| Component | Color | Hex Code | Usage |
|-----------|-------|----------|-------|
| Primary | Blue | #1E3A8A | Active indicators, section headers |
| Text Primary | Dark Gray | #1F2937 | Card titles |
| Text Secondary | Mid Gray | #6B7280 | Card descriptions |
| Text Tertiary | Light Gray | #9CA3AF | Dates, secondary info |
| Background | White | #FFFFFF | Card background |
| Placeholder | Light Gray | #F3F4F6 | Image placeholders |
| Shadow | Black | #000000 | Drop shadows (8-15% opacity) |
| Border | Light Gray | #E5E7EB | Card borders (if any) |

---

## 🔄 Data Flow

```
┌─────────────────────────────────────────┐
│     AppStateService (Provider)          │
│  stores: news, events, currentUser      │
└────────┬────────────────────────────────┘
         │
         ↓
┌─────────────────────────────────────────┐
│  MemberHomeScreenState                  │
│  - _bannerImages (list)                 │
│  - _currentBannerIndex (int)            │
│  - _currentTab (int)                    │
└────────┬────────────────────────────────┘
         │
         ↓
┌─────────────────────────────────────────┐
│     UI Widgets                          │
│  - Banner Carousel                      │
│  - Banner Indicators                    │
│  - News Feed (vertical list)            │
│  - Related News (vertical list)         │
│  - Events Section                       │
└─────────────────────────────────────────┘
         │
         ↓ (User Clicks)
         │
┌─────────────────────────────────────────┐
│  NewsDetailScreen                       │
│  (Shows full article)                   │
└─────────────────────────────────────────┘
```

---

## 📊 Typography

### **Font Family**
- Main: `Manrope` (Google Fonts)
- Fallback: System default sans-serif
- Special: `Times New Roman` (for vintage feel on some elements)

### **Font Sizes**
| Element | Size | Weight | Color |
|---------|------|--------|-------|
| Banner Title | 16px | Bold | #FFFFFF |
| Section Header | 18px | Bold | #1F2937 |
| Card Title | 14px | w600 | #1F2937 |
| Card Description | 12px | w400 | #6B7280 |
| Card Date | 11px | w400 | #9CA3AF |
| Icon | 12-14px | - | #9CA3AF |

---

## 🔧 Responsive Breakpoints

### **Mobile (< 640px)**
- Full width layout
- 20px padding
- Single column
- Larger touch targets (120px cards)

### **Tablet (640px - 1024px)**
- Central column
- Max-width: 600px
- Optimized padding
- Same card sizes

### **Desktop (> 1024px)**
- Central column
- Max-width: 700px
- Comfortable padding
- Enhanced shadows

---

## ♿ Accessibility

✅ **Keyboard Navigation**
- Tab through links
- Enter to activate buttons
- Space to interact

✅ **Screen Reader Support**
- Image alt text
- Semantic HTML structure
- ARIA labels where needed

✅ **Color Contrast**
- Text meets WCAG AA standards
- Sufficient contrast ratios

✅ **Touch Targets**
- Minimum 44x44px for touch
- Cards are 120px (large enough)

---

## 🎬 Animations

### **Banner Carousel**
- **Type**: Automatic slide transition
- **Duration**: Every 4 seconds
- **Effect**: Smooth fade/slide
- **Manual**: Click indicators to jump

### **News Cards**
- **Type**: On-press animation
- **Duration**: 300ms
- **Effect**: Subtle scale + shadow
- **Result**: Provides tactile feedback

### **Page Transitions**
- **Type**: Material slide transition
- **Duration**: 300ms
- **Direction**: Bottom to top (default)

---

## 📋 Component Hierarchy

```
MemberHomeScreen (StatefulWidget)
├── AppBar
│   └── Logo Carousel
├── Body (TabView)
│   ├── HomeTab
│   │   ├── Banner Carousel
│   │   ├── Banner Indicators
│   │   ├── News Feed Section
│   │   │   └── News Cards (vertical list)
│   │   ├── Related News Section
│   │   │   └── Related News Cards
│   │   └── Upcoming Events Section
│   ├── EventsTab
│   ├── SearchTab
│   ├── OfficersTab
│   └── ProfileTab
└── Bottom Navigation
```

---

## ✨ Loading States

```
Initial Load:
  ↓
Loading Banner (show cached previous)
  ↓
Loading News Feed (show spinner)
  ↓
Loading Related News
  ↓
Loading Events
  ↓
Display Complete UI
```

---

**Chúc bạn có một giao diện tuyệt vời!** 🎉
