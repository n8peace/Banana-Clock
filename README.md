# Banana Clock 🌅

**Transform your mornings from jarring to joyful**

Banana Clock reimagines how we wake up by replacing harsh alarms with personalized, AI-powered morning experiences that set you up for success every day.

## 💡 The Problem We Solve

**Traditional alarms are broken.** They jolt you awake with harsh sounds, offer no context about your day, and create anxiety instead of motivation. Most people start their mornings in fight-or-flight mode, checking multiple apps for weather, news, and reminders—all while trying to shake off sleep inertia.

**Banana Clock fixes this** by creating a warm, personalized morning companion that:
- **Eliminates morning anxiety** with gentle, encouraging wake-up experiences
- **Provides instant context** about your day (weather, news, schedule) without reaching for your phone
- **Motivates and inspires** with personalized encouragement tailored to your preferences
- **Streamlines morning routines** by consolidating information into one beautiful experience

## 🚀 The Banana Clock Difference

### 🤖 **AI-Powered Personalization**
Every morning is unique. Our GPT-4o engine creates personalized scripts based on:
- Your location, weather, and personal preferences
- Current news in categories you care about (business, sports, pop culture)
- Your schedule, reminders, and upcoming events
- Motivational content aligned with your values and interests

### 🎵 **Cinema-Quality Experience**
- **Premium voice synthesis** via ElevenLabs (not robotic text-to-speech)
- **Background music integration** that complements your wake-up script
- **Emotional intelligence** in tone and content delivery
- **Multiple voice personalities** to match your preference

### ⏰ **Smart Time Management Suite**
Beyond revolutionary wake-ups, Banana Clock is a complete time management solution:
- **Intelligent Wake-Up Alarms**: AI-generated personalized morning experiences
- **Regular Alarms**: Traditional alarms with premium sounds and customization
- **Smart Timers**: Perfect for cooking, workouts, and productivity sessions
- **World Clock with AI**: Timezone converter with AI-powered meeting scheduling recommendations
- **Precision Stopwatch**: Professional-grade timing for any activity

