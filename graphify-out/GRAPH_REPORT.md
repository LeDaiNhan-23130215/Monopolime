# Graph Report - Monopolime-merge_with_main  (2026-06-02)

## Corpus Check
- 5 files · ~536,549 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 62 nodes · 57 edges · 8 communities
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `717f4784`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 3|Community 3]]
- [[_COMMUNITY_Community 4|Community 4]]
- [[_COMMUNITY_Community 5|Community 5]]
- [[_COMMUNITY_Community 6|Community 6]]

## God Nodes (most connected - your core abstractions)
1. `TÀI LIỆU ĐẶC TẢ YÊU CẦU NGHIỆP VỤ (BRS)` - 11 edges
2. `3. Yêu cầu nghiệp vụ chi tiết (Business Rules)` - 11 edges
3. `USER REQUIREMENT SPECIFICATION (URS) - MONOPOLIME (CỜ TỶ PHÚ)` - 7 edges
4. `Đặc tả Use Case: Lưu và Tải ván chơi (UC-03)` - 6 edges
5. `Đặc tả Use Case: Quản lý tài chính (UC-06)` - 6 edges
6. `4. Save / Load Game` - 4 edges
7. `6. Yêu cầu phi chức năng` - 4 edges
8. `2. Yêu cầu Chức năng (Functional Requirements)` - 4 edges
9. `1. Giới thiệu` - 3 edges
10. `3. Luồng thay thế (Alternative Flows)` - 3 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Communities (8 total, 0 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.18
Nodes (10): 1.1 Mục đích, 1.2 Phạm vi, 1. Giới thiệu, 2. Mục tiêu nghiệp vụ, 5. Yêu cầu chức năng (Functional Requirements), 7. Giả định, 8. Rủi ro, 9. Mở rộng tương lai (+2 more)

### Community 1 - "Community 1"
Cohesion: 0.18
Nodes (11): 3.10 Bankruptcy & End Game, 3.1 Setup & Turn Order, 3.2 Movement, 3.3 Property, 3.4 Rent Logic, 3.5 Building Rules, 3.6 Jail Rules, 3.7 Event Rules (+3 more)

### Community 2 - "Community 2"
Cohesion: 0.18
Nodes (10): 1. Thông tin chung (General Information), 2. Luồng sự kiện chính (Main Flow 3.1), 3.4.1 Lỗi không gian lưu trữ, 3.4.2 Dữ liệu bản lưu bị hỏng (Corrupted Data), 3. Luồng thay thế (Alternative Flows), 4. Luồng ngoại lệ (Exception Flow - 3.4), 5. Quy tắc nghiệp vụ mapping (Business Rules), Luồng thay thế 1 (3.2): Tải ván chơi đã lưu (Load Game) (+2 more)

### Community 3 - "Community 3"
Cohesion: 0.18
Nodes (10): 1. Giới thiệu dự án, 2.1 Hệ thống Quản lý Ván chơi, 2.2 Cơ chế Gameplay Cốt lõi, 2.3 Hệ thống Kinh tế & Sự kiện, 2. Yêu cầu Chức năng (Functional Requirements), 3. Yêu cầu Giao diện & Trải nghiệm (UI/UX), 4. Yêu cầu Kỹ thuật & Phi chức năng, 5. Quy tắc Tính toán (Logic) (+2 more)

### Community 4 - "Community 4"
Cohesion: 0.22
Nodes (8): 1. Thông tin chung (General Information), 2. Luồng sự kiện chính (Main Flow 6.1), 3. Alternative Flows, 4. Luồng ngoại lệ (Exception Flow - 6.4), 5. Quy tắc nghiệp vụ (Business Rules), Luồng thay thế 1 (6.2): Nhận tiền thưởng, Luồng thay thế 2 (6.3): Thế chấp tài sản để thanh toán, Đặc tả Use Case: Quản lý tài chính (UC-06)

### Community 5 - "Community 5"
Cohesion: 0.5
Nodes (4): 4.1 Save Game, 4.2 Load Game, 4.3 Thoát giữa chừng, 4. Save / Load Game

### Community 6 - "Community 6"
Cohesion: 0.5
Nodes (4): 6.1 Hiệu năng, 6.2 Khả dụng, 6.3 Độ tin cậy, 6. Yêu cầu phi chức năng

## Knowledge Gaps
- **45 isolated node(s):** `Hệ thống Game Monopolime (Offline)`, `1.1 Mục đích`, `1.2 Phạm vi`, `2. Mục tiêu nghiệp vụ`, `3.1 Setup & Turn Order` (+40 more)
  These have ≤1 connection - possible missing edges or undocumented components.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `TÀI LIỆU ĐẶC TẢ YÊU CẦU NGHIỆP VỤ (BRS)` connect `Community 0` to `Community 1`, `Community 5`, `Community 6`?**
  _High betweenness centrality (0.184) - this node is a cross-community bridge._
- **Why does `3. Yêu cầu nghiệp vụ chi tiết (Business Rules)` connect `Community 1` to `Community 0`?**
  _High betweenness centrality (0.128) - this node is a cross-community bridge._
- **Why does `4. Save / Load Game` connect `Community 5` to `Community 0`?**
  _High betweenness centrality (0.044) - this node is a cross-community bridge._
- **What connects `Hệ thống Game Monopolime (Offline)`, `1.1 Mục đích`, `1.2 Phạm vi` to the rest of the system?**
  _45 weakly-connected nodes found - possible documentation gaps or missing edges._