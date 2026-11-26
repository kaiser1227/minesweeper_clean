---
name: minesweeper
description: |
  지뢰찾기: 무추측 클린 에디션 (Minesweeper: No Guess & Clean) 전담 개발 및 운영 스킬.
  Flutter 모바일(Android/iOS) 및 Web 개발, 무추측(No-Guess) 논리 보드 생성기 알고리즘,
  물결 터치 UI/UX 개선, 진동/사운드 피드백, 릴리즈 빌드 및 스마트폰 설치 자동화를 전담합니다.
license: Apache-2.0
metadata:
  version: v1
  publisher: antigravity
---

# 💣 지뢰찾기 (Minesweeper) 전담 개발 마스터 스킬

글로벌 캐주얼 게임 **《지뢰찾기: 무추측 클린 에디션 (Minesweeper: No Guess & Clean)》**의 Flutter 앱 개발, UI/UX 버그 수정, 빌드 및 디바이스 설치를 전담하는 공식 에이전트 스킬입니다.

---

## 🎯 핵심 역할 및 가이드라인
1. **무추측(No-Guess) 논리 엔진**:
   - 찍기(50:50 추측) 상황을 원천 배제하고 순수 논리적 연역으로 100% 클리어 가능한 보드 보장.
   - 첫 탭 100% 안전 보장 및 빈 공간(0) 연쇄 개방.
2. **반응형 보드 및 제스처 인터랙션**:
   - `InteractiveViewer(constrained: false)`를 통한 자유로운 팬(이동) 및 줌(확대/축소).
   - 대형 보드(중급 16x16, 고급 30x16)에서도 모든 타일의 터치, 롱프레스 깃발 배치, 코드(Chord) 연속 개방 완벽 지원.
3. **직관적인 아이콘 & 툴팁 UI**:
   - 사운드(🔊/🔇), 진동(📳/📴), OLED 테마(◐), 게임 통계/기록(🏆) 등 시인성 높은 아이콘 및 툴팁 제공.
4. **빌드 및 기기 배포 환경**:
   - 프로젝트 경로: `/Users/akm/minesweeper_clean`
   - JAVA_HOME: `/Users/akm/Pomo_Farm/jdk17/Contents/Home`
   - 빌드 명령: `flutter build apk --release`
   - 설치 명령: `adb -s <device_serial> install -r build/app/outputs/flutter-apk/app-release.apk`
