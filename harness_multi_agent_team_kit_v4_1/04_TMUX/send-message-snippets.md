# tmux Send Message Snippets

## pane에 메시지 보내기

```bash
tmux send-keys -t product-war-room:planning.0 'cat 02_AGENT_PROMPTS/PLANNING_PM_PROMPT.md' C-m
```

## 긴 업무지시 보내기

```bash
tmux load-buffer /tmp/task.md
tmux paste-buffer -t product-war-room:ceo.0
tmux send-keys -t product-war-room:ceo.0 C-m
```

## 모든 pane 목록 보기

```bash
tmux list-panes -a -F '#S:#W.#P #{pane_current_command} #{pane_current_path}'
```

## 특정 window로 이동

```bash
tmux select-window -t product-war-room:development
```

## 세션 종료

```bash
tmux kill-session -t product-war-room
```

## 권장 운영 방식

1. pane에 직접 장문을 치지 않는다.
2. `/tmp/task.md` 또는 `.agents/{role}/inbox.md`에 지시를 작성한다.
3. `tmux paste-buffer`로 주입한다.
4. 결과는 `handoffs/`에 파일로 남기게 한다.
