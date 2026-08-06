import unittest

from ai_qa.doubao_healthcheck import DEFAULT_BASE_URL, build_payload, get_config


class DoubaoHealthcheckTests(unittest.TestCase):
    def test_config_prefers_environment_variables(self):
        config = get_config(
            {"ARK_API_KEY": "environment-key", "ARK_MODEL": "environment-model"},
            {"ARK_API_KEY": "file-key", "ARK_MODEL": "file-model"},
        )
        self.assertEqual(config["api_key"], "environment-key")
        self.assertEqual(config["model"], "environment-model")
        self.assertEqual(config["base_url"], DEFAULT_BASE_URL)

    def test_config_rejects_missing_required_values(self):
        with self.assertRaisesRegex(ValueError, "api_key, model"):
            get_config({}, {})

    def test_payload_is_deterministic_and_uses_requested_model(self):
        payload = build_payload("ep-test-model")
        self.assertEqual(payload["model"], "ep-test-model")
        self.assertEqual(payload["temperature"], 0)
        self.assertEqual(payload["max_tokens"], 40)
        self.assertEqual(len(payload["messages"]), 2)


if __name__ == "__main__":
    unittest.main()
