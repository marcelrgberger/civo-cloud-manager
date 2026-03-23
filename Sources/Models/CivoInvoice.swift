import Foundation

struct CivoInvoice: Codable, Identifiable, Sendable {
    let id: String
    let invoiceNumber: String?
    let total: Double?
    let status: String?
    let createdAt: String?
    let invoicePeriodStart: String?
    let invoicePeriodEnd: String?

    enum CodingKeys: String, CodingKey {
        case id, total, status
        case invoiceNumber = "invoice_number"
        case createdAt = "created_at"
        case invoicePeriodStart = "invoice_period_start"
        case invoicePeriodEnd = "invoice_period_end"
    }

    var periodDisplay: String {
        guard let start = invoicePeriodStart?.prefix(10),
              let end = invoicePeriodEnd?.prefix(10) else {
            return createdAt?.prefix(10).description ?? "Unknown"
        }
        return "\(start) — \(end)"
    }

    var statusDisplay: String {
        status?.capitalized ?? "Unknown"
    }
}
