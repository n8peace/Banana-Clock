import Foundation

// MARK: - Enhanced Holiday System

struct Holiday: Codable {
    let name: String
    let emoji: String
    let month: Int
    let day: Int
    let country: String
    let type: HolidayType
    let year: Int? // nil for recurring holidays, specific year for one-time events
    
    enum HolidayType: String, Codable {
        case fixed = "fixed"           // Same date every year (e.g., Christmas)
        case floating = "floating"     // Moves based on rules (e.g., Easter)
        case lunar = "lunar"           // Based on lunar calendar
        case observed = "observed"     // Observed on different date if falls on weekend
    }
    
    var isToday: Bool {
        let calendar = Calendar.current
        let today = Date()
        return calendar.component(.month, from: today) == month &&
               calendar.component(.day, from: today) == day
    }
    
    var isTomorrow: Bool {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        return calendar.component(.month, from: tomorrow) == month &&
               calendar.component(.day, from: tomorrow) == day
    }
}

struct DynamicHolidayCalculator {
    
    // MARK: - Easter Calculation (Gregorian)
    static func easterDate(for year: Int) -> Date {
        // Meeus/Jones/Butcher algorithm
        let a = year % 19
        let b = year / 100
        let c = year % 100
        let d = b / 4
        let e = b % 4
        let f = (b + 8) / 25
        let g = (b - f + 1) / 3
        let h = (19 * a + b - d - g + 15) % 30
        let i = c / 4
        let k = c % 4
        let l = (32 + 2 * e + 2 * i - h - k) % 7
        let m = (a + 11 * h + 22 * l) / 451
        let month = (h + l - 7 * m + 114) / 31
        let day = ((h + l - 7 * m + 114) % 31) + 1
        
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        
        return Calendar.current.date(from: components) ?? Date()
    }
    
    // MARK: - Chinese New Year (Lunar)
    static func chineseNewYear(for year: Int) -> Date {
        // Simplified calculation - in practice you'd use a proper lunar calendar library
        // This is an approximation based on typical dates
        let baseDates: [Int: (month: Int, day: Int)] = [
            2024: (2, 10), 2025: (1, 29), 2026: (2, 17), 2027: (2, 6), 2028: (1, 26),
            2029: (2, 13), 2030: (2, 3), 2031: (1, 23), 2032: (2, 11), 2033: (1, 31)
        ]
        
        if let date = baseDates[year] {
            var components = DateComponents()
            components.year = year
            components.month = date.month
            components.day = date.day
            return Calendar.current.date(from: components) ?? Date()
        }
        
        // Fallback calculation (approximate)
        let baseYear = 2024
        let baseDate = Calendar.current.date(from: DateComponents(year: 2024, month: 2, day: 10)) ?? Date()
        let yearsDiff = year - baseYear
        let daysToAdd = yearsDiff * 365 + (yearsDiff / 4) // Approximate lunar cycle
        return Calendar.current.date(byAdding: .day, value: daysToAdd, to: baseDate) ?? Date()
    }
    
    // MARK: - Islamic Holidays (Hijri Calendar)
    static func ramadanStart(for year: Int) -> Date {
        // Simplified - in practice use proper Hijri calendar
        let baseDates: [Int: (month: Int, day: Int)] = [
            2024: (3, 10), 2025: (2, 28), 2026: (2, 18), 2027: (2, 8), 2028: (1, 28)
        ]
        
        if let date = baseDates[year] {
            var components = DateComponents()
            components.year = year
            components.month = date.month
            components.day = date.day
            return Calendar.current.date(from: components) ?? Date()
        }
        
        // Fallback
        return Calendar.current.date(from: DateComponents(year: year, month: 3, day: 10)) ?? Date()
    }
    
    static func eidAlFitr(for year: Int) -> Date {
        // Ramadan + 29-30 days
        let ramadanStart = self.ramadanStart(for: year)
        return Calendar.current.date(byAdding: .day, value: 29, to: ramadanStart) ?? Date()
    }
    
    static func eidAlAdha(for year: Int) -> Date {
        // Approximately 2 months after Eid al-Fitr
        let eidAlFitr = self.eidAlFitr(for: year)
        return Calendar.current.date(byAdding: .month, value: 2, to: eidAlFitr) ?? Date()
    }
    
