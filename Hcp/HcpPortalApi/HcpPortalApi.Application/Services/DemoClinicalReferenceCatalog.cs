namespace HcpPortalApi.Application.Services;

public static class DemoClinicalReferenceCatalog
{
    public sealed record ClinicalReferenceItem(
        string Key,
        string Title,
        string ContentText);

    public static IReadOnlyList<ClinicalReferenceItem> Build() =>
    [
        new ClinicalReferenceItem(
            "interaction-review-checklist",
            "Clinical interaction and contraindication review checklist",
            """
Use this checklist when asked which clinically significant drug interactions and contraindications should be reviewed before starting a therapy.

Interaction review priorities:
- Strong CYP inhibitors and inducers that can increase toxicity or reduce therapeutic exposure.
- Additive QT prolongation risk when combining with other QT-prolonging medications.
- Concomitant anticoagulants or antiplatelet agents where bleeding risk may be clinically significant.
- Central nervous system depressants, serotonergic combinations, or other class-specific additive toxicities as appropriate.
- Nephrotoxic or hepatotoxic co-medications that increase organ injury risk.

Contraindication review priorities:
- Prior severe hypersensitivity to active ingredient or excipients.
- Pregnancy, lactation, or reproductive safety restrictions per labeling.
- Severe hepatic or renal impairment where therapy is contraindicated or requires specialist review.
- Uncontrolled baseline cardiac risk factors when therapy has arrhythmia or QT concerns.
- Active serious infection or immunosuppression concerns for therapies with immune effects.

Minimum data required before final recommendation:
- Therapy name and formulation, intended dose, indication.
- Active medication list including OTC and supplements.
- Renal and hepatic status, pregnancy status, and major comorbidities.
- Most recent ECG/electrolytes when QT risk is relevant.
"""),
        new ClinicalReferenceItem(
            "caldovanib-safety-profile",
            "Caldovanib demo safety profile",
            """
Demo therapy safety profile for Caldovanib (synthetic demo content, not production guidance).

Key interactions to review:
- Strong CYP3A4 inhibitors may increase Caldovanib exposure and adverse-event risk; monitor closely and consider dose reduction.
- Strong CYP3A4 inducers may reduce exposure and compromise efficacy; avoid when possible.
- Additional QT-prolonging agents may increase arrhythmia risk; correct potassium and magnesium before initiation.
- Concurrent anticoagulants and antiplatelet agents can increase clinically relevant bleeding risk in susceptible patients.

Key contraindications to review:
- Severe hypersensitivity history to Caldovanib or formulation excipients.
- Persistently prolonged baseline QTc or uncontrolled electrolyte disturbance until corrected.
- Severe hepatic dysfunction where risk outweighs expected benefit.

Monitoring reminders:
- Review baseline medication reconciliation before first dose and at every dose change.
- Reassess interaction risk when new prescriptions are added.
- Monitor hepatic function and ECG trend when clinically indicated.
""")
    ];
}
