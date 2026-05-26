import Foundation

/// Opt-in timing logs for floating-pet translate + interaction stutter investigation.
///
/// Enable at launch:
///   `CODOGOTCHI_FLOATING_PERF_DEBUG=1` (Console.app filter: `FloatingPetPerf`)
///
/// Hypotheses under test (Fix 14):
/// 1. Interaction swaps during translate call `setInteraction` → `paintCurrentFrame`
///    (`SKTexture(cgImage:)` on the main thread in the same run-loop turn as `setFrameOrigin`).
/// 2. `restartTimer()` during interaction row changes causes RunLoop / phase hitches.
/// 3. `SKView.inLiveResize` is true while the panel origin moves, throttling SpriteKit draws
///    (see Apple Developer Forums “SpriteKit refresh during live resize”).
enum FloatingPetPerfDebug {
	static let enabled: Bool = {
		ProcessInfo.processInfo.environment["CODOGOTCHI_FLOATING_PERF_DEBUG"] == "1"
	}()

	/// Set by `FloatingPetInteractionView` during translate drags.
	static var isTranslating = false

	private static var dragSessionID = 0
	private static var translateEventCount = 0
	private static var lastTranslateLogTime: CFAbsoluteTime = 0
	private static var lastInLiveResizeLog: Bool?

	// MARK: - Translate drag session

	static func beginTranslateDrag() {
		guard enabled else { return }
		dragSessionID += 1
		translateEventCount = 0
		isTranslating = true
		lastTranslateLogTime = 0
		log("translate-drag BEGIN session=\(dragSessionID)")
	}

	static func endTranslateDrag() {
		guard enabled else { return }
		isTranslating = false
		log("translate-drag END session=\(dragSessionID) events=\(translateEventCount)")
	}

	static func translateTick(
		applyFrameMs: Double,
		emitMs: Double,
		interaction: FloatingInteraction?,
		interactionChanged: Bool,
		frameOrigin: CGPoint,
		inLiveResize: Bool
	) {
		guard enabled else { return }
		translateEventCount += 1
		let now = CFAbsoluteTimeGetCurrent()
		let shouldLog = interactionChanged
			|| inLiveResize
			|| (now - lastTranslateLogTime) > 0.2
		guard shouldLog else { return }
		lastTranslateLogTime = now
		log(
			String(
				format: "translate s=%d #%d apply=%.2fms emit=%.2fms interaction=%@ changed=%@ origin=(%.0f,%.0f) inLiveResize=%@",
				dragSessionID,
				translateEventCount,
				applyFrameMs,
				emitMs,
				interactionLabel(interaction),
				interactionChanged ? "Y" : "n",
				frameOrigin.x,
				frameOrigin.y,
				inLiveResize ? "Y" : "n"
			)
		)
	}

	// MARK: - Scene / interaction

	static func setInteraction(
		from prior: FloatingInteraction?,
		to interaction: FloatingInteraction?,
		branch: String,
		totalMs: Double,
		framesLoadMs: Double,
		paintMs: Double,
		restartedTimer: Bool,
		frameIndex: Int,
		frameCount: Int
	) {
		guard enabled else { return }
		log(
			String(
				format: "setInteraction %@→%@ branch=%@ total=%.2fms framesLoad=%.2fms paint=%.2fms restartTimer=%@ frame=%d/%d translating=%@",
				interactionLabel(prior),
				interactionLabel(interaction),
				branch,
				totalMs,
				framesLoadMs,
				paintMs,
				restartedTimer ? "Y" : "n",
				frameIndex,
				frameCount,
				isTranslating ? "Y" : "n"
			)
		)
	}

	static func restartTimer(intervalMs: Double, source: String, frameCount: Int) {
		guard enabled else { return }
		log(
			String(
				format: "restartTimer interval=%.1fms source=%@ frames=%d translating=%@",
				intervalMs,
				source,
				frameCount,
				isTranslating ? "Y" : "n"
			)
		)
	}

	static func paintSlow(ms: Double, frameIndex: Int, source: String, interaction: FloatingInteraction?) {
		guard enabled else { return }
		log(
			String(
				format: "paintSLOW %.2fms frame=%d source=%@ interaction=%@ translating=%@",
				ms,
				frameIndex,
				source,
				interactionLabel(interaction),
				isTranslating ? "Y" : "n"
			)
		)
	}

	static func noteInLiveResize(_ value: Bool) {
		guard enabled, isTranslating else { return }
		guard lastInLiveResizeLog != value else { return }
		lastInLiveResizeLog = value
		log("SKView.inLiveResize=\(value ? "Y" : "n") (during translate)")
	}

	// MARK: - Timing helper

	static func measure(_ body: () -> Void) -> Double {
		let start = CFAbsoluteTimeGetCurrent()
		body()
		return (CFAbsoluteTimeGetCurrent() - start) * 1000
	}

	private static func interactionLabel(_ interaction: FloatingInteraction?) -> String {
		guard let interaction else { return "nil" }
		return String(describing: interaction)
	}

	private static func log(_ message: String) {
		NSLog("[FloatingPetPerf] %@", message)
	}
}