    // MARK: - Jewish Holidays (Hebrew Calendar)
    static func roshHashanah(for year: Int) -> Date {
        // Simplified - typically September/October
        let baseDates: [Int: (month: Int, day: Int)] = [
            2024: (10, 3), 2025: (9, 23), 2026: (10, 12), 2027: (10, 2), 2028: (9, 21)
        ]
        
        if let date = baseDates[year] {
            var components = DateComponents()
            components.year = year
            components.month = date.month
            components.day = date.day
            return Calendar.current.date(from: components) ?? Date()
        }
        
        // Fallback
        return Calendar.current.date(from: DateComponents(year: year, month: 9, day: 25)) ?? Date()
    }
    
    static func yomKippur(for year: Int) -> Date {
        // 10 days after Rosh Hashanah
        let roshHashanah = self.roshHashanah(for: year)
        return Calendar.current.date(byAdding: .day, value: 10, to: roshHashanah) ?? Date()
    }
    
    // MARK: - Hindu Holidays
    static func diwali(for year: Int) -> Date {
        // Typically October/November
        let baseDates: [Int: (month: Int, day: Int)] = [
            2024: (11, 1), 2025: (10, 21), 2026: (11, 8), 2027: (10, 29), 2028: (11, 17)
        ]
        
        if let date = baseDates[year] {
            var components = DateComponents()
            components.year = year
            components.month = date.month
            components.day = date.day
            return Calendar.current.date(from: components) ?? Date()
        }
        
        // Fallback
        return Calendar.current.date(from: DateComponents(year: year, month: 11, day: 5)) ?? Date()
    }
    
    // MARK: - US Federal Holidays (Floating)
    static func laborDay(for year: Int) -> Date {
        // First Monday in September
        var components = DateComponents()
        components.year = year
        components.month = 9
        components.day = 1
        
        guard let firstOfSeptember = Calendar.current.date(from: components) else {
            return Calendar.current.date(from: DateComponents(year: year, month: 9, day: 2)) ?? Date()
        }
        
        let weekday = Calendar.current.component(.weekday, from: firstOfSeptember)
        let mondayValue = 2 // Monday = 2 in Calendar weekday values
        
        var daysToAdd = 0
        if weekday == mondayValue {
            // September 1st is already Monday
            daysToAdd = 0
        } else if weekday == 1 {
            // September 1st is Sunday, next Monday is the 2nd
            daysToAdd = 1
        } else {
            // September 1st is Tue-Sat, find next Monday
            daysToAdd = (7 - weekday + mondayValue)
        }
        
        return Calendar.current.date(byAdding: .day, value: daysToAdd, to: firstOfSeptember) ?? firstOfSeptember
    }
    
    static func memorialDay(for year: Int) -> Date {
        // Last Monday in May
        var components = DateComponents()
        components.year = year
        components.month = 6  // Start from June 1st
        components.day = 1
        
        guard let firstOfJune = Calendar.current.date(from: components) else {
            return Calendar.current.date(from: DateComponents(year: year, month: 5, day: 27)) ?? Date()
        }
        
        // Go back to find the last Monday in May
        let weekday = Calendar.current.component(.weekday, from: firstOfJune)
        let mondayValue = 2 // Monday = 2
        
        var daysBack = 1 // Start from May 31st
        if weekday == mondayValue {
            daysBack = 1 // June 1st is Monday, so May 31st is Sunday, go back to May 25th
            daysBack = 7
        } else {
            daysBack = weekday - mondayValue + 1
            if daysBack <= 0 { daysBack += 7 }
        }
        
        return Calendar.current.date(byAdding: .day, value: -daysBack, to: firstOfJune) ?? 
               Calendar.current.date(from: DateComponents(year: year, month: 5, day: 27)) ?? Date()
    }
    
    static func thanksgiving(for year: Int) -> Date {
        // Fourth Thursday in November
        var components = DateComponents()
        components.year = year
        components.month = 11
        components.day = 1
        
        guard let firstOfNovember = Calendar.current.date(from: components) else {
            return Calendar.current.date(from: DateComponents(year: year, month: 11, day: 28)) ?? Date()
        }
        
        let weekday = Calendar.current.component(.weekday, from: firstOfNovember)
        let thursdayValue = 5 // Thursday = 5
        
        var daysToAdd = 0
        if weekday <= thursdayValue {
            // First Thursday is in the first week
            daysToAdd = (thursdayValue - weekday) + 21 // Add 3 weeks to get the fourth Thursday
        } else {
            // First Thursday is in the second week  
            daysToAdd = (7 - weekday + thursdayValue) + 21 // Add 3 weeks to get the fourth Thursday
        }
        
        return Calendar.current.date(byAdding: .day, value: daysToAdd, to: firstOfNovember) ?? firstOfNovember
    }

