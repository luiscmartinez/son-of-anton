import AppKit
import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation
import SpriteKit

@MainActor
final class FloatingPetScene: SKScene {
	private let codexPet: MaliPet
	private let codogotchiPet: CodogotchiPet?
	private let ciContext: CIContext
	private let desaturateFrame: (MaliPet.Frame) -> CGImage?
	private let interactionFrames: (FloatingInteraction) -> [MaliPet.Frame]

	private let petLayer = SKNode()
	private let overlayLayer = SKNode()
	private let spriteNode = SKSpriteNode()

	private var currentState: ActivityState = .idle
	private var currentMode: VisualMode = .normal
	private var currentInteraction: FloatingInteraction?
	private var currentFrames: [MaliPet.Frame] = []
	private var currentSource: FloatingFrameSource = .codex
	private var frameIndex: Int = 0
	private var timer: Timer?
	/// When set, overrides sheet-specific frame intervals (demo mode).
	private let demoFrameInterval: TimeInterval?

	init(
		size: CGSize,
		codexPet: MaliPet,
		codogotchiPet: CodogotchiPet?,
		demoFrameInterval: TimeInterval? = nil,
		desaturateFrame: ((MaliPet.Frame) -> CGImage?)? = nil,
		interactionFramesProvider: ((FloatingInteraction) -> [MaliPet.Frame])? = nil
	) {
		self.codexPet = codexPet
		self.codogotchiPet = codogotchiPet
		let context = CIContext(options: nil)
		self.ciContext = context
		self.desaturateFrame = desaturateFrame ?? { frame in
			Self.desaturate(frame, ciContext: context)
		}
		self.interactionFrames = interactionFramesProvider ?? { interaction in
			codexPet.floatingFrames(forInteraction: interaction)
		}
		self.demoFrameInterval = demoFrameInterval
		super.init(size: size)

		backgroundColor = .clear
		scaleMode = .resizeFill
		petLayer.name = "pet"
		overlayLayer.name = "overlays"
		addChild(petLayer)
		addChild(overlayLayer)
		petLayer.addChild(spriteNode)
		layoutLayers()

		let initialFrames = resolveFrames(for: .idle)
		currentFrames = initialFrames.frames
		currentSource = initialFrames.source
		paintCurrentFrame()
		restartTimer()
	}

	deinit {
		timer?.invalidate()
	}

	@available(*, unavailable)
	required init?(coder aDecoder: NSCoder) {
		fatalError("FloatingPetScene does not support storyboard initialization")
	}

	override var size: CGSize {
		didSet {
			layoutLayers()
			paintCurrentFrame()
		}
	}

	func update(state: ActivityState, visualMode: VisualMode) {
		let stateChanged = state != currentState || currentFrames.isEmpty
		currentState = state
		currentMode = visualMode

		// During an active mouse-reactive interaction the interaction animation
		// owns the sprite — defer the activity-state frame swap until the
		// interaction is cleared. The latest state is still stored so
		// `setInteraction(nil)` resumes from the most recent live/demo state.
		if currentInteraction != nil {
			paintCurrentFrame()
			return
		}

		if stateChanged {
			let resolved = resolveFrames(for: state)
			currentFrames = resolved.frames
			currentSource = resolved.source
			frameIndex = 0
		}

		paintCurrentFrame()

		if stateChanged || timer == nil {
			restartTimer()
		}
	}

