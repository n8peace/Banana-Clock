# Bug List - Banana Clock

## Overview
This document tracks bugs organized by page/feature for the Banana Clock iOS app and backend services.

## Bug Status Legend
- **Open**: Bug identified, not yet addressed
- **In Progress**: Currently being worked on
- **Fixed**: Bug resolved, pending testing
- **Verified**: Bug fixed and tested
- **Won't Fix**: Bug acknowledged but not planned for fix

## Priority Levels
- **Critical**: App crashes, data loss, security issues
- **High**: Major functionality broken, poor user experience
- **Medium**: Minor functionality issues, UI inconsistencies
- **Low**: Cosmetic issues, minor annoyances

---

## iOS App

### Main Tab View
| Bug ID | Description | Status | Priority | Assigned | Notes |
|--------|-------------|--------|----------|----------|-------|
| | | | | | |

### Alarms Feature
| Bug ID | Description | Status | Priority | Assigned | Notes |
|--------|-------------|--------|----------|----------|-------|
| | | | | | |

### Wake Up AI Settings
| Bug ID | Description | Status | Priority | Assigned | Notes |
|--------|-------------|--------|----------|----------|-------|
| | | | | | |

### Alarm Management
| Bug ID | Description | Status | Priority | Assigned | Notes |
|--------|-------------|--------|----------|----------|-------|
| | | | | | |

### Sound Picker
| Bug ID | Description | Status | Priority | Assigned | Notes |
|--------|-------------|--------|----------|----------|-------|
| | | | | | |

### Music Picker
| Bug ID | Description | Status | Priority | Assigned | Notes |
|--------|-------------|--------|----------|----------|-------|
| | | | | | |

### Voice Picker
| Bug ID | Description | Status | Priority | Assigned | Notes |
|--------|-------------|--------|----------|----------|-------|
| | | | | | |

### Sports Picker
| Bug ID | Description | Status | Priority | Assigned | Notes |
|--------|-------------|--------|----------|----------|-------|
| | | | | | |

### Headlines Picker
| Bug ID | Description | Status | Priority | Assigned | Notes |
|--------|-------------|--------|----------|----------|-------|
| | | | | | |

### Settings
| Bug ID | Description | Status | Priority | Assigned | Notes |
|--------|-------------|--------|----------|----------|-------|
| | | | | | |

### Timers Feature
| Bug ID | Description | Status | Priority | Assigned | Notes |
|--------|-------------|--------|----------|----------|-------|
| TIMER-001 | Entire row is clickable instead of just buttons | Fixed | Medium | Unassigned | Incorrect touch target behavior |
| TIMER-002 | Buttons not clickable due to row being clickable | Fixed | High | Unassigned | Buttons blocked by row touch target |
| TIMER-004 | Timer buttons not clickable - rows work correctly, but buttons are unresponsive | Open | High | Unassigned | .allowsHitTesting(showSelection) blocks buttons in normal mode |
| TIMER-003 | Unable to select timers when clicking edit to delete | Fixed | High | Unassigned | Edit mode selection not working |
| TIMER-005 | Cannot swipe to delete timers | Open | Medium | Unassigned | Missing swipe-to-delete functionality that exists in Alarms |

### Stopwatch Feature
| Bug ID | Description | Status | Priority | Assigned | Notes |
|--------|-------------|--------|----------|----------|-------|
| | | | | | |

### World Clock Feature
| Bug ID | Description | Status | Priority | Assigned | Notes |
|--------|-------------|--------|----------|----------|-------|
| WC-001 | Edit mode shows negative red box by options instead of consistent mass delete/edit UI pattern | Fixed | Medium | Unassigned | Inconsistent with other edit pages |
| WC-002 | No deselect option when selecting timezones to delete in edit mode | Fixed | Medium | Unassigned | Missing deselect functionality |

### Premium/Paywall
| Bug ID | Description | Status | Priority | Assigned | Notes |
|--------|-------------|--------|----------|----------|-------|
| | | | | | |

---

## Backend Services

### Supabase Functions
| Bug ID | Description | Status | Priority | Assigned | Notes |
|--------|-------------|--------|----------|----------|-------|
| | | | | | |

### Database
| Bug ID | Description | Status | Priority | Assigned | Notes |
|--------|-------------|--------|----------|----------|-------|
| | | | | | |

### Content Generation
| Bug ID | Description | Status | Priority | Assigned | Notes |
|--------|-------------|--------|----------|----------|-------|
| | | | | | |

### Audio Generation
| Bug ID | Description | Status | Priority | Assigned | Notes |
|--------|-------------|--------|----------|----------|-------|
| | | | | | |

### Health Checks
| Bug ID | Description | Status | Priority | Assigned | Notes |
|--------|-------------|--------|----------|----------|-------|
| | | | | | |

---

## Cross-Platform Issues

### iOS-Backend Integration
| Bug ID | Description | Status | Priority | Assigned | Notes |
|--------|-------------|--------|----------|----------|-------|
| | | | | | |

### Data Synchronization
| Bug ID | Description | Status | Priority | Assigned | Notes |
|--------|-------------|--------|----------|----------|-------|
| | | | | | |

### Authentication
| Bug ID | Description | Status | Priority | Assigned | Notes |
|--------|-------------|--------|----------|----------|-------|
| | | | | | |

---

## Performance Issues

### iOS Performance
| Bug ID | Description | Status | Priority | Assigned | Notes |
|--------|-------------|--------|----------|----------|-------|
| | | | | | |

### Backend Performance
| Bug ID | Description | Status | Priority | Assigned | Notes |
|--------|-------------|--------|----------|----------|-------|
| | | | | | |

---

## Known Issues

### iOS Known Issues
| Bug ID | Description | Status | Priority | Assigned | Notes |
|--------|-------------|--------|----------|----------|-------|
| | | | | | |

### Backend Known Issues
| Bug ID | Description | Status | Priority | Assigned | Notes |
|--------|-------------|--------|----------|----------|-------|
| | | | | | |

---

## Bug Template
Use this template when adding new bugs:

```markdown
| BUG-001 | Brief description of the bug | Open | High | Unassigned | Additional context, steps to reproduce, etc. |
```

## Notes
- Update status and priority as bugs are addressed
- Include reproduction steps in Notes column when relevant
- Link to related issues or PRs in Notes
- Add date stamps for status changes 