    // MARK: - Buddhist Holidays
    static func vesak(for year: Int) -> Date {
        // Buddha's birthday - typically May
        let baseDates: [Int: (month: Int, day: Int)] = [
            2024: (5, 23), 2025: (5, 13), 2026: (5, 31), 2027: (5, 20), 2028: (5, 9)
        ]
        
        if let date = baseDates[year] {
            var components = DateComponents()
            components.year = year
            components.month = date.month
            components.day = date.day
            return Calendar.current.date(from: components) ?? Date()
        }
        
        // Fallback
        return Calendar.current.date(from: DateComponents(year: year, month: 5, day: 15)) ?? Date()
    }
}

struct EnhancedHolidayDatabase {
    
    // MARK: - Static Holidays
    static let staticHolidays: [Holiday] = [
        // United States
        Holiday(name: "New Year's Day", emoji: "🎆", month: 1, day: 1, country: "United States", type: .fixed, year: nil),
        Holiday(name: "Martin Luther King Jr. Day", emoji: "✊", month: 1, day: 15, country: "United States", type: .observed, year: nil),
        Holiday(name: "Presidents' Day", emoji: "🏛️", month: 2, day: 19, country: "United States", type: .observed, year: nil),
        Holiday(name: "Independence Day", emoji: "🇺🇸", month: 7, day: 4, country: "United States", type: .fixed, year: nil),
        Holiday(name: "Columbus Day", emoji: "🚢", month: 10, day: 14, country: "United States", type: .observed, year: nil),
        Holiday(name: "Veterans Day", emoji: "🎖️", month: 11, day: 11, country: "United States", type: .fixed, year: nil),
        Holiday(name: "Christmas Day", emoji: "🎄", month: 12, day: 25, country: "United States", type: .fixed, year: nil),
        
        // Canada
        Holiday(name: "New Year's Day", emoji: "🎆", month: 1, day: 1, country: "Canada", type: .fixed, year: nil),
        Holiday(name: "Family Day", emoji: "👨‍👩‍👧‍👦", month: 2, day: 19, country: "Canada", type: .observed, year: nil),
        Holiday(name: "Good Friday", emoji: "✝️", month: 3, day: 29, country: "Canada", type: .floating, year: nil),
        Holiday(name: "Easter Monday", emoji: "🐰", month: 4, day: 1, country: "Canada", type: .floating, year: nil),
        Holiday(name: "Victoria Day", emoji: "👑", month: 5, day: 20, country: "Canada", type: .observed, year: nil),
        Holiday(name: "Canada Day", emoji: "🍁", month: 7, day: 1, country: "Canada", type: .fixed, year: nil),
        Holiday(name: "Labour Day", emoji: "👷", month: 9, day: 2, country: "Canada", type: .observed, year: nil),
        Holiday(name: "Thanksgiving", emoji: "🦃", month: 10, day: 14, country: "Canada", type: .observed, year: nil),
        Holiday(name: "Remembrance Day", emoji: "🎖️", month: 11, day: 11, country: "Canada", type: .fixed, year: nil),
        Holiday(name: "Christmas Day", emoji: "🎄", month: 12, day: 25, country: "Canada", type: .fixed, year: nil),
        Holiday(name: "Boxing Day", emoji: "📦", month: 12, day: 26, country: "Canada", type: .fixed, year: nil),
        
        // United Kingdom
        Holiday(name: "New Year's Day", emoji: "🎆", month: 1, day: 1, country: "United Kingdom", type: .fixed, year: nil),
        Holiday(name: "Good Friday", emoji: "✝️", month: 3, day: 29, country: "United Kingdom", type: .floating, year: nil),
        Holiday(name: "Easter Monday", emoji: "🐰", month: 4, day: 1, country: "United Kingdom", type: .floating, year: nil),
        Holiday(name: "Early May Bank Holiday", emoji: "🌺", month: 5, day: 6, country: "United Kingdom", type: .observed, year: nil),
        Holiday(name: "Spring Bank Holiday", emoji: "🌱", month: 5, day: 27, country: "United Kingdom", type: .observed, year: nil),
        Holiday(name: "Summer Bank Holiday", emoji: "☀️", month: 8, day: 26, country: "United Kingdom", type: .observed, year: nil),
        Holiday(name: "Christmas Day", emoji: "🎄", month: 12, day: 25, country: "United Kingdom", type: .fixed, year: nil),
        Holiday(name: "Boxing Day", emoji: "📦", month: 12, day: 26, country: "United Kingdom", type: .fixed, year: nil),
        
        // Mexico
        Holiday(name: "New Year's Day", emoji: "🎆", month: 1, day: 1, country: "Mexico", type: .fixed, year: nil),
        Holiday(name: "Constitution Day", emoji: "📜", month: 2, day: 5, country: "Mexico", type: .fixed, year: nil),
        Holiday(name: "Benito Juárez Day", emoji: "🏛️", month: 3, day: 18, country: "Mexico", type: .observed, year: nil),
        Holiday(name: "Labor Day", emoji: "👷", month: 5, day: 1, country: "Mexico", type: .fixed, year: nil),
        Holiday(name: "Independence Day", emoji: "🇲🇽", month: 9, day: 16, country: "Mexico", type: .fixed, year: nil),
        Holiday(name: "Revolution Day", emoji: "⚔️", month: 11, day: 18, country: "Mexico", type: .observed, year: nil),
        Holiday(name: "Christmas Day", emoji: "🎄", month: 12, day: 25, country: "Mexico", type: .fixed, year: nil),
        
        // Australia
        Holiday(name: "New Year's Day", emoji: "🎆", month: 1, day: 1, country: "Australia", type: .fixed, year: nil),
        Holiday(name: "Australia Day", emoji: "🇦🇺", month: 1, day: 26, country: "Australia", type: .fixed, year: nil),
        Holiday(name: "Good Friday", emoji: "✝️", month: 3, day: 29, country: "Australia", type: .floating, year: nil),
        Holiday(name: "Easter Monday", emoji: "🐰", month: 4, day: 1, country: "Australia", type: .floating, year: nil),
        Holiday(name: "ANZAC Day", emoji: "🎖️", month: 4, day: 25, country: "Australia", type: .fixed, year: nil),
        Holiday(name: "Christmas Day", emoji: "🎄", month: 12, day: 25, country: "Australia", type: .fixed, year: nil),
        Holiday(name: "Boxing Day", emoji: "📦", month: 12, day: 26, country: "Australia", type: .fixed, year: nil),
        
        // Japan
        Holiday(name: "New Year's Day", emoji: "🎆", month: 1, day: 1, country: "Japan", type: .fixed, year: nil),
        Holiday(name: "Coming of Age Day", emoji: "👘", month: 1, day: 8, country: "Japan", type: .observed, year: nil),
        Holiday(name: "National Foundation Day", emoji: "🏛️", month: 2, day: 11, country: "Japan", type: .fixed, year: nil),
        Holiday(name: "Emperor's Birthday", emoji: "👑", month: 2, day: 23, country: "Japan", type: .fixed, year: nil),
        Holiday(name: "Golden Week", emoji: "🌸", month: 4, day: 29, country: "Japan", type: .fixed, year: nil),
        Holiday(name: "Children's Day", emoji: "🎏", month: 5, day: 5, country: "Japan", type: .fixed, year: nil),
        Holiday(name: "Marine Day", emoji: "🌊", month: 7, day: 15, country: "Japan", type: .observed, year: nil),
        Holiday(name: "Mountain Day", emoji: "⛰️", month: 8, day: 11, country: "Japan", type: .fixed, year: nil),
        Holiday(name: "Respect for the Aged Day", emoji: "👴", month: 9, day: 16, country: "Japan", type: .observed, year: nil),
        Holiday(name: "Sports Day", emoji: "🏃", month: 10, day: 14, country: "Japan", type: .observed, year: nil),
        Holiday(name: "Culture Day", emoji: "🎭", month: 11, day: 3, country: "Japan", type: .fixed, year: nil),
        Holiday(name: "Labor Thanksgiving Day", emoji: "🙏", month: 11, day: 23, country: "Japan", type: .fixed, year: nil),
        
        // Germany
        Holiday(name: "New Year's Day", emoji: "🎆", month: 1, day: 1, country: "Germany", type: .fixed, year: nil),
        Holiday(name: "Good Friday", emoji: "✝️", month: 3, day: 29, country: "Germany", type: .floating, year: nil),
        Holiday(name: "Easter Monday", emoji: "🐰", month: 4, day: 1, country: "Germany", type: .floating, year: nil),
        Holiday(name: "Labor Day", emoji: "👷", month: 5, day: 1, country: "Germany", type: .fixed, year: nil),
        Holiday(name: "Ascension Day", emoji: "⛪", month: 5, day: 9, country: "Germany", type: .floating, year: nil),
        Holiday(name: "Whit Monday", emoji: "🕊️", month: 5, day: 20, country: "Germany", type: .floating, year: nil),
        Holiday(name: "German Unity Day", emoji: "🇩🇪", month: 10, day: 3, country: "Germany", type: .fixed, year: nil),
        Holiday(name: "Christmas Day", emoji: "🎄", month: 12, day: 25, country: "Germany", type: .fixed, year: nil),
        Holiday(name: "Boxing Day", emoji: "📦", month: 12, day: 26, country: "Germany", type: .fixed, year: nil),
        
        // France
        Holiday(name: "New Year's Day", emoji: "🎆", month: 1, day: 1, country: "France", type: .fixed, year: nil),
        Holiday(name: "Labor Day", emoji: "👷", month: 5, day: 1, country: "France", type: .fixed, year: nil),
        Holiday(name: "Victory in Europe Day", emoji: "✌️", month: 5, day: 8, country: "France", type: .fixed, year: nil),
        Holiday(name: "Bastille Day", emoji: "🇫🇷", month: 7, day: 14, country: "France", type: .fixed, year: nil),
        Holiday(name: "Assumption Day", emoji: "⛪", month: 8, day: 15, country: "France", type: .fixed, year: nil),
        Holiday(name: "All Saints' Day", emoji: "🕯️", month: 11, day: 1, country: "France", type: .fixed, year: nil),
        Holiday(name: "Armistice Day", emoji: "🎖️", month: 11, day: 11, country: "France", type: .fixed, year: nil),
        Holiday(name: "Christmas Day", emoji: "🎄", month: 12, day: 25, country: "France", type: .fixed, year: nil),
        
        // India
        Holiday(name: "Republic Day", emoji: "🇮🇳", month: 1, day: 26, country: "India", type: .fixed, year: nil),
        Holiday(name: "Independence Day", emoji: "🇮🇳", month: 8, day: 15, country: "India", type: .fixed, year: nil),
        Holiday(name: "Gandhi Jayanti", emoji: "🕉️", month: 10, day: 2, country: "India", type: .fixed, year: nil),
        
        // China
        Holiday(name: "New Year's Day", emoji: "🎆", month: 1, day: 1, country: "China", type: .fixed, year: nil),
        Holiday(name: "National Day", emoji: "🇨🇳", month: 10, day: 1, country: "China", type: .fixed, year: nil),
        
        // Brazil
        Holiday(name: "New Year's Day", emoji: "🎆", month: 1, day: 1, country: "Brazil", type: .fixed, year: nil),
        Holiday(name: "Independence Day", emoji: "🇧🇷", month: 9, day: 7, country: "Brazil", type: .fixed, year: nil),
        Holiday(name: "Christmas Day", emoji: "🎄", month: 12, day: 25, country: "Brazil", type: .fixed, year: nil),
        
        // South Africa
        Holiday(name: "New Year's Day", emoji: "🎆", month: 1, day: 1, country: "South Africa", type: .fixed, year: nil),
        Holiday(name: "Human Rights Day", emoji: "✊", month: 3, day: 21, country: "South Africa", type: .fixed, year: nil),
        Holiday(name: "Freedom Day", emoji: "🕊️", month: 4, day: 27, country: "South Africa", type: .fixed, year: nil),
        Holiday(name: "Workers' Day", emoji: "👷", month: 5, day: 1, country: "South Africa", type: .fixed, year: nil),
        Holiday(name: "Youth Day", emoji: "👨‍🎓", month: 6, day: 16, country: "South Africa", type: .fixed, year: nil),
        Holiday(name: "National Women's Day", emoji: "👩", month: 8, day: 9, country: "South Africa", type: .fixed, year: nil),
        Holiday(name: "Heritage Day", emoji: "🏛️", month: 9, day: 24, country: "South Africa", type: .fixed, year: nil),
        Holiday(name: "Day of Reconciliation", emoji: "🤝", month: 12, day: 16, country: "South Africa", type: .fixed, year: nil),
        Holiday(name: "Christmas Day", emoji: "🎄", month: 12, day: 25, country: "South Africa", type: .fixed, year: nil),
        Holiday(name: "Day of Goodwill", emoji: "🙏", month: 12, day: 26, country: "South Africa", type: .fixed, year: nil)
    ]
    
