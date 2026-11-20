---
name: sol-dispatch
description: Codex Sol로 구현·테스트·디버깅을 디스패치하거나, 끊긴 실행을 재개(resume)·재디스패치·폴백하기 직전에 로드한다. codex exec 템플릿(< /dev/null), ultra·장시간용 tmux 런처, writer 1명 생존 확인, 디스패치 기록 한 줄, 완료 후 검증. Load before any Codex dispatch, resume, re-dispatch or fallback.
---
# sol-dispatch (2026-11-18)
판단 규칙은 `~/.claude/rules/orchestration.md`가 정본이고, 여기에는 레시피만 둔다. Z1 플레이북의 디스패치 예시와 다르면 이 파일을 따른다. 샌드박스·권한 플래그는 디스패치에 붙이지 않는다. 읽기 레인과 리뷰도 같다: `-s read-only`는 권한 프로필을 통째로 바꿔 디스크 전체 읽기, deny 0개, 쓰기·네트워크 차단이 된다(2026-11-20 thread store, 11-19 이후 21스레드). 2026-11-20부터 lane-verify가 세션 시작 때 deny 목록이 빠진 디스패치 스레드를 `thread <id> deny list: <m> of <n> denied locations missing`으로 보고한다. 정책은 Codex config(샌드박스 없음, 비밀 위치 deny 목록)와 `~/.codex/AGENTS.md`가 담는다.

## Dispatch
- 헤드리스 exec는 프로필을 항상 `-p`로 명시한다. 대화형 TUI에서 모델을 바꾸면 base `~/.codex/config.toml`의 model/effort가 다시 써지고, 그 값이 `-p` 없는 디스패치로 샌다. 프로필(9개): `luna`(Luna/medium, 기계적인 일)·`high`(Sol/high)·`xhigh`(Sol/xhigh, 복잡하거나 중요한 일)·`astra`(Astra/high, 드물게)·`ultra`·`max`(Sol), `fast`(Terra/medium), `terra-max`·`terra-ultra`(사용자가 Terra 레인을 지정했을 때만). 측정 전에는 `high`로 시작하고, 여러 원인이 상호작용할 수 있으면 `xhigh`나 `astra`를 쓴다.
- `service_tier`는 base config에서 모든 실행에 적용되고 프로필로 막을 수 없다. lane-verify가 감시한다. effort는 프로필(`-p`)로 정하거나 그 위에 `-c model_reasoning_effort=<level>`을 얹어 정한다(0.166.0에서 확인, thread store에 `xhigh`·`ultra`가 기록됨). 적용된 값은 thread store로 확인한다.
- 모든 디스패치는 `--output-schema <이 스킬 폴더>/report.schema.json -o <보고서 파일 절대경로>`를 붙인다(리뷰는 `review.schema.json`). 최종 보고가 구조화되어 나온다.
- 짧은 실행(run_in_background): `cd <abs wt> && codex exec -p <profile> --output-schema <schema> -o <report> "<계약 절대경로>를 읽고 수행하라" < /dev/null > <log> 2>&1`
- worktree는 `git worktree add -b sol/<task> <path> <base>`로 만든다. 헤드리스 디스패치에 OMX는 필요 없다(11-18 디스패치가 이 방식이었다).
- 대안 한 줄: `codex exec --worktree`(값 없는 플래그)는 `~/.codex/worktrees/<id>/<repo>`에 detached HEAD로 새 worktree를 만들고 거기 남긴다. 브랜치가 필요하면 위 방식을 쓴다.
- ultra이거나 1시간을 넘길 실행은 detached tmux로 띄운다(Claude의 BG-shell reaper가 메모리 압박 때 오래 도는 codex exec를 죽인 적이 있다, gotcha 14). stdin은 런처 안에서 닫는다.
  - `<launcher.sh>`: `cd <abs wt> && exec codex exec -p <profile> --output-schema <schema> -o <report> "<같은 지시>" < /dev/null > <log> 2>&1`
  - `tmux new-session -d -s sol-<task> 'zsh <launcher.sh>'`. 알림을 줄 수 없는 이 실행에만 `tmux has-session -t sol-<task>`를 기다리는 가벼운 감시를 실행 하나에 하나 둔다.
