# Skills ecosystem

18 skills, grouped by lifecycle stage. Render natively on GitHub.

```mermaid
flowchart LR
    subgraph SETUP [Setup]
        direction TB
        s1[init-project]
        s2[attach-project]
        s3[analyze-project]
        s4[help]
        s1 ~~~ s2 ~~~ s3 ~~~ s4
    end

    subgraph DISCOVER [Discover and Design]
        direction TB
        d1[discover]
        d2[discover-apple-check]
        d3[seed-mempalace]
        d4[design-sync]
        d5[design-page]
        d1 ~~~ d2 ~~~ d3 ~~~ d4 ~~~ d5
    end

    subgraph BUILD [Build]
        direction TB
        b1[add-feature]
        b2[fix-bug]
        b3[swiftui-pro]
        b1 ~~~ b2 ~~~ b3
    end

    subgraph SHIP [Docs Ship Memory]
        direction TB
        sh1[write-project-docs]
        sh2[write-user-stories]
        sh3[write-test-docs]
        sh4[pre-release-check]
        sh5[compact-save]
        sh1 ~~~ sh2 ~~~ sh3 ~~~ sh4 ~~~ sh5
    end

    classDef cluster fill:#e8eef9,stroke:#3b5998,color:#1c2e5e
    class SETUP,DISCOVER,BUILD,SHIP cluster
```

## Cluster meaning

- **Setup** — старт нового або підхоплення існуючого проекту, плюс довідник скілів
- **Discover and Design** — дослідження ринку, контракт продукту, design system, генерація екранів
- **Build** — лайфцикл фічі / багфіксу + iOS-специфічне ревю
- **Docs, Ship and Memory** — документація, фінальна верифікація перед релізом, кросс-сесійна пам'ять
