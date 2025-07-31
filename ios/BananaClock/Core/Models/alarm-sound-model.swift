import Foundation

enum AlarmSound: String, CaseIterable, Codable {
    case glassHorizon = "glassHorizon"
    case pulseShift = "pulseShift"
    case morningMonks = "morningMonks"
    case orbitalBounce = "orbitalBounce"
    case woodWake = "woodWake"
    case dreamExit = "dreamExit"
    case loFiLift = "loFiLift"
    case sparkTaps = "sparkTaps"
    case sunGarden = "sunGarden"
    case chronoTriggered = "chronoTriggered"
    case timesUp = "timesUp"
    case timerComplete = "timer_complete"
    
    var displayName: String {
        switch self {
        case .glassHorizon: return "Glass Horizon"
        case .pulseShift: return "Pulse Shift"
        case .morningMonks: return "Morning Monks"
        case .orbitalBounce: return "Orbital Bounce"
        case .woodWake: return "Wood Wake"
        case .dreamExit: return "Dream Exit"
        case .loFiLift: return "Lo-Fi Lift"
        case .sparkTaps: return "Spark Taps"
        case .sunGarden: return "SunGarden"
        case .chronoTriggered: return "ChronoTriggered"
        case .timesUp: return "Time's Up"
        case .timerComplete: return "Timer Complete"
        }
    }
    
    var fileName: String {
        switch self {
        case .glassHorizon: return "alarm_glass_horizon"
        case .pulseShift: return "alarm_pulse_shift"
        case .morningMonks: return "alarm_morning_monks"
        case .orbitalBounce: return "alarm_orbital_bounce"
        case .woodWake: return "alarm_wood_wake"
        case .dreamExit: return "alarm_dream_exit"
        case .loFiLift: return "alarm_lofi_lift"
        case .sparkTaps: return "alarm_spark_taps"
        case .sunGarden: return "alarm_sungarden"
        case .chronoTriggered: return "alarm_chronotriggered"
        case .timesUp: return "alarm_times_up"
        case .timerComplete: return "timer_complete"
        }
    }
    
    var url: URL? {
        // Try multiple file extensions for sound resolution
        let extensions = ["caf", "mp3", "aac"]
        
        for ext in extensions {
            if let url = Bundle.main.url(forResource: fileName, withExtension: ext) {
                return url
            }
        }
        
        return nil
    }
}
