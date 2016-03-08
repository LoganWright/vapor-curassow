# Vapor Curassow Server

Use <a href="https://github.com/kylef/Curassow">Curassow</a>'s HTTPServer in your Vapor application.

## Add Package

Include the package as a dependency to your project.

```swift
.Package(url: "https://github.com/qutheory/vapor-curassow-server.git", majorVersion: 0)
```

Example `Package.swift`

```swift
import PackageDescription

let package = Package(
    name: "VaporApp",
    dependencies: [
        .Package(url: "https://github.com/qutheory/vapor-curassow-server.git", majorVersion: 0)
    ]
)
```

## Add Provider

Once the package is included, import it and add the Provider.

```swift
import Vapor
import VaporCurassowServer

let app = Application()

// ... application logic

app.providers.append(VaporCurassowServer.Provider)
app.start()
```

## Run

Curassow requires some command line arguments to configure ports differently than 8000, here's an example call updating that.

```
swift build && .build/debug/YourAppName --bind 0.0.0.0:8080
```
