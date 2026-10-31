import SwiftUI

struct ConfettiView: View {
    @State private var animate = false
    
    let colors: [Color] = [
        Color(red: 242/255, green: 108/255, blue: 146/255), // Theme pink
        Color.blue,
        Color.green,
        Color.yellow,
        Color.orange,
        Color.purple,
        Color.red
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<50, id: \.self) { index in
                    ConfettiPiece(
                        color: colors.randomElement() ?? Color.pink,
                        geometry: geometry
                    )
                    .opacity(animate ? 0 : 1)
                    .offset(
                        x: animate ? Double.random(in: -100...100) : 0,
                        y: animate ? geometry.size.height + 100 : -100
                    )
                    .rotationEffect(.degrees(animate ? Double.random(in: 0...360) : 0))
                    .animation(
                        .easeOut(duration: Double.random(in: 2.0...2.5))
                        .delay(Double.random(in: 0...0.1)),
                        value: animate
                    )
                }
            }
        }
        .onAppear {
            animate = true
        }
    }
}

struct ConfettiPiece: View {
    let color: Color
    let geometry: GeometryProxy
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(
                width: Double.random(in: 4...12),
                height: Double.random(in: 4...12)
            )
            .position(
                x: Double.random(in: 0...geometry.size.width),
                y: 0
            )
    }
}

struct ConfettiView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
            ConfettiView()
        }
    }
}
