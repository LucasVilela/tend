import Foundation

/// Names a workout from what was logged, since Log workout has no title field:
/// intensity, time of day and type, e.g. "Easy morning run" or "Hard evening ride".
enum WorkoutTitle {
    static func make(type: WorkoutType, intensity: Intensity, at date: Date, calendar: Calendar = .practices) -> String {
        let hour = calendar.component(.hour, from: date)
        let part = switch hour {
        case 5..<12: "morning"
        case 12..<17: "afternoon"
        case 17..<22: "evening"
        default: "late"
        }
        let noun = switch type {
        case .run: "run"
        case .walk: "walk"
        case .strength: "strength session"
        case .yoga: "yoga"
        case .cycle: "ride"
        case .other: "workout"
        }
        return "\(intensity.name) \(part) \(noun)"
    }
}