- 알림을 주는 실행은 디스패치와 완료 사이에 로그나 worktree를 들여다보지 않는다(확인 한 번이 요청 한 번이고 요청마다 컨텍스트 전체를 다시 읽는다).
- 실행이 끝나면 같은 깨어남에서 이어 간다: 보고서 읽기, 헤더·thread store 확인(Record), diff 확인, 다음 단계 착수. 결과를 읽고 멈추지 않는다.

## 계약 블록과 사전 점검
근거: 수정 라운드 120회 분류(`~/.claude/backups/audit-20261117/structure/codex/fixcause.md`). 수락 항목 누락 54회, 계약 오류·누락 35회, 앞선 수정이 만든 회귀 22회.
- 구현 계약 끝에 두 블록을 둔다.
  - `## Gates`: 명령을 한 줄에 하나씩, 통과 조건을 관측 가능한 형태로 적는다.
  - `## Self-review`: "최종 메시지 전에 수락 항목을 하나씩 실제 diff, 호출 경로, 오류 경로와 대조한다. 빠진 것을 고치고 게이트를 다시 돌린다. 게이트가 통과할 때까지 반복한다. 같은 지적이 표적 수정 뒤에 다시 나오면 원인을 찾아 원인을 고친다. 그 원인이 계약 범위 밖에 있거나 소유자 결정이 필요할 때만 루프를 떠나 보고하고, 그 항목은 열어 둔 채 나머지 일을 계속한다. 수리에서는 실패하던 검사를 통과로 바꾼 변경만 남긴다. 검사를 움직이지 못한 수정은 원인을 찾지 못하고 넣은 것이니, '혹시 몰라' 넣은 방어 코드와 함께 마지막 게이트 실행 전에 되돌린다."
- 디스패치 전에 계약을 읽기 레인에 한 번 보내 저장소와 대조시킨다: 기존 테스트·금지 범위와의 충돌, 빠진 수락 항목, 틀린 경로·수치·fixture, 환경 전제.
- 리뷰 계약에는 차단 기준과 증거 요구를 적는다(orchestration.md Verification, 2026-11-19).
  - 차단 기준: 전달할 버전에서 실패하는 실행, 또는 소유자나 사용자가 이 환경에서 실제로 겪을 결함·피해(버그, 비밀·비공개 이름 노출, 라이선스 위반)만 완료를 막는다. 그 밖의 지적은 후속 항목으로 보고하게 한다. 계약의 수락 기준이 기준의 전부이고, 리뷰어는 그 위에 관문을 더하지 않는다.
  - 증거: 지적마다 실제로 돌린 명령과 그 출력을 요구한다. 실행으로 보이지 못한 지적은 "추정"으로 표시하게 하고, 추정은 막지 않는다.
  - 리허설: 실제 환경을 바꾸는 변경(훅·설정·설치기·설정 파일·launch agent)이면 리뷰와 별개로 환경 사본에서 변경 전, 변경 후 순서로 실제로 돌리고 두 출력을 남긴다. 사본은 실제 파일을 복사해 만든 별도 경로다(가짜 HOME, PATH 맨 앞의 가짜 서비스 관리자). 사본이 한 준비 가운데 실제 환경은 하지 않을 것을 보고에 적고, 그 부분은 미검증으로 남긴다.
