import OptikosPrimeSDK
import UIKit

/// All example colors are defined here and resolve against the current appearance.
enum ExampleTheme {
    static let style: OptikosPrimeStyle = {
        var style = OptikosPrimeStyle.default
        style.colors = .init(
            background: UIColor(light: UIColor(red: 0.96, green: 0.97, blue: 1, alpha: 1), dark: UIColor(red: 0.06, green: 0.08, blue: 0.16, alpha: 1)),
            surface: UIColor(light: .white, dark: UIColor(red: 0.12, green: 0.15, blue: 0.25, alpha: 1)),
            primaryText: UIColor(light: UIColor(red: 0.10, green: 0.14, blue: 0.28, alpha: 1), dark: .white),
            secondaryText: UIColor(light: .darkGray, dark: .lightGray),
            primaryAction: UIColor(light: UIColor(red: 0.25, green: 0.22, blue: 0.70, alpha: 1), dark: UIColor(red: 0.76, green: 0.73, blue: 1, alpha: 1)),
            primaryActionText: UIColor(light: .white, dark: UIColor(red: 0.10, green: 0.08, blue: 0.25, alpha: 1)),
            secondaryAction: UIColor(light: UIColor(red: 0.88, green: 0.89, blue: 0.97, alpha: 1), dark: UIColor(red: 0.20, green: 0.23, blue: 0.36, alpha: 1)),
            success: UIColor(light: UIColor(red: 0.08, green: 0.43, blue: 0.28, alpha: 1), dark: .systemMint),
            warning: UIColor(light: UIColor(red: 0.60, green: 0.32, blue: 0.02, alpha: 1), dark: .systemYellow),
            error: UIColor(light: UIColor(red: 0.72, green: 0.12, blue: 0.22, alpha: 1), dark: .systemPink)
        )
        style.layout.cornerRadius = 20

        return style
    }()

    static let customizedStyle: OptikosPrimeStyle = {
        var style = Self.style
        style.colors.primaryAction = UIColor(light: UIColor(red: 0.02, green: 0.40, blue: 0.33, alpha: 1), dark: .systemMint)
        style.colors.primaryActionText = UIColor(light: .white, dark: .black)
        style.layout.cornerRadius = 18
        return style
    }()
}
