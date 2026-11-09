import SwiftData
import SwiftUI

/// Answer a guided template (or edit a stored entry). Saves even with some answers empty, not all.
struct AnswerTemplateSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    private let name: String
    private let questions: [String]
    private let date: Date
    private let entry: GuidedEntry?
    private let original: [String]

    @State private var answers: [String]
    @State private var confirmingClose = false

    init(template: GuidedTemplate) {
        name = template.name
        questions = template.questions
        date = .now
        entry = nil
        original = Array(repeating: "", count: template.questions.count)
        _answers = State(initialValue: original)
    }

    init(entry: GuidedEntry) {
        let ordered = entry.orderedAnswers
        name = entry.templateName
        questions = ordered.map(\.question)
        date = entry.createdAt
        self.entry = entry
        original = ordered.map(\.answer)
        _answers = State(initialValue: original)
    }

    private func isAnswered(_ text: String) -> Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var answeredCount: Int { answers.filter(isAnswered).count }

    var body: some View {
        SheetScaffold {
            SheetHeader(onClose: close) {
                Text(Formats.dateAndTime(date))
                    .textStyle(Theme.Font.caption)
                    .foregroundStyle(Theme.textTertiary)
            }
        } content: {
            VStack(alignment: .leading, spacing: 18) {
                Text(name)
                    .textStyle(Theme.Font.title)
                    .foregroundStyle(Theme.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        ForEach(answers.indices, id: \.self) { i in
                            Capsule()
                                .fill(isAnswered(answers[i]) ? Practice.journal.color : Theme.track)
                                .frame(height: 3)
                        }
                    }
                    Text("\(answeredCount) of \(questions.count)")
                        .textStyle(Theme.Font.micro)
                        .foregroundStyle(Theme.textTertiary)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(answeredCount) of \(questions.count) answered")
                .animation(.easeOut(duration: 0.2), value: answeredCount)
            }
            ForEach(questions.indices, id: \.self) { i in
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("\(i + 1)")
                            .textStyle(Theme.Font.caption)
                            .foregroundStyle(Practice.journal.color)
                        Text(questions[i])
                            .textStyle(Theme.Font.prompt, monospacedDigits: false)
                            .foregroundStyle(Theme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .accessibilityElement(children: .combine)
                    UnderlinedField(placeholder: "Your answer…", text: $answers[i],
                                    style: TextStyleToken(size: 16, lineHeight: 24, weight: 400, tracking: 0),
                                    accent: Practice.journal.color, lineLimit: 2...12, minHeight: 52)
                        .padding(.leading, 22)
                }
            }
        } footer: {
            PrimaryButton(title: "Save answers", color: Practice.journal.color, enabled: answeredCount > 0, action: save)
        }
        .confirmationDialog("Discard your answers?", isPresented: $confirmingClose, titleVisibility: .visible) {
            Button("Discard", role: .destructive) { dismiss() }
            Button("Keep writing", role: .cancel) {}
        }
        .interactiveDismissDisabled(answers != original)
    }

    private func close() {
        if answers != original && answers.contains(where: isAnswered) { confirmingClose = true } else { dismiss() }
    }

    private func save() {
        if let entry {
            for answer in entry.answers where answer.order < answers.count {
                answer.answer = answers[answer.order]
            }
        } else {
            let newEntry = GuidedEntry(createdAt: date, templateName: name)
            context.insert(newEntry)
            for (i, question) in questions.enumerated() {
                let answer = GuidedAnswer(order: i, question: question, answer: answers[i])
                context.insert(answer)
                answer.entry = newEntry
            }
        }
        try? context.save()
        dismiss()
    }
}
