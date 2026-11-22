# 2026-11-22 — DASHSCOPE_API_KEY needed on both machines

The Alibaba Qwen4-Max provider config is in place and linked
(`pi/.pi/agent/models.json`), but no machine has a real key yet.

Steps, on EACH machine (woodlawn and linden):

1. Create an API key in the Alibaba Cloud Model Studio console
   (alibabacloud.com -> Model Studio -> API keys). Check the console
   for new-account free quotas.
2. Add `export DASHSCOPE_API_KEY=sk-...` to the shell profile
   (~/.profile / ~/.zprofile). Never commit the key.
3. Open a new shell, verify:
   `pi auth check --provider alibaba --json` -> `"status":"ready"`.
4. Region check: the config uses the international endpoint
   (`dashscope-intl.aliyuncs.com`). A Beijing-region key needs
   `https://dashscope.aliyuncs.com/compatible-mode/v1` instead — if the
   two machines end up with different regions, use a second provider
   block in models.json rather than switching the shared one.

Also from the 20261120 brief: `models.json` `cost.cacheRead/cacheWrite`
are placeholders (set to input price); correct with real cache pricing.
