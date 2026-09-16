# programMoe — Codex Astra + DeepSeek Multi-Agent Setup

ชุดตัวอย่างสำหรับจัด Workflow แบบ Multi-Agent บน **Codex + VS Code** โดยเน้นให้โมเดลที่เก่งกว่ารับหน้าที่คิด/วางแผน และให้โมเดล Flash รับงานย่อยที่แยกขอบเขตได้ชัดเจน

```text
                 GPT-6 Astra
                   medium
                      │
              plan / orchestrate
                      │
        ┌─────────────┼─────────────┐
        │             │             │
   researcher       worker        writer
        │             │             │
        └────── DeepSeek Flash ─────┘
                      │
               results / output
                      │
                 GPT-6 Astra
                   medium
              integrate + verify
                      │
                only if needed
                      ▼
                 GPT-6 Astra
                    high
                 final review
```

> **Let Astra think. Let Flash execute.**

## แนวคิด

- **GPT-6 Astra (medium)** — Root / Orchestrator: วิเคราะห์โจทย์ วางแผน แบ่งงาน รวมผล และตรวจสอบ
- **DeepSeek Flash** — Worker: research, coding/debugging และงานเขียนที่กำหนดขอบเขตได้
- **GPT-6 Astra (high)** — ใช้เฉพาะ Final Review สำหรับ architecture, security, data integrity หรืองานที่มีความเสี่ยงสูง

## เริ่มต้นใช้งาน

อ่านคู่มือติดตั้งฉบับเต็มที่:

👉 [docs/INSTALL-CODEX-ASTRA-DEEPSEEK.md](docs/INSTALL-CODEX-ASTRA-DEEPSEEK.md)

ไฟล์สำคัญในโปรเจกต์:

```text
.
├── AGENTS.md
├── .codex/
│   └── agents/
│       └── final-reviewer.toml
├── docs/
│   └── INSTALL-CODEX-ASTRA-DEEPSEEK.md
└── scripts/
    └── deepseek-agent.ps1
```

## ความปลอดภัย

ห้าม commit API key ลง GitHub เด็ดขาด ให้เก็บ `DEEPSEEK_API_KEY` ไว้ใน Environment Variable ของเครื่องเท่านั้น

## เอกสารอ้างอิง

- OpenAI Codex: https://github.com/openai/codex
- OpenAI ChatGPT Work & Codex: https://help.openai.com/en/articles/20001275/
- DeepSeek + Codex: https://api-docs.deepseek.com/quick_start/agent_integrations/codex/
- DeepSeek Responses API: https://api-docs.deepseek.com/guides/responses_api/
