# Plant Maintenance Scheduler - User Guide

## 🌟 Overview
The maintenance scheduler automatically generates AI-powered care tasks for your plants based on:
- Your available time (days per week)
- Current weather conditions
- Individual plant needs
- Scientific recommendations

## 🚀 Features

### 1. **Smart Task Generation**
- AI analyzes each plant and generates personalized tasks
- Tasks include: watering, fertilizing, pruning, pest control
- Weather-aware recommendations (e.g., less watering during rain)
- Distributed across your available days

### 2. **Day-by-Day View**
- Navigate through 7 days using the day selector
- See all tasks for a specific day
- Tasks grouped by plant for easy tracking
- Progress bar shows completion percentage

### 3. **Task Management**
- ✅ Check off tasks as you complete them
- 📊 Track progress for each plant
- 🔄 Auto-refresh when tasks are completed
- 📝 Detailed notes and recommendations

### 4. **Customizable Schedule**
- Set how many days per week you can care for plants (1-7 days)
- System distributes tasks evenly across available days
- Easy to adjust settings at any time

## 📖 How to Use

### Step 1: Add Plants
Before using the maintenance scheduler, make sure you have added plants to "My Plants":
1. Go to **My Plants** screen
2. Add your plants using the camera or manual entry
3. Each plant will get its own maintenance schedule

### Step 2: Configure Your Availability
1. Open **Maintenance Schedule** screen
2. Tap the **Settings** icon (⚙️) in the top-right
3. Use the slider to select days per week (1-7)
   - **1-2 days**: Light maintenance schedule
   - **3-4 days**: Moderate care schedule
   - **5-7 days**: Intensive care schedule
4. Tap **Save**

### Step 3: Generate Tasks
1. Tap the **"Generate Tasks"** button (⭐ icon)
2. AI will analyze:
   - All your plants
   - Current weather in your location
   - Plant health and requirements
3. Tasks are created and distributed across your available days
4. Success message appears when complete

### Step 4: Complete Daily Tasks
1. **Navigate Days**: Swipe or tap on days to view tasks
2. **View Tasks**: Each plant shows its tasks with:
   - Task type (watering, fertilizing, pruning, etc.)
   - Description and recommendations
   - Additional notes (e.g., frequency, fertilizer type)
3. **Complete Tasks**: Tap checkbox when done
4. **Track Progress**: See completion percentage per plant

## 🎨 Task Types & Icons

| Icon | Task Type | Description |
|------|-----------|-------------|
| 💧 | Watering | Water your plants based on weather and soil conditions |
| 🌱 | Fertilizing | Apply nutrients according to plant growth stage |
| ✂️ | Pruning | Remove dead/damaged parts for healthy growth |
| 🐛 | Pest Control | Check for pests and apply treatments if needed |

## 💡 Tips for Best Results

### 1. **Keep Weather Updated**
- The system uses weather data for smart recommendations
- Visit **Weather Advisory** screen to refresh data
- Location services improve accuracy

### 2. **Regenerate Tasks Weekly**
- Weather and plant needs change
- Tap "Generate Tasks" each week for updated recommendations
- Old incomplete tasks remain visible

### 3. **Check Tasks Daily**
- Today's tasks are highlighted
- Complete tasks early in the day (morning recommended)
- Some tasks are time-sensitive (e.g., watering in heat)

### 4. **Adjust Availability**
- Start with 3 days/week if unsure
- Increase if you want more frequent care
- Decrease if schedule is too intensive

## 🤖 AI-Powered Recommendations

The system uses **Groq AI** with **Llama 3.1** model to generate recommendations based on:

### Weather Factors:
- **Temperature**: Adjusts watering frequency
- **Humidity**: Affects disease prevention
- **Rainfall**: Reduces watering needs
- **Wind**: Influences pruning timing

### Plant Factors:
- **Species**: Specific care requirements
- **Health Status**: Prioritizes recovery tasks
- **Growth Stage**: Age-appropriate care
- **Season**: Seasonal adjustments

