# Skill Flows

Simplified lifecycle diagrams for all 18 skills. Render natively on GitHub.

---

## Setup Skills

### init-project — Bootstrap new project from scratch

```mermaid
flowchart LR
    A([/init-project]):::start --> B[Ask: name / stack\ndomain / private?]
    B --> C[Create dirs\n+ .gitignore]
    C --> D{Swift?}
    D -- yes --> E[xcodegen setup\nproject.yml + source files]
    D -- no --> F{Backend?}
    E --> F
    F -- python/go --> G[Backend files\nDockerfile + compose]
    F -- none --> H
    G --> H[CLAUDE.md + agents\n+ doc stubs]
    H --> I[Roadmap?\noptional — Step 9.5]
    I --> J[git init + commit]
    J --> K([Done → /analyze-project]):::done

    classDef start fill:#d0f0d0,stroke:#006600,color:#003300,font-weight:bold
    classDef done  fill:#d0f0d0,stroke:#006600,color:#003300,font-weight:bold
```

---

### attach-project — Add Claude structure to existing project

```mermaid
flowchart LR
    A([/attach-project]):::start --> B[Verify project root]
    B --> C[Auto-detect stacks\nfrom requirements.txt\ngo.mod / pubspec / xcodeproj…]
    C --> D[Ask: extra stacks\ndomain / private?]
    D --> E[Create missing structure\nskip existing files]
    E --> F([Done → /analyze-project]):::done

    classDef start fill:#d0f0d0,stroke:#006600,color:#003300,font-weight:bold
    classDef done  fill:#d0f0d0,stroke:#006600,color:#003300,font-weight:bold
```

---

### analyze-project — Document codebase architecture

```mermaid
flowchart LR
    A([/analyze-project]):::start --> B[Read existing\narchitecture docs]
    B --> C{2+ independent\ncomponents?}
    C -- yes --> D[Parallel agents\nper component]
    C -- no  --> E[Scan: dirs / deps\nentry points / config]
    D --> E
    E --> F[Analyze: endpoints\nschema / auth / state\nDocker / CI]
    F --> G[Write\ndocs/architecture/]
    G --> H([Done → /add-feature]):::done

    classDef start fill:#d0f0d0,stroke:#006600,color:#003300,font-weight:bold
    classDef done  fill:#d0f0d0,stroke:#006600,color:#003300,font-weight:bold
```

---

## Discover and Design Skills

### discover — AI research for competitors, monetization, valuation, marketing

```mermaid
flowchart LR
    A([/discover]):::start --> B[Read start-project.md\nsections 1-5 required]
    B --> C[MemPalace search\nprior research]
    C --> D[Ask: which sections\nto fill?]
    D --> E[Parallel research\ncompetitors · monetization\nvaluation · marketing]
    E --> F{iOS?}
    F -- yes --> G["/discover-apple-check\nApp Store feasibility"]
    F -- no  --> H[Write start-project.md\nsections 6–10]
    G --> H
    H --> I[MemPalace records]
    I --> J([Done]):::done

    classDef start fill:#d0f0d0,stroke:#006600,color:#003300,font-weight:bold
    classDef done  fill:#d0f0d0,stroke:#006600,color:#003300,font-weight:bold
```

---

### design-sync — Canonize design tokens from existing codebase

```mermaid
flowchart LR
    A([/design-sync]):::start --> B[Verify UI project\nSwift / Flutter\nAndroid / Web]
    B --> C[Read existing\ndocs/design/system.md]
    C --> D[Scan codebase\ncolors · typography\nicons · spacing]
    D --> E[Detect drift\nduplicates / inconsistencies]
    E --> F[Present to user\ncanonize tokens]
    F --> G[Write\ndocs/design/system.md]
    G --> H[MemPalace\ndesign decisions]
    H --> I([Done]):::done

    classDef start fill:#d0f0d0,stroke:#006600,color:#003300,font-weight:bold
    classDef done  fill:#d0f0d0,stroke:#006600,color:#003300,font-weight:bold
```

---

### design-page — Generate UI screen from design system

