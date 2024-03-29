// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "IPaURLResourceUI",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "IPaURLResourceUI",
            targets: ["IPaURLResourceUI"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url:"https://github.com/ipapamagic/IPaXMLSection.git",from: "2.2.0") ,
        .package(url:"https://github.com/ipapamagic/IPaLog.git",from: "3.1.0") ,
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "IPaURLResourceUI",
            dependencies: [.product(name: "IPaXMLSection", package: "IPaXMLSection"),.product(name: "IPaLog", package: "IPaLog")]
        ),
        .testTarget(
            name: "IPaURLResourceUITests",
            dependencies: ["IPaURLResourceUI"]),
    ]
)
