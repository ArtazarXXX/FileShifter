import SwiftUI

public struct DocumentMetadata: Sendable {
    public let fileName: String
    public let fileSizeString: String
    public let formatName: String
    public let icon: String
    public let pageCount: Int?
    public let wordCount: Int?
    public let charCount: Int?
    public let linesCount: Int?
    public let readingTimeMinutes: Double?
    public let isEncrypted: Bool?
    public let hasTextLayer: Bool?
    public let syntaxValid: Bool?
    public let note: String?
}

public struct DocumentInfoCardView: View {
    public let meta: DocumentMetadata
    
    public var body: some View {
        GlassCard(width: 300) {
            VStack(alignment: .leading, spacing: 10) {
                // Header
                HStack(spacing: 8) {
                    Image(systemName: meta.icon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.indigo)
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text(meta.fileName)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(white: 0.12))
                            .lineLimit(1)
                        
                        Text("\(meta.formatName) • \(meta.fileSizeString)")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(Color(white: 0.4))
                    }
                    
                    Spacer()
                    
                    if let valid = meta.syntaxValid {
                        HStack(spacing: 3) {
                            Image(systemName: valid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .font(.system(size: 9))
                            Text(valid ? "Валиден" : "Ошибка")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3.5)
                        .background(Capsule().fill(valid ? Color.green.opacity(0.18) : Color.red.opacity(0.18)))
                        .foregroundStyle(valid ? Color.green : Color.red)
                    } else if let pages = meta.pageCount {
                        HStack(spacing: 3) {
                            Image(systemName: "doc.plaintext")
                                .font(.system(size: 9))
                            Text("\(pages) стр.")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3.5)
                        .background(Capsule().fill(Color.indigo.opacity(0.18)))
                        .foregroundStyle(.indigo)
                    }
                }
                
                Divider()
                    .background(Color.black.opacity(0.1))
                
                // Grid specs
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    if let pages = meta.pageCount {
                        InfoCellView(icon: "doc.on.doc", title: "Страниц", value: "\(pages)", hasCardBackground: true)
                    }
                    if let words = meta.wordCount {
                        InfoCellView(icon: "text.word.spacing", title: "Слов", value: "\(words)", hasCardBackground: true)
                    }
                    if let chars = meta.charCount {
                        InfoCellView(icon: "character.cursor.ibeam", title: "Символов", value: "\(chars)", hasCardBackground: true)
                    }
                    if let lines = meta.linesCount {
                        InfoCellView(icon: "text.alignleft", title: "Строк / Записей", value: "\(lines)", hasCardBackground: true)
                    }
                    if let reading = meta.readingTimeMinutes {
                        let readingStr = reading < 1.0 ? "< 1 мин" : String(format: "%.1f мин", reading)
                        InfoCellView(icon: "clock", title: "Время чтения", value: readingStr, hasCardBackground: true)
                    }
                    if let textLayer = meta.hasTextLayer {
                        InfoCellView(icon: "text.viewfinder", title: "Текстовый слой", value: textLayer ? "Есть (текст)" : "Скан (без текста)", hasCardBackground: true)
                    }
                    if let encrypted = meta.isEncrypted {
                        InfoCellView(icon: encrypted ? "lock.fill" : "lock.open.fill", title: "Защита", value: encrypted ? "Пароль" : "Без пароля", hasCardBackground: true)
                    }
                    InfoCellView(icon: "internaldrive", title: "Размер", value: meta.fileSizeString, hasCardBackground: true)
                }
                
                if let note = meta.note, !note.isEmpty {
                    Text(note)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(white: 0.45))
                        .padding(.top, 2)
                }
            }
        }
    }
}