- 시험 중(2026-11-19 ~ 12-03, orchestration.md Trials). 수치는 디스패치 기록과 수리 계약에서 센다.
  - 실패 확인: 수락 항목마다 변경 전에는 실패하고 변경 후에는 통과하는 검사를 `## Gates`에 둔다. 작업자는 보고의 항목별 evidence에 전·후 결과를 적는다. 수리 계약은 지적을 재현하는 검사부터 두고, 디스패치 전에 그 검사가 실패하는 것을 본다. 사전 점검 레인은 기준 커밋에서 게이트를 돌린다: 이미 통과하거나 다른 이유로 실패하는 게이트는 계약 오류다(없는 명령이라 실패한 것처럼 뻔한 경우는 이유를 적는다).
  - `## Assumptions`: 계약이 기대는 환경 사실을 한 줄에 하나씩, 어디서 언제 읽었는지와 함께 적는다. 사전 점검은 각 줄을 지금 상태와, 그 시각 뒤에 내려진 결정(규칙·설정·메모리의 변경)에 대조한다.

## 실행 원장 (시험, 2026-11-19 ~ 12-03)
- 여러 단위이거나 자리를 비우는 요청이면 main checkout에 `.omc/plans/<request>.ledger.md`를 둔다. 맨 위에 요청의 완료 조건을 검사 형태로 적고, 그 아래에 단위와 띄운 실행(Codex 스레드 또는 Claude 에이전트)마다 한 줄을 둔다: `<UTC> | <단위> | <실행 id> | <worktree 또는 -> | <기준: 기본 브랜치 또는 올라탄 단위> | dispatched|finished|accepted|merged | <근거 경로>`.
- 줄은 디스패치하거나 수락하는 그 호출에서 덧붙인다(Record와 같은 방식). 깨어날 때, 압축 뒤, 새 세션에서는 원장을 먼저 읽는다. accepted 단위는 다시 하지 않고, finished 줄은 결과물에 검사를 돌려 수락하거나 수리한다. accepted인데 merged가 아닌 단위가 병합 대기다(Worktree / 커밋 / 검증).
- 잴 것: 깨어났을 때 수락되지 않은 채 발견된 finished 줄 수, 실행 종료부터 수락까지 걸린 시간, 병합을 물을 때 대기 중인 단위 수와 쌓인 깊이.

## 결정 기록 (시험, 2026-11-19 ~ 12-03)
- 원장 옆에 `.omc/plans/<request>.decisions.tsv`를 둔다. 원장은 이어받는 에이전트가 읽는 실행 상태이고, 이 파일은 소유자가 나중에 판단을 검토하려고 읽는 것이라 따로 둔다. 프로젝트가 정해지지 않은 요청은 그 요청의 산출물 폴더에 둔다.
- 열(탭 구분, 한 줄에 한 결정): `ts`(UTC) · `phase` · `decision`(무엇을 골랐나) · `why` · `evidence`(커밋, 파일:줄, 로그 경로처럼 가리키는 것. 문단 금지) · `result`.
- 적는 때: 질문 대신 스스로 정했을 때, 후보를 걸러 냈을 때, 범위를 줄였을 때, 방향을 바꾸거나 되돌렸을 때. 사소하고 뻔한 것은 적지 않는다. 결정하는 그 호출에서 덧붙이고, 지우거나 고치지 않는다(틀린 결정은 그것을 대체하는 새 줄을 쓴다).
- 최종 보고는 이 파일을 가리키고, 소유자가 뒤집을 만한 줄을 따로 짚는다. pstack의 대화 기록 대조 감사와 다른 회사 모델 검토는 넣지 않았다(실행마다 에이전트가 더 든다).
- 잴 것: 소유자가 뒤집은 줄 수, 줄 없이 나중에 드러난 결정 수.

