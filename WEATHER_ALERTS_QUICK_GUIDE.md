# Weather Alerts Feature - Quick Guide

## What Changed?

### ✅ Before vs After

#### BEFORE:
```
Plant Maintenance > Alerts Tab
┌─────────────────────────────────┐
│   Current Weather               │
│   29.4°C  51%  4.3km/h         │
├─────────────────────────────────┤
│   Weather Alerts                │
│                                 │
│   ⚠️  Select a plant in the     │
│      Plant Guide tab to see     │
│      weather alerts             │
│                                 │
└─────────────────────────────────┘
```

#### AFTER:
```
Plant Maintenance > Alerts Tab
┌─────────────────────────────────┐
│   Current Weather               │
│   29.4°C  51%  4.3km/h         │
├─────────────────────────────────┤
│   Weather Alerts                │
│                                 │
│   🌿 Tomato Plant               │
│   ⚠️  Temperature too high      │
│   ⚠️  Low humidity - water more │
│                                 │
│   🌿 Rose Garden                │
│   ✅  Weather conditions optimal│
│                                 │
│   🌿 Basil                      │
│   🔴  Temperature too low       │
│                                 │
└─────────────────────────────────┘
```

### 🔔 NEW: Popup Notification on Login

```
┌─────────────────────────────────┐
│  ⚠️  Weather Alerts             │
├─────────────────────────────────┤
│  Found 2 weather alerts for     │
│  your plants:                   │
│                                 │
│  🌿 Tomato Plant                │
│    • Temperature too high       │
│    • Low humidity               │
│                                 │
│  🌿 Basil                       │
│    • Temperature too low        │
│                                 │
├─────────────────────────────────┤
│        [Dismiss] [View Details] │
└─────────────────────────────────┘
```

## How It Works

### 1. Automatic Alert Generation
```
User Opens App
    ↓
Home Screen Loads
    ↓
Fetch User's Plants (from plants table)
    ↓
Fetch Current Weather (OpenWeatherMap API)
    ↓
For Each Plant:
    • Get scientific name
    • Query plant_maintenance table
    • Get ideal conditions (temp, humidity, wind)
    • Compare with current weather
    • Generate alerts if outside range
    ↓
Display Popup if Critical Alerts Found
```

### 2. Alert Types

| Severity | Color | Example |
|----------|-------|---------|
| ✅ Optimal | Green | All conditions within range |
| ℹ️ Info | Blue | Minor deviation (humidity high) |
| ⚠️ Warning | Orange | Temp high, humidity low, wind high |
| 🔴 Critical | Red | Temperature too low (frost danger) |

### 3. Where Alerts Appear

1. **Home Screen Popup** (on login)
   - Only critical/warning alerts
   - Shows once per session
   - Quick overview with navigation

2. **Plant Maintenance > Alerts Tab**
   - All alerts for all plants
   - Grouped by plant name
   - Detailed recommendations
   - Current weather conditions

## Database Schema

### plants table (User's Plants)
```sql
- id
- user_id
- plant_name
- scientific_name    ← Used for matching
- nickname          ← Display name
- image_url
- health_status
```

### plant_maintenance table (Ideal Conditions)
```sql
- scientific_name   ← Matching key
- common_name
- min_temp_c        ← 🌡️ Temperature range
- max_temp_c
- min_humidity      ← 💧 Humidity range
- max_humidity
- max_wind_speed_kmph ← 💨 Wind tolerance
- watering_frequency_days
- watering_amount_liters
```

## Alert Generation Logic

```dart
// Example: Temperature Check
if (current_temp > max_temp_c) {
  Alert: "Temperature too high" (Warning)
  Recommendation: "Move to cooler location, increase watering"
}
else if (current_temp < min_temp_c) {
  Alert: "Temperature too low" (Critical)
  Recommendation: "Move indoors or provide frost protection"
}

// Example: Humidity Check
if (current_humidity < min_humidity) {
  Alert: "Low humidity - increase watering" (Warning)
  Recommendation: "Increase watering, consider misting leaves"
}

// Example: All Optimal
if (all conditions within range) {
  Alert: "Weather conditions are optimal" (Success)
  Recommendation: "Continue regular maintenance"
}
```

## User Journey

### Scenario 1: Critical Alert
```
1. User logs in
2. Home screen shows popup: "2 weather alerts found"
3. User sees: Tomato (temp high), Basil (temp low)
4. User taps "View Details"
5. Navigates to Maintenance > Alerts tab
6. Sees detailed recommendations for each plant
```

### Scenario 2: No Alerts
```
1. User logs in
2. No popup shown (all conditions optimal)
3. User navigates to Maintenance > Alerts tab
4. Sees green checkmarks for all plants
5. "Weather conditions are optimal" messages
```

### Scenario 3: New User
```
1. New user logs in
2. No plants added yet
3. No popup shown
4. Alerts tab shows: "No plants added yet"
5. User adds plants
6. Next time: Automatic alerts generated
```

## Technical Implementation

### Key Files Modified

1. **MaintenanceProvider** (`lib/providers/maintenance_provider.dart`)
   - `generateAlertsForAllUserPlants()` - Main logic
   - `getCriticalAlerts()` - Filter severe alerts
   - `alertsByPlant` - Grouped alert storage

2. **MaintenanceSchedulerScreen** (`lib/screens/maintenance_scheduler_screen.dart`)
   - `_initializeData()` - Auto-generate alerts on load
   - `_buildAlertsTab()` - Display grouped alerts

3. **HomeScreen** (`lib/screens/home_screen.dart`)
   - `_initializeWeatherAlerts()` - Setup weather & alerts
   - `_showWeatherAlertNotification()` - Popup dialog

### Data Flow

```
PlantProvider (User's Plants)
        ↓
MaintenanceProvider (Orchestrator)
        ↓
PlantMaintenanceService (Database Query)
        ↓
plant_maintenance table (Ideal Conditions)
        ↓
WeatherProvider (Current Weather)
        ↓
compareWithWeather() (Generate Alerts)
        ↓
alertsByPlant (Grouped Results)
        ↓
UI Display (Popup & Alerts Tab)
```

## Benefits

✅ **Zero Manual Work** - Alerts auto-generated for all plants  
✅ **Real-Time** - Based on actual current weather  
✅ **Intelligent** - Compares with scientific plant requirements  
✅ **Proactive** - Notifies before problems get worse  
✅ **Comprehensive** - All plants checked simultaneously  
✅ **Actionable** - Direct recommendations provided  

## Testing Checklist

- [ ] Login with no plants → No popup, "No plants added" message
- [ ] Login with plants in optimal conditions → No popup, green checkmarks
- [ ] Login with plants in warning conditions → Popup shows, orange alerts
- [ ] Login with plants in critical conditions → Popup shows, red alerts
- [ ] Tap "Dismiss" on popup → Dialog closes
- [ ] Tap "View Details" on popup → Navigates to maintenance screen
- [ ] Check Alerts tab → Shows all plants with grouped alerts
- [ ] Logout and login again → Popup shows again (new session)
- [ ] Stay logged in → Popup shows only once