```mermaid
flowchart LR
    A([/design-page]):::start --> B[Read docs/design/system.md\n+ screen requirements]
    B --> C[Generate screen code\nusing design tokens only\nno raw hex / hardcoded values]
    C --> D[Write files + commit]
    D --> E([Done]):::done

    classDef start fill:#d0f0d0,stroke:#006600,color:#003300,font-weight:bold
    classDef done  fill:#d0f0d0,stroke:#006600,color:#003300,font-weight:bold
```

---

### seed-mempalace — Seed memory from existing project

```mermaid
flowchart LR
    A([/seed-mempalace]):::start --> B[Read project:\narchitecture + git log\n+ existing docs]
    B --> C[Extract: key decisions\nbug fixes · patterns\ndeployment facts]
    C --> D[Write MemPalace\ndecision / problem\nmilestone drawers]
    D --> E([Done]):::done

    classDef start fill:#d0f0d0,stroke:#006600,color:#003300,font-weight:bold
    classDef done  fill:#d0f0d0,stroke:#006600,color:#003300,font-weight:bold
```

---

## Build Skills

### add-feature — Full feature lifecycle (design → plan → implement → merge)

```mermaid
flowchart LR
    A([/add-feature]):::start --> B[Read CLAUDE.md\narchitecture / PRD / tasks]
    B --> C[Get feature description]
    C --> D[Create worktree]
    D --> E[Brainstorm design]
    E --> AP1{{Approve design}}:::approval
    AP1 --> F[Define contract\ntypes + examples + errors]
    F --> AP2{{Approve contract}}:::approval
    AP2 --> G{Large feature?}
    G -- yes --> H[Generate roadmap\ndocs/roadmap/slug.md\nphases + done-when]
    G -- no  --> I[Write implementation plan]
    H --> I
    I --> AP3{{Approve plan}}:::approval
    AP3 --> J[Execute plan\nsubagents · parallel agents\nguard rails + auto-gate]
    J --> K[Code review]
    K --> L[Merge to dev]
    L --> M([Architect report\n→ /write-test-docs]):::done

    classDef start    fill:#d0f0d0,stroke:#006600,color:#003300,font-weight:bold
    classDef done     fill:#d0f0d0,stroke:#006600,color:#003300,font-weight:bold
    classDef approval fill:#fde7c2,stroke:#a87000,color:#5a3a00,font-weight:bold
```

---

### fix-bug — Full bug fix lifecycle (reproduce → fix → review → merge)

```mermaid
flowchart LR
    A([/fix-bug]):::start --> B[Read project + bug report]
    B --> C[Create worktree\nbranch: fix/description]
    C --> D[Reproduce bug\nsystematic debugging]
    D --> E[Write failing test\nTDD — test MUST fail first]
    E --> F[Fix root cause\nnot symptom]
    F --> G{Tests pass?}
    G -- no  --> F
    G -- yes --> H[Code review\nno regressions\nedge cases covered]
    H --> I{Feedback?}
    I -- yes --> F
    I -- no  --> J[Merge + MemPalace\nproblem record]
    J --> K([Done → /write-test-docs]):::done

    classDef start fill:#d0f0d0,stroke:#006600,color:#003300,font-weight:bold
    classDef done  fill:#d0f0d0,stroke:#006600,color:#003300,font-weight:bold
```

---

### swiftui-pro — SwiftUI-specific code review

```mermaid
flowchart LR
    A([/swiftui-pro]):::start --> B[Read SwiftUI files\nin staged diff]
    B --> C[Check deprecated APIs\niOS version compat]
    C --> D[Check Swift concurrency\ndata race safety]
    D --> E[Check HIG compliance\ntap targets / VoiceOver\ndark mode / Dynamic Type]
    E --> F[Report HIGH issues\nblock commit on blocker]
    F --> G([Done]):::done

    classDef start fill:#d0f0d0,stroke:#006600,color:#003300,font-weight:bold
    classDef done  fill:#d0f0d0,stroke:#006600,color:#003300,font-weight:bold
```

---

## Docs, Ship and Memory Skills

### write-user-stories — Generate user story registry

