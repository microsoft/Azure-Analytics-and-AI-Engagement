# Connect the Fabric Data Agent knowledge source (manual step)

The deploy script builds the **AI Search** knowledge source (Joe's documents) and
the knowledge base automatically. It does **not** create the **Fabric Data Agent**
knowledge source, because the SDK-created Fabric source fails to connect at query
time (`connection failed`), while the **portal-connected** one works. So we connect
Fabric once, in the portal, after the deploy.

> The deploy is safe to re-run: the knowledge-base step **preserves** a
> manually-connected Fabric source. You only need to redo this after a full
> `reset_foundry.py` (which deletes the knowledge base).

## Prerequisites

- `python deploy_foundry_agents.py` has completed (KB `fsi-knowledge-base` exists
  with the `fsi-customer-data` source).
- The Fabric Data Agent is **published** and you can query it in Fabric.
  - Workspace ID: `ded5294c-c3fe-408c-a3c4-99fd93ffb29f`
  - Data Agent ID: `febef30c-df4f-42e6-a1f5-2350b5635261`

## Steps (Foundry portal)

1. Go to **Build → Knowledge** and open **`fsi-knowledge-base`**.
2. Under **Knowledge sources (Foundry IQ)**, click **Add sources** and choose the
   **Fabric IQ (Data agent)** source type.
3. Select the workspace (`FSI_Data_Agent` / `ded5294c-…`) and the published
   **Data Agent** (`febef30c-…`).
4. **Name the source `fsi-financial-data-agent`.** The exact name matters:
   - the deploy's KB step preserves it across redeploys, and
   - the KB retrieval instructions route financial questions to it.
   Give it a description mentioning *financial evaluation — income, expenses,
   liabilities, savings, debt-to-income, credit score, risk indicators* so the KB
   planner routes financial queries here.
5. **Save** the knowledge base. Confirm both sources show a healthy/Active status
   (not stuck on *Loading…*).

## Verify

In **Agents**, open **Financial-Resilience-Insight-Agent** → **Playground**, and ask:

> Evaluate the financial resilience of customer Joe.

Expect a grounded answer (income, DTI, savings, risk indicators) with no
`connection failed` error. If the agent connects but reports it *can't find Joe*,
the connection is fine — that's a retrieval/data question to tune separately
(query phrasing, or the published Data Agent's data), not a wiring failure.

## Re-running the deploy

Safe. `python deploy_foundry_agents.py` keeps `fsi-financial-data-agent` on the KB.
Only after `python reset_foundry.py` (full teardown) do you repeat these steps.

## (Advanced) Let the script create it instead

If a future SDK/preview line fixes the Fabric source connection, set
`FABRIC_KS_MODE=script` in `.env` (with `FABRIC_WORKSPACE_ID` / `FABRIC_DATA_AGENT_ID`
populated) and the deploy will create the Fabric source itself. Default is `manual`.