### 🌍 **Global Coordination Made Easy**
The AI timezone converter eliminates the mental math of global scheduling:
- Input multiple cities and get instant AI-powered meeting time recommendations
- Considers business hours, cultural preferences, and optimal windows
- Beautiful confetti effects celebrate successful coordination (because scheduling shouldn't be boring!)

## 🏗️ Architecture & Technology

### **iOS App (SwiftUI + Native Integration)**
- **AlarmKit Integration**: System-level alarm reliability that works even when backgrounded/closed (requires iOS 26+)
- **Core Data + CloudKit**: Reliable local storage with cloud sync
- **Premium Design**: Dark-mode interface with signature banana yellow accents
- **iOS 26+ Required**: Uses AlarmKit framework for system-level alarm reliability

### **AI-Powered Backend (Supabase + Edge Functions)**
- **GPT-4o Content Generation**: Creates unique morning scripts daily
- **ElevenLabs Voice Synthesis**: Hollywood-quality voice generation
- **PostgreSQL Database**: Robust user preferences and content management
- **Real-time Sync**: Seamless experience across devices
- **Intelligent Caching**: 72-hour content retention with smart fallbacks

### **Subscription Model**
- **Premium Experience Only**: $4.99/month (3-day trial) or $39.99/year (7-day trial)
- **No Freemium Distractions**: Every feature designed for paying customers who value quality
- **RevenueCat Integration**: Smooth, reliable subscription management

## 🎯 Who This Is For

### **Morning Optimizers**
People who want to start their day feeling prepared, motivated, and in control rather than rushed and reactive.

### **Global Professionals**
Remote workers, consultants, and executives who coordinate across time zones and need intelligent scheduling assistance.

### **Wellness-Focused Individuals**
Those who understand that how you wake up determines how you feel all day, and invest in premium experiences that support their well-being.

### **Productivity Enthusiasts**
People who appreciate beautiful, thoughtful software that combines multiple time management tools into one cohesive experience.

## 🚀 Getting Started

### **For Users**
1. Download from the App Store (iOS 26+ required)
2. Start your free trial (3-7 days depending on plan)
3. Set up your first wake-up alarm with AI preferences
4. Wake up tomorrow to your personalized experience

### **For Developers**
See [iOS Development README](ios/README.md) for complete setup instructions.

## 📁 Project Structure

```
Banana-Clock/
├── ios/                  # iOS app (SwiftUI + AlarmKit)
│   ├── BananaClock/     # Main app code
│   │   ├── App/         # Configuration, entry point
│   │   ├── Core/        # Models, services, utilities
│   │   │   ├── Models/  # Alarm, Timer, User models
│   │   │   ├── Services/# AI, audio, sync services
│   │   │   └── Components/ # Reusable UI components
│   │   ├── Features/    # Feature modules
│   │   │   ├── Alarms/  # Wake-up & regular alarms
│   │   │   ├── Timers/  # Timer functionality
│   │   │   ├── WorldClock/ # Time zones + AI converter
│   │   │   ├── Stopwatch/  # Precision timing
│   │   │   └── Premium/ # Subscription management
│   │   └── Design/      # Theme, colors, typography
├── supabase/            # Backend infrastructure
│   ├── functions/       # AI content generation (7 functions)
│   │   ├── generate-banana-content/  # Main wake-up scripts
│   │   ├── generate-weather-content/ # Weather integration
│   │   ├── generate-headlines-content/ # News summaries
│   │   └── generate-audio/           # Voice synthesis
│   ├── migrations/      # Database schema (5 tables)
│   └── config.toml     # Environment configuration
├── docs/               # Comprehensive documentation
└── .github/workflows/  # CI/CD automation
```

## 🎯 Core Features Deep Dive

### **🌅 Wake-Up Alarms (The Star)**
- **Flexible Scheduling**: Different times on different days (7am MWF, 8am Tue/Thu, off weekends)
- **One-Per-Day Limit**: Prevents over-scheduling, maintains focus on quality
- **18-Hour Visibility Rule**: Shows tomorrow's alarm after 6pm today
- **AI Content Categories**: Weather, news, sports, markets, philosophy, reminders
- **Voice Customization**: Multiple ElevenLabs voice options
- **Music Integration**: Background music that complements your wake-up script

### **⏰ Regular Alarms**
- **Native iOS Integration**: Appears in system Clock app
- **Premium Sounds**: Curated audio library
- **Smart Snooze**: 1-15 minute customizable snooze
- **Volume Control**: Gradual wake-up or instant alert
- **Repeat Patterns**: Flexible scheduling for any use case

### **⏲️ Smart Timers**
- **Quick Presets**: 1, 5, 10 minute instant start
- **Custom Durations**: Hours, minutes, seconds precision
- **Activity Labels**: Cooking, workout, meditation, etc.
- **Background Operation**: Works while phone is locked
- **Bulk Management**: Edit, delete multiple timers
- **Smart Deduplication**: Prevents identical timer clutter

### **🌍 World Clock + AI Timezone Converter**
- **Global Time Display**: Beautiful, real-time world clocks
- **AI Meeting Scheduler**: Input cities, get optimal meeting times
- **Business Hours Intelligence**: Considers work schedules across cultures
- **Confetti Celebrations**: Delightful animations when AI finds solutions
- **Drag-to-Convert**: Interactive time slider for visual scheduling

### **⏱️ Precision Stopwatch**
- **Millisecond Accuracy**: Professional-grade timing
- **Lap Functionality**: Track intervals and splits
- **Clean Interface**: Distraction-free design
- **Background Operation**: Continues timing when app is closed

## 🏆 Competitive Advantages

### **Versus Apple Clock**
- **Personalized content** vs. generic alarms
- **AI-powered intelligence** vs. basic functionality
- **Premium experience** vs. utilitarian design
- **Emotional wellness focus** vs. pure functionality

### **Versus Sleep Cycle / AutoSleep**
- **Active morning engagement** vs. passive sleep tracking
- **Content delivery** vs. data collection
- **Motivational focus** vs. analysis paralysis
- **AI personalization** vs. generic recommendations

### **Versus Calendly / Scheduling Apps**
- **Timezone intelligence** vs. manual coordination
- **AI-powered recommendations** vs. user guesswork
- **Integrated time management** vs. single-purpose tools
- **Beautiful experience** vs. functional interfaces

## 🛣️ Roadmap & Vision

### **Short Term (Next 3 Months)**
- Complete audio mixer for seamless music + voice experience
- Launch production-ready subscription system
- Implement push notifications and background processing
- Add comprehensive analytics and user insights

### **Medium Term (3-6 Months)**
- Multi-language support for global expansion
- Advanced AI personalization with learning algorithms
- Integration with calendar and task management systems
- Apple Watch companion app for wrist-based wake-ups

### **Long Term (6+ Months)**
- Smart home integration (lights, coffee makers, etc.)
- Social features for family and team coordination
- Corporate enterprise solutions for global teams
- Voice assistant integration (Siri, shortcuts)

## 🤝 Contributing

We welcome contributions that align with our vision of creating joyful morning experiences:

1. **Fork & Feature Branch**: Create focused, well-tested features
2. **Design First**: Consider user experience over technical convenience
3. **Performance Matters**: Optimize for battery life and responsiveness
4. **Documentation**: Update docs for any user-facing changes
5. **Test Thoroughly**: Especially alarm functionality (use real devices)

## 📊 Key Metrics We Track

- **Morning Sentiment**: How users feel after using wake-up alarms
- **Engagement Depth**: Which AI content categories resonate most
- **Retention Quality**: Long-term subscription value vs. churn
- **Global Usage**: Timezone converter adoption across regions
- **Performance**: App responsiveness, battery usage, sync reliability

## 🆘 Support & Community

### **For Users**
- In-app help system with video tutorials
- Email support: support@bananaclock.app
- Community forum: [community.bananaclock.app](https://community.bananaclock.app)

### **For Developers**
- Complete documentation in `/docs/`
- Development setup guide: [ios/README.md](ios/README.md)
- Technical architecture: [CLAUDE.md](CLAUDE.md)
- Issue tracking: GitHub Issues with detailed templates

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

---

**Banana Clock** isn't just another alarm app—it's a morning transformation system that helps you wake up feeling prepared, motivated, and connected to your day. Join thousands of users who've already transformed their mornings from jarring to joyful.

*"The way you wake up determines how you feel all day. Make it count."* 🌅

---

*Last updated: January 2025*