    // MARK: - Dynamic Holiday Generation
    static func generateDynamicHolidays(for year: Int) -> [Holiday] {
        var dynamicHolidays: [Holiday] = []
        
        // Easter and related holidays
        let easterDate = DynamicHolidayCalculator.easterDate(for: year)
        let easterComponents = Calendar.current.dateComponents([.month, .day], from: easterDate)
        
        // Good Friday (2 days before Easter)
        let goodFriday = Calendar.current.date(byAdding: .day, value: -2, to: easterDate) ?? easterDate
        let goodFridayComponents = Calendar.current.dateComponents([.month, .day], from: goodFriday)
        
        // Easter Monday (1 day after Easter)
        let easterMonday = Calendar.current.date(byAdding: .day, value: 1, to: easterDate) ?? easterDate
        let easterMondayComponents = Calendar.current.dateComponents([.month, .day], from: easterMonday)
        
        // Ascension Day (39 days after Easter)
        let ascensionDay = Calendar.current.date(byAdding: .day, value: 39, to: easterDate) ?? easterDate
        let ascensionComponents = Calendar.current.dateComponents([.month, .day], from: ascensionDay)
        
        // Whit Monday (50 days after Easter)
        let whitMonday = Calendar.current.date(byAdding: .day, value: 50, to: easterDate) ?? easterDate
        let whitMondayComponents = Calendar.current.dateComponents([.month, .day], from: whitMonday)
        
        // Add Christian holidays
        dynamicHolidays.append(Holiday(name: "Good Friday", emoji: "✝️", month: goodFridayComponents.month ?? 3, day: goodFridayComponents.day ?? 29, country: "United Kingdom", type: .floating, year: year))
        dynamicHolidays.append(Holiday(name: "Good Friday", emoji: "✝️", month: goodFridayComponents.month ?? 3, day: goodFridayComponents.day ?? 29, country: "Canada", type: .floating, year: year))
        dynamicHolidays.append(Holiday(name: "Good Friday", emoji: "✝️", month: goodFridayComponents.month ?? 3, day: goodFridayComponents.day ?? 29, country: "Australia", type: .floating, year: year))
        dynamicHolidays.append(Holiday(name: "Good Friday", emoji: "✝️", month: goodFridayComponents.month ?? 3, day: goodFridayComponents.day ?? 29, country: "Germany", type: .floating, year: year))
        
        dynamicHolidays.append(Holiday(name: "Easter Monday", emoji: "🐰", month: easterMondayComponents.month ?? 4, day: easterMondayComponents.day ?? 1, country: "United Kingdom", type: .floating, year: year))
        dynamicHolidays.append(Holiday(name: "Easter Monday", emoji: "🐰", month: easterMondayComponents.month ?? 4, day: easterMondayComponents.day ?? 1, country: "Canada", type: .floating, year: year))
        dynamicHolidays.append(Holiday(name: "Easter Monday", emoji: "🐰", month: easterMondayComponents.month ?? 4, day: easterMondayComponents.day ?? 1, country: "Australia", type: .floating, year: year))
        dynamicHolidays.append(Holiday(name: "Easter Monday", emoji: "🐰", month: easterMondayComponents.month ?? 4, day: easterMondayComponents.day ?? 1, country: "Germany", type: .floating, year: year))
        
        dynamicHolidays.append(Holiday(name: "Ascension Day", emoji: "⛪", month: ascensionComponents.month ?? 5, day: ascensionComponents.day ?? 9, country: "Germany", type: .floating, year: year))
        dynamicHolidays.append(Holiday(name: "Whit Monday", emoji: "🕊️", month: whitMondayComponents.month ?? 5, day: whitMondayComponents.day ?? 20, country: "Germany", type: .floating, year: year))
        
        // US Federal Holidays (Floating)
        let laborDay = DynamicHolidayCalculator.laborDay(for: year)
        let laborDayComponents = Calendar.current.dateComponents([.month, .day], from: laborDay)
        dynamicHolidays.append(Holiday(name: "Labor Day", emoji: "👷", month: laborDayComponents.month ?? 9, day: laborDayComponents.day ?? 2, country: "United States", type: .floating, year: year))
        
        let memorialDay = DynamicHolidayCalculator.memorialDay(for: year)
        let memorialDayComponents = Calendar.current.dateComponents([.month, .day], from: memorialDay)
        dynamicHolidays.append(Holiday(name: "Memorial Day", emoji: "🇺🇸", month: memorialDayComponents.month ?? 5, day: memorialDayComponents.day ?? 27, country: "United States", type: .floating, year: year))
        
        let thanksgiving = DynamicHolidayCalculator.thanksgiving(for: year)
        let thanksgivingComponents = Calendar.current.dateComponents([.month, .day], from: thanksgiving)
        dynamicHolidays.append(Holiday(name: "Thanksgiving", emoji: "🦃", month: thanksgivingComponents.month ?? 11, day: thanksgivingComponents.day ?? 28, country: "United States", type: .floating, year: year))
        
        // Chinese New Year
        let chineseNewYear = DynamicHolidayCalculator.chineseNewYear(for: year)
        let cnyComponents = Calendar.current.dateComponents([.month, .day], from: chineseNewYear)
        dynamicHolidays.append(Holiday(name: "Chinese New Year", emoji: "🧨", month: cnyComponents.month ?? 2, day: cnyComponents.day ?? 10, country: "China", type: .lunar, year: year))
        dynamicHolidays.append(Holiday(name: "Chinese New Year", emoji: "🧨", month: cnyComponents.month ?? 2, day: cnyComponents.day ?? 10, country: "Singapore", type: .lunar, year: year))
        dynamicHolidays.append(Holiday(name: "Chinese New Year", emoji: "🧨", month: cnyComponents.month ?? 2, day: cnyComponents.day ?? 10, country: "Malaysia", type: .lunar, year: year))
        
        // Islamic Holidays
        let ramadanStart = DynamicHolidayCalculator.ramadanStart(for: year)
        let ramadanComponents = Calendar.current.dateComponents([.month, .day], from: ramadanStart)
        dynamicHolidays.append(Holiday(name: "Ramadan Start", emoji: "🌙", month: ramadanComponents.month ?? 3, day: ramadanComponents.day ?? 10, country: "Saudi Arabia", type: .lunar, year: year))
        dynamicHolidays.append(Holiday(name: "Ramadan Start", emoji: "🌙", month: ramadanComponents.month ?? 3, day: ramadanComponents.day ?? 10, country: "UAE", type: .lunar, year: year))
        dynamicHolidays.append(Holiday(name: "Ramadan Start", emoji: "🌙", month: ramadanComponents.month ?? 3, day: ramadanComponents.day ?? 10, country: "Qatar", type: .lunar, year: year))
        
        let eidAlFitr = DynamicHolidayCalculator.eidAlFitr(for: year)
        let eidAlFitrComponents = Calendar.current.dateComponents([.month, .day], from: eidAlFitr)
        dynamicHolidays.append(Holiday(name: "Eid al-Fitr", emoji: "🌙", month: eidAlFitrComponents.month ?? 4, day: eidAlFitrComponents.day ?? 9, country: "Saudi Arabia", type: .lunar, year: year))
        dynamicHolidays.append(Holiday(name: "Eid al-Fitr", emoji: "🌙", month: eidAlFitrComponents.month ?? 4, day: eidAlFitrComponents.day ?? 9, country: "UAE", type: .lunar, year: year))
        dynamicHolidays.append(Holiday(name: "Eid al-Fitr", emoji: "🌙", month: eidAlFitrComponents.month ?? 4, day: eidAlFitrComponents.day ?? 9, country: "Qatar", type: .lunar, year: year))
        
        let eidAlAdha = DynamicHolidayCalculator.eidAlAdha(for: year)
        let eidAlAdhaComponents = Calendar.current.dateComponents([.month, .day], from: eidAlAdha)
        dynamicHolidays.append(Holiday(name: "Eid al-Adha", emoji: "🐪", month: eidAlAdhaComponents.month ?? 6, day: eidAlAdhaComponents.day ?? 17, country: "Saudi Arabia", type: .lunar, year: year))
        dynamicHolidays.append(Holiday(name: "Eid al-Adha", emoji: "🐪", month: eidAlAdhaComponents.month ?? 6, day: eidAlAdhaComponents.day ?? 17, country: "UAE", type: .lunar, year: year))
        dynamicHolidays.append(Holiday(name: "Eid al-Adha", emoji: "🐪", month: eidAlAdhaComponents.month ?? 6, day: eidAlAdhaComponents.day ?? 17, country: "Qatar", type: .lunar, year: year))
        
        // Jewish Holidays
        let roshHashanah = DynamicHolidayCalculator.roshHashanah(for: year)
        let roshComponents = Calendar.current.dateComponents([.month, .day], from: roshHashanah)
        dynamicHolidays.append(Holiday(name: "Rosh Hashanah", emoji: "🍎", month: roshComponents.month ?? 9, day: roshComponents.day ?? 25, country: "Israel", type: .lunar, year: year))
        
        let yomKippur = DynamicHolidayCalculator.yomKippur(for: year)
        let yomComponents = Calendar.current.dateComponents([.month, .day], from: yomKippur)
        dynamicHolidays.append(Holiday(name: "Yom Kippur", emoji: "🕯️", month: yomComponents.month ?? 10, day: yomComponents.day ?? 5, country: "Israel", type: .lunar, year: year))
        
        // Hindu Holidays
        let diwali = DynamicHolidayCalculator.diwali(for: year)
        let diwaliComponents = Calendar.current.dateComponents([.month, .day], from: diwali)
        dynamicHolidays.append(Holiday(name: "Diwali", emoji: "🪔", month: diwaliComponents.month ?? 11, day: diwaliComponents.day ?? 5, country: "India", type: .lunar, year: year))
        
        // Buddhist Holidays
        let vesak = DynamicHolidayCalculator.vesak(for: year)
        let vesakComponents = Calendar.current.dateComponents([.month, .day], from: vesak)
        dynamicHolidays.append(Holiday(name: "Vesak", emoji: "🌸", month: vesakComponents.month ?? 5, day: vesakComponents.day ?? 15, country: "Sri Lanka", type: .lunar, year: year))
        dynamicHolidays.append(Holiday(name: "Vesak", emoji: "🌸", month: vesakComponents.month ?? 5, day: vesakComponents.day ?? 15, country: "Thailand", type: .lunar, year: year))
        
        return dynamicHolidays
    }
    
