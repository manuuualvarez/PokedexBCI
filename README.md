# PokeDex BCI - Your Ultimate Pokémon Companion

A modern, high-performance iOS application that brings the world of Pokémon to your fingertips. This app was developed as a technical challenge, showcasing professional iOS development skills while delivering a polished user experience.

![Pokémon App Banner](https://raw.githubusercontent.com/PokeAPI/media/master/logo/pokeapi_256.png)

## 🏗️ Architecture & Technologies

### MVVM-C Architecture
This application implements the MVVM-C (Model-View-ViewModel-Coordinator) pattern, an evolution of standard MVVM that offers significant advantages:

- **Better Navigation Management**: Coordinators handle all navigation logic, keeping it separate from view controllers
- **Enhanced Testability**: Each component is clearly separated and can be tested in isolation
- **Improved Code Organization**: Clear boundaries between different parts of the application
- **Greater Scalability**: New features can be added with minimal impact on existing code

### Key Technologies
- **UIKit** with programmatic views (no storyboards)
- **SnapKit** for declarative Auto Layout
- **Kingfisher** for efficient image loading and caching
- **SwiftData** for local persistence
- **Swift Package Manager** for dependency management

## 💾 Data Persistence

### SwiftData Implementation
The app leverages SwiftData for efficient local storage of Pokémon data:

- **Offline Capabilities**: Search and browse Pokémon even without an internet connection
- **Performance Optimization**: Reduces network calls through strategic caching
- **Automatic Updates**: Cache invalidation system to ensure data freshness
- **Type Safety**: Full type safety with Swift's strong type system

## 🧪 Testing Strategy

The project prioritizes code quality through comprehensive testing:

- **Unit Tests**: Verify individual components (ViewModels, Services, etc.)
- **Snapshot Tests**: Ensure UI consistency across devices and iOS versions using PointFree's swift-snapshot-testing
- **UI Tests**: Validate user flows and interactions
- **Mock Infrastructure**: Extensive mocking support for testing network calls and data sources

## ✨ Key Features

### Pokémon Listing & Search
- Browse a comprehensive list of Pokémon
- Search functionality to quickly find specific Pokémon by name
- Smooth scrolling performance even with large datasets

### Detailed Pokémon Information
- Type information with color-coded visual indicators
- Abilities, moves, and base stats
- High-quality sprite images

### Efficient Image Handling
- Optimized image loading pipeline
- Intelligent caching to reduce network usage
- Smooth transitions and placeholder images

## 📚 Development Best Practices

- **Clean Code**: Adherence to Swift style guidelines and best practices
- **Documentation**: Comprehensive inline documentation and comments
- **Error Handling**: Robust error handling with user-friendly messages
- **Dependency Injection**: Used throughout the app for better testability
- **Version Control**: Git workflow with meaningful commit messages

## 🚀 Getting Started

### Prerequisites
- Xcode 15.0+
- iOS 17.0+
- macOS Ventura or later

### Installation
1. Clone the repository
   ```bash
   git clone https://github.com/yourusername/pokedex-bci.git
   cd pokedex-bci
   ```

2. Open the project in Xcode
   ```bash
   open PokedexBCI.xcodeproj
   ```

3. Build and run the application
   - Select your desired simulator or connected device
   - Press Cmd+R or click the Run button

## 📝 License

This project is available under the MIT License. See the LICENSE file for more info.

---

Developed with ❤️ by Manuel Alvarez