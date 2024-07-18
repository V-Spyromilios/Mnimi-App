//
//  VisualEffect.swift
//  MyndVault
//
//  Created by Evangelos Spyromilios on 06.07.24.
//

import SwiftUI

//MARK: DEPRICATED

struct VisualEffectModifier: ViewModifier {
    let geometryProxy: GeometryProxy
    let height: CGFloat

    func body(content: Content) -> some View {
        content
//            .hueRotation(Angle(degrees: geometryProxy.frame(in: .global).origin.y / 10))
            .scaleEffect(VisualEffectFunctions.scale(geometryProxy, height: height), anchor: .top)
            .blur(radius: 1 * VisualEffectFunctions.progress(geometryProxy, height: height))
            .offset(y: VisualEffectFunctions.minY(geometryProxy))
            .offset(y: VisualEffectFunctions.excessTop(geometryProxy))
    }
}

extension View {
    func visualEffect(geometryProxy: GeometryProxy, height: CGFloat) -> some View {
        self.modifier(VisualEffectModifier(geometryProxy: geometryProxy, height: height))
    }
}

struct VisualEffectFunctions {
    static func minY(_ proxy: GeometryProxy) -> CGFloat {
        let minY = proxy.frame(in: .scrollView(axis: .vertical)).minY
        return minY < 0 ? -minY : 0
    }

    static func scale(_ proxy: GeometryProxy, height: CGFloat, scale: CGFloat = 0.1) -> CGFloat {
        let val = 1.0 - (progress(proxy, height: height) * scale)
        return val
    }

    static func excessTop(_ proxy: GeometryProxy, offset: CGFloat = 12) -> CGFloat {
        let p = progress(proxy, height: 80)  // Use default height for excessTop
        return -p * offset
    }

    static func brightness(_ proxy: GeometryProxy) -> CGFloat {
        let progress = progress(proxy, height: 80)  // Use default height for brightness
        let variation = 0.2
        let threshold = -0.2
        let value = -progress * variation
        return value < threshold ? threshold : value
    }

    static func progress(_ proxy: GeometryProxy, height: CGFloat) -> CGFloat {

        if minY(proxy) == 0 {
            return 0
        }
        let maxY = proxy.frame(in: .scrollView(axis: .vertical)).maxY
        let progress = 1.0 - (maxY / height)
        return progress
    }
}