    // MARK: - Public API
    static func getAllHolidays(for year: Int) -> [Holiday] {
        return staticHolidays + generateDynamicHolidays(for: year)
    }
    
    static func getHoliday(for city: City) -> Holiday? {
        let currentYear = Calendar.current.component(.year, from: Date())
        let allHolidays = getAllHolidays(for: currentYear)
        
        return allHolidays.first { holiday in
            holiday.country == city.country && (holiday.isToday || holiday.isTomorrow)
        }
    }
    
    static func getHolidayText(for city: City) -> String? {
        guard let holiday = getHoliday(for: city) else { return nil }
        
        let prefix = holiday.isToday ? "" : "Tomorrow, "
        return "\(prefix)\(holiday.emoji) \(holiday.name)"
    }
    
    static func getHolidayTextForDate(for city: City, date: Date) -> String? {
        let calendar = Calendar.current
        let targetYear = calendar.component(.year, from: date)
        let targetMonth = calendar.component(.month, from: date)
        let targetDay = calendar.component(.day, from: date)
        
        let allHolidays = getAllHolidays(for: targetYear)
        
        // Find holiday that matches the target date
        let holiday = allHolidays.first { holiday in
            holiday.country == city.country && 
            holiday.month == targetMonth && 
            holiday.day == targetDay
        }
        
        guard let holiday = holiday else { return nil }
        
        // Check if this is today or tomorrow relative to the target date
        let today = Date()
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        
        let isToday = calendar.isDate(date, inSameDayAs: today)
        let isTomorrow = calendar.isDate(date, inSameDayAs: tomorrow)
        
        let prefix = isToday ? "" : (isTomorrow ? "Tomorrow, " : "")
        return "\(prefix)\(holiday.emoji) \(holiday.name)"
    }
} 