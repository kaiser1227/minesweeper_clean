# Minesweeper: No Guess & Clean (지뢰찾기: 무추측 클린 에디션)

> 글로벌 170여 개국 동시 출시 0원 마케팅 캐주얼 게임 프로젝트 제1탄
> 100% 논리 연역(No-Guess) 보증, 언어 장벽 제로(No-Text UI), 120FPS 햅틱 & 사운드 감각 경험

---

## 🎮 주요 특징 (Key Features)

### 1. 100% 무추측(No-Guess) 논리 보드 생성기
- **첫 탭 무조건 0(빈 공간) 개방**: 첫 클릭 시 지뢰 위험이 없으며 주변 8개 타일 역시 지뢰가 배치되지 않아 시원한 연쇄 개방(Cascade)으로 게임을 시작합니다.
- **찍기(50:50 추측) 원천 배제**: 단일 셀 추론(Single-cell deduction), 부분집합 축약(Subset reduction), 쌍 경계 분석(Coupled bounds), 전역 잔여 지뢰 추론(Global mine count)으로 구성된 연역 추론 솔버(`DeductionSolver`)가 100% 검증한 보드만 생성합니다.
- **난이도 모드**:
  - **초급 (Beginner)**: 9x9, 10개 지뢰
  - **중급 (Intermediate)**: 16x16, 40개 지뢰
  - **고급 (Expert)**: 30x16, 99개 지뢰

### 2. 언어 장벽 제로 UI (No-Text UI)
- 텍스트 없이 직관적인 만국 공통 심볼 배치:
  - ↻ : 재시작 / 새 게임 (부드러운 스핀)
  - 🚩 : 깃발 모드 토글 (모바일 원터치 지원)
  - ↶ : 실행 취소 (실수 클릭/폭발 복구 지원)
  - 💡 : 논리 힌트 (연역적으로 확정된 셀 및 근거 클루 펄스 표시)
  - 🔊 / 🔇 : 사운드 토글
  - 📳 / 📴 : 햅틱 진동 토글
  - ◐ : OLED 트루 블랙(#000000) / 페이퍼 라이트 테마 전환
- **첫 실행 제스처 튜토리얼**:
  - 긴 텍스트 설명 대신 반투명 탭(👆 ➔ 0) 및 롱프레스(👆⏱️ ➔ 🚩) 제스처 가이드 제공.

### 3. 감각적인 손맛 (ASMR & 120FPS)
- **리플 애니메이션**: 타일 개방 시 거리 기반 밀리초 단위 스태거(Stagger) 물결 연쇄 애니메이션.
- **단계별 햅틱 피드백**: 타일 탭(Light), 깃발 배치(Medium), 힌트/실행취소(Selection), 폭발(Heavy), 승리(Celebration double pattern).
- **청량한 자체 생성 16-bit PCM 사운드**: 번들 크기 50KB 미만으로 클릭, 깃발, 연쇄 개방, 승리, 폭발 효과음 자체 내장.

### 4. 초경량 12개국어 현지화
- 대화상자(승리 팝업, 기록 통계)용 25단어 내외 초경량 딕셔너리 탑재:
  - 영어(en), 한국어(ko), 일본어(ja), 스페인어(es), 포르투갈어(pt), 독일어(de), 프랑스어(fr), 중국어 번체(zh-TW), 중국어 간체(zh-CN), 러시아어(ru), 이탈리아어(it), 베트남어(vi).

---

## 📁 프로젝트 구조 (Project Structure)

```
minesweeper_clean/
├── assets/
│   └── audio/                  # 자체 생성 16-bit PCM WAV (click, flag, unflag, cascade, hint, win, explode)
├── lib/
│   ├── core/
│   │   ├── audio_controller.dart     # ASMR 효과음 컨트롤러 (Asset + SystemSound Fallback)
│   │   ├── haptic_controller.dart    # 5단계 햅틱 피드백
│   │   ├── localization.dart         # 초경량 12개국어 사전
│   │   ├── preferences_manager.dart  # 통계, 최고기록, 테마 설정 저장
│   │   └── theme_manager.dart        # OLED Dark & Paper Light 테마 및 1-8 컬러
│   ├── engine/
│   │   ├── board_generator.dart      # 100% 무추측 보드 생성기 (초급/중급/고급)
│   │   ├── cell_model.dart           # 불변 타일 상태 모델
│   │   ├── deduction_solver.dart     # 연역 논리 제약 충족 솔버 & 실시간 힌트 엔진
│   │   └── game_state.dart           # 게임 상태 머신, 타이머, 스냅샷 실행취소
│   ├── ui/
│   │   ├── animated_tile.dart        # 120FPS 최적화 타일 위젯
│   │   ├── board_view.dart           # InteractiveViewer 줌/팬 반응형 그리드
│   │   ├── gesture_guide_overlay.dart# 텍스트 없는 제스처 튜토리얼
│   │   ├── header_bar.dart           # 만국 공통 심볼 HUD 바
│   │   ├── stats_dialog.dart         # 난이도별 기록 통계 팝업
│   │   └── victory_dialog.dart       # 승리 축하 모달
│   └── main.dart                     # 앱 엔트리포인트 및 화면 바인딩
├── test/
│   ├── engine_test.dart              # 솔버 및 보드 생성기 무추측 검증 (100% Pass)
│   ├── game_engine_test.dart         # 상태 머신, 연쇄, 깃발, 실행취소 검증 (100% Pass)
│   ├── localization_test.dart        # 12개 언어 누락 키 전수 검사 (100% Pass)
│   └── widget_test.dart              # 위젯 렌더링 및 HUD 상호작용 검증 (100% Pass)
└── tool/
    └── generate_audio.dart           # PCM WAV 사운드 신시사이저
```

---

## 🧪 무결성 검증 결과 (Verification Results)

```bash
$ flutter analyze
Analyzing minesweeper_clean...
No issues found! (ran in 1.6s)

$ flutter test
00:03 +29: All tests passed!

$ flutter build web --no-pub
Font asset "CupertinoIcons.ttf" was tree-shaken (99.5% reduction)
Font asset "MaterialIcons-Regular.otf" was tree-shaken (99.4% reduction)
✓ Built build/web
```
