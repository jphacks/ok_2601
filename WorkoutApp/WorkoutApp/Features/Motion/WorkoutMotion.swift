
import Foundation
import CoreMotion
import Combine

final class WorkoutMotion: ObservableObject {
    private let motionManager = CMMotionManager()

    @Published var isAvailable = false
    @Published var pitch: Double = 0.0
    @Published var status = "未確認"
    @Published var count = 0

    // 計測開始時の姿勢
    private var baselinePitch: Double?
    
    // 起き上がった状態を検出済みか
    private var hasRaised = false

    // 誤検知を抑えるためのしきい値（ラジアン）
    private let raisedThreshold = 0.35
    private let returnedThreshold = 0.15

    func checkAvailability() {
        isAvailable = motionManager.isDeviceMotionAvailable

        if isAvailable {
            status = "モーションセンサーを利用できます"
        } else {
            status = "モーションセンサーを利用できません"
        }
    }

    func startMonitoring() {
        guard motionManager.isDeviceMotionAvailable else {
            isAvailable = false
            status = "モーションセンサーを利用できません"
            return
        }

        guard !motionManager.isDeviceMotionActive else {
            status = "計測中"
            return
        }

        count = 0
        baselinePitch = nil
        hasRaised = false

        motionManager.deviceMotionUpdateInterval = 0.1
        status = "基準姿勢を取得しています"

        motionManager.startDeviceMotionUpdates(to: .main) {
            [weak self] data, error in

            guard let self else { return }

            if let error {
                self.status = "エラー: \(error.localizedDescription)"
                return
            }

            guard let data else { return }

            let currentPitch = data.attitude.pitch
            self.pitch = currentPitch

            // 最初の姿勢を基準として保存
            guard let baseline = self.baselinePitch else {
                self.baselinePitch = currentPitch
                self.status = "計測中：横になった姿勢を基準にしました"
                return
            }

            let difference = abs(currentPitch - baseline)

            // 起き上がった状態を検出
            if !self.hasRaised &&
                difference >= self.raisedThreshold {
                self.hasRaised = true
                self.status = "起き上がりを検出しました"
            }

            // 基準姿勢に戻ったら1回加算
            if self.hasRaised &&
                difference <= self.returnedThreshold {
                self.count += 1
                self.hasRaised = false
                self.status = "計測中"
            }
        }
    }

    func stopMonitoring() {
        motionManager.stopDeviceMotionUpdates()
        status = "計測停止（\(count)回）"
        baselinePitch = nil
        hasRaised = false
    }
}