## PR 넘기기 (시험, 2026-11-19 ~ 12-03)
- 대상: origin이 비공개 GitHub 저장소인 프로젝트. 공개 저장소와 원격 없는 곳은 Worktree 절의 병합 대기 절차를 쓴다.
- 디스패치할 때 PR 본문 파일 `.omc/plans/<task>.pr.md`(목표, 수락 항목, 계약 경로)를 계약과 함께 만들고, 계약에 그 경로와 보고 요약 파일 경로를 적는다. 코드를 Codex가 쓴 단위면 본문 끝(Claude Code 줄 앞)에 `Generated with [Codex](https://openai.com/codex/).` 한 줄을 둔다(소유자, 2026-11-21: Codex의 작업도 흔적을 남긴다). Codex는 마지막 커밋 뒤 스스로 `pr-script handoff <wt> --body-file <task>.pr.md --report <요약 파일>`을 실행한다(AGENTS.md).
- 실행이 끝나면 같은 깨어남에서 PR이 그 커밋을 가리키는지 확인한다(`gh pr view <번호> --repo github.com/<owner>/<name> --json headRefOid`). 커밋이 없거나 넘기기가 실패했으면 원장에 적고, 필요하면 세션이 handoff를 대신 돌린다.
- 그 커밋에서 게이트를 다시 돌리고 `pr-script status <wt> --context gates --state success|failure --description "<요약>"`. 리뷰 레인의 결과는 `pr-script review <wt> --file <review.json>`과 `--context review` 상태로 남긴다.
- 수리는 열린 지적을 수리 계약에 옮겨 같은 브랜치로 다시 디스패치하고, Codex의 handoff가 같은 PR을 갱신한다.
- 수락: `pr-script status <wt> --context acceptance --state success`, 원장에 accepted와 PR 번호.
- 병합: 세 상태가 head에서 success면 세션이 바로 `pr-script merge <wt>`로 병합한다. 이 명령이 base가 기본 브랜치인지, head가 맞는지, 세 상태가 success인지 확인하고 squash 병합한 뒤, 병합이 기본 브랜치에 들어갔는지 확인한다(orchestration.md Safety; 기본 브랜치 병합이 자동 배포로 이어지는 저장소는 배포 확인을 받는다). 소유자가 먼저 보겠다고 한 PR만 `pr-script wait <wt>`를 백그라운드로 띄워 병합이나 코멘트를 기다린다(`comment`면 읽고 처리한다. 모든 계정이 소유자 것이라 작성자로는 구분하지 않고, 되돌리기 어려운 요청은 대화에서 확인한다).
- 병합 뒤: `pr-script land <wt>`가 병합이 기본 브랜치에 들어갔는지 확인하고, 원격 작업 브랜치를 지우고, 작업 폴더와 로컬 브랜치를 정리한다. lock된 재사용 폴더, 수정이나 추적 안 된 파일이 있는 폴더, 사용 중인 폴더는 남기고 이유를 보고한다. main 체크아웃은 그것을 쓰는 세션이 직접 따라 올린다(`git fetch origin <기본 브랜치>` 뒤 `git merge --ff-only FETCH_HEAD`). 원장에 merged를 적는다.
- 쌓인 정리: `pr-script sweep <저장소>`로 미리보기를 파일에 남겨 소유자에게 보이고, 지울 때는 그 파일을 계획으로 넘긴다(`--apply --plan <파일>`). 계획 뒤에 바뀌거나 새로 생긴 항목은 건드리지 않는다(2026-11-20 미리보기에 없던 폴더가 지워진 일 뒤로).
- 쌓기는 아래 단위의 코드가 필요할 때만 `--base sol/<아래>`로 한다. 아래가 squash로 병합되면 `git rebase --onto origin/<기본 브랜치> <아래의 옛 끝> <위 브랜치>`로 다시 쌓고 handoff한다.

## Codex 읽기 레인
- 대상: 고정된 파일을 읽기만 하는 일(계약 사전 점검, 정적 조사, 리뷰, 로그·기록 분석). 실행 중인 writer의 트리를 봐야 하는 검증은 고정된 트리와 worktree 절차를 쓴다.
- 한 호출(run_in_background): `mkdir -p <scratch> && ( cd <scratch> && codex exec -p <profile> --skip-git-repo-check --output-schema <review.schema.json 또는 report.schema.json> -o <보고서 절대경로> "<계약 절대경로>를 읽고 수행하라" < /dev/null > <log> 2>&1 )`. 계약에는 읽을 경로, 질문, 규칙(저장소를 바꾸지 않고 scratch에만 쓴다), "최종 메시지가 보고서"를 적는다. 독립적인 읽기 레인은 한 호출에서 `&`와 `wait`로 함께 띄운다.

