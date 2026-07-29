namespace HcpPortalApi.Application.Services;

public static class DemoClinicalGuidanceComposer
{
    public static string Build(
        string npi,
        string firstName,
        string lastName,
        string email,
        string specialty,
        string organizationName,
        DateTimeOffset createdUtc)
    {
        return $"""
Demo therapy context for the Caldova HCP experience.
Prescriber profile. NPI: {npi}. Name: {firstName} {lastName}. Email: {email}. Specialty: {specialty}. Organization: {organizationName}. Enrollment created: {createdUtc:O}.

Therapy overview:
- Demo therapy: Caldovanib 200 mg oral targeted therapy.
- Intended demo indication: specialty oncology and complex prior-authorization workflows.
- Demo note: this content is synthetic grounding data for the portal experience and should be treated as non-production sample content.

Drug interaction and contraindication guidance:
- Review concomitant use with strong CYP3A4 inhibitors because exposure to Caldovanib may increase; monitor closely or consider dose reduction.
- Review strong CYP3A4 inducers because exposure may decrease and reduce therapy effectiveness.
- Use caution with additional QT-prolonging agents and correct electrolyte abnormalities before initiation.
- Review anticoagulants and antiplatelet agents for additive bleeding risk if the patient has mucosal irritation or thrombocytopenia.
- Contraindication for this demo profile: avoid use in patients with a prior severe hypersensitivity reaction to Caldovanib or formulation excipients.

Dosing and titration guidance:
- Demo starting dose: 200 mg by mouth once daily.
- If tolerated after 14 days, titrate to 300 mg once daily for improved disease control in eligible patients.
- For grade 3 adverse events, hold therapy until recovery and resume at the next lower dose level.
- For moderate hepatic impairment or persistent grade 2 toxicities, consider maintaining the lower dose level.
- Review renal function, hepatic function, weight trends, and concurrent CYP3A-modifying therapy before escalating dose.

Formulary and access guidance:
- Demo formulary status: non-preferred specialty therapy on most commercial plans.
- Prior authorization is typically required with diagnosis confirmation and documentation of previous therapy failure or intolerance.
- Step therapy may require trial of a preferred alternative before approval.
- Dispensing channel is commonly restricted to designated specialty pharmacies.
- Appeals should include specialty rationale, contraindications to alternatives, and supporting chart documentation.
""";
    }
}