	/// Apply or clear a transient mouse-reactive interaction overlay
	/// (running-right / running-left / jumping). When `interaction` is non-nil
	/// and the reserved Codex row provides non-empty frames, the scene swaps
	/// to those frames for the duration of the interaction. When the row is
	/// missing (empty frames) the interaction is dropped and the current
	/// activity-state animation remains in place. Passing `nil` restores the
	/// ordinary activity-state animation.
	func setInteraction(_ interaction: FloatingInteraction?) {
		let prior = currentInteraction
		let start = CFAbsoluteTimeGetCurrent()
		var branch = "noop"
		var paintMs = 0.0
		var restartedTimer = false

		guard let interaction else {
			guard currentInteraction != nil else { return }
			branch = "clear"
			currentInteraction = nil
			let resolved = resolveFrames(for: currentState)
			currentFrames = resolved.frames
			currentSource = resolved.source
			frameIndex = 0
			paintMs = FloatingPetPerfDebug.measure { paintCurrentFrame() }
			restartTimer()
			restartedTimer = true
			logSetInteraction(
				from: prior, to: nil, branch: branch, start: start,
				paintMs: paintMs, restartedTimer: restartedTimer, framesLoadMs: 0
			)
			return
		}

		if currentInteraction == interaction {
			branch = "same-interaction"
			logSetInteraction(
				from: prior, to: interaction, branch: branch, start: start,
				paintMs: paintMs, restartedTimer: restartedTimer, framesLoadMs: 0
			)
			return
		}

		var frames: [MaliPet.Frame] = []
		let framesLoadMs = FloatingPetPerfDebug.measure {
			frames = interactionFrames(interaction)
		}
		guard !frames.isEmpty else {
			if currentInteraction != nil {
				branch = "missing-row-clear"
				currentInteraction = nil
				let resolved = resolveFrames(for: currentState)
				currentFrames = resolved.frames
				currentSource = resolved.source
				frameIndex = 0
				paintMs = FloatingPetPerfDebug.measure { paintCurrentFrame() }
				restartTimer()
				restartedTimer = true
			} else {
				branch = "missing-row-noop"
			}
			logSetInteraction(
				from: prior, to: interaction, branch: branch, start: start,
				paintMs: paintMs, restartedTimer: restartedTimer, framesLoadMs: framesLoadMs
			)
			return
		}

		let priorSource = currentSource
		let priorFramesCount = currentFrames.count
		let preserveRunningCycle = Self.isRunningInteraction(prior)
			&& Self.isRunningInteraction(interaction)
		let preserveJumpingToRunningCycle = prior == .jumping
			&& Self.isRunningInteraction(interaction)

		currentInteraction = interaction
		currentFrames = frames
		currentSource = .codexInteraction
		if preserveRunningCycle || preserveJumpingToRunningCycle {
			branch = preserveRunningCycle ? "preserve-running" : "preserve-jumping-to-running"
			frameIndex = frameIndex % frames.count
			paintMs = FloatingPetPerfDebug.measure { paintCurrentFrame() }
			if priorSource == .codexInteraction, demoFrameInterval == nil, priorFramesCount != frames.count {
				restartTimer()
				restartedTimer = true
			}
		} else {
			branch = priorSource == .codexInteraction ? "swap-codex-interaction" : "swap-from-activity"
			frameIndex = 0
			paintMs = FloatingPetPerfDebug.measure { paintCurrentFrame() }
			if priorSource == .codexInteraction {
				if demoFrameInterval == nil, priorFramesCount != frames.count {
					restartTimer()
					restartedTimer = true
				}
			} else {
				restartTimer()
				restartedTimer = true
			}
		}

		logSetInteraction(
			from: prior, to: interaction, branch: branch, start: start,
			paintMs: paintMs, restartedTimer: restartedTimer, framesLoadMs: framesLoadMs
		)
	}

	private func logSetInteraction(
		from prior: FloatingInteraction?,
		to interaction: FloatingInteraction?,
		branch: String,
		start: CFAbsoluteTime,
		paintMs: Double,
		restartedTimer: Bool,
		framesLoadMs: Double
	) {
		let totalMs = (CFAbsoluteTimeGetCurrent() - start) * 1000
		FloatingPetPerfDebug.setInteraction(
			from: prior,
			to: interaction,
			branch: branch,
			totalMs: totalMs,
			framesLoadMs: framesLoadMs,
			paintMs: paintMs,
			restartedTimer: restartedTimer,
			frameIndex: frameIndex,
			frameCount: currentFrames.count
		)
	}

	private static func isRunningInteraction(_ interaction: FloatingInteraction?) -> Bool {
		interaction == .runningLeft || interaction == .runningRight
	}

	// MARK: - Test access

	var currentStateForTesting: ActivityState { currentState }
	var currentInteractionForTesting: FloatingInteraction? { currentInteraction }
	var currentFrameIndexForTesting: Int { frameIndex }
	var currentFramesForTesting: [NSImage] { currentFrames.map(\.image) }
	var currentFrameSourceForTesting: String { currentSource.logLabel }
	var petLayerForTesting: SKNode { petLayer }
	var overlayLayerForTesting: SKNode { overlayLayer }
	var currentTextureForTesting: SKTexture? { spriteNode.texture }
	var currentColorForTesting: NSColor { spriteNode.color }
	var currentColorBlendFactorForTesting: CGFloat { spriteNode.colorBlendFactor }