## Liveness / writer 1명
1. 1순위는 thread store(읽기 전용): `sqlite3 -readonly ~/.codex/state_5.sqlite "select id, datetime(updated_at_ms/1000,'unixepoch','localtime'), rollout_path, model, reasoning_effort, sandbox_policy from threads where cwd='<abs wt>' order by updated_at_ms desc limit 3"`. 이어서 `ls -l <rollout_path>`로 mtime을 본다. `first_user_message` 등 다른 열은 읽지 않는다. `-readonly`가 `unable to open database file (14)`로 실패하면(쓰는 쪽이 없어 `-wal`·`-shm` 파일이 지워진 때) 같은 질의를 `sqlite3 "file:$HOME/.codex/state_5.sqlite?mode=ro&immutable=1"`로 다시 한다(2026-11-19에 세 번 겪음).
2. 보조로 `pgrep -x codex`를 돌리고, pid마다 `lsof -a -p <pid> -d cwd -Fn`을 본다. `-a`를 빼면 조건이 OR로 묶인다.
3. 금지: `pgrep -lf`, `ps e`/`-E`/`eww`. env 비밀을 출력한다.
4. 1과 2가 모두 '끝남'이어야 끝난 것이다. 애매하면 끝나지 않은 것으로 본다. 그 worktree에는 쓰지 않고, 다른 일을 하며 그 스레드가 끝나기를 기다린다(끝남은 Liveness 1·2로 확인).
5. 살아 있으면 끼어들지 않는다. 실행 중인 실행은 중단하지 않는다.

## Resume
1. Liveness로 이전 실행이 끝났는지 확인한다.
2. `git -C <wt> status --short`와 계약 게이트를 남은 결과물에 돌린다.
3. `cd <wt> && codex exec -p <기록된 profile> resume <thread id> < /dev/null > <log> 2>&1`. 장시간이면 tmux 런처에 넣는다. `resume`은 `-p`·`-C`를 받지 않으니 프로필과 `-c`는 `resume` 앞에 다시 넘기고 worktree에는 `cd`로 들어간다. 그러지 않으면 effort와 설정이 빠진다. thread id는 기록에서, 없으면 Liveness 1의 최신 행에서 가져온다. `--last`는 쓰지 않는다(남의 스레드를 고를 수 있다).
4. Record를 확인한다. 기대값과 다르면 그 실행을 기록에 mismatch로 남기고, 올바른 `-p`로 새로 디스패치한다(같은 worktree면 writer 1명 규칙을 먼저 지킨다).
5. 명시적 일시 오류(capacity·5xx·stream disconnect로 프로세스가 오류를 내고 끝남)가 나면 그때마다 재개한다. 같은 오류가 되풀이되면 횟수를 세지 말고 원인을 찾는다. 조용하거나 오래 걸리는 ultra는 실패가 아니다.

## Record (디스패치·재개마다 한 줄)
- 파일: 프로젝트에 기존 디스패치 기록(예: `.omc/plans/u1-dispatch-record.md`)이 있으면 그 파일과 형식을 쓴다. 없으면 main checkout의 `.omc/plans/<task>.dispatch.md`.
- 형식: `<UTC> | dispatch|resume | thread=<id> | wt=<abs> | profile=<p|none> | app=<model>/<effort> src=thread-store | policy=open|other | status=ok|mismatch|unknown | log=<abs>`
- `app`은 thread store의 `model`·`reasoning_effort`, `policy`는 `sandbox_policy` 열에서 읽는다(로그 헤더가 아니다): JSON에 `"type":"managed"`가 있고 `"access":"deny"` 항목이 들어 있으면 `open`, 그 밖은 `other`. 프로필 기대값과 다르면 mismatch, 관측하지 못한 값은 `unknown`이다. Sol의 자기보고는 출처로 쓰지 않는다.
- 줄은 확인하는 그 호출에서 `printf '%s\n' '<줄>' >> <기록 파일>`로 덧붙인다. 기록만 따로 Edit하지 않는다.

