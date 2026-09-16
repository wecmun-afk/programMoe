# วิธีติดตั้ง Codex + GPT-6 Astra + DeepSeek Flash บน VS Code

คู่มือนี้ใช้แนวคิด **Astra คิด / Flash ลงมือทำ** โดยให้ GPT-6 Astra เป็นตัวหลักสำหรับวางแผนและตรวจงาน แล้วเรียก DeepSeek Flash เป็น worker แยกผ่าน `codex exec` สำหรับงานที่กำหนดขอบเขตได้ชัดเจน

> แนวทางนี้ตั้งใจแยก provider ของ parent และ worker ให้ชัดเจน จึงไม่ต้องพึ่งการสลับ provider ภายใน native subagent เดียวกัน

## 1) สิ่งที่ต้องมี

- Windows 10/11
- VS Code
- Node.js + npm
- Codex extension สำหรับ VS Code
- Codex CLI รุ่นล่าสุด
- บัญชี OpenAI/ChatGPT ที่ใช้งานโมเดล Astra ได้
- DeepSeek API key

## 2) ติดตั้ง Codex CLI

เปิด PowerShell แล้วรัน:

```powershell
npm install -g @openai/codex@latest
codex --version
```

จากนั้นล็อกอิน:

```powershell
codex login
```

ใน VS Code ให้ติดตั้ง extension ของ Codex/OpenAI แล้วเปิดโฟลเดอร์โปรเจกต์ที่ต้องการทำงาน

## 3) ตั้งค่า DeepSeek API key

PowerShell:

```powershell
setx DEEPSEEK_API_KEY "YOUR_DEEPSEEK_API_KEY"
```

ปิด VS Code/Terminal แล้วเปิดใหม่ เพื่อให้ process ใหม่เห็น Environment Variable

> ห้ามใส่ API key ลงใน `config.toml`, source code หรือ commit ขึ้น GitHub

## 4) ตั้งค่า Codex

เปิดไฟล์:

```text
%USERPROFILE%\.codex\config.toml
```

ตัวอย่าง:

```toml
model = "gpt-6-astra"
model_reasoning_effort = "medium"
approval_policy = "on-request"
sandbox_mode = "workspace-write"

[agents]
enabled = true
max_concurrent_threads_per_session = 4

[model_providers.deepseek]
name = "DeepSeek"
base_url = "https://api.deepseek.com"
env_key = "DEEPSEEK_API_KEY"
wire_api = "responses"
requires_openai_auth = false

[agents.final_reviewer]
description = "High-reasoning Astra architecture and final review agent."
config_file = "./agents/final-reviewer.toml"
```

> ถ้าบัญชี Codex ของคุณแสดงชื่อ/ID ของ Astra แตกต่างจากตัวอย่าง ให้ใช้ model ID ที่ Codex แสดงให้บัญชีของคุณ

Codex ปัจจุบันรองรับส่วน `[agents]`, การกำหนดจำนวน concurrent threads และ custom agent role ที่อ้าง `config_file` ได้

## 5) ทดสอบ DeepSeek ผ่าน Codex

รันจาก PowerShell:

```powershell
codex exec `
  -c 'model_provider="deepseek"' `
  -c 'model="deepseek-flash"' `
  "Reply only with: DeepSeek worker OK"
```

หาก provider/model ในบัญชี DeepSeek ของคุณใช้ alias อื่น ให้แทน `deepseek-flash` ด้วย model ID ที่บัญชีของคุณรองรับ

## 6) ติดตั้ง Worker Script

ใน repository นี้มีไฟล์:

```text
scripts/deepseek-agent.ps1
```

คัดลอกไปที่:

```text
%USERPROFILE%\.codex\bin\deepseek-agent.ps1
```

ใช้คำสั่ง:

```powershell
New-Item -ItemType Directory -Force "$HOME\.codex\bin"
Copy-Item .\scripts\deepseek-agent.ps1 "$HOME\.codex\bin\deepseek-agent.ps1"
```

ทดสอบ researcher:

```powershell
powershell -ExecutionPolicy Bypass `
  -File "$HOME\.codex\bin\deepseek-agent.ps1" `
  -Role researcher `
  -Task "Analyze this repository and summarize the important modules."
```

ทดสอบ worker:

```powershell
powershell -ExecutionPolicy Bypass `
  -File "$HOME\.codex\bin\deepseek-agent.ps1" `
  -Role worker `
  -Task "Inspect the current project and suggest a small safe refactor."
