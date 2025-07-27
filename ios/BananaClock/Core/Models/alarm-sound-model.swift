import Foundation

enum AlarmSound: String, CaseIterable, Codable {
    case `default` = "default"
    case radar = "radar"
    case beacon = "beacon"
    case signal = "signal"
    case circuit = "circuit"
    case reflection = "reflection"
    case apex = "apex"
    case bulletin = "bulletin"
    case sencha = "sencha"
    case waves = "waves"
    
    var displayName: String {
        switch self {
        case .default: return "Default"
        case .radar: return "Radar"
        case .beacon: return "Beacon"
        case .signal: return "Signal"
        case .circuit: return "Circuit"
        case .reflection: return "Reflection"
        case .apex: return "Apex"
        case .bulletin: return "Bulletin"
        case .sencha: return "Sencha"
        case .waves: return "Waves"
        }
    }
    
    var fileName: String {
        switch self {
        case .default: return "alarm_default"
        case .radar: return "alarm_radar"
        case .beacon: return "alarm_beacon"
        case .signal: return "alarm_signal"
        case .circuit: return "alarm_circuit"
        case .reflection: return "alarm_reflection"
        case .apex: return "alarm_apex"
        case .bulletin: return "alarm_bulletin"
        case .sencha: return "alarm_sencha"
        case .waves: return "alarm_waves"
        }
    }
    
    var url: URL? {
        Bundle.main.url(forResource: fileName, withExtension: "caf")
    }
}