## Worktree / 커밋 / 검증
- 태스크 1개 = `sol/<task>` 브랜치 1개 = worktree 1개 = writer 1명이다.
- 게이트가 통과하면 Codex가 task 브랜치에 커밋한다(`~/.codex/AGENTS.md`대로 메시지 끝에 `Co-authored-by: Codex <noreply@openai.com>`). 프로젝트가 세션이 커밋한다고 정한 경우처럼 Codex가 쓴 변경을 세션이 대신 커밋할 때도 같은 꼬리말을 붙인다(소유자, 2026-11-21). 메인 세션은 `git diff <base>..<branch>`로 변경(`.husky/`, `.pre-commit-config.yaml`, package.json scripts 포함)을 보고, 그 커밋에서 게이트를 다시 돌려 통과를 확인한다. 커밋 확인 전에 `git -C <wt> rev-parse --abbrev-ref HEAD`가 `sol/<task>`이고 `git -C <wt> status --porcelain`이 비어 있는지 본다. 아니면 그 상태를 보고서와 대조하고 남은 변경을 결과에 포함해 판단한다. 기본 브랜치 병합은 소유자 확인을 기다린다(검증된 PR은 PR 넘기기 절대로 세션이 병합한다).
- 병합 대기(orchestration.md Safety, 2026-11-19): 수락된 단위는 원장에 accepted로 두고 다른 일을 계속한다. 병합 때문에 멈추지 않고, 질문을 빠뜨리지도 않는다. 보고마다 대기 목록을 적고, 소유자가 대화에 들어오면 맨 먼저 대기 중인 확인을 한 질문으로 묻는다. 단위가 쌓여 있으면 아래부터 수락된 구간 전체를 묻고, 그 구간의 맨 위 단위와 그 위에 남는 단위 수를 밝힌다. 승인되면 기본 브랜치를 그 지점까지 fast-forward하고 원장에 merged를 적은 뒤, 새 단위는 기본 브랜치에서 시작한다.
- 병합 질문에는 그 병합으로 지울 수 있는 worktree 목록을 붙인다: `git worktree list`와 `git -C <wt> status --porcelain`으로 변경 없음 / 미추적 파일만 있음(파일 이름) / 수정 있음으로 나누고, HANDOFF나 계약이 재사용한다고 적은 worktree는 뺀다. 병합 승인은 변경 없는 worktree의 제거까지 포함하고, 나머지는 따로 묻는다.
- worktree 제거는 병합 뒤에 한다. 검증된 PR은 세션의 병합이, 그 밖의 저장소는 병합 질문에 대한 소유자의 승인이 변경 없는 worktree의 제거 승인이다. 순서: `git -C <wt> status --porcelain --ignored`의 `!!`·`??` 경로를 tar로 보존 → `git worktree remove <wt>`(`--force` 없이) → `git branch -d`(squash 병합이라 거부되면, 브랜치 끝이 병합된 PR의 headRefOid와 같을 때만 `git branch -D`) → `git worktree prune`. 여러 단위가 다시 쓰는 worktree는 `git worktree lock <wt> --reason reused`로 표시하고 지우지 않는다. 제거한 사실을 기록에 남긴다.

## Claude 폴백
- Codex가 실제로 실패했거나 소유자가 지시했을 때만 ≤opus Claude 서브에이전트로 넘긴다(인라인 아님). 프롬프트 첫 줄: `SOL-FALLBACK(a): <실패한 codex 명령과 그것이 출력한 글, 40자 이상, 최근 60분 안의 Bash/Read 출력에서 그대로>` 또는 `SOL-FALLBACK(b): "<소유자 지시 원문 10자 이상>"`. 두 번 연속 차단되면 표지를 고쳐 다시 시도하지 말고 원인을 보고한다.