	func advanceFrameForTesting() {
		tick()
	}

	// MARK: - Internals

	private func restartTimer() {
		timer?.invalidate()
		guard !currentFrames.isEmpty else {
			timer = nil
			return
		}

		let interval: TimeInterval
		if let demo = demoFrameInterval {
			interval = demo
		} else {
			switch currentSource {
			case .codogotchi:
				interval = CodogotchiPet.frameInterval
			case .codexInteraction, .codex, .idleFallback:
				interval = MaliPet.animationCycleDuration / Double(max(currentFrames.count, 1))
			}
		}

		FloatingPetPerfDebug.restartTimer(
			intervalMs: interval * 1000,
			source: currentSource.logLabel,
			frameCount: currentFrames.count
		)

		let newTimer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
			Task { @MainActor in self?.tick() }
		}
		RunLoop.main.add(newTimer, forMode: .common)
		timer = newTimer
	}

	private func tick() {
		guard !currentFrames.isEmpty else {
			return
		}
		frameIndex = (frameIndex + 1) % currentFrames.count
		paintCurrentFrame()
	}

	private func resolveFrames(for state: ActivityState) -> (frames: [MaliPet.Frame], source: FloatingFrameSource) {
		let codexFrames = codexPet.floatingFrames(for: state)
		if !codexFrames.isEmpty { return (codexFrames, .codex) }

		let codogotchiFrames = codogotchiPet?.floatingFrames(for: state) ?? []
		if !codogotchiFrames.isEmpty { return (codogotchiFrames, .codogotchi) }

		return (codexPet.floatingFrames(for: .idle), .idleFallback)
	}

	private func paintCurrentFrame() {
		let paintStart = CFAbsoluteTimeGetCurrent()
		defer {
			let paintMs = (CFAbsoluteTimeGetCurrent() - paintStart) * 1000
			if paintMs > 4 {
				FloatingPetPerfDebug.paintSlow(
					ms: paintMs,
					frameIndex: frameIndex,
					source: currentSource.logLabel,
					interaction: currentInteraction
				)
			}
		}

		guard !currentFrames.isEmpty else {
			spriteNode.texture = nil
			return
		}

		let frame = currentFrames[frameIndex % currentFrames.count]
		let textureImage: CGImage
		let colorBlendFactor: CGFloat
		switch currentMode {
		case .normal:
			textureImage = frame.cgImage
			colorBlendFactor = 0
		case .desaturated:
			if let desaturated = desaturateFrame(frame) {
				textureImage = desaturated
				colorBlendFactor = 0
			} else {
				NSLog("FloatingPetScene: desaturate skipped - using gray failure fallback")
				textureImage = frame.cgImage
				colorBlendFactor = 1
			}
		}

		let texture = SKTexture(cgImage: textureImage)
		texture.filteringMode = .nearest
		spriteNode.texture = texture
		spriteNode.color = .gray
		spriteNode.colorBlendFactor = colorBlendFactor
		let spriteSize = fittedSpriteSize(for: frame.image.size)
		spriteNode.size = spriteSize
	}

	private func fittedSpriteSize(for imageSize: CGSize) -> CGSize {
		FloatingFramePolicy.fittedSpriteSize(imageSize: imageSize, panelSize: size)
	}

	private func layoutLayers() {
		let center = CGPoint(x: size.width / 2, y: size.height / 2)
		petLayer.position = center
		overlayLayer.position = center
		spriteNode.position = .zero
	}

	private static func desaturate(_ frame: MaliPet.Frame, ciContext: CIContext) -> CGImage? {
		let ci = CIImage(cgImage: frame.cgImage)
		let filter = CIFilter.colorControls()
		filter.inputImage = ci
		filter.saturation = 0
		guard let output = filter.outputImage else { return nil }
		return ciContext.createCGImage(output, from: output.extent)
	}

	private enum FloatingFrameSource {
		case codex
		case codogotchi
		case idleFallback
		case codexInteraction

		var logLabel: String {
			switch self {
			case .codex:
				return "codex"
			case .codogotchi:
				return "codogotchi"
			case .idleFallback:
				return "idle-fallback"
			case .codexInteraction:
				return "codex-interaction"
			}
		}
	}
}
