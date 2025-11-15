# QR & Barcode Scanner App

A professional, feature-rich Flutter application for scanning and generating QR codes and barcodes with a modern, clean UI design.

## 🚀 Features

### Core Functionality

- **QR Code Scanner**: Real-time QR code detection with full-screen camera view
- **Barcode Scanner**: Support for multiple barcode formats (EAN-13, UPC, Code-128, etc.)
- **QR Code Generator**: Create custom QR codes with multiple types (URL, Text, Email, Phone, SMS, WiFi)
- **Barcode Generator**: Generate barcodes in 9 different formats (EAN-13, EAN-8, UPC-A, UPC-E, Code-128, Code-39, Code-93, ITF-14, Codabar)
- **History Management**: Save, search, filter, and manage scan/generation history
- **Export & Share**: Save to gallery, share barcodes/QR codes, copy to clipboard

### UI/UX Features

- **Modern Design**: Clean, minimalist interface with smooth animations
- **Full-Screen Scanning**: Immersive camera experience
- **Animated Scanning Indicator**: Visual feedback with animated blue dot
- **Responsive Layout**: Optimized for all screen sizes
- **Dark Theme**: Professional dark interface

## 📦 Packages Used

- `mobile_scanner` - Camera-based QR/barcode scanning
- `qr_flutter` - QR code generation
- `barcode` & `barcode_widget` - Barcode generation
- `shared_preferences` - Local data storage
- `path_provider` - File system access
- `share_plus` - Share functionality
- `image_gallery_saver` - Save images to gallery
- `permission_handler` - Permission management

## 🏗️ Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── history_item.dart     # History item model
├── screens/
│   ├── scanner_screen.dart    # Main scanner screen
│   ├── qr_generator_screen.dart
│   ├── barcode_generator_screen.dart
│   ├── history_screen.dart
│   └── settings_screen.dart
└── services/
    └── history_service.dart  # History management service
```

## 🛠️ Setup & Installation

### Prerequisites

- Flutter SDK (3.7.2 or higher)
- Android Studio / VS Code
- Android device or emulator

### Installation Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/JithinGK51/scanner_night.git
   cd scanner_night
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Android Configuration

Required permissions (already configured in `AndroidManifest.xml`):
- Camera
- Storage (with Android 13+ support)

## 📱 Screens

1. **Scanner Screen**: Full-screen camera scanner with animated scanning indicator
2. **QR Generator**: Create QR codes with multiple types and formats
3. **Barcode Generator**: Generate barcodes in various formats
4. **History**: Searchable scan/generation history with filters
5. **Settings**: Configure scanning behavior and preferences

## ✨ Key Features

### Scanner Screen
- Full-screen camera preview
- Animated scanning dot (blue pulse, green on success)
- Flash toggle
- Camera switch (front/back)
- Manual input option
- Auto-save to history

### QR Generator
- Multiple QR types (URL, Text, Email, Phone, SMS, WiFi)
- Real-time preview
- Copy, Save, Share functionality
- Auto-save to history

### Barcode Generator
- 9 barcode formats supported
- Input validation per format
- Real-time preview
- Copy, Save, Share functionality
- Auto-save to history

### History
- Search functionality
- Filter by type (All, Scanned, Generated, Favorites)
- Favorite/unfavorite items
- Delete items
- Clear all history
- View details

## 🎨 Design Philosophy

The app follows a **modern, minimalist design** with:
- Clean white cards on light gray background
- Smooth animations and transitions
- Intuitive navigation
- Professional color scheme (teal/green accents)

## 🔧 Technical Details

- **State Management**: StatefulWidget with SharedPreferences for persistence
- **Architecture**: Clean architecture with separation of concerns
- **Storage**: SharedPreferences for local data storage
- **Permissions**: Runtime permission handling
- **Error Handling**: Comprehensive error handling with user-friendly messages

## 📝 Notes

- All scanned and generated codes are automatically saved to history
- History persists across app restarts
- Maximum 1000 history items (oldest removed when limit reached)
- Duplicate prevention for same data and type

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is open source and available for personal and commercial use.

## 👨‍💻 Author

**JithinGK51**

---

**Version**: 1.1.0  
**Last Updated**: November 2025
