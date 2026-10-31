import SwiftUI
import UIKit

// MARK: - Liquid Glass View with iOS 26 Support
struct LiquidGlassView<Content: View>: View {
    let content: Content
    let style: LiquidGlassStyle
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    let shadowColor: Color
    
    init(
        style: LiquidGlassStyle = .systemUltraThinMaterial,
        cornerRadius: CGFloat = 25,
        shadowRadius: CGFloat = 20,
        shadowColor: Color = .black.opacity(0.1),
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.shadowColor = shadowColor
        self.content = content()
    }
    
    var body: some View {
        // FIXED: Removed iOS 26.0 reference (iOS 26 doesn't exist)
        // Using BlurView for all iOS 16+ versions
        fallbackBlurView
    }
    
    // @available(iOS 26.0, *) - REMOVED: iOS 26 doesn't exist
    private var liquidGlassView: some View {
        content
            .background(
                LiquidGlassBackground(style: style)
                    .cornerRadius(cornerRadius)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 10)
    }
    
    private var fallbackBlurView: some View {
        content
            .background(
                ZStack {
                    // Blur background
                    BlurView(style: style.uiBlurStyle)
                        .ignoresSafeArea()
                    
                    // Semi-transparent overlay
                    Color.white.opacity(0.1)
                        .ignoresSafeArea()
                    
                    // Border
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 10)
    }
}

// MARK: - Liquid Glass Background (Future iOS version)
// @available(iOS 26.0, *) - REMOVED: iOS 26 doesn't exist
struct LiquidGlassBackground: UIViewRepresentable {
    let style: LiquidGlassStyle
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        
        // Create LiquidGlassUI effect
        let liquidGlass = LiquidGlassUI()
        liquidGlass.style = style.liquidGlassStyle
        liquidGlass.cornerRadius = 25
        liquidGlass.isUserInteractionEnabled = false
        
        // Add as subview
        view.addSubview(liquidGlass)
        liquidGlass.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            liquidGlass.topAnchor.constraint(equalTo: view.topAnchor),
            liquidGlass.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            liquidGlass.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            liquidGlass.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update if needed
    }
}

// MARK: - Liquid Glass Styles
enum LiquidGlassStyle {
    case systemUltraThinMaterial
    case systemThinMaterial
    case systemMaterial
    case systemThickMaterial
    case systemChromeMaterial
    
    // @available(iOS 26.0, *) - REMOVED: iOS 26 doesn't exist
    var liquidGlassStyle: LiquidGlassUI.Style {
        switch self {
        case .systemUltraThinMaterial:
            return .ultraThin
        case .systemThinMaterial:
            return .thin
        case .systemMaterial:
            return .regular
        case .systemThickMaterial:
            return .thick
        case .systemChromeMaterial:
            return .chrome
        }
    }
    
    var uiBlurStyle: UIBlurEffect.Style {
        switch self {
        case .systemUltraThinMaterial:
            return .systemUltraThinMaterial
        case .systemThinMaterial:
            return .systemThinMaterial
        case .systemMaterial:
            return .systemMaterial
        case .systemThickMaterial:
            return .systemThickMaterial
        case .systemChromeMaterial:
            return .systemChromeMaterial
        }
    }
}

// MARK: - Blur View for Fallback
struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

// MARK: - LiquidGlassUI Class (Placeholder for future iOS version)
// @available(iOS 26.0, *) - REMOVED: iOS 26 doesn't exist
class LiquidGlassUI: UIView {
    enum Style {
        case ultraThin
        case thin
        case regular
        case thick
        case chrome
    }
    
    var style: Style = .regular {
        didSet {
            updateStyle()
        }
    }
    
    var cornerRadius: CGFloat = 25 {
        didSet {
            layer.cornerRadius = cornerRadius
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .clear
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = true
        isUserInteractionEnabled = false
    }
    
    private func updateStyle() {
        // Update the visual style based on the selected style
        // This will be implemented when iOS 26 is released
        switch style {
        case .ultraThin:
            backgroundColor = UIColor.systemBackground.withAlphaComponent(0.1)
        case .thin:
            backgroundColor = UIColor.systemBackground.withAlphaComponent(0.2)
        case .regular:
            backgroundColor = UIColor.systemBackground.withAlphaComponent(0.3)
        case .thick:
            backgroundColor = UIColor.systemBackground.withAlphaComponent(0.4)
        case .chrome:
            backgroundColor = UIColor.systemBackground.withAlphaComponent(0.5)
        }
    }
}

// MARK: - Usage Examples
struct LiquidGlassExamples: View {
    var body: some View {
        VStack(spacing: 20) {
            // Basic usage
            LiquidGlassView {
                Text("Hello, Liquid Glass!")
                    .padding()
            }
            
            // Custom style
            LiquidGlassView(
                style: .systemThickMaterial,
                cornerRadius: 15,
                shadowRadius: 10
            ) {
                HStack {
                    Image(systemName: "star.fill")
                    Text("Custom Style")
                }
                .padding()
            }
            
            // Tab bar style
            LiquidGlassView(
                style: .systemUltraThinMaterial,
                cornerRadius: 25,
                shadowRadius: 20
            ) {
                HStack {
                    ForEach(0..<5, id: \.self) { _ in
                        Circle()
                            .fill(Color.appColor)
                            .frame(width: 20, height: 20)
                        Spacer()
                    }
                }
                .padding()
            }
        }
        .padding()
    }
}

#Preview {
    LiquidGlassExamples()
}

