"""Offline package checks: Python 3.11+, no API calls or third-party packages."""
import json
from pathlib import Path
import re
import tomllib
import unittest

ROOT = Path(__file__).resolve().parents[1]

class PackageTests(unittest.TestCase):
    def test_toml_and_root(self):
        for path in ROOT.rglob('*.toml'):
            with path.open('rb') as stream:
                tomllib.load(stream)
        config = tomllib.loads((ROOT / '.codex/config.example.toml').read_text())
        self.assertEqual(config['model'], 'gpt-6-astra')
        self.assertEqual(config['model_provider'], 'openai')
        self.assertEqual(config['model_reasoning_effort'], 'medium')
        self.assertNotIn('model_catalog_json', config)
        self.assertEqual(config['model_providers']['deepseek']['env_key'], 'DEEPSEEK_API_KEY')

    def test_reviewer(self):
        config = tomllib.loads((ROOT / '.codex/agents/final-reviewer.toml').read_text())
        for key in ('name', 'description', 'developer_instructions'):
            self.assertTrue(config[key])
        self.assertEqual(config['sandbox_mode'], 'read-only')
        self.assertEqual(config['model_reasoning_effort'], 'high')

    def test_catalog(self):
        model, = json.loads((ROOT / 'config/deepseek-models.json').read_text())['models']
        self.assertEqual(model['slug'], 'deepseek-flash')
        self.assertEqual(model['input_modalities'], ['text', 'image'])
        self.assertEqual({r['effort'] for r in model['supported_reasoning_levels']}, {'low', 'high', 'max'})
        for key in ('shell_type', 'visibility', 'priority', 'supported_in_api',
                    'support_verbosity', 'truncation_policy', 'experimental_supported_tools'):
            self.assertIn(key, model)
        self.assertTrue(model['model_messages']['instructions_template'])

    def test_document_links(self):
        for path in ROOT.rglob('*.md'):
            for link in re.findall(r'\]\(([^)]+)\)', path.read_text(encoding='utf-8')):
                if '://' in link or link.startswith('#'):
                    continue
                target = (path.parent / link.split('#', 1)[0]).resolve()
                self.assertTrue(target.is_relative_to(ROOT), f'Escaping link: {link}')
                self.assertTrue(target.exists(), f'Broken link in {path.name}: {link}')

    def test_no_obvious_credentials(self):
        patterns = [r'sk-[A-Za-z0-9_-]{24,}', r'ghp_[A-Za-z0-9]{30,}',
                    r'github_pat_[A-Za-z0-9_]{30,}', r'-----BEGIN [A-Z ]*PRIVATE KEY-----']
        for path in ROOT.rglob('*'):
            if not path.is_file() or any(part in {'.git', '__pycache__', 'node_modules'}
                                         for part in path.relative_to(ROOT).parts):
                continue
            text = path.read_text(encoding='utf-8')
            for pattern in patterns:
                self.assertIsNone(re.search(pattern, text), f'Credential-like text in {path}')

if __name__ == '__main__':
    unittest.main(verbosity=2)
