class TaskDecomposerService {
  /// Intelligently decomposes any task into 4–5 concrete, actionable steps
  /// based on semantic domain patterns (Software Engineering, Academic/Study,
  /// Writing/Content, Design/UI, Operations/DevOps, or General Execution).
  static List<String> decompose(String title, {String description = ''}) {
    final text = '${title.toLowerCase()} ${description.toLowerCase()}';

    // 1. Software Engineering & Coding
    if (text.contains('api') ||
        text.contains('backend') ||
        text.contains('endpoint') ||
        text.contains('auth') ||
        text.contains('database') ||
        text.contains('sql') ||
        text.contains('fix') ||
        text.contains('bug') ||
        text.contains('refactor') ||
        text.contains('feature') ||
        text.contains('code') ||
        text.contains('flutter') ||
        text.contains('python')) {
      if (text.contains('bug') || text.contains('fix')) {
        return [
          'Reproduce issue and inspect error stack trace',
          'Identify root cause in source file',
          'Write failing regression test case',
          'Implement targeted fix and verify test passes',
          'Run full analyzer and regression suite',
        ];
      }
      return [
        'Define schema models and interface contracts',
        'Implement repository and persistence operations',
        'Build business logic and validation handlers',
        'Write automated unit and integration tests',
        'Verify zero analyzer errors and create pull request',
      ];
    }

    // 2. DevOps, Cloud & Deployment
    if (text.contains('deploy') ||
        text.contains('docker') ||
        text.contains('k8s') ||
        text.contains('kubernetes') ||
        text.contains('ci/cd') ||
        text.contains('pipeline') ||
        text.contains('server') ||
        text.contains('release')) {
      return [
        'Audit environment variables and production secrets',
        'Run clean build and containerize application image',
        'Execute automated test pipeline on staging target',
        'Perform zero-downtime deployment rollout',
        'Inspect health metrics and error logs post-launch',
      ];
    }

    // 3. Academic, Study & Research
    if (text.contains('study') ||
        text.contains('exam') ||
        text.contains('research') ||
        text.contains('paper') ||
        text.contains('read') ||
        text.contains('learn') ||
        text.contains('course')) {
      return [
        'Gather authoritative source papers and reference texts',
        'Create high-level outline of key theoretical principles',
        'Perform 50-minute deep work note synthesis',
        'Solve practice problems / active recall exercises',
        'Synthesize core summary and flashcard anchors',
      ];
    }

    // 4. Design & UI/UX
    if (text.contains('design') ||
        text.contains('ui') ||
        text.contains('ux') ||
        text.contains('prototype') ||
        text.contains('wireframe') ||
        text.contains('component')) {
      return [
        'Analyze user requirements and interaction states',
        'Establish layout typography and spacing tokens',
        'Draft wireframe layout for mobile and desktop viewports',
        'Implement component with active, hover, and focus states',
        'Conduct usability review and responsiveness check',
      ];
    }

    // 5. Default General Action Plan
    return [
      'Define clear scope and completion criteria',
      'Gather necessary resources, documents, and tools',
      'Execute high-priority initial milestone',
      'Review output against quality requirements',
      'Finalize, document, and clean up workspace',
    ];
  }
}