```mermaid
flowchart LR
    A([/write-user-stories]):::start --> B[Read PRD + API\n+ architecture]
    B --> C[Scan codebase\nfor implemented features\nroutes / screens / tests]
    C --> D["Write stories:\nAS [role] I CAN [action]\nSO THAT [benefit]\n+ acceptance criteria\n+ status: Done/Partial/Not started"]
    D --> E[Save\ndocs/product/user-stories.md]
    E --> F([Done]):::done

    classDef start fill:#d0f0d0,stroke:#006600,color:#003300,font-weight:bold
    classDef done  fill:#d0f0d0,stroke:#006600,color:#003300,font-weight:bold
```

---

### write-test-docs — Generate test plan + manual QA checklist

```mermaid
flowchart LR
    A([/write-test-docs]):::start --> B[Read PRD\n+ user-stories\n+ architecture + tests]
    B --> C[Generate test plan\nunit / integration\nedge cases from PRD]
    C --> D[Generate manual QA\nchecklist per user flow\nhappy path + errors\n+ empty + loading]
    D --> E[Write\ndocs/testing/test-plan.md\n+ manual-qa.md]
    E --> F([Done]):::done

    classDef start fill:#d0f0d0,stroke:#006600,color:#003300,font-weight:bold
    classDef done  fill:#d0f0d0,stroke:#006600,color:#003300,font-weight:bold
```

---

### write-project-docs — Generate README + onboarding + deployment docs

```mermaid
flowchart LR
    A([/write-project-docs]):::start --> B[Read CLAUDE.md\n+ architecture\n+ deployment configs]
    B --> C[Write README.md\nhow to run + structure\n+ API overview]
    C --> D[Write docs/onboarding.md\nsetup + workflow + tests]
    D --> E[Write docs/deployment.md\nsteps + env vars + rollback]
    E --> F([Done]):::done

    classDef start fill:#d0f0d0,stroke:#006600,color:#003300,font-weight:bold
    classDef done  fill:#d0f0d0,stroke:#006600,color:#003300,font-weight:bold
```

---

### pre-release-check — Final gate before production

```mermaid
flowchart LR
    A([/pre-release-check]):::start --> B[Read tasks / checklist\nmanual-qa / user-stories\nrollback plan]
    B --> C[Run checks:\ntasks complete?\ntests pass?\nno REPLACE_ME?\ndocs up to date?\nchangelog written?]
    C --> D["⚠️ Translations reminder\n— add them NOW"]
    D --> E{iOS?}
    E -- yes --> F["/discover-apple-check\nApp Store submission review"]
    E -- no  --> G[Print release report\nPASS / FAIL / WARN per check]
    F --> G
    G --> H([Done]):::done

    classDef start fill:#d0f0d0,stroke:#006600,color:#003300,font-weight:bold
    classDef done  fill:#d0f0d0,stroke:#006600,color:#003300,font-weight:bold
```

---

### stash — Pause and save mental state to MemPalace

```mermaid
flowchart LR
    A([/stash]):::start --> B[Detect wing\nfrom pwd]
    B --> C[Collect from conversation:\ntask · open question\ndone in session\npending files · deferred]
    C --> D[Write MemPalace\nstash drawer\nlatest-wins semantics]
    D --> E([Saved\n→ resume with /unstash]):::done

    classDef start fill:#d0f0d0,stroke:#006600,color:#003300,font-weight:bold
    classDef done  fill:#d0f0d0,stroke:#006600,color:#003300,font-weight:bold
```

---

### unstash — Resume stashed task from MemPalace

```mermaid
flowchart LR
    A([/unstash]):::start --> B[Detect wing]
    B --> C[Find newest stash\nin MemPalace\nlatest-wins]
    C --> D{Stash found?}
    D -- no  --> E[Ask: search other wings?]
    D -- yes --> F[Validate pending files\ngit status per path\nlive / committed / missing]
    F --> G[Restore into conversation:\nopen question + done\n+ pending files + deferred]
    G --> H([Resumed]):::done

    classDef start fill:#d0f0d0,stroke:#006600,color:#003300,font-weight:bold
    classDef done  fill:#d0f0d0,stroke:#006600,color:#003300,font-weight:bold
```
