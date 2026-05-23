import { useEffect, useMemo, useState } from 'react';
import { invoke } from '@tauri-apps/api/core';
import type { WorkspaceModelSettings } from '../model/snapshot';
import { workspaceModelErrorMessage, type WorkspaceModelCommandResult } from '../model/actions';

function optionKey(provider: string, model: string): string {
  return `${provider}::${model}`;
}

function sourceLabel(source?: string): string {
  switch (source) {
    case 'project': return '프로젝트 설정';
    case 'hermes-config': return 'Hermes 기본값';
    case 'default': return '기본값';
    default: return source || '확인 중';
  }
}

export function ModelSettingsPanel({
  projectRoot,
  snapshotModel,
  onApplied,
}: {
  projectRoot: string;
  snapshotModel?: WorkspaceModelSettings;
  onApplied: () => void | Promise<unknown>;
}) {
  const [settings, setSettings] = useState<WorkspaceModelSettings | undefined>(snapshotModel);
  const [provider, setProvider] = useState(snapshotModel?.provider ?? 'openai-codex');
  const [model, setModel] = useState(snapshotModel?.model ?? 'gpt-5.5');
  const [pending, setPending] = useState(false);
  const [status, setStatus] = useState<string>('AI 모델 설정을 불러오는 중입니다.');
  const options = useMemo(() => settings?.options ?? snapshotModel?.options ?? [], [settings?.options, snapshotModel?.options]);

  useEffect(() => {
    if (!snapshotModel) return;
    setSettings((current) => current ?? snapshotModel);
    if (snapshotModel.provider) setProvider(snapshotModel.provider);
    if (snapshotModel.model) setModel(snapshotModel.model);
  }, [snapshotModel]);

  useEffect(() => {
    let cancelled = false;
    invoke<WorkspaceModelCommandResult>('workspace_model', { projectRoot })
      .then((result) => {
        if (cancelled) return;
        if (result.ok && result.parsed) {
          setSettings(result.parsed);
          setProvider(result.parsed.provider || 'openai-codex');
          setModel(result.parsed.model || 'gpt-5.5');
          setStatus(`현재 ${sourceLabel(result.parsed.source)}을 사용 중입니다.`);
        } else {
          setStatus(workspaceModelErrorMessage(result));
        }
      })
      .catch((error) => {
        if (!cancelled) setStatus(error instanceof Error ? error.message : String(error));
      });
    return () => { cancelled = true; };
  }, [projectRoot]);

  const selectedKey = options.some((option) => option.provider === provider && option.model === model)
    ? optionKey(provider, model)
    : 'custom';

  const applyOption = (key: string) => {
    if (key === 'custom') return;
    const next = options.find((option) => optionKey(option.provider, option.model) === key);
    if (!next) return;
    setProvider(next.provider);
    setModel(next.model);
  };

  const applyModel = async () => {
    const nextProvider = provider.trim();
    const nextModel = model.trim();
    if (!nextModel) {
      setStatus('모델 이름을 입력하세요.');
      return;
    }
    setPending(true);
    setStatus('Hermes 에이전트에 모델 변경을 전달하는 중입니다…');
    try {
      const result = await invoke<WorkspaceModelCommandResult>('workspace_model_set', {
        projectRoot,
        provider: nextProvider,
        model: nextModel,
      });
      if (result.ok && result.parsed) {
        setSettings(result.parsed);
        setProvider(result.parsed.provider || nextProvider);
        setModel(result.parsed.model || nextModel);
        const applied = result.parsed.applied_running_count ?? 0;
        setStatus(applied > 0
          ? `적용 완료: 실행 중인 ${applied}개 Hermes 역할에 전달했습니다.`
          : '저장 완료: 다음 Hermes 실행부터 적용됩니다. 실행 중 역할이 있으면 자동 전달을 시도합니다.');
        await onApplied();
      } else {
        setStatus(workspaceModelErrorMessage(result));
      }
    } catch (error) {
      setStatus(error instanceof Error ? error.message : String(error));
    } finally {
      setPending(false);
    }
  };

  return (
    <section className="snapshot-control-card model-settings-card" aria-label="AI model settings">
      <header>
        <p className="eyebrow">AI 모델</p>
        <h2>Hermes 모델 선택</h2>
      </header>
      <p className="model-settings-summary">
        UI에서 바꾸면 AgentDock 런타임 설정에 저장되고, 실행 중인 Hermes 역할에는 <code>/model</code> 명령으로 전달됩니다.
      </p>
      <label>
        <span>빠른 선택</span>
        <select value={selectedKey} onChange={(event) => applyOption(event.target.value)} disabled={pending}>
          {options.map((option) => (
            <option key={optionKey(option.provider, option.model)} value={optionKey(option.provider, option.model)}>
              {option.label ?? option.model}
            </option>
          ))}
          <option value="custom">직접 입력</option>
        </select>
      </label>
      <div className="model-input-grid">
        <label>
          <span>Provider</span>
          <input value={provider} onChange={(event) => setProvider(event.target.value)} placeholder="openai-codex" disabled={pending} />
        </label>
        <label>
          <span>Model</span>
          <input value={model} onChange={(event) => setModel(event.target.value)} placeholder="gpt-5.5" disabled={pending} />
        </label>
      </div>
      <button type="button" onClick={applyModel} disabled={pending || !model.trim()}>
        {pending ? '적용 중…' : '모델 적용'}
      </button>
      <p className="snapshot-refresh-state">{status}</p>
      {settings ? <small>현재값: {settings.provider} / {settings.model} · {sourceLabel(settings.source)}</small> : null}
    </section>
  );
}
