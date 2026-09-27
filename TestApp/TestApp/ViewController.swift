import OptikosPrimeSDK
import UIKit

final class ViewController: UIViewController {
    private let outputLabel = UILabel()
    private let languageSelector = UISegmentedControl(items: ["Swift", "Objective-C"])

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ExampleTheme.style.colors.background

        var buttonConfiguration = UIButton.Configuration.filled()
        buttonConfiguration.title = "Start full vision check"
        buttonConfiguration.cornerStyle = .medium
        buttonConfiguration.baseBackgroundColor = ExampleTheme.customizedStyle.colors.primaryAction
        buttonConfiguration.baseForegroundColor = ExampleTheme.customizedStyle.colors.primaryActionText
        let button = UIButton(configuration: buttonConfiguration)
        button.addTarget(self, action: #selector(startFullFlow), for: .touchUpInside)

        outputLabel.text = "Ready to start a vision check."
        outputLabel.font = .preferredFont(forTextStyle: .body)
        outputLabel.textColor = ExampleTheme.style.colors.secondaryText
        outputLabel.textAlignment = .center
        outputLabel.numberOfLines = 0

        languageSelector.selectedSegmentIndex = 0
        languageSelector.accessibilityLabel = "SDK integration language"
        let stack = UIStackView(arrangedSubviews: [languageSelector, button, outputLabel])
        stack.axis = .vertical
        stack.spacing = 24
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24)
        ])
    }

    @objc private func startFullFlow() {
        guard presentedViewController == nil else { return }
        guard let licenseKey = Bundle.main.object(forInfoDictionaryKey: "SDKLicenseKey") as? String,
              !licenseKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            outputLabel.text = "Set SDKLicenseKey in Info.plist to the production license for com.optikosprime.SDKUIKitExample."
            return
        }

        if languageSelector.selectedSegmentIndex == 1 {
            ObjCSDKExample.start(from: self, licenseKey: licenseKey) { [weak self] status in
                self?.outputLabel.text = status
            }
            return
        }

        do {
            try OptikosPrimeSDK.initialize(licenseKey: licenseKey, environment: .production)
            // Matches the internal example's complete customized flow, including the questionnaire.
            let configuration = OptikosPrimeConfiguration(style: ExampleTheme.customizedStyle, isOlderThan43: true)
            let controller = try OptikosPrimeSDKBridge.visionCheckViewController(configuration: configuration) { [weak self] completion in
                guard let self else { return }
                self.dismiss(animated: true)
                switch completion {
                case .completed(let result):
                    self.outputLabel.text = "Completed: \(result.conclusion.rawValue), measurement \(result.measurementID)"
                case .cancelled:
                    self.outputLabel.text = "The test was cancelled."
                case .failed(let error):
                    self.outputLabel.text = "The test failed: \(error)"
                @unknown default:
                    self.outputLabel.text = "The test returned an unknown status."
                }
            }
            controller.modalPresentationStyle = .fullScreen
            present(controller, animated: true)
        } catch {
            outputLabel.text = error.localizedDescription
        }
    }
}
