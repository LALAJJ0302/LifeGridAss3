import Lottie
import SwiftUI

struct GrowingPlantAnimation: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if reduceMotion {
            LottieView(animation: .named("growing_plant"))
                .currentProgress(1)
                .resizable()
        } else {
            LottieView(animation: .named("growing_plant"))
                .looping()
                .resizable()
        }
    }
}

struct SuccessCheckAnimation: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            if reduceMotion {
                LottieView(animation: .named("success_check"))
                    .currentProgress(1)
                    .resizable()
            } else {
                LottieView(animation: .named("success_check"))
                    .playing(.fromProgress(0, toProgress: 1, loopMode: .playOnce))
                    .resizable()
            }

            Image(systemName: "checkmark")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}

struct SupportPulseAnimation: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            if reduceMotion {
                LottieView(animation: .named("support_pulse"))
                    .currentProgress(1)
                    .resizable()
            } else {
                LottieView(animation: .named("support_pulse"))
                    .looping()
                    .resizable()
            }

            Image(systemName: "heart.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
}
