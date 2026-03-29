import Foundation

struct NoteDraftTemplate: Sendable {
    let title: String
    let bodyMarkdown: String
    let noteType: NoteType
}

enum FamilyEmergencyPlanTemplate {
    static func draft() -> NoteDraftTemplate {
        NoteDraftTemplate(
            title: "Family Emergency Plan",
            bodyMarkdown: """
            ## Household Members
            - Adults and children:
            - Daily schedules:
            - Mobility or communication needs:

            ## Primary Meeting Point
            - Location:
            - Address or landmark:
            - When to use it:

            ## Backup Meeting Point
            - Location:
            - Address or landmark:
            - When to switch to it:

            ## Out-Of-Area Contact
            - Name:
            - Phone:
            - How everyone checks in:

            ## Medical Needs
            - Prescriptions and refill dates:
            - Allergies:
            - Equipment or support needs:

            ## Pet Plan
            - Food and medication:
            - Carrier or leash location:
            - Backup caregiver:

            ## Utility Shutoffs
            - Water shutoff:
            - Gas shutoff:
            - Electrical panel:

            ## Go-Bag And Supply Locations
            - Adult go-bags:
            - Kids or dependent supplies:
            - Vehicle kit:

            ## Important Documents
            - IDs and insurance:
            - Medical records:
            - Local copies stored:
            """,
            noteType: .familyPlan
        )
    }
}
