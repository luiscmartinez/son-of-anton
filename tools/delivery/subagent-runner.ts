export type SubagentRunnerOutcome = 'clean' | 'patched' | 'skipped';

export type SubagentRunnerArtifact = {
  runnerKind: 'claude-cli' | 'codex-exec' | 'skipped';
  reviewedHeadSha: string;
  outcome: SubagentRunnerOutcome;
  completedAt: string;
};

export type SpawnResult = {
  exitCode: number | null;
  timedOut: boolean;
};

export type RunnerAttemptResult =
  | { status: 'ran'; outcome: 'clean' | 'patched' }
  | { status: 'unavailable' }
  | { status: 'timeout' };

export type BuildSubagentReviewPromptInput = {
  baseBranch: string;
  changedFiles: string[];
};

export function buildSubagentReviewPrompt({
  baseBranch,
  changedFiles,
}: BuildSubagentReviewPromptInput): string {
  const files = changedFiles.length
    ? changedFiles.map((file) => `- ${file}`).join('\n')
    : '- (no changed files detected)';

  return [
    'Assume this implementation has holes. Find demonstrable ticket-relevant behavior breaks, not repo-wide hygiene issues.',
    '',
    `Review all code changes introduced in the current branch versus its base branch (${baseBranch}).`,
    '',
    'Changed files:',
    files,
    '',
    'Hard write boundary:',
    '- Never modify files under docs/product/delivery/**.',
    '- If you find an issue there, report it under Findings for human review only.',
    '- This includes ticket docs, implementation plans, handoffs, review artifacts, and rationale sections.',
    '',
    'Review boundary:',
    '- Start from the changed files, then independently inspect directly related implementation code before deciding the review is complete.',
    '- You may add attack surfaces when your repo read finds plausible ticket-relevant failure paths.',
    '- Patch only demonstrated correctness gaps relevant to the branch behavior.',
    '- Do not patch for style, preference, formatting, linting, or spellcheck noise.',
    '- If full-repo verification fails on pre-existing or generated-doc paths, classify it as out of scope.',
    '',
    'Commit any fixes with messages ending with " [subagent-review]".',
    'Do not rationalize away anything you notice: patch valid invariant breaks and report non-patched concerns for the human.',
  ].join('\n');
}

export function isDeliveryDocPath(filePath: string): boolean {
  const normalized = filePath.replace(/\\/g, '/').replace(/^\.\//, '');
  return (
    normalized === 'docs/product/delivery' ||
    normalized.startsWith('docs/product/delivery/')
  );
}

export function findDeliveryDocPaths(paths: string[]): string[] {
  return paths.filter(isDeliveryDocPath);
}

export function tryRunner(
  spawnProcess: () => SpawnResult,
  checkHasChanges: () => boolean,
): RunnerAttemptResult {
  let result: SpawnResult;
  try {
    result = spawnProcess();
  } catch {
    return { status: 'unavailable' };
  }

  if (result.timedOut) return { status: 'timeout' };

  const hasChanges = checkHasChanges();
  return { status: 'ran', outcome: hasChanges ? 'patched' : 'clean' };
}

export function buildRunnerArtifact(
  runnerKind: SubagentRunnerArtifact['runnerKind'],
  reviewedHeadSha: string,
  outcome: SubagentRunnerOutcome,
): SubagentRunnerArtifact {
  return {
    runnerKind,
    reviewedHeadSha,
    outcome,
    completedAt: new Date().toISOString(),
  };
}

const VALID_RUNNER_KINDS: SubagentRunnerArtifact['runnerKind'][] = [
  'claude-cli',
  'codex-exec',
  'skipped',
];
const VALID_OUTCOMES: SubagentRunnerOutcome[] = ['clean', 'patched', 'skipped'];

export function validateRunnerArtifact(
  value: unknown,
): SubagentRunnerArtifact | null {
  if (typeof value !== 'object' || value === null) return null;

  const obj = value as Record<string, unknown>;

  if (
    typeof obj['runnerKind'] !== 'string' ||
    !(VALID_RUNNER_KINDS as string[]).includes(obj['runnerKind'])
  ) {
    return null;
  }

  if (
    typeof obj['reviewedHeadSha'] !== 'string' ||
    obj['reviewedHeadSha'] === ''
  )
    return null;

  if (
    typeof obj['outcome'] !== 'string' ||
    !(VALID_OUTCOMES as string[]).includes(obj['outcome'])
  ) {
    return null;
  }

  if (typeof obj['completedAt'] !== 'string' || obj['completedAt'] === '')
    return null;

  return {
    runnerKind: obj['runnerKind'] as SubagentRunnerArtifact['runnerKind'],
    reviewedHeadSha: obj['reviewedHeadSha'] as string,
    outcome: obj['outcome'] as SubagentRunnerOutcome,
    completedAt: obj['completedAt'] as string,
  };
}
