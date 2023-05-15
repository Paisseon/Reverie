enum SleepStatus {
    case autoSlept // Sleep percent reached
    case autoWoken // Wake percent reached
    case dreamless // In a state unrelated to Reverie
    case userSlept // CC module or prefs button pressed
    case userWoken // Upvolume pressed thrice
}
