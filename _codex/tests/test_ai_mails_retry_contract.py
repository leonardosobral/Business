from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[2]


class AiMailsRetryContract(unittest.TestCase):
    def test_openai_rate_limit_is_distinct_from_configuration_errors(self):
        ai = (ROOT / "administracao/ai-mails/includes/ai.cfm").read_text(encoding="utf-8")
        self.assertIn("status==429", ai)
        self.assertIn('type="AIMail.RateLimit"', ai)
        self.assertIn('type="AIMail.ProviderConfig"', ai)
        self.assertIn("Retry-After", ai)
        self.assertIn("insufficient_quota", ai)

    def test_transient_provider_failure_is_requeued_without_failing_the_cron(self):
        ai = (ROOT / "administracao/ai-mails/includes/ai.cfm").read_text(encoding="utf-8")
        process = (ROOT / "administracao/ai-mails/jobs/process.cfm").read_text(encoding="utf-8")
        self.assertIn('status=rateLimited?"rate_limited":"retry_scheduled"', ai)
        self.assertIn("retry_after_seconds=delay", ai)
        self.assertIn("available_at=now()+(:delay*interval '1 second')", ai)
        self.assertIn("attempts=attempts+1", ai)
        self.assertIn('result.status!="ok"', process)
        self.assertIn("cfheader(statuscode=503)", process)

    def test_rate_limit_backoff_has_a_five_minute_floor_and_six_hour_cap(self):
        ai = (ROOT / "administracao/ai-mails/includes/ai.cfm").read_text(encoding="utf-8")
        self.assertIn("max(300,max(providerRetryAfter,retryDelay))", ai)
        self.assertIn("min(21600", ai)


if __name__ == "__main__":
    unittest.main()