### Smart Features:
- **Water Conservation**: Less watering during rain
- **Pest Prevention**: Proactive checks during humid weather
- **Growth Optimization**: Fertilizer timing for best results
- **Safety**: Warnings for extreme weather

## 📊 Understanding Progress

### Plant Card Headers:
- **Plant Name**: Identifies which plant
- **Task Count**: "X of Y tasks completed"
- **Percentage**: Overall completion (0-100%)
- **Progress Bar**: Visual completion indicator

### Task Status:
- **Unchecked**: Task pending
- **Checked**: Task completed
- **Strikethrough**: Completed task (for reference)

## 🔧 Database Setup Required

**IMPORTANT**: Before using this feature, you need to create the `user_settings` table in Supabase.

### Quick Setup:
1. Open your Supabase project dashboard
2. Go to **SQL Editor**
3. Open the file `USER_SETTINGS_TABLE.md` in this project
4. Copy the SQL code
5. Paste and run in Supabase SQL Editor
6. Table will be created with proper security policies

The app will automatically create default settings (3 days/week) for new users.

## ⚠️ Troubleshooting

### "No plants found. Add plants first"
- You need at least one plant in "My Plants"
- Go to My Plants → Add a plant → Return to Maintenance Schedule

### Tasks Not Generating
- Check internet connection (needs API access)
- Verify plants are added to your account
- Try again in a few minutes (API rate limits)

### Weather Data Missing
- Visit Weather Advisory screen
- Allow location access for GPS
- Or manually search for your city

### Settings Not Saving
- Ensure you're logged in
- Check database table is created (see USER_SETTINGS_TABLE.md)
- Try logging out and back in

## 🎯 Example Workflow

### Monday Morning:
1. Open Maintenance Schedule
2. View "Today" tasks
3. See: Water Tomato Plant, Check Rose for Pests
4. Complete watering → Check ✅
5. Inspect roses → Check ✅
6. Progress bar shows 100%

### Wednesday:
1. View Wednesday tasks
2. See: Fertilize Tomato Plant
3. Apply fertilizer as recommended
4. Check ✅
5. Read notes for fertilizer type used

### Sunday (Planning):
1. Tap "Generate Tasks"
2. AI creates new week's schedule
3. Review upcoming tasks
4. Adjust settings if needed

## � Best Practices

### Task Completion Tips
- ✅ **Complete tasks in order** - Prioritize overdue tasks first
- 📱 **Check daily** - Review tasks each morning for better planning
- 💧 **Weather check** - Look at weather alerts before watering
- 📝 **Add notes** - Document any observations for future reference

### Optimization Strategies
- 🎯 **Set realistic availability** - Start with 3 days/week, adjust as needed
- 🌱 **Group plants** - Similar plants can share maintenance schedules
- ⏰ **Best time slots** - Morning tasks work best for watering
- 📊 **Track patterns** - Monitor which tasks take longest

### Common Mistakes to Avoid
- ❌ Don't skip pest checks - Early detection prevents major issues
- ❌ Don't overwater - Follow AI recommendations, not just schedule
- ❌ Don't ignore weather - Heavy rain means skip watering tasks
- ❌ Don't forget fertilization - Essential for healthy plant growth

## �📈 Advanced Features (Coming Soon)

- 🔔 Push notifications for daily tasks
- 📅 Calendar view with all tasks
- 📊 Analytics: completion rates, plant health trends
- 🌐 Community sharing of care schedules
- 🎨 Custom task types and reminders
- 📸 Before/after photos for task tracking

## 🆘 Support

If you encounter issues:
1. Check [USER_SETTINGS_TABLE.md](USER_SETTINGS_TABLE.md) for database setup
2. Review [API_KEYS_SETUP.md](API_KEYS_SETUP.md) for API configuration
3. Check console logs for error messages
4. Ensure all packages are installed: `flutter pub get`

---

**Made with 🌱 by AgroCare Team**
*Powered by Groq AI, OpenWeatherMap, and Supabase*
