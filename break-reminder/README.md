# Mindful Break Reminder System

A comprehensive Clarity smart contract system for tracking and encouraging regular mindful breaks, complete with achievement system and user progress tracking.

## 📋 Overview

Version 0.2.0 introduces significant enhancements to the original break reminder concept:

- **Enhanced Security**: Proper access controls, input validation, and error handling
- **Bug Fixes**: Corrected timestamp handling and added proper time-based calculations  
- **Achievement System**: Gamified experience with points, streaks, and unlockable achievements
- **User Customization**: Personal break intervals, goals, and notification preferences
- **Progress Tracking**: Detailed analytics on break habits and consistency

## 🏗️ Architecture

### Core Contracts

1. **mindful-break-reminder.clar** - Main contract handling break tracking and user management
2. **achievement-system.clar** - Companion contract for gamification features

## ✨ Features

### Phase 2 Enhancements

#### 🐛 Bug Fixes
- Fixed timestamp handling using proper `stx-get-block-info?` function instead of `block-height`
- Added input validation for all user inputs
- Implemented proper error handling with meaningful error codes

#### 🔒 Security Improvements
- Owner-only functions for administrative operations
- Input sanitization and bounds checking
- Protection against unauthorized access
- Validation of time intervals and break durations

#### 🎮 New Functionality
- **User Streaks**: Track consecutive days of taking breaks
- **Custom Intervals**: Users can set personal break reminders (1 minute to 24 hours)
- **Break Types**: Categorize breaks (meditation, walk, stretch, etc.)
- **Goal Setting**: Personal daily break targets
- **Achievement System**: Unlock achievements and earn points
- **Break History**: Detailed logging of all break activities
- **Leaderboards**: Compare progress with other users

### Core Functions

#### Main Contract Functions

```clarity
;; User Management
(touch-in) ; Check in and update streak
(take-break duration break-type) ; Log a completed break
(set-user-interval seconds) ; Set personal break interval
(set-break-goal goal) ; Set daily break target

;; Queries
(get-user-break-info user) ; Get user's break statistics
(time-until-next-break user) ; Time remaining until next break due
(is-break-due user) ; Check if break is currently due

;; Settings
(toggle-notifications) ; Enable/disable notifications
(reset-streak) ; Reset user's current streak
```

#### Achievement System Functions

```clarity
;; Achievement Management
(award-achievement user achievement-id) ; Award achievement to user
(check-and-award-achievements user streak total) ; Auto-check achievements
(get-user-stats user) ; Get user's points and achievement count

;; Queries
(has-achievement user achievement-id) ; Check if user has specific achievement
(get-leaderboard-position user) ; Get user's ranking by points
```

## 🎯 Default Achievements

| Achievement | Requirement | Points | Description |
|-------------|-------------|---------|-------------|
| First Break | 1 total break | 10 | Take your first mindful break |
| Streak Master | 7-day streak | 50 | Maintain breaks for a week |
| Century Club | 100 total breaks | 100 | Reach 100 lifetime breaks |
| Consistency Champion | 30-day consistency | 200 | Break every day for a month |

## 🚀 Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks wallet for testing

### Installation

1. Clone the repository:
```bash
git clone <your-repo-url>
cd mindful-break-reminder
```

2. Initialize the project:
```bash
clarinet check
```

3. Deploy to local testnet:
```bash
clarinet integrate
```

### Usage Examples

```clarity
;; Set a custom 30-minute break interval
(contract-call? .mindful-break-reminder set-user-interval u1800)

;; Check in for a break (updates streak)
(contract-call? .mindful-break-reminder touch-in)

;; Log a 10-minute meditation break
(contract-call? .mindful-break-reminder take-break u600 "meditation")

;; Set a goal of 8 breaks per day
(contract-call? .mindful-break-reminder set-break-goal u8)

;; Check achievement status
(contract-call? .achievement-system get-user-stats tx-sender)
```

## 🧪 Testing

Run the test suite:

```bash
clarinet test
```

Check contracts:

```bash
clarinet check
```

## 📊 Data Structure

### User Break Data
```clarity
{
  last-break: uint,      ; Timestamp of last break
  streak: uint,          ; Current consecutive days
  total-breaks: uint     ; Lifetime break count
}
```

### User Settings
```clarity
{
  custom-interval: uint,        ; Personal break interval
  notifications-enabled: bool,  ; Notification preference
  break-goal: uint             ; Daily break target
}
```

### Achievement Data
```clarity
{
  name: string-ascii,           ; Achievement name
  description: string-ascii,    ; Achievement description
  requirement-type: string,     ; Type of requirement
  requirement-value: uint,      ; Required value
  reward-points: uint          ; Points awarded
}
```

## 🔧 Configuration

### Network Settings

- **Local**: `http://localhost:20443`
- **Testnet**: Stacks testnet nodes
- **Mainnet**: Stacks mainnet nodes

### Contract Settings

- Default break interval: 1 hour (3600 seconds)
- Minimum interval: 1 minute (60 seconds)
- Maximum interval: 24 hours (86400 seconds)
- Maximum break duration: 2 hours (7200 seconds)

## 🛠️ Development

### Adding New Achievements

```clarity
(contract-call? .achievement-system create-achievement 
  "New Achievement" 
  "Description of the achievement" 
  "requirement-type" 
  requirement-value 
  reward-points)
```

### Extending Functionality

The modular design allows easy extension:

- Add new break types
- Implement team challenges
- Create seasonal achievements
- Add integration with external wellness apps

## 📈 Roadmap

- [ ] Mobile app integration
- [ ] Social features and team challenges
- [ ] AI-powered break recommendations
- [ ] Integration with calendar systems
- [ ] Wellness analytics dashboard
- [ ] NFT rewards for major milestones

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new features
4. Ensure all tests pass
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Stacks blockchain community
- Clarity language developers
- Mindfulness and wellness advocates

---

**Version**: 0.2.0  
**Last Updated**: Phase 2 Development  
**Status**: Active Development