```

Role ที่มีให้:

- `researcher` — อ่าน/สำรวจ/วิเคราะห์ โดยใช้ sandbox แบบ read-only
- `worker` — เขียนโค้ด แก้บั๊ก refactor และ test โดยใช้ workspace-write
- `writer` — เขียน docs/summary โดยใช้ read-only

## 7) ติดตั้ง Astra High Final Reviewer

ใน repository มี:

```text
.codex\agents\final-reviewer.toml
```

คัดลอกไปไว้ที่ Codex home:

```powershell
New-Item -ItemType Directory -Force "$HOME\.codex\agents"
Copy-Item .\.codex\agents\final-reviewer.toml "$HOME\.codex\agents\final-reviewer.toml"
```

Reviewer นี้ตั้งเป็น read-only และใช้ reasoning สูง เพื่อเน้นตรวจ:

- architecture
- correctness
- security
- concurrency
- data integrity
- regression
- performance
- missing tests

## 8) ใช้ AGENTS.md ในโปรเจกต์

Repository นี้มี `AGENTS.md` ที่ root แล้ว เมื่อเปิดโปรเจกต์ด้วย Codex ให้สั่งประมาณนี้:

```text
Implement this feature using the orchestration rules in AGENTS.md.

Astra should plan first.
Delegate bounded research/coding/writing work to DeepSeek workers.
Then Astra must inspect the results, integrate compatible changes, and run tests.
Use the high reviewer only when architecture, security, data integrity,
or another high-risk concern justifies it.
```

Workflow ที่ต้องการคือ:

```text
GPT-6 Astra Medium
        │
        ├── plan / orchestrate
        │
        ├── DeepSeek researcher
        ├── DeepSeek worker
        └── DeepSeek writer
                 │
                 ▼
GPT-6 Astra Medium
integrate + verify + test
                 │
          only if needed
                 ▼
GPT-6 Astra High
final review
```

## 9) ตัวอย่างการเรียก Worker โดยตรง

Research:

```powershell
powershell -ExecutionPolicy Bypass -File "$HOME\.codex\bin\deepseek-agent.ps1" -Role researcher -Task "Find all authentication-related files and summarize the current flow."
```

Coding:

```powershell
powershell -ExecutionPolicy Bypass -File "$HOME\.codex\bin\deepseek-agent.ps1" -Role worker -Task "Add validation to the login handler and run relevant tests."
```

Writing:

```powershell
powershell -ExecutionPolicy Bypass -File "$HOME\.codex\bin\deepseek-agent.ps1" -Role writer -Task "Create a concise README section explaining the authentication flow."
```

## 10) Troubleshooting

### `codex` command not found

ตรวจ Node/npm ก่อน:

```powershell
node --version
npm --version
```

แล้วติดตั้ง Codex CLI ใหม่:

```powershell
npm install -g @openai/codex@latest
```

### ไม่พบ `DEEPSEEK_API_KEY`

ตรวจว่าเปิด terminal ใหม่หลัง `setx` แล้ว และทดสอบ:

```powershell
echo $env:DEEPSEEK_API_KEY
```

### DeepSeek ตอบว่า model ไม่รองรับ

เปลี่ยนค่า `model="deepseek-flash"` ใน command/script ให้ตรงกับ model ID ที่ DeepSeek เปิดให้บัญชีของคุณ

### Astra ใช้งานไม่ได้

ตรวจ model ที่ Codex account/workspace ของคุณเปิดให้ใช้ แล้วแก้ `model = "..."` ใน `%USERPROFILE%\.codex\config.toml` ให้ตรงกับ model ID ที่ระบบแสดง

## ไฟล์ใน repository นี้

```text
programMoe/
├── README.md
├── AGENTS.md
├── .codex/
│   └── agents/
│       └── final-reviewer.toml
├── docs/
│   └── INSTALL-CODEX-ASTRA-DEEPSEEK.md
└── scripts/
    └── deepseek-agent.ps1
```

## References

- OpenAI Codex repository: https://github.com/openai/codex
- OpenAI ChatGPT Work and Codex: https://help.openai.com/en/articles/20001275/
- DeepSeek Codex integration: https://api-docs.deepseek.com/quick_start/agent_integrations/codex/
- DeepSeek Responses API: https://api-docs.deepseek.com/guides/responses_